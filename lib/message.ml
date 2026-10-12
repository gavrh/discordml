module type Message = sig
    type t

    val id : t -> string
    val channel_id : t -> string
    val channel : t -> Channel.t
    val content : t -> string
    val author : t -> User.t
    val guild_id : t -> string option
    val type_ : t -> int
    val pinned : t -> bool
    val tts : t -> bool
    val timestamp : t -> string option
    val edited_timestamp : t -> string option
    val attachments : t -> Attachment.t list
    val mentions : t -> User.t list
    val reactions : t -> Reaction.t list
    val embeds : t -> Yojson.Safe.t list

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val pp : Format.formatter -> t -> unit
    val show : t -> string

    val reply : Rest.t -> t -> string -> unit
    val reply_file : Rest.t -> t -> Attachment.t -> unit
    val edit : Rest.t -> t -> string -> unit
    val delete : Rest.t -> t -> unit

    val list :
        Rest.t ->
        channel_id:string ->
        ?before:string ->
        ?after:string ->
        ?limit:int ->
        unit ->
        t list
end

include (struct

    type t = {
        id : string;
        channel_id : string;
        content : string;
        author : User.t;
        guild_id : string option;
        type_ : int;
        pinned : bool;
        tts : bool;
        timestamp : string option;
        edited_timestamp : string option;
        attachments : Attachment.t list;
        mentions : User.t list;
        reactions : Reaction.t list;
        embeds : Yojson.Safe.t list;
    } [@@deriving show]

    let id (m : t) : string = m.id
    let channel_id (m : t) : string = m.channel_id
    let channel (m : t) : Channel.t = Channel.create m.channel_id
    let content (m : t) : string = m.content
    let author (m : t) : User.t = m.author
    let guild_id (m : t) : string option = m.guild_id
    let type_ (m : t) : int = m.type_
    let pinned (m : t) : bool = m.pinned
    let tts (m : t) : bool = m.tts
    let timestamp (m : t) : string option = m.timestamp
    let edited_timestamp (m : t) : string option = m.edited_timestamp
    let attachments (m : t) : Attachment.t list = m.attachments
    let mentions (m : t) : User.t list = m.mentions
    let reactions (m : t) : Reaction.t list = m.reactions
    let embeds (m : t) : Yojson.Safe.t list = m.embeds

    let attachment_of_yojson (json : Yojson.Safe.t) : Attachment.t =
        let open Yojson.Safe.Util in
        let name = json |> member "filename" |> to_string in
        let content_type = json |> member "content_type" |> to_string_option in
        let content =
            json |> member "url" |> to_string_option |> Option.value ~default:""
        in
        Attachment.create ?content_type ~name content

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let id = json |> member "id" |> to_string in
            let channel_id = json |> member "channel_id" |> to_string in
            let author =
                match User.of_yojson (json |> member "author") with
                | Ok a -> a
                | Error msg -> raise (Failure msg)
            in
            let attachments =
                match json |> member "attachments" with
                | `List l -> List.map attachment_of_yojson l
                | _ -> []
            in
            let mentions =
                match json |> member "mentions" with
                | `List l ->
                    List.map
                        (fun u ->
                           match User.of_yojson u with
                           | Ok user -> user
                           | Error msg -> raise (Failure msg))
                        l
                | _ -> []
            in
            let reactions =
                match json |> member "reactions" with
                | `List l ->
                    List.map
                        (fun r ->
                           match Reaction.of_yojson ~channel_id ~message_id:id r
                           with
                           | Ok reaction -> reaction
                           | Error msg -> raise (Failure msg))
                        l
                | _ -> []
            in
            let embeds =
                match json |> member "embeds" with `List l -> l | _ -> []
            in
            Ok
                { id;
                  channel_id;
                  content = json |> member "content" |> to_string;
                  author;
                  guild_id = json |> member "guild_id" |> to_string_option;
                  type_ =
                    json |> member "type" |> to_int_option
                    |> Option.value ~default:0;
                  pinned =
                    json |> member "pinned" |> to_bool_option
                    |> Option.value ~default:false;
                  tts =
                    json |> member "tts" |> to_bool_option
                    |> Option.value ~default:false;
                  timestamp = json |> member "timestamp" |> to_string_option;
                  edited_timestamp =
                    json |> member "edited_timestamp" |> to_string_option;
                  attachments; mentions; reactions; embeds }
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

    let reply_file (rest : Rest.t) (m : t) (attachment : Attachment.t) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages" in
        let body =
            `Assoc
                [ ("message_reference", `Assoc [ ("message_id", `String m.id) ]) ]
            |> Yojson.Safe.to_string
        in
        let files =
            [ (Attachment.name attachment, Attachment.content attachment,
               Attachment.content_type attachment) ]
        in
        let code, resp = Rest.request rest ~body ~files Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let edit (rest : Rest.t) (m : t) (content : string) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages/" ^ m.id in
        let body =
            `Assoc [ ("content", `String content) ] |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Patch path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp)

    let delete (rest : Rest.t) (m : t) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages/" ^ m.id in
        let code, resp = Rest.request rest Rest.Delete path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let list (rest : Rest.t) ~channel_id ?before ?after ?limit () : t list =
        let base = "/channels/" ^ channel_id ^ "/messages" in
        let params =
            (match before with Some v -> [ ("before", v) ] | None -> [])
            @ (match after with Some v -> [ ("after", v) ] | None -> [])
            @ (match limit with
               | Some v -> [ ("limit", string_of_int v) ]
               | None -> [])
        in
        let path =
            match params with
            | [] -> base
            | _ ->
                List.fold_left
                    (fun uri (k, v) -> Uri.add_query_param' uri (k, v))
                    (Uri.of_string base) params
                |> Uri.to_string
        in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        Yojson.Safe.from_string resp |> Yojson.Safe.Util.to_list
        |> List.map (fun json ->
               match of_yojson json with
               | Ok m -> m
               | Error msg -> failwith (path ^ ": " ^ msg))

end : Message)
