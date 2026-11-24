module Request_io = Cohttp.Request.Private.Make (Cohttp_eio.Private.IO)
module Response_io = Cohttp.Response.Private.Make (Cohttp_eio.Private.IO)

type connection = [ Eio.Flow.two_way_ty | Eio.Resource.close_ty ] Eio.Std.r

type idle_connection = {
  conn : connection;
  reader : Eio.Buf_read.t;
  since : float;
}

type t = {
  connect :
    sw:Eio.Switch.t -> on_connection:(connection -> unit) -> Uri.t -> connection;
  sw : Eio.Switch.t;
  token : string;
  timeout : 'a. float -> (unit -> 'a) -> ('a, [ `Timeout ]) result;
  now : unit -> float;
  mutex : Eio.Mutex.t;
  idle : (string, idle_connection list) Hashtbl.t;
  pooling : bool;
}

let request_timeout : float = 30.
let idle_timeout : float = 30.
let max_idle_per_host : int = 2
let endpoint : string = "https://discord.com/api/v10"

let user_agent : string =
  "DiscordBot (https://github.com/gavrh/discordml, 0.1.0)"

let https () =
  let authenticator =
    match Ca_certs.authenticator () with
    | Ok a -> a
    | Error (`Msg m) -> failwith ("rest: ca-certs: " ^ m)
  in
  let tls_config =
    match Tls.Config.client ~authenticator () with
    | Ok c -> c
    | Error (`Msg m) -> failwith ("rest: tls config: " ^ m)
  in
  fun uri raw ->
    let host =
      Uri.host uri
      |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
    in
    Tls_eio.client_of_flow ?host tls_config raw

let connect_uri ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
    ~(on_connection : connection -> unit)
    ~(https :
       Uri.t ->
       [ Eio.Flow.two_way_ty | Eio.Resource.close_ty ] Eio.Std.r ->
       [> Eio.Resource.close_ty ] Eio.Flow.two_way) (uri : Uri.t) : connection =
  let service =
    match Uri.port uri with
    | Some port -> Int.to_string port
    | None -> Uri.scheme uri |> Option.value ~default:"http"
  in
  let address =
    match
      Eio.Net.getaddrinfo_stream ~service net
        (Uri.host_with_default ~default:"localhost" uri)
    with
    | address :: _ -> address
    | [] -> failwith "rest: failed to resolve hostname"
  in
  let raw = (Eio.Net.connect ~sw net address :> connection) in
  on_connection raw;
  match Uri.scheme uri with
  | Some "https" -> (https uri raw :> connection)
  | Some "http" -> raw
  | scheme ->
      failwith
        (Printf.sprintf "rest: unsupported URL scheme: %s"
           (Option.value scheme ~default:"<none>"))

let pooling_enabled_from_env () =
  match Sys.getenv_opt "DISCORDML_REST_POOL" with
  | Some ("0" | "false" | "no" | "off") -> false
  | _ -> true

