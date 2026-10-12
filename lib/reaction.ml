module type Reaction = sig
    type t

    val channel_id : t -> string
    val message_id : t -> string
    val emoji : t -> string
    val count : t -> int
    val me : t -> bool

    val of_yojson :
        channel_id:string ->
        message_id:string ->
        Yojson.Safe.t ->
        (t, string) result

    val show : t -> string

    val users : Rest.t -> t -> User.t list

    val remove_user : Rest.t -> t -> string -> unit
end

include (struct

    type t = {
        channel_id : string;
        message_id : string;
        emoji : string;
        count : int;
        me : bool;
    } [@@deriving show, eq]

    let channel_id (r : t) : string = r.channel_id
    let message_id (r : t) : string = r.message_id
    let emoji (r : t) : string = r.emoji
    let count (r : t) : int = r.count
    let me (r : t) : bool = r.me

    let of_yojson ~(channel_id : string) ~(message_id : string)
            (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let emoji_json = json |> member "emoji" in
            let name = emoji_json |> member "name" |> to_string in
            let emoji =
                match emoji_json |> member "id" with
                | `Null -> name
                | id -> name ^ ":" ^ to_string id
            in
            Ok
                { channel_id;
                  message_id;
                  emoji;
                  count = json |> member "count" |> to_int;
                  me = json |> member "me" |> to_bool }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

    let reaction_path (r : t) : string =
        "/channels/" ^ r.channel_id ^ "/messages/" ^ r.message_id
        ^ "/reactions/" ^ Uri.pct_encode r.emoji

    let users (rest : Rest.t) (r : t) : User.t list =
        let path = reaction_path r in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        let json = Yojson.Safe.from_string resp in
        Yojson.Safe.Util.to_list json
        |> List.map (fun user_json ->
               match User.of_yojson user_json with
               | Ok u -> u
               | Error msg -> failwith (path ^ ": " ^ msg))

    let remove_user (rest : Rest.t) (r : t) (user_id : string) : unit =
        let path = reaction_path r ^ "/" ^ user_id in
        let code, resp = Rest.request rest Rest.Delete path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

end : Reaction)
