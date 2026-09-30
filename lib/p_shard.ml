module type Shard = sig
    type t

    val connect :
        sw:Eio.Switch.t ->
        net:'a Eio.Net.t ->
        url:string ->
        id:int ->
        num_shards:int ->
        token:string ->
        intents:int ->
        t

    val run : t -> unit

    val show : t -> string
end

include (struct

    type t = {
        id : int;
        num_shards : int;
        token : string [@opaque];
        intents : int;
        conn : P_ws.t [@opaque];
        mutable seq : int option;
        mutable heartbeat_interval : float option;
    } [@@deriving show]

    let connect ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) ~(url : string)
            ~(id : int) ~(num_shards : int) ~(token : string) ~(intents : int) : t =
        let conn =
            P_ws.connect ~sw ~net
                ~url:(P_ws.gateway_url ~url ~shard:id ~num_shards)
        in
        { id; num_shards; token; intents; conn; seq = None;
          heartbeat_interval = None }

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

    let run (t : t) : unit =
        read_hello t;
        identify t

end : Shard)