let create ?(pooling = pooling_enabled_from_env ()) ~(sw : Eio.Switch.t)
    ~(net : 'a Eio.Net.t) ~(clock : 'b Eio.Time.clock) ~(token : string) () : t
    =
  Mirage_crypto_rng_unix.use_default ();
  let https = https () in
  let connect ~sw ~on_connection uri =
    connect_uri ~sw ~net ~https ~on_connection uri
  in
  let timeout : 'a. float -> (unit -> 'a) -> ('a, [ `Timeout ]) result =
   fun duration f -> Eio.Time.with_timeout clock duration (fun () -> Ok (f ()))
  in
  {
    connect;
    sw;
    token;
    timeout;
    now = (fun () -> Eio.Time.now clock);
    mutex = Eio.Mutex.create ();
    idle = Hashtbl.create 0;
    pooling;
  }

let cohttp_meth (meth : string) =
  match meth with
  | "GET" -> `GET
  | "POST" -> `POST
  | "PUT" -> `PUT
  | "PATCH" -> `PATCH
  | "DELETE" -> `DELETE
  | meth -> invalid_arg ("p_http: unsupported method: " ^ meth)

let random_boundary () : string =
  let raw = Mirage_crypto_rng.generate 16 in
  let b = Buffer.create 32 in
  String.iter (fun c -> Printf.bprintf b "%02x" (Char.code c)) raw;
  Buffer.contents b

let escape_filename (name : string) : string =
  let b = Buffer.create (String.length name) in
  String.iter
    (fun c ->
      match c with
      | '\r' | '\n' -> ()
      | '"' -> Buffer.add_string b "%22"
      | '\\' -> Buffer.add_string b "%5C"
      | c -> Buffer.add_char b c)
    name;
  Buffer.contents b

let multipart_body (field : string) (boundary : string) (body : string option)
    (files : (string * string * string option) list) : string =
  let b = Buffer.create 1024 in
  let crlf () = Buffer.add_string b "\r\n" in
  (match body with
  | Some json ->
      Buffer.add_string b ("--" ^ boundary);
      crlf ();
      Buffer.add_string b
        "Content-Disposition: form-data; name=\"payload_json\"";
      crlf ();
      Buffer.add_string b "Content-Type: application/json";
      crlf ();
      crlf ();
      Buffer.add_string b json;
      crlf ()
  | None -> ());
  List.iteri
    (fun i (filename, content, content_type) ->
      Buffer.add_string b ("--" ^ boundary);
      crlf ();
      let name =
        if field = "files" then Printf.sprintf "files[%d]" i else field
      in
      Buffer.add_string b
        (Printf.sprintf
           "Content-Disposition: form-data; name=\"%s\"; filename=\"%s\"" name
           (escape_filename filename));
      crlf ();
      let content_type =
        Option.value content_type ~default:"application/octet-stream"
      in
      if String.contains content_type '\r' || String.contains content_type '\n'
      then failwith "rest: attachment content_type must not contain CR/LF";
      Buffer.add_string b ("Content-Type: " ^ content_type);
      crlf ();
      crlf ();
      Buffer.add_string b content;
      crlf ())
    files;
  Buffer.add_string b ("--" ^ boundary ^ "--");
  crlf ();
  Buffer.contents b

let host_key (uri : Uri.t) : string =
  Uri.host_with_default ~default:"localhost" uri

let close_connection (conn : connection) : unit =
  try Eio.Flow.close conn with _ -> ()

let take_idle (t : t) (host : string) : idle_connection option =
  let now = t.now () in
  let stale = ref [] in
  let found =
    Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
        let rec loop () =
          match Hashtbl.find_opt t.idle host with
          | None | Some [] ->
              Hashtbl.remove t.idle host;
              None
          | Some (entry :: rest) ->
              if rest = [] then Hashtbl.remove t.idle host
              else Hashtbl.replace t.idle host rest;
              if now -. entry.since > idle_timeout then begin
                stale := entry.conn :: !stale;
                loop ()
              end
              else Some entry
        in
        loop ())
  in
  List.iter close_connection !stale;
  found

let connect_fresh (t : t) ~(on_connection : connection -> unit) (uri : Uri.t) :
    idle_connection =
  let conn = t.connect ~sw:t.sw ~on_connection uri in
  on_connection conn;
  { conn; reader = Eio.Buf_read.of_flow ~max_size:max_int conn; since = 0. }

let acquire (t : t) ?(fresh = false) ~(on_connection : connection -> unit)
    (uri : Uri.t) : idle_connection * bool =
  if fresh || not t.pooling then (connect_fresh t ~on_connection uri, false)
  else
    match take_idle t (host_key uri) with
    | Some entry ->
        on_connection entry.conn;
        (entry, true)
    | None -> (connect_fresh t ~on_connection uri, false)

let release (t : t) (host : string) (entry : idle_connection) : unit =
  let keep =
    t.pooling
    && Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
        let idle = Option.value (Hashtbl.find_opt t.idle host) ~default:[] in
        if List.length idle >= max_idle_per_host then false
        else begin
          Hashtbl.replace t.idle host ({ entry with since = t.now () } :: idle);
          true
        end)
  in
  if not keep then close_connection entry.conn

let response_body (response : Cohttp.Response.t) (reader : Eio.Buf_read.t) :
    string =
  match Cohttp.Response.has_body response with
  | `No -> ""
  | `Yes | `Unknown ->
      let body_reader = Response_io.make_body_reader response reader in
      let buffer = Buffer.create 1024 in
      let rec loop () =
        match Response_io.read_body_chunk body_reader with
        | Cohttp.Transfer.Done -> ()
        | Chunk chunk | Final_chunk chunk ->
            Buffer.add_string buffer chunk;
            if Buffer.length buffer > 10_000_000 then
              failwith "rest: response body too large";
            loop ()
      in
      loop ();
      Buffer.contents buffer

let exchange (entry : idle_connection) ~(meth : Cohttp.Code.meth)
    ~(headers : Http.Header.t) ~(body : string option) (uri : Uri.t) :
    Cohttp.Response.t * string =
  let body_length =
    match body with
    | None -> 0L
    | Some body -> Int64.of_int (String.length body)
  in
  let request =
    Cohttp.Request.make ~meth ~headers
      ~encoding:(Cohttp.Transfer.Fixed body_length) uri
  in
  Eio.Buf_write.with_flow entry.conn (fun output ->
      Request_io.write ~flush:true
        (fun writer ->
          match body with
          | None -> ()
          | Some body -> Request_io.write_body writer body)
        request output);
  match Response_io.read entry.reader with
  | `Eof -> raise End_of_file
  | `Invalid reason -> failwith ("rest: invalid response: " ^ reason)
  | `Ok response -> (response, response_body response entry.reader)

let retryable_exception = function
  | End_of_file -> true
  | Eio.Io _ -> true
  | Unix.Unix_error _ -> true
  | Tls_eio.Tls_alert _ -> true
  | Tls_eio.Tls_failure _ -> true
  | _ -> false

let send (t : t) ?(headers = []) ?(body : string option)
    ?(files : (string * string * string option) list = [])
    ?(file_field = "files") ?content_type ?(authorization = "Bot " ^ t.token)
    ~(meth : string) (path : string) =
  let uri = Uri.of_string (endpoint ^ path) in
  let content_type, body =
    if files = [] then
      (Option.value content_type ~default:"application/json", body)
    else
      let boundary = random_boundary () in
      ( "multipart/form-data; boundary=" ^ boundary,
        Some (multipart_body file_field boundary body files) )
  in
  let authorization =
    if authorization = "" then [] else [ ("Authorization", authorization) ]
  in
  let all_headers =
    Http.Header.of_list
      (authorization
      @ [ ("User-Agent", user_agent); ("Content-Type", content_type) ]
      @ headers)
  in
  let host = host_key uri in
  let rec attempt ~(retried : bool) ~(fresh : bool) =
    let current = ref None in
    let reused = ref false in
    let on_connection conn = current := Some conn in
    let result =
      try
        match
          t.timeout request_timeout (fun () ->
              let entry, is_reused = acquire t ~fresh ~on_connection uri in
              reused := is_reused;
              let response =
                exchange entry ~meth:(cohttp_meth meth) ~headers:all_headers
                  ~body uri
              in
              (entry, response))
        with
        | Ok value -> Ok value
        | Error `Timeout -> Error `Timeout
      with
      | Eio.Cancel.Cancelled _ as exn ->
          Option.iter close_connection !current;
          raise exn
      | exn -> Error (`Exn exn)
    in
    match result with
    | Ok (entry, (response, body)) ->
        if
          Http.Response.is_keep_alive response
          && Cohttp.Response.has_body response <> `Unknown
        then release t host entry
        else close_connection entry.conn;
        (response, body)
    | Error `Timeout ->
        Option.iter close_connection !current;
        failwith
          (Printf.sprintf "rest: %s %s timed out after %.0fs" meth path
             request_timeout)
    | Error (`Exn exn) ->
        Option.iter close_connection !current;
        if !reused && (not retried) && retryable_exception exn then
          attempt ~retried:true ~fresh:true
        else raise exn
  in
  attempt ~retried:false ~fresh:false
