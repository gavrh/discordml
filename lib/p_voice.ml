type state = Disconnected | Connecting | Connected | Reconnecting | Closed

type udp = {
  udp_send : Cstruct.t list -> unit;
  udp_recv : Cstruct.t -> Eio.Net.Sockaddr.datagram * int;
  udp_close : unit -> unit;
}

type t = {
  sw : Eio.Switch.t;
  connect_ws : sw:Eio.Switch.t -> string -> Discord_private.P_ws.t;
  make_udp : sw:Eio.Switch.t -> ip:string -> port:int -> udp;
  clock : [ `Clock of float ] Eio.Time.clock;
  user_id : string;
  guild_id : string;
  channel_id : string;
  mutable self_mute : bool;
  mutable self_deaf : bool;
  send_gateway : Yojson.Safe.t -> unit;
  mutable state : state;
  mutable session_id : string option;
  mutable server : (string * string) option;
  mutable ssrc : int option;
  mutable stopping : bool;
  mutable voice_sw : Eio.Switch.t option;
  mutable conn : Discord_private.P_ws.t option;
  mutable udp : udp option;
  mutable key : string option;
  mutable mode : P_crypto.mode option;
  mutable dave : P_dave.session option;
  mutable dave_version : int;
  mutable dave_initialized : int option;
  mutable dave_external_sender : string option;
  mutable dave_ready : bool;
  mutable encryptor : P_dave.encryptor option;
  mutable sequence : int;
  mutable timestamp : int;
  mutable nonce : int;
  mutable last_seq : int;
  mutable acked : bool;
  mutable heartbeat_interval : float option;
  mutable speaking : bool;
  recognized_users : (string, unit) Hashtbl.t;
  pending_transitions : (int, int) Hashtbl.t;
  cond : Eio.Condition.t;
  cond_mutex : Eio.Mutex.t;
  ws_send_mutex : Eio.Mutex.t;
  state_handlers : (t -> state -> unit) list Atomic.t;
}

let guild_id (t : t) : string = t.guild_id
let channel_id (t : t) : string = t.channel_id
let state (t : t) : state = t.state
let ssrc (t : t) : int option = t.ssrc
let self_mute (t : t) : bool = t.self_mute
let self_deaf (t : t) : bool = t.self_deaf

let on_state_change (t : t) (f : t -> state -> unit) : unit =
  let rec add () =
    let current = Atomic.get t.state_handlers in
    if not (Atomic.compare_and_set t.state_handlers current (f :: current)) then
      add ()
  in
  add ()

let set_state (t : t) (state : state) : unit =
  t.state <- state;
  List.iter
    (fun f -> Eio.Fiber.fork ~sw:t.sw (fun () -> f t state))
    (Atomic.get t.state_handlers)

let send_json (t : t) (json : Yojson.Safe.t) : unit =
  match t.conn with
  | None -> ()
  | Some conn ->
      Eio.Mutex.use_rw ~protect:true t.ws_send_mutex (fun () ->
          if not (Discord_private.P_ws.is_closed conn) then
            Discord_private.P_ws.send_text conn (Yojson.Safe.to_string json))

let send_binary (t : t) (payload : string) : unit =
  match t.conn with
  | None -> ()
  | Some conn ->
      Eio.Mutex.use_rw ~protect:true t.ws_send_mutex (fun () ->
          if not (Discord_private.P_ws.is_closed conn) then
            Discord_private.P_ws.send_binary conn payload)

let now_ms (t : t) : int = int_of_float (Eio.Time.now t.clock *. 1000.)

let send_heartbeat (t : t) : unit =
  let d = `Assoc [ ("t", `Int (now_ms t)); ("seq_ack", `Int t.last_seq) ] in
  send_json t (`Assoc [ ("op", `Int 3); ("d", d) ]);
  t.acked <- false

let heartbeat_loop (t : t) (sw : Eio.Switch.t) : unit =
  match t.heartbeat_interval with
  | None -> ()
  | Some interval ->
      let rec loop () =
        Eio.Time.sleep t.clock interval;
        if not t.acked then
          Eio.Switch.fail sw (Failure "voice: heartbeat ack timeout")
        else begin
          send_heartbeat t;
          loop ()
        end
      in
      loop ()

