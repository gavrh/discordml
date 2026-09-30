module type Rest = sig
    type gateway_info = {
        url : string;
        shards : int;
        max_concurrency : int;
    }

    val gateway_bot :
        sw:Eio.Switch.t -> net:'a Eio.Net.t -> token:string -> gateway_info
end

include (struct

    type gateway_info = {
        url : string;
        shards : int;
        max_concurrency : int;
    } [@@deriving show]

    let endpoint : string = "https://discord.com/api/v10"

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

    let gateway_bot ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) ~(token : string) :
            gateway_info =
        Mirage_crypto_rng_unix.use_default ();
        let client = Cohttp_eio.Client.make ~https:(Some (https ())) net in
        let headers =
            Http.Header.of_list
                [ ("Authorization", "Bot " ^ token);
                  ("User-Agent",
                   "DiscordBot (https://github.com/gavrh/discordml, 0.1.0)") ]
        in
        let resp, body =
            Cohttp_eio.Client.get client ~sw ~headers
                (Uri.of_string (endpoint ^ "/gateway/bot"))
        in
        let code = Http.Status.to_int resp.status in
        let body =
            Eio.Buf_read.(parse_exn take_all) body ~max_size:10_000_000
        in
        if code <> 200 then
            failwith (Printf.sprintf "gateway/bot: HTTP %d: %s" code body);
        let json = Yojson.Safe.from_string body in
        let open Yojson.Safe.Util in
        let url = json |> member "url" |> to_string in
        let shards = json |> member "shards" |> to_int in
        let max_concurrency =
            json |> member "session_start_limit" |> member "max_concurrency" |> to_int
        in
        { url; shards; max_concurrency }

end : Rest)
