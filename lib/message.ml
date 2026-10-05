module type Message = sig
    type t

    val id : t -> string
    val channel_id : t -> string
    val channel : t -> Channel.t
    val content : t -> string
    val author : t -> User.t

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val show : t -> string

    val reply : Rest.t -> t -> string -> unit
end

include (struct

    type t = {
        id : string;
        channel_id : string;
        content : string;
        author : User.t [@printer fun fmt a -> Format.pp_print_string fmt (User.show a)];
    } [@@deriving show]

    let id (m : t) : string = m.id
    let channel_id (m : t) : string = m.channel_id
    let channel (m : t) : Channel.t = Channel.create m.channel_id
    let content (m : t) : string = m.content
    let author (m : t) : User.t = m.author

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let author =
                match User.of_yojson (json |> member "author") with
                | Ok a -> a
                | Error msg -> raise (Failure msg)
            in
            Ok
                { id = json |> member "id" |> to_string;
                  channel_id = json |> member "channel_id" |> to_string;
                  content = json |> member "content" |> to_string;
                  author }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let reply (rest : Rest.t) (m : t) (content : string) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages" in
        let body =
            `Assoc
                [ ("content", `String content);
                  ("message_reference", `Assoc [ ("message_id", `String m.id) ]) ]
            |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

end : Message)