let send_voice_state (t : t) (channel_id : string option) : unit =
  let d =
    `Assoc
      [
        ("guild_id", `String t.guild_id);
        ( "channel_id",
          match channel_id with Some id -> `String id | None -> `Null );
        ("self_mute", `Bool t.self_mute);
        ("self_deaf", `Bool t.self_deaf);
      ]
  in
  t.send_gateway (`Assoc [ ("op", `Int 4); ("d", d) ])

let close_conn (t : t) : unit =
  match t.conn with
  | Some conn ->
      Eio.Mutex.use_rw ~protect:true t.ws_send_mutex (fun () ->
          Discord_private.P_ws.close conn)
  | None -> ()

let request_reconnect (t : t) : unit = close_conn t

let on_session (t : t) (session_id : string) : unit =
  let changed =
    Eio.Mutex.use_rw ~protect:false t.cond_mutex (fun () ->
        let changed = t.session_id <> Some session_id in
        t.session_id <- Some session_id;
        changed)
  in
  if changed && t.state = Connected then request_reconnect t;
  Eio.Condition.broadcast t.cond

let on_server (t : t) ~(token : string) ~(endpoint : string) : unit =
  let changed =
    Eio.Mutex.use_rw ~protect:false t.cond_mutex (fun () ->
        let changed =
          match t.server with
          | Some (old_token, old_endpoint) ->
              old_token <> token || old_endpoint <> endpoint
          | None -> true
        in
        t.server <- Some (token, endpoint);
        changed)
  in
  if changed && t.state = Connected then request_reconnect t;
  Eio.Condition.broadcast t.cond

let dave_add_recognized_user (t : t) (user_id : string) : unit =
  Hashtbl.replace t.recognized_users user_id ();
  match t.dave with
  | Some session -> P_dave.session_add_recognized_user session user_id
  | None -> ()

let dave_remove_recognized_user (t : t) (user_id : string) : unit =
  Hashtbl.remove t.recognized_users user_id;
  match t.dave with
  | Some session -> P_dave.session_remove_recognized_user session user_id
  | None -> ()

let on_user_update (t : t) ~(user_id : string) ~(channel_id : string option) :
    unit =
  if user_id <> t.user_id then
    match channel_id with
    | Some channel_id when channel_id = t.channel_id ->
        dave_add_recognized_user t user_id
    | _ -> dave_remove_recognized_user t user_id

let wait_ready (t : t) : unit =
  Eio.Mutex.use_ro t.cond_mutex (fun () ->
      while (not t.stopping) && (t.session_id = None || t.server = None) do
        Eio.Condition.await t.cond t.cond_mutex
      done)

let set_mode (t : t) (mode : P_crypto.mode) : unit = t.mode <- Some mode

let choose_mode (t : t) (modes : string list) : P_crypto.mode =
  let has mode = List.mem (P_crypto.string_of_mode mode) modes in
  if has P_crypto.Aes256_gcm_rtpsize then P_crypto.Aes256_gcm_rtpsize
  else if has P_crypto.Xchacha20_poly1305_rtpsize then
    P_crypto.Xchacha20_poly1305_rtpsize
  else
    failwith
      ("voice: no supported encryption mode (offered: "
     ^ String.concat ", " modes ^ ")")

let int_of_bytes (json : Yojson.Safe.t) : string =
  let open Yojson.Safe.Util in
  match json with
  | `List bytes ->
      let b = Bytes.create (List.length bytes) in
      List.iteri
        (fun i value -> Bytes.set b i (Char.chr (to_int value land 0xff)))
        bytes;
      Bytes.unsafe_to_string b
  | `String s -> s
  | _ -> failwith "voice: invalid secret_key"

