module type Shard = sig
    type t

    type ready = {
        session_id : string;
        resume_gateway_url : string;
        user_id : string;
        user_name : string;
        application_id : string;
    }

    val connect :
        sw:Eio.Switch.t ->
        net:'a Eio.Net.t ->
        url:string ->
        id:int ->
        num_shards:int ->
        token:string ->
        intents:int ->
        t

    val run : ?on_ready:(ready -> unit) -> 'a Eio.Time.clock -> t -> unit

    val show : t -> string
end

include (struct

    type ready = {
        session_id : string;
        resume_gateway_url : string;
        user_id : string;
        user_name : string;
        application_id : string;
    } [@@deriving show]

    type t = {
        id : int;
        num_shards : int;
        token : string [@opaque];
        intents : int;
        conn : P_ws.t [@opaque];
        mutable seq : int option;
        mutable heartbeat_interval : float option;
        mutable acked : bool;
        mutable session_id : string option;
        mutable resume_gateway_url : string option;
    } [@@deriving show]

    let connect ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
            ~(url : string) ~(id : int) ~(num_shards : int) ~(token : string)
            ~(intents : int) : t =
        let conn =
            P_ws.connect ~sw ~net
                ~url:(P_ws.gateway_url ~url ~shard:id ~num_shards)
        in
        { id; num_shards; token; intents; conn; seq = None;
          heartbeat_interval = None; acked = true; session_id = None;
          resume_gateway_url = None }

    let read_hello (t : t) : unit =
        match P_ws.recv t.conn with
        | None ->
            failwith (Printf.sprintf "shard %d: gateway closed before hello" t.id)
        | Some s ->
            let json = Yojson.Safe.from_string s in
            let open Yojson.Safe.Util in
            let op = json |> member "op" |> to_int in
            if op <> 10 then
                failwith (Printf.sprintf "shard %d: expected hello, got op %d" t.id op);
            let interval =
                json |> member "d" |> member "heartbeat_interval" |> to_int
            in
            t.heartbeat_interval <- Some (float_of_int interval /. 1000.)

    let identify (t : t) : unit =
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
        let payload = `Assoc [ ("op", `Int 2); ("d", d) ] in
        P_ws.send_text t.conn (Yojson.Safe.to_string payload)

    let send_heartbeat (t : t) : unit =
        let d = match t.seq with Some s -> `Int s | None -> `Null in
        let payload = `Assoc [ ("op", `Int 1); ("d", d) ] in
        P_ws.send_text t.conn (Yojson.Safe.to_string payload);
        t.acked <- false

    let heartbeat_loop clock (t : t) : unit =
        match t.heartbeat_interval with
        | None -> ()
        | Some interval ->
            Eio.Time.sleep clock (interval *. Random.float 1.);
            let rec loop first =
                if (not first) && not t.acked then
                    P_ws.close t.conn
                else begin
                    send_heartbeat t;
                    Eio.Time.sleep clock interval;
                    loop false
                end
            in
            loop true

    let handle_ready (t : t) (d : Yojson.Safe.t) : ready =
        let open Yojson.Safe.Util in
        let user = d |> member "user" in
        let ready =
            { session_id = d |> member "session_id" |> to_string;
              resume_gateway_url = d |> member "resume_gateway_url" |> to_string;
              user_id = user |> member "id" |> to_string;
              user_name = user |> member "username" |> to_string;
              application_id =
                d |> member "application" |> member "id" |> to_string_option
                |> Option.value ~default:"" }
        in
        t.session_id <- Some ready.session_id;
        t.resume_gateway_url <- Some ready.resume_gateway_url;
        ready

    let listen on_ready (t : t) : unit =
        let open Yojson.Safe.Util in
        let rec loop () =
            match P_ws.recv t.conn with
            | None -> ()
            | Some s ->
                let json = Yojson.Safe.from_string s in
                (match json |> member "op" |> to_int with
                 | 11 ->
                     t.acked <- true;
                     loop ()
                 | 1 ->
                     send_heartbeat t;
                     loop ()
                 | 0 ->
                     (match json |> member "s" |> to_int_option with
                      | Some seq -> t.seq <- Some seq
                      | None -> ());
                     (match json |> member "t" |> to_string_option with
                      | Some "READY" ->
                          let ready = handle_ready t (json |> member "d") in
                          (match on_ready with
                           | Some f -> f ready
                           | None -> ())
                      | _ -> ());
                     loop ()
                 | 7 | 9 -> ()
                 | _ -> loop ())
        in
        loop ()

    let run ?on_ready clock (t : t) : unit =
        read_hello t;
        identify t;
        Eio.Switch.run @@ fun sw ->
        Eio.Fiber.fork ~sw (fun () -> heartbeat_loop clock t);
        listen on_ready t

end : Shard)
