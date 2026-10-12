module type Count_details = sig
    type t = {
        burst : int;
        normal : int;
    }

    val burst : t -> int
    val normal : t -> int

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

module Count_details : Count_details = struct
    type t = {
        burst : int;
        normal : int;
    } [@@deriving show, eq]

    let burst (c : t) : int = c.burst
    let normal (c : t) : int = c.normal

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { burst =
                    json |> member "burst" |> to_int_option
                    |> Option.value ~default:0;
                  normal =
                    json |> member "normal" |> to_int_option
                    |> Option.value ~default:0 }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
end

module type Reaction = sig
    type t

    val channel_id : t -> string
    val message_id : t -> string
    val emoji : t -> Emoji.t
    val emoji_identifier : t -> string
    val count : t -> int
    val me : t -> bool
    val count_details : t -> Count_details.t
    val burst_colors : t -> string list
    val me_burst : t -> bool

    val of_yojson :
        channel_id:string ->
        message_id:string ->
        Yojson.Safe.t ->
        (t, string) result

    val pp : Format.formatter -> t -> unit

    val show : t -> string

    val users : Rest.t -> t -> User.t list

    val remove_user : Rest.t -> t -> string -> unit
end

include (struct

    type t = {
        channel_id : string;
        message_id : string;
        emoji : Emoji.t;
        count : int;
        me : bool;
        count_details : Count_details.t;
        burst_colors : string list;
        me_burst : bool;
    } [@@deriving show, eq]

    let channel_id (r : t) : string = r.channel_id
    let message_id (r : t) : string = r.message_id
    let emoji (r : t) : Emoji.t = r.emoji
    let count (r : t) : int = r.count
    let me (r : t) : bool = r.me
    let count_details (r : t) : Count_details.t = r.count_details
    let burst_colors (r : t) : string list = r.burst_colors
    let me_burst (r : t) : bool = r.me_burst

    let emoji_identifier (r : t) : string =
        match Emoji.id r.emoji, Emoji.name r.emoji with
        | Some id, Some name -> name ^ ":" ^ id
        | Some id, None -> id
        | None, Some name -> name
        | None, None -> ""

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map
                (function `String s -> Some s | _ -> None)
                l
        | _ -> []

    let of_yojson ~(channel_id : string) ~(message_id : string)
            (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let emoji =
                match Emoji.of_yojson (json |> member "emoji") with
                | Ok emoji -> emoji
                | Error msg -> raise (Failure msg)
            in
            let count_details =
                match json |> member "count_details" with
                | `Null -> { Count_details.burst = 0; normal = 0 }
                | c ->
                    (match Count_details.of_yojson c with
                     | Ok details -> details
                     | Error msg -> raise (Failure msg))
            in
            Ok
                { channel_id;
                  message_id;
                  emoji;
                  count = json |> member "count" |> to_int;
                  me =
                    json |> member "me" |> to_bool_option
                    |> Option.value ~default:false;
                  count_details;
                  burst_colors = string_list (json |> member "burst_colors");
                  me_burst =
                    json |> member "me_burst" |> to_bool_option
                    |> Option.value ~default:false }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let reaction_path (r : t) : string =
        "/channels/" ^ r.channel_id ^ "/messages/" ^ r.message_id
        ^ "/reactions/" ^ Uri.pct_encode (emoji_identifier r)

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