let setup_udp ~(net : 'a Eio.Net.t) ~(sw : Eio.Switch.t) ~(ip : string)
    ~(port : int) : udp =
  let domain = if String.contains ip ':' then `UdpV6 else `UdpV4 in
  let socket = Eio.Net.datagram_socket ~sw net domain in
  let dst =
    match Eio.Net.getaddrinfo_datagram net ip ~service:(string_of_int port) with
    | addr :: _ -> addr
    | [] -> failwith ("voice: could not resolve udp endpoint " ^ ip)
  in
  {
    udp_send = (fun bufs -> Eio.Net.send socket ~dst bufs);
    udp_recv = (fun buf -> Eio.Net.recv socket buf);
    udp_close = (fun () -> Eio.Net.close socket);
  }

let ip_discovery (t : t) (udp : udp) (ssrc : int) : string * int =
  let request = Cstruct.create 74 in
  Cstruct.BE.set_uint16 request 0 0x0001;
  Cstruct.BE.set_uint16 request 2 70;
  Cstruct.BE.set_uint32 request 4 (Int32.of_int ssrc);
  udp.udp_send [ request ];
  let response = Cstruct.create 74 in
  match
    Eio.Time.with_timeout t.clock 5.0 (fun () -> Ok (udp.udp_recv response))
  with
  | Ok (_, received) when received >= 74 ->
      let kind = Cstruct.BE.get_uint16 response 0 in
      if kind <> 0x0002 then failwith "voice: invalid ip discovery response";
      let address = Cstruct.to_string response ~off:8 ~len:64 in
      let address =
        match String.index_opt address '\000' with
        | Some i -> String.sub address 0 i
        | None -> address
      in
      let port = Cstruct.BE.get_uint16 response 72 in
      (address, port)
  | Ok _ -> failwith "voice: short ip discovery response"
  | Error `Timeout -> failwith "voice: ip discovery timed out"

let send_select_protocol (t : t) ~(address : string) ~(port : int)
    ~(mode : P_crypto.mode) : unit =
  let d =
    `Assoc
      [
        ("protocol", `String "udp");
        ( "data",
          `Assoc
            [
              ("address", `String address);
              ("port", `Int port);
              ("mode", `String (P_crypto.string_of_mode mode));
            ] );
      ]
  in
  send_json t (`Assoc [ ("op", `Int 1); ("d", d) ])

let send_speaking (t : t) ~(speaking : bool) : bool =
  match t.ssrc with
  | None -> false
  | Some ssrc ->
      let value = if speaking then 1 else 0 in
      let d =
        `Assoc
          [ ("speaking", `Int value); ("delay", `Int 0); ("ssrc", `Int ssrc) ]
      in
      send_json t (`Assoc [ ("op", `Int 5); ("d", d) ]);
      t.speaking <- speaking;
      true

let dave_destroy (t : t) : unit =
  (match t.encryptor with
  | Some encryptor -> P_dave.encryptor_destroy encryptor
  | None -> ());
  t.encryptor <- None;
  (match t.dave with
  | Some session -> P_dave.session_destroy session
  | None -> ());
  t.dave <- None;
  t.dave_initialized <- None;
  t.dave_ready <- false;
  t.dave_version <- 0;
  Hashtbl.clear t.pending_transitions

let send_key_package (t : t) : unit =
  match t.dave with
  | None -> ()
  | Some session ->
      let package = P_dave.session_get_key_package session in
      if String.length package > 0 then
        send_binary t (String.make 1 (Char.chr 26) ^ package)

let dave_set_external_sender (t : t) (data : string) : unit =
  t.dave_external_sender <- Some data;
  match t.dave with
  | None -> ()
  | Some session -> P_dave.session_set_external_sender session data

let dave_init (t : t) (version : int) : unit =
  t.dave_version <- version;
  if version <= 0 then begin
    dave_destroy t
  end
  else if t.dave_initialized = Some version then ()
  else begin
    (match t.dave with
    | Some session -> P_dave.session_destroy session
    | None -> ());
    let session = P_dave.session_create "" in
    t.dave <- Some session;
    (match t.dave_external_sender with
    | Some data -> P_dave.session_set_external_sender session data
    | None -> ());
    P_dave.session_init session ~version ~group_id:t.guild_id ~user_id:t.user_id;
    Hashtbl.iter
      (fun user_id () -> P_dave.session_add_recognized_user session user_id)
      t.recognized_users;
    t.dave_initialized <- Some version;
    send_key_package t
  end

let dave_reinit (t : t) : unit =
  t.dave_initialized <- None;
  dave_init t t.dave_version

let dave_reinit_version (t : t) (version : int) : unit =
  t.dave_initialized <- None;
  dave_init t version

let dave_apply_transition (t : t) (version : int) : unit =
  t.dave_version <- version;
  if version <= 0 then begin
    (match t.encryptor with
    | Some encryptor -> P_dave.encryptor_destroy encryptor
    | None -> ());
    t.encryptor <- None;
    t.dave_ready <- false;
    match t.dave with
    | Some session -> P_dave.session_reset session
    | None -> ()
  end
  else
    match (t.dave, t.ssrc) with
    | Some session, Some ssrc ->
        P_dave.session_set_protocol_version session version;
        let ratchet = P_dave.session_get_key_ratchet session t.user_id in
        if ratchet = 0n then failwith "voice: no DAVE key ratchet for self";
        let encryptor =
          match t.encryptor with
          | Some encryptor -> encryptor
          | None -> P_dave.encryptor_create ()
        in
        P_dave.encryptor_assign_ssrc encryptor ~ssrc ~codec:1;
        P_dave.encryptor_set_key_ratchet encryptor ratchet;
        P_dave.encryptor_set_passthrough encryptor false;
        P_dave.key_ratchet_destroy ratchet;
        t.encryptor <- Some encryptor;
        t.dave_ready <- true
    | _ -> failwith "voice: DAVE session is not initialized"

let dave_prepare_transition (t : t) ~(transition_id : int) ~(version : int) :
    unit =
  if transition_id = 0 then dave_apply_transition t version
  else Hashtbl.replace t.pending_transitions transition_id version

let send_transition_ready (t : t) (transition_id : int) : unit =
  send_json t
    (`Assoc
       [
         ("op", `Int 23); ("d", `Assoc [ ("transition_id", `Int transition_id) ]);
       ])

let send_invalid_commit (t : t) (transition_id : int) : unit =
  let b = Bytes.create 3 in
  Bytes.set b 0 (Char.chr 31);
  Bytes.set b 1 (Char.chr ((transition_id lsr 8) land 0xff));
  Bytes.set b 2 (Char.chr (transition_id land 0xff));
  send_binary t (Bytes.unsafe_to_string b)

let dave_process_commit (t : t) ~(transition_id : int) (commit : string) : unit
    =
  match t.dave with
  | None ->
      send_invalid_commit t transition_id;
      send_key_package t
  | Some session ->
      let result = P_dave.session_process_commit session commit in
      if result = 0n then begin
        send_invalid_commit t transition_id;
        dave_reinit t
      end
      else begin
        let ignored = P_dave.commit_result_is_ignored result in
        let failed = P_dave.commit_result_is_failed result in
        let joined = P_dave.commit_result_has_roster result in
        P_dave.commit_result_destroy result;
        if ignored then ()
        else if failed || not joined then begin
          send_invalid_commit t transition_id;
          dave_reinit t
        end
        else begin
          let version = P_dave.session_get_protocol_version session in
          dave_prepare_transition t ~transition_id ~version;
          if transition_id <> 0 then send_transition_ready t transition_id
        end
      end

let dave_process_welcome (t : t) ~(transition_id : int) (welcome : string) :
    unit =
  match t.dave with
  | None ->
      send_invalid_commit t transition_id;
      send_key_package t
  | Some session ->
      let result = P_dave.session_process_welcome session welcome in
      let joined = result <> 0n && P_dave.welcome_result_has_roster result in
      if result <> 0n then P_dave.welcome_result_destroy result;
      if joined then begin
        let version = P_dave.session_get_protocol_version session in
        dave_prepare_transition t ~transition_id ~version;
        if transition_id <> 0 then send_transition_ready t transition_id
      end
      else begin
        send_invalid_commit t transition_id;
        send_key_package t
      end

let dave_execute_transition (t : t) (transition_id : int) : unit =
  match Hashtbl.find_opt t.pending_transitions transition_id with
  | None -> ()
  | Some version ->
      Hashtbl.remove t.pending_transitions transition_id;
      dave_apply_transition t version

let int_option (json : Yojson.Safe.t) (name : string) : int option =
  let open Yojson.Safe.Util in
  match json |> member name with
  | `Int value -> Some value
  | `String value -> int_of_string_opt value
  | `Float value -> Some (int_of_float value)
  | _ -> None

let handle_dave_json (t : t) (op : int) (json : Yojson.Safe.t) : unit =
  match op with
  | 21 -> (
      match
        (int_option json "transition_id", int_option json "protocol_version")
      with
      | Some transition_id, Some version ->
          dave_prepare_transition t ~transition_id ~version;
          if transition_id <> 0 then send_transition_ready t transition_id
      | _ -> ())
  | 22 -> (
      match int_option json "transition_id" with
      | Some transition_id -> dave_execute_transition t transition_id
      | None -> ())
  | 24 -> (
      match (int_option json "epoch", int_option json "protocol_version") with
      | Some 1, Some version -> dave_reinit_version t version
      | Some _, Some version -> (
          match t.dave with
          | Some session -> P_dave.session_set_protocol_version session version
          | None -> dave_init t version)
      | _ -> ())
  | _ -> ()

let handle_dave_binary (t : t) (op : int) (payload : string) : unit =
  match op with
  | 25 -> dave_set_external_sender t payload
  | 27 -> (
      match t.dave with
      | Some session when String.length payload >= 1 ->
          let commit = P_dave.session_process_proposals session payload in
          if String.length commit > 0 then
            send_binary t (String.make 1 (Char.chr 28) ^ commit)
      | _ -> ())
  | 29 ->
      if String.length payload >= 2 then begin
        let transition_id =
          (Char.code payload.[0] lsl 8) lor Char.code payload.[1]
        in
        let commit = String.sub payload 2 (String.length payload - 2) in
        dave_process_commit t ~transition_id commit
      end
  | 30 ->
      if String.length payload >= 2 then begin
        let transition_id =
          (Char.code payload.[0] lsl 8) lor Char.code payload.[1]
        in
        let welcome = String.sub payload 2 (String.length payload - 2) in
        dave_process_welcome t ~transition_id welcome
      end
  | _ -> ()

let handle_session_description (t : t) (json : Yojson.Safe.t) : unit =
  let open Yojson.Safe.Util in
  (match json |> member "mode" |> to_string_option with
  | Some mode_text -> (
      match P_crypto.mode_of_string mode_text with
      | Some mode -> set_mode t mode
      | None -> failwith ("voice: unsupported session mode " ^ mode_text))
  | None -> ());
  (match json |> member "secret_key" with
  | `Null -> ()
  | key -> t.key <- Some (int_of_bytes key));
  let dave_version =
    int_option json "dave_protocol_version" |> Option.value ~default:0
  in
  if dave_version > 0 then dave_init t dave_version;
  set_state t Connected

let handle_ready (t : t) (sw : Eio.Switch.t) (json : Yojson.Safe.t) : unit =
  let open Yojson.Safe.Util in
  let ssrc = json |> member "ssrc" |> to_int in
  let ip = json |> member "ip" |> to_string in
  let port = json |> member "port" |> to_int in
  let modes =
    match json |> member "modes" with
    | `List modes ->
        List.filter_map (function `String mode -> Some mode | _ -> None) modes
    | _ -> []
  in
  let mode = choose_mode t modes in
  set_mode t mode;
  t.ssrc <- Some ssrc;
  (match t.udp with Some udp -> udp.udp_close () | None -> ());
  let udp = t.make_udp ~sw ~ip ~port in
  t.udp <- Some udp;
  let address, port = ip_discovery t udp ssrc in
  send_select_protocol t ~address ~port ~mode

let handle_json (t : t) (sw : Eio.Switch.t) (json : Yojson.Safe.t) : unit =
  let open Yojson.Safe.Util in
  (match json |> member "seq" |> to_int_option with
  | Some seq -> t.last_seq <- seq
  | None -> ());
  match json |> member "op" |> to_int_option with
  | Some 2 -> handle_ready t sw (json |> member "d")
  | Some 4 -> handle_session_description t (json |> member "d")
  | Some 6 -> t.acked <- true
  | Some 8 -> (
      match
        json |> member "d" |> member "heartbeat_interval" |> to_int_option
      with
      | Some interval ->
          t.heartbeat_interval <- Some (float_of_int interval /. 1000.)
      | None -> ())
  | Some 9 ->
      if t.speaking then ignore (send_speaking t ~speaking:true);
      set_state t Connected
  | Some 13 -> (
      match json |> member "d" |> member "user_id" |> to_string_option with
      | Some user_id when user_id = t.user_id ->
          failwith "voice: disconnected by the voice server"
      | _ -> ())
  | Some (21 | 22 | 24) ->
      handle_dave_json t (json |> member "op" |> to_int) (json |> member "d")
  | _ -> ()

let handle_binary (t : t) (data : string) : unit =
  if String.length data >= 3 then begin
    let seq = (Char.code data.[0] lsl 8) lor Char.code data.[1] in
    t.last_seq <- seq;
    let op = Char.code data.[2] in
    let payload = String.sub data 3 (String.length data - 3) in
    handle_dave_binary t op payload
  end

let read_hello (t : t) (conn : Discord_private.P_ws.t) : unit =
  match Discord_private.P_ws.recv conn with
  | Discord_private.P_ws.Closed _ ->
      failwith "voice: socket closed before hello"
  | Discord_private.P_ws.Data data -> (
      let json = Yojson.Safe.from_string data in
      let open Yojson.Safe.Util in
      match json |> member "op" |> to_int_option with
      | Some 8 -> (
          match
            json |> member "d" |> member "heartbeat_interval" |> to_int_option
          with
          | Some interval ->
              t.heartbeat_interval <- Some (float_of_int interval /. 1000.)
          | None -> ())
      | _ -> failwith "voice: expected hello")

let send_identify (t : t) ~(session_id : string) ~(token : string) : unit =
  let max_dave =
    if P_dave.available () then P_dave.max_protocol_version () else 0
  in
  let d =
    `Assoc
      [
        ("server_id", `String t.guild_id);
        ("user_id", `String t.user_id);
        ("session_id", `String session_id);
        ("token", `String token);
        ("max_dave_protocol_version", `Int max_dave);
      ]
  in
  send_json t (`Assoc [ ("op", `Int 0); ("d", d) ])

let connection_url (endpoint : string) : string =
  let scheme, host =
    if String.length endpoint >= 6 && String.sub endpoint 0 6 = "wss://" then
      ("wss://", String.sub endpoint 6 (String.length endpoint - 6))
    else if String.length endpoint >= 5 && String.sub endpoint 0 5 = "ws://"
    then ("ws://", String.sub endpoint 5 (String.length endpoint - 5))
    else ("wss://", endpoint)
  in
  let host =
    match String.index_opt host '/' with
    | Some i -> String.sub host 0 i
    | None -> (
        match String.index_opt host '?' with
        | Some i -> String.sub host 0 i
        | None -> host)
  in
  scheme ^ host ^ "/?v=8"

let rec listen (t : t) (sw : Eio.Switch.t) (conn : Discord_private.P_ws.t) :
    unit =
  match Discord_private.P_ws.recv conn with
  | Discord_private.P_ws.Closed (code, reason) ->
      if code = Discord_private.P_ws.Authentication_failed then
        failwith "voice: authentication failed"
      else if code = Discord_private.P_ws.Invalid_shard then
        failwith "voice: invalid shard"
      else if code = Discord_private.P_ws.Disallowed_intents then
        failwith "voice: voice connection rejected"
      else if code = Discord_private.P_ws.Unknown_code 4017 then
        failwith
          "voice: E2EE/DAVE protocol required (install libdave and set \
           DISCORDML_LIBDAVE)"
      else if code = Discord_private.P_ws.Unknown_code 4011 then
        failwith "voice: server not found"
      else if code = Discord_private.P_ws.Unknown_code 4012 then
        failwith "voice: unknown protocol"
      else if code = Discord_private.P_ws.Unknown_code 4014 then
        failwith "voice: disconnected"
      else if code = Discord_private.P_ws.Unknown_code 4016 then
        failwith "voice: unknown encryption mode"
      else if code = Discord_private.P_ws.Unknown_code 4020 then
        failwith "voice: bad request"
      else if code = Discord_private.P_ws.Unknown_code 4021 then
        failwith "voice: rate limited"
      else if code = Discord_private.P_ws.Unknown_code 4022 then
        failwith "voice: call terminated"
      else
        failwith
          (Printf.sprintf "voice: connection closed (%s%s)"
             (Discord_private.P_ws.show_close_code code)
             (if reason = "" then "" else ": " ^ reason))
  | Discord_private.P_ws.Data data -> (
      match
        if String.length data > 0 && data.[0] = '{' then
          handle_json t sw (Yojson.Safe.from_string data)
        else handle_binary t data
      with
      | () -> listen t sw conn
      | exception exn -> raise exn)

and connect_once (t : t) (sw : Eio.Switch.t) : unit =
  match (t.session_id, t.server) with
  | Some session_id, Some (token, endpoint) ->
      let url = connection_url endpoint in
      let conn = t.connect_ws ~sw url in
      t.conn <- Some conn;
      t.acked <- true;
      t.last_seq <- -1;
      read_hello t conn;
      Eio.Fiber.fork ~sw (fun () -> heartbeat_loop t sw);
      send_identify t ~session_id ~token;
      listen t sw conn
  | _ -> failwith "voice: missing session or server information"

let is_fatal_message (message : string) : bool =
  let prefixes =
    [
      "voice: authentication failed";
      "voice: invalid shard";
      "voice: voice connection rejected";
      "voice: server not found";
      "voice: unknown protocol";
      "voice: disconnected";
      "voice: disconnected by the voice server";
      "voice: unknown encryption mode";
      "voice: bad request";
      "voice: rate limited";
      "voice: call terminated";
      "voice: E2EE/DAVE protocol required";
    ]
  in
  List.exists
    (fun prefix ->
      String.length message >= String.length prefix
      && String.sub message 0 (String.length prefix) = prefix)
    prefixes

let rec manager (t : t) (first : bool) : unit =
  if t.stopping then set_state t Closed
  else begin
    wait_ready t;
    if t.stopping then set_state t Closed
    else begin
      if first && t.state = Disconnected then set_state t Connecting
      else if t.state <> Connecting then set_state t Reconnecting;
      let outcome =
        try
          Eio.Switch.run @@ fun sw ->
          t.voice_sw <- Some sw;
          Fun.protect
            ~finally:(fun () ->
              t.conn <- None;
              match t.udp with
              | Some udp ->
                  udp.udp_close ();
                  t.udp <- None
              | None -> ())
            (fun () -> connect_once t sw);
          `Retry
        with
        | Eio.Cancel.Cancelled _ when t.stopping -> `Stopped
        | Failure message when is_fatal_message message ->
            prerr_endline message;
            `Fatal
        | exn ->
            if not t.stopping then
              prerr_endline ("voice: " ^ Printexc.to_string exn);
            `Retry
      in
      t.voice_sw <- None;
      t.conn <- None;
      (match t.udp with
      | Some udp ->
          udp.udp_close ();
          t.udp <- None
      | None -> ());
      match outcome with
      | `Stopped -> set_state t Closed
      | `Fatal -> set_state t Closed
      | `Retry ->
          if t.stopping then set_state t Closed
          else begin
            set_state t Reconnecting;
            Eio.Time.sleep t.clock 1.0;
            if t.stopping then set_state t Closed
            else begin
              (* Force a fresh voice session; the gateway will send a new
                 VOICE_STATE_UPDATE and VOICE_SERVER_UPDATE. *)
              Eio.Mutex.use_rw ~protect:false t.cond_mutex (fun () ->
                  t.session_id <- None;
                  t.server <- None);
              t.key <- None;
              t.mode <- None;
              t.ssrc <- None;
              t.speaking <- false;
              dave_destroy t;
              send_voice_state t (Some t.channel_id);
              manager t false
            end
          end
    end
  end

let create ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
    ~(clock : [ `Clock of float ] Eio.Time.clock) ~(user_id : string)
    ~(session_id : string option) ~(guild_id : string) ~(channel_id : string)
    ?(self_mute = false) ?(self_deaf = false)
    ~(send_gateway : Yojson.Safe.t -> unit) () : t =
  let connect_ws ~sw url = Discord_private.P_ws.connect ~sw ~net ~url in
  let make_udp ~sw ~ip ~port = setup_udp ~net ~sw ~ip ~port in
  let t =
    {
      sw;
      connect_ws;
      make_udp;
      clock;
      user_id;
      guild_id;
      channel_id;
      self_mute;
      self_deaf;
      send_gateway;
      state = Disconnected;
      session_id;
      server = None;
      ssrc = None;
      stopping = false;
      voice_sw = None;
      conn = None;
      udp = None;
      key = None;
      mode = None;
      dave = None;
      dave_version = 0;
      dave_initialized = None;
      dave_external_sender = None;
      dave_ready = false;
      encryptor = None;
      sequence = 0;
      timestamp = 0;
      nonce = 0;
      last_seq = -1;
      acked = true;
      heartbeat_interval = None;
      speaking = false;
      recognized_users = Hashtbl.create 0;
      pending_transitions = Hashtbl.create 0;
      cond = Eio.Condition.create ();
      cond_mutex = Eio.Mutex.create ();
      ws_send_mutex = Eio.Mutex.create ();
      state_handlers = Atomic.make [];
    }
  in
  set_state t Connecting;
  Eio.Fiber.fork ~sw (fun () -> manager t false);
  t

let send_audio (t : t) (opus : string) : bool =
  match (t.conn, t.udp, t.key, t.mode, t.ssrc) with
  | Some _, Some udp, Some key, Some mode, Some ssrc ->
      let payload =
        if t.dave_version > 0 then
          match t.encryptor with
          | Some encryptor when t.dave_ready ->
              let code, frame = P_dave.encryptor_encrypt encryptor ~ssrc opus in
              if code <> 0 then "" else frame
          | _ -> ""
        else opus
      in
      if payload = "" then false
      else begin
        let header = Bytes.create 12 in
        Bytes.set header 0 (Char.chr 0x80);
        Bytes.set header 1 (Char.chr 0x78);
        Bytes.set header 2 (Char.chr ((t.sequence lsr 8) land 0xff));
        Bytes.set header 3 (Char.chr (t.sequence land 0xff));
        Bytes.set header 4 (Char.chr ((t.timestamp lsr 24) land 0xff));
        Bytes.set header 5 (Char.chr ((t.timestamp lsr 16) land 0xff));
        Bytes.set header 6 (Char.chr ((t.timestamp lsr 8) land 0xff));
        Bytes.set header 7 (Char.chr (t.timestamp land 0xff));
        Bytes.set header 8 (Char.chr ((ssrc lsr 24) land 0xff));
        Bytes.set header 9 (Char.chr ((ssrc lsr 16) land 0xff));
        Bytes.set header 10 (Char.chr ((ssrc lsr 8) land 0xff));
        Bytes.set header 11 (Char.chr (ssrc land 0xff));
        let header = Bytes.unsafe_to_string header in
        let packet =
          P_crypto.encrypt mode ~key ~counter:t.nonce ~header payload
        in
        udp.udp_send [ Cstruct.of_string packet ];
        t.sequence <- (t.sequence + 1) land 0xffff;
        t.timestamp <- (t.timestamp + 960) land 0xffffffff;
        t.nonce <- (t.nonce + 1) land 0xffffffff;
        true
      end
  | _ -> false

let play (t : t) ~(source : unit -> int array option) : unit =
  match t.voice_sw with
  | None -> failwith "voice: not connected"
  | Some sw ->
      if not (P_opus.available ()) then
        failwith ("voice: " ^ P_opus.load_error ());
      Eio.Fiber.fork ~sw (fun () ->
          let encoder = P_opus.encoder_create () in
          let speaking = ref false in
          let start_speaking () =
            if not !speaking then speaking := send_speaking t ~speaking:true
          in
          let stop_speaking () =
            if !speaking then begin
              ignore (send_speaking t ~speaking:false);
              speaking := false
            end
          in
          Fun.protect
            ~finally:(fun () ->
              (try stop_speaking () with _ -> ());
              P_opus.encoder_destroy encoder)
            (fun () ->
              let rec loop () =
                match source () with
                | None ->
                    if !speaking then begin
                      for _ = 1 to 5 do
                        ignore (send_audio t "\xF8\xFF\xFE");
                        Eio.Time.sleep t.clock 0.02
                      done;
                      stop_speaking ()
                    end
                | Some pcm ->
                    start_speaking ();
                    ignore (send_audio t (P_opus.encode encoder pcm));
                    Eio.Time.sleep t.clock 0.02;
                    loop ()
              in
              loop ()))

let set_self_mute (t : t) (mute : bool) : unit =
  t.self_mute <- mute;
  if not t.stopping then send_voice_state t (Some t.channel_id)

let set_self_deaf (t : t) (deaf : bool) : unit =
  t.self_deaf <- deaf;
  if not t.stopping then send_voice_state t (Some t.channel_id)

let leave (t : t) : unit =
  if not t.stopping then begin
    t.stopping <- true;
    Eio.Condition.broadcast t.cond;
    send_voice_state t None;
    if t.speaking then ignore (send_speaking t ~speaking:false);
    close_conn t;
    (match t.voice_sw with
    | Some sw -> Eio.Switch.fail sw (Failure "voice: left")
    | None -> ());
    dave_destroy t;
    set_state t Closed
  end
