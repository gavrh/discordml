module type Message = sig
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
        embeds : Embed.t list;
        components : Component.t list;
        sticker_items : Sticker.t list;
        member : Member.t option;
        nonce : string option;
        webhook_id : string option;
        application_id : string option;
        flags : int;
        position : int option;
        referenced_message : t option;
        thread : Channel.t option;
        mention_everyone : bool;
        mention_roles : string list;
        mention_channels : mention_channel list;
        interaction : interaction_metadata option;
        poll : Poll.t option;
        message_snapshots : snapshot list;
        role_subscription_data : Role_subscription_data.t option;
        activity : Message_activity.t option;
    }

    and mention_channel = {
        id : string;
        guild_id : string;
        type_ : int;
        name : string;
    }

    and interaction_metadata = {
        id : string;
        type_ : int;
        name : string;
        user : User.t;
    }

    and snapshot = { message : t }

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
    val embeds : t -> Embed.t list
    val components : t -> Component.t list
    val sticker_items : t -> Sticker.t list
    val member : t -> Member.t option
    val nonce : t -> string option
    val webhook_id : t -> string option
    val application_id : t -> string option
    val flags : t -> int
    val position : t -> int option
    val referenced_message : t -> t option
    val thread : t -> Channel.t option
    val mention_everyone : t -> bool
    val mention_roles : t -> string list
    val mention_channels : t -> mention_channel list
    val interaction : t -> interaction_metadata option
    val poll : t -> Poll.t option
    val message_snapshots : t -> snapshot list
    val role_subscription_data : t -> Role_subscription_data.t option
    val activity : t -> Message_activity.t option

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
        embeds : Embed.t list;
        components : Component.t list;
        sticker_items : Sticker.t list;
        member : Member.t option;
        nonce : string option;
        webhook_id : string option;
        application_id : string option;
        flags : int;
        position : int option;
        referenced_message : t option;
        thread : Channel.t option;
        mention_everyone : bool;
        mention_roles : string list;
        mention_channels : mention_channel list;
        interaction : interaction_metadata option;
        poll : Poll.t option;
        message_snapshots : snapshot list;
        role_subscription_data : Role_subscription_data.t option;
        activity : Message_activity.t option;
    }

    and mention_channel = {
        id : string;
        guild_id : string;
        type_ : int;
        name : string;
    }

    and interaction_metadata = {
        id : string;
        type_ : int;
        name : string;
        user : User.t;
    }

    and snapshot = { message : t }
    [@@deriving show]

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
    let embeds (m : t) : Embed.t list = m.embeds
    let components (m : t) : Component.t list = m.components
    let sticker_items (m : t) : Sticker.t list = m.sticker_items
    let member (m : t) : Member.t option = m.member
    let nonce (m : t) : string option = m.nonce
    let webhook_id (m : t) : string option = m.webhook_id
    let application_id (m : t) : string option = m.application_id
    let flags (m : t) : int = m.flags
    let position (m : t) : int option = m.position
    let referenced_message (m : t) : t option = m.referenced_message
    let thread (m : t) : Channel.t option = m.thread
    let mention_everyone (m : t) : bool = m.mention_everyone
    let mention_roles (m : t) : string list = m.mention_roles
    let mention_channels (m : t) : mention_channel list = m.mention_channels
    let interaction (m : t) : interaction_metadata option = m.interaction
    let poll (m : t) : Poll.t option = m.poll
    let message_snapshots (m : t) : snapshot list = m.message_snapshots
    let role_subscription_data (m : t) :
        Role_subscription_data.t option =
        m.role_subscription_data
    let activity (m : t) : Message_activity.t option = m.activity

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map
                (function `String s -> Some s | _ -> None)
                l
        | _ -> []

    let parse_opt (json : Yojson.Safe.t) (of_yojson :
            Yojson.Safe.t -> ('a, string) result) : 'a option =
        match json with
        | `Null -> None
        | v ->
            (match of_yojson v with
             | Ok x -> Some x
             | Error _ -> None)

    let rec of_yojson (json : Yojson.Safe.t) : (t, string) result =
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
                | `List l ->
                    List.filter_map
                        (fun a ->
                           match Attachment.of_yojson a with
                           | Ok attachment -> Some attachment
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let mentions =
                match json |> member "mentions" with
                | `List l ->
                    List.filter_map
                        (fun u ->
                           match User.of_yojson u with
                           | Ok user -> Some user
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let reactions =
                match json |> member "reactions" with
                | `List l ->
                    List.filter_map
                        (fun r ->
                           match Reaction.of_yojson ~channel_id ~message_id:id r
                           with
                           | Ok reaction -> Some reaction
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let embeds =
                match json |> member "embeds" with
                | `List l ->
                    List.filter_map
                        (fun e ->
                           match Embed.of_yojson e with
                           | Ok embed -> Some embed
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let components =
                match json |> member "components" with
                | `List l ->
                    List.filter_map
                        (fun c ->
                           match Component.of_yojson c with
                           | Ok component -> Some component
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let sticker_items =
                match json |> member "sticker_items" with
                | `List l ->
                    List.filter_map
                        (fun s ->
                           match Sticker.of_yojson s with
                           | Ok sticker -> Some sticker
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let member_opt =
                match json |> member "member" with
                | `Null -> None
                | m ->
                    (match Member.of_yojson_partial ~user:author m with
                     | Ok member -> Some member
                     | Error _ -> None)
            in
            let referenced_message =
                parse_opt (json |> member "referenced_message") of_yojson
            in
            let thread =
                parse_opt (json |> member "thread") Channel.of_yojson
            in
            let mention_channels =
                match json |> member "mention_channels" with
                | `List l ->
                    List.filter_map
                        (fun c ->
                           try
                               let open Yojson.Safe.Util in
                               Some
                                   { id = c |> member "id" |> to_string;
                                     guild_id =
                                       c |> member "guild_id" |> to_string;
                                     type_ =
                                       c |> member "type" |> to_int_option
                                       |> Option.value ~default:0;
                                     name = c |> member "name" |> to_string }
                           with
                           | Type_error _ | Undefined _ -> None)
                        l
                | _ -> []
            in
            let interaction =
                parse_opt (json |> member "interaction") (fun i ->
                    let open Yojson.Safe.Util in
                    try
                        Ok
                            { id = i |> member "id" |> to_string;
                              type_ =
                                i |> member "type" |> to_int_option
                                |> Option.value ~default:0;
                              name = i |> member "name" |> to_string;
                              user =
                                (match User.of_yojson (i |> member "user") with
                                 | Ok user -> user
                                 | Error msg -> raise (Failure msg)) }
                    with
                    | Type_error (msg, _) -> Error msg
                    | Undefined (msg, _) -> Error msg
                    | Failure msg -> Error msg)
            in
            let poll = parse_opt (json |> member "poll") Poll.of_yojson in
            let message_snapshots =
                match json |> member "message_snapshots" with
                | `List l ->
                    List.filter_map
                        (fun s ->
                           match of_yojson (s |> member "message") with
                           | Ok message -> Some { message }
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let role_subscription_data =
                parse_opt (json |> member "role_subscription_data")
                    Role_subscription_data.of_yojson
            in
            let activity =
                parse_opt (json |> member "activity") Message_activity.of_yojson
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
                  attachments;
                  mentions;
                  reactions;
                  embeds;
                  components;
                  sticker_items;
                  member = member_opt;
                  nonce = json |> member "nonce" |> to_string_option;
                  webhook_id = json |> member "webhook_id" |> to_string_option;
                  application_id =
                    json |> member "application_id" |> to_string_option;
                  flags =
                    json |> member "flags" |> to_int_option
                    |> Option.value ~default:0;
                  position = json |> member "position" |> to_int_option;
                  referenced_message;
                  thread;
                  mention_everyone =
                    json |> member "mention_everyone" |> to_bool_option
                    |> Option.value ~default:false;
                  mention_roles = string_list (json |> member "mention_roles");
                  mention_channels;
                  interaction;
                  poll;
                  message_snapshots;
                  role_subscription_data;
                  activity }
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
