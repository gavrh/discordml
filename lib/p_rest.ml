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

    let gateway_bot ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) ~(token : string) :
            gateway_info =
        let code, body =
            P_http.get ~sw ~net
                ~headers:
                    [ ("Authorization", "Bot " ^ token);
                      ("User-Agent", "DiscordBot (https://github.com/gavrh/discordml, 0.1.0)") ]
                (endpoint ^ "/gateway/bot")
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
