module type Rest = sig
    type t

    type meth =
        | Get
        | Post
        | Put
        | Patch
        | Delete

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
end

include (struct

    type meth =
        | Get
        | Post
        | Put
        | Patch
        | Delete

    type bucket = {
        mutable remaining : int;
        mutable reset_at : float;
    }

    type t = {
        client : Cohttp_eio.Client.t;
        sw : Eio.Switch.t;
        token : string;
        sleep : float -> unit;
        now : unit -> float;
        mutex : Eio.Mutex.t;
        buckets : (string, bucket) Hashtbl.t;
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

    let bucket_key (meth : meth) (path : string) : string =
        meth_name meth ^ " " ^ path

    let wait_time (t : t) (key : string) : float =
        Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
            let now = t.now () in
            let global = max 0. (t.global_until -. now) in
            let bucket =
                match Hashtbl.find_opt t.buckets key with
                | Some b when b.remaining <= 0 -> max 0. (b.reset_at -. now)
                | _ -> 0.
            in
            max global bucket)

    let update_bucket (t : t) (key : string) (headers : Http.Header.t) : unit =
        match
            Http.Header.get headers "x-ratelimit-remaining",
            Http.Header.get headers "x-ratelimit-reset-after"
        with
        | Some rem, Some reset ->
            (match int_of_string_opt rem, float_of_string_opt reset with
             | Some remaining, Some reset_after ->
                 Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
                     Hashtbl.replace t.buckets key
                         { remaining; reset_at = t.now () +. reset_after })
             | _ -> ())
        | _ -> ()

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
        let key = bucket_key meth path in
        let rec attempt n =
            let wait = wait_time t key in
            if wait > 0. then t.sleep wait;
            let resp, body = send t ?headers ?body meth path in
            let headers = Http.Response.headers resp in
            update_bucket t key headers;
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

end : Rest)
