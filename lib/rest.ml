module type Rest = sig
    type t

    type meth =
        | Get
        | Post
        | Put
        | Patch
        | Delete

    type gateway_info = {
        url : string;
        shards : int;
        max_concurrency : int;
        sessions_remaining : int;
        sessions_reset_after : float;
    }

    val create :
        sw:Eio.Switch.t ->
        net:'a Eio.Net.t ->
        clock:'b Eio.Time.clock ->
        token:string ->
        t

    val request :
        t ->
        ?headers:(string * string) list ->
        ?body:string ->
        meth ->
        string ->
        int * string

    val gateway_bot : t -> gateway_info
end

include (struct

    type meth =
        | Get
        | Post
        | Put
        | Patch
        | Delete

    type gateway_info = {
        url : string;
        shards : int;
        max_concurrency : int;
        sessions_remaining : int;
        sessions_reset_after : float;
    }

    type bucket = {
        mutable remaining : int;
        mutable reset_at : float;
        mutable in_flight : int;
        mutable learned : bool;
        changed : Eio.Condition.t;
    }

    type t = {
        client : Cohttp_eio.Client.t;
        sw : Eio.Switch.t;
        token : string;
        sleep : float -> unit;
        now : unit -> float;
        mutex : Eio.Mutex.t;
        buckets : (string, bucket) Hashtbl.t;
        bucket_ids : (string, string) Hashtbl.t;
        mutable global_until : float;
    }

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

    let create ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
            ~(clock : 'b Eio.Time.clock) ~(token : string) : t =
        Mirage_crypto_rng_unix.use_default ();
        let client = Cohttp_eio.Client.make ~https:(Some (https ())) net in
        { client; sw; token;
          sleep = (fun d -> Eio.Time.sleep clock d);
          now = (fun () -> Eio.Time.now clock);
          mutex = Eio.Mutex.create ();
          buckets = Hashtbl.create 0;
          bucket_ids = Hashtbl.create 0;
          global_until = 0. }

    let meth_name = function
        | Get -> "GET"
        | Post -> "POST"
        | Put -> "PUT"
        | Patch -> "PATCH"
        | Delete -> "DELETE"

    let cohttp_meth = function
        | Get -> `GET
        | Post -> `POST
        | Put -> `PUT
        | Patch -> `PATCH
        | Delete -> `DELETE

    let route_key (meth : meth) (path : string) : string =
        let path =
            match String.index_opt path '?' with
            | Some i -> String.sub path 0 i
            | None -> path
        in
        meth_name meth ^ " " ^ path

    let bucket_for (t : t) (route : string) : bucket =
        let key =
            match Hashtbl.find_opt t.bucket_ids route with
            | Some bucket_id -> bucket_id
            | None -> route
        in
        match Hashtbl.find_opt t.buckets key with
        | Some bucket -> bucket
        | None ->
            let bucket = {
                remaining = 0;
                reset_at = 0.;
                in_flight = 0;
                learned = false;
                changed = Eio.Condition.create ();
            } in
            Hashtbl.replace t.buckets key bucket;
            bucket

    let global_wait (t : t) : float =
        Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
            max 0. (t.global_until -. t.now ()))

    let reserve (t : t) (route : string) : bucket =
        let rec loop () =
            let action =
                Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
                    let bucket = bucket_for t route in
                    let now = t.now () in
                    if not bucket.learned then
                        if bucket.in_flight = 0 then begin
                            bucket.in_flight <- 1;
                            `Reserved bucket
                        end else begin
                            Eio.Condition.await bucket.changed t.mutex;
                            `Retry
                        end
                    else if bucket.remaining > 0 then begin
                        bucket.remaining <- bucket.remaining - 1;
                        bucket.in_flight <- bucket.in_flight + 1;
                        `Reserved bucket
                    end
                    else if bucket.reset_at <= now then begin
                        bucket.learned <- false;
bucket.in_flight <- bucket.in_flight + 1;
                        `Reserved bucket
                    end
                    else
                        `Wait (bucket.reset_at -. now))
            in
            match action with
            | `Reserved bucket -> bucket
            | `Retry -> loop ()
            | `Wait delay -> t.sleep delay; loop ()
        in
        loop ()

    let finish (t : t) (route : string) (reserved : bucket)
            (headers : Http.Header.t) : unit =
        let bucket_id = Http.Header.get headers "x-ratelimit-bucket" in
        let limit =
            match
                Http.Header.get headers "x-ratelimit-remaining",
                Http.Header.get headers "x-ratelimit-reset-after"
            with
            | Some remaining, Some reset_after ->
                (match int_of_string_opt remaining,
                       float_of_string_opt reset_after with
                 | Some remaining, Some reset_after ->
                     Some (remaining, reset_after)
                 | _ -> None)
            | _ -> None
        in
        Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
            let target =
                match bucket_id with
                | Some id ->
                    Hashtbl.replace t.bucket_ids route id;
                    let target =
                        match Hashtbl.find_opt t.buckets id with
                        | Some bucket -> bucket
                        | None ->
                            Hashtbl.replace t.buckets id reserved;
                            reserved
                    in
                    if id <> route then Hashtbl.remove t.buckets route;
                    target
                | None -> reserved
            in
            (match limit with
             | Some (remaining, reset_after) ->
                 target.learned <- true;
                 target.remaining <- remaining;
                 target.reset_at <- t.now () +. reset_after
             | None -> ());
            reserved.in_flight <- max 0 (reserved.in_flight - 1);
            Eio.Condition.broadcast reserved.changed;
            if target != reserved then
                Eio.Condition.broadcast target.changed)

    let retry_after (headers : Http.Header.t) : float =
        match Http.Header.get headers "retry-after" with
        | Some v -> (match float_of_string_opt v with Some d -> d | None -> 1.)
        | None -> 1.

    let send (t : t) ?(headers = []) ?(body : string option) (meth : meth)
            (path : string) =
        let uri = Uri.of_string (endpoint ^ path) in
        let all_headers =
            Http.Header.of_list
                (("Authorization", "Bot " ^ t.token)
                 :: ("User-Agent", user_agent)
                 :: ("Content-Type", "application/json")
                 :: headers)
        in
        let body = Option.map Cohttp_eio.Body.of_string body in
        let resp, resp_body =
            Cohttp_eio.Client.call t.client ~sw:t.sw ?body ~headers:all_headers
                (cohttp_meth meth) uri
        in
        let body =
            Eio.Buf_read.(parse_exn take_all) resp_body ~max_size:10_000_000
        in
        (resp, body)

    let request (t : t) ?headers ?body (meth : meth) (path : string) : int * string =
        let route = route_key meth path in
        let rec attempt n =
            let wait = global_wait t in
            if wait > 0. then t.sleep wait;
            let bucket = reserve t route in
            let resp, body =
                match send t ?headers ?body meth path with
                | response -> response
                | exception exn ->
                    finish t route bucket (Http.Header.of_list []);
                    raise exn
            in
            let headers = Http.Response.headers resp in
            finish t route bucket headers;
            let status = Http.Status.to_int (Http.Response.status resp) in
            if status = 429 && n < 3 then begin
                let delay = retry_after headers in
                (match Http.Header.get headers "x-ratelimit-scope" with
                 | Some "global" ->
                     Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
                         t.global_until <- t.now () +. delay)
                 | _ -> ());
                t.sleep delay;
                attempt (n + 1)
            end
            else (status, body)
        in
        attempt 0

    let gateway_bot (t : t) : gateway_info =
        let code, body = request t Get "/gateway/bot" in
        if code <> 200 then
            failwith (Printf.sprintf "gateway/bot: HTTP %d: %s" code body);
        let json = Yojson.Safe.from_string body in
        let open Yojson.Safe.Util in
        let session_start_limit = json |> member "session_start_limit" in
        { url = json |> member "url" |> to_string;
          shards = json |> member "shards" |> to_int;
          max_concurrency =
            session_start_limit |> member "max_concurrency" |> to_int;
          sessions_remaining =
            session_start_limit |> member "remaining" |> to_int;
          sessions_reset_after =
            float_of_int
                (session_start_limit |> member "reset_after" |> to_int)
            /. 1000. }

end : Rest)
