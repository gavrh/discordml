module type Shard = sig
    type t

    val connect :
        url:string ->
        id:int ->
        num_shards:int ->
        token:string ->
        intents:int ->
        t

    val run :
        dispatch:(string -> Yojson.Safe.t -> unit) ->
        net:'a Eio.Net.t ->
        'b Eio.Time.clock ->
        t ->
        unit

    val show : t -> string
end

include (struct

    type op =
        | Dispatch
        | Heartbeat
        | Identify
        | Presence_update
        | Voice_state_update
        | Resume
        | Reconnect
        | Request_guild_members
        | Invalid_session
        | Hello
        | Heartbeat_ack
        | Unknown of int

    let op_of_int = function
        | 0 -> Dispatch
        | 1 -> Heartbeat
        | 2 -> Identify
        | 3 -> Presence_update
        | 4 -> Voice_state_update
        | 6 -> Resume
        | 7 -> Reconnect
        | 8 -> Request_guild_members
        | 9 -> Invalid_session
        | 10 -> Hello
        | 11 -> Heartbeat_ack
        | n -> Unknown n

    let int_of_op = function
        | Dispatch -> 0
        | Heartbeat -> 1
        | Identify -> 2
        | Presence_update -> 3
        | Voice_state_update -> 4
        | Resume -> 6
        | Reconnect -> 7
        | Request_guild_members -> 8
        | Invalid_session -> 9
        | Hello -> 10
        | Heartbeat_ack -> 11
        | Unknown n -> n

    type t = {
        id : int;
        num_shards : int;
        token : string [@opaque];
        intents : int;
        url : string;
        mutable seq : int option;
        mutable heartbeat_interval : float option;
        mutable acked : bool;
        mutable session_id : string option;
        mutable resume_gateway_url : string option;
        mutable established : bool;
    } [@@deriving show]

    let connect ~(url : string) ~(id : int) ~(num_shards : int)
            ~(token : string) ~(intents : int) : t =
        { id; num_shards; token; intents; url; seq = None;
          heartbeat_interval = None; acked = true; session_id = None;
          resume_gateway_url = None; established = false }

    let read_hello (conn : P_ws.t) (t : t) : unit =
        match P_ws.recv conn with
        | P_ws.Closed _ ->
            failwith (Printf.sprintf "shard %d: gateway closed before hello" t.id)
        | P_ws.Data s ->
            let json = Yojson.Safe.from_string s in
            let open Yojson.Safe.Util in
            (match op_of_int (json |> member "op" |> to_int) with
             | Hello ->
                 let interval =
                     json |> member "d" |> member "heartbeat_interval" |> to_int
                 in
                 t.heartbeat_interval <- Some (float_of_int interval /. 1000.)
             | op ->
                 failwith
                     (Printf.sprintf "shard %d: expected hello, got op %d" t.id
                        (int_of_op op)))

    let identify (conn : P_ws.t) (t : t) : unit =
        let properties =
            `Assoc
                [ ("os", `String "linux");
                  ("browser", `String "discordml");
                  ("device", `String "discordml") ]
        in
        let d =
            `Assoc
                [ ("token", `String t.token);
                  ("intents", `Int t.intents);
                  ("shard", `List [ `Int t.id; `Int t.num_shards ]);
                  ("properties", properties) ]
        in
        let payload = `Assoc [ ("op", `Int (int_of_op Identify)); ("d", d) ] in
        P_ws.send_text conn (Yojson.Safe.to_string payload)

    let resume (conn : P_ws.t) (t : t) : unit =
        match t.session_id, t.seq with
        | Some session_id, Some seq ->
            let d =
                `Assoc
                    [ ("token", `String t.token);
                      ("session_id", `String session_id);
                      ("seq", `Int seq) ]
            in
            let payload = `Assoc [ ("op", `Int (int_of_op Resume)); ("d", d) ] in
            P_ws.send_text conn (Yojson.Safe.to_string payload)
        | _ -> identify conn t

    let send_heartbeat (conn : P_ws.t) (t : t) : unit =
        let d = match t.seq with Some s -> `Int s | None -> `Null in
        let payload = `Assoc [ ("op", `Int (int_of_op Heartbeat)); ("d", d) ] in
        P_ws.send_text conn (Yojson.Safe.to_string payload);
        t.acked <- false

    let heartbeat_loop clock (conn : P_ws.t) (t : t) : unit =
        match t.heartbeat_interval with
        | None -> ()
        | Some interval ->
            Eio.Time.sleep clock (interval *. Random.float 1.);
            let rec loop first =
                if (not first) && not t.acked then
                    P_ws.close conn
                else begin
                    send_heartbeat conn t;
                    Eio.Time.sleep clock interval;
                    loop false
                end
            in
            loop true

    let handle_ready (t : t) (d : Yojson.Safe.t) : unit =
        let open Yojson.Safe.Util in
        t.session_id <- Some (d |> member "session_id" |> to_string);
        t.resume_gateway_url <- Some (d |> member "resume_gateway_url" |> to_string)

    type close_reason =
        | Reconnect_requested
        | Session_invalid of bool
        | Socket_closed of P_ws.close_code * string

    let listen dispatch (conn : P_ws.t) (t : t) : close_reason =
        let open Yojson.Safe.Util in
        let rec loop () =
            match P_ws.recv conn with
            | P_ws.Closed (code, reason) -> Socket_closed (code, reason)
            | P_ws.Data s ->
                let json = Yojson.Safe.from_string s in
                (match op_of_int (json |> member "op" |> to_int) with
                 | Heartbeat_ack ->
                     t.acked <- true;
                     loop ()
                 | Heartbeat ->
                     send_heartbeat conn t;
                     loop ()
                 | Dispatch ->
                     (match json |> member "s" |> to_int_option with
                      | Some seq -> t.seq <- Some seq
                      | None -> ());
                     (match json |> member "t" |> to_string_option with
                      | Some name ->
                          (match name with
                           | "READY" ->
                               handle_ready t (json |> member "d");
                               t.established <- true
                           | "RESUMED" -> t.established <- true
                           | _ -> ());
                          dispatch name (json |> member "d")
                      | None -> ());
                     loop ()
                 | Reconnect -> Reconnect_requested
                 | Invalid_session ->
                     let resumable =
                         match json |> member "d" with `Bool b -> b | _ -> false
                     in
                     Session_invalid resumable
                 | _ -> loop ())
        in
        loop ()

    let base_delay : float = 1.
    let max_delay : float = 60.

    let fatal_close = function
        | P_ws.Authentication_failed
        | P_ws.Invalid_shard
        | P_ws.Sharding_required
        | P_ws.Invalid_api_version
        | P_ws.Invalid_intents
        | P_ws.Disallowed_intents -> true
        | _ -> false

    let clear_session (t : t) : unit =
        t.session_id <- None;
        t.resume_gateway_url <- None;
        t.seq <- None

    type action = Stop | Reconnect

    type delay = Backoff | Jitter of float * float

    type plan = { action : action; clear_session : bool; delay : delay }

    let plan_of_reason ~(resume_failed : bool) (reason : close_reason) : plan =
        match reason with
        | Reconnect_requested ->
            { action = Reconnect; clear_session = false; delay = Backoff }
        | Session_invalid true ->
            { action = Reconnect; clear_session = false; delay = Jitter (1., 5.) }
        | Session_invalid false ->
            { action = Reconnect; clear_session = true; delay = Jitter (1., 5.) }
        | Socket_closed (code, _) when fatal_close code ->
            { action = Stop; clear_session = false; delay = Backoff }
        | Socket_closed (P_ws.Invalid_seq, _)
        | Socket_closed (P_ws.Session_timed_out, _) ->
            { action = Reconnect; clear_session = true; delay = Backoff }
        | Socket_closed (P_ws.Rate_limited, _) ->
            { action = Reconnect; clear_session = false; delay = Jitter (1., 5.) }
        | Socket_closed _ when resume_failed ->
            { action = Reconnect; clear_session = true; delay = Backoff }
        | Socket_closed _ ->
            { action = Reconnect; clear_session = false; delay = Backoff }

    let run ~dispatch ~(net : 'a Eio.Net.t) clock (t : t) : unit =
        let jitter d = d *. (0.5 +. Random.float 1.) in
        let rec loop delay =
            let resume_attempted = t.session_id <> None && t.seq <> None in
            let url =
                match t.session_id, t.resume_gateway_url with
                | Some _, Some r -> r
                | _ -> t.url
            in
            let full =
                P_ws.gateway_url ~url ~shard:t.id ~num_shards:t.num_shards
            in
            t.established <- false;
            t.acked <- true;
            let reason =
                try
                    Eio.Switch.run @@ fun sw ->
                    let conn = P_ws.connect ~sw ~net ~url:full in
                    read_hello conn t;
                    Eio.Fiber.fork ~sw (fun () -> heartbeat_loop clock conn t);
                    resume conn t;
                    listen dispatch conn t
                with exn -> Socket_closed (P_ws.Abnormal, Printexc.to_string exn)
            in
            let resume_failed = resume_attempted && not t.established in
            let plan = plan_of_reason ~resume_failed reason in
            match plan.action with
            | Stop ->
                (match reason with
                 | Socket_closed (P_ws.Disallowed_intents, _) ->
                     prerr_endline
                         "shard: intents not enabled for this application (enable \
                          privileged intents in the Discord developer portal)"
                 | Socket_closed (P_ws.Authentication_failed, _) ->
                     prerr_endline
                         "shard: authentication failed (check the bot token)"
                 | _ -> ())
            | Reconnect ->
                let wait = if t.established then base_delay else delay in
                let next_delay = min max_delay (wait *. 2.) in
                if plan.clear_session then clear_session t;
                let seconds =
                    match plan.delay with
                    | Backoff -> jitter wait
                    | Jitter (lo, hi) -> lo +. Random.float (hi -. lo)
                in
                Eio.Time.sleep clock seconds;
                loop next_delay
        in
        loop base_delay

end : Shard)
