module type Overwrite = sig
    type t

    val id : t -> string
    val type_ : t -> int
    val allow : t -> Permission.t
    val deny : t -> Permission.t

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
end

module Overwrite : Overwrite = struct
    type t = {
        id : string;
        type_ : int;
        allow : Permission.t;
        deny : Permission.t;
    } [@@deriving show, eq]

    let id (o : t) : string = o.id
    let type_ (o : t) : int = o.type_
    let allow (o : t) : Permission.t = o.allow
    let deny (o : t) : Permission.t = o.deny

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { id = json |> member "id" |> to_string;
                  type_ =
                    json |> member "type" |> to_int_option
                    |> Option.value ~default:0;
                  allow = Permission.of_yojson (json |> member "allow");
                  deny = Permission.of_yojson (json |> member "deny") }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
end

module type Channel = sig
    module Thread_metadata : sig
        type t = {
            archived : bool;
            auto_archive_duration : int;
            archive_timestamp : string option;
            locked : bool;
            invitable : bool option;
            create_timestamp : string option;
        }

        val archived : t -> bool
        val auto_archive_duration : t -> int
        val archive_timestamp : t -> string option
        val locked : t -> bool
        val invitable : t -> bool option
        val create_timestamp : t -> string option

        val of_yojson : Yojson.Safe.t -> (t, string) result

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
    end

    module Forum_tag : sig
        type t = {
            id : string;
            name : string;
            moderated : bool;
            emoji_id : string option;
            emoji_name : string option;
        }

        val id : t -> string
        val name : t -> string
        val moderated : t -> bool
        val emoji_id : t -> string option
        val emoji_name : t -> string option

        val of_yojson : Yojson.Safe.t -> (t, string) result

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
    end

    type t =
        | Text of text
        | Direct of direct
        | Voice of voice
        | Group of group
        | Category of category
        | News of news
        | Thread of thread
        | Stage of stage
        | Forum of forum
        | Media of media
        | Unknown of common
        | Partial of common

    and common = {
        id : string;
        type_ : int;
        guild_id : string option;
        name : string option;
        position : int option;
        permission_overwrites : Overwrite.t list;
        parent_id : string option;
        nsfw : bool;
        flags : int;
        permissions : Permission.t option;
    }

    and text = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        default_auto_archive_duration : int option;
        default_thread_rate_limit_per_user : int option;
    }

    and direct = {
        common : common;
        last_message_id : string option;
        recipients : User.t list;
    }

    and voice = {
        common : common;
        bitrate : int;
        user_limit : int;
        rtc_region : string option;
        video_quality_mode : int;
    }

    and group = {
        common : common;
        last_message_id : string option;
        icon : string option;
        owner_id : string option;
        recipients : User.t list;
    }

    and category = { common : common }

    and news = {
        common : common;
        topic : string option;
        last_message_id : string option;
        default_auto_archive_duration : int option;
    }

    and thread = {
        common : common;
        owner_id : string option;
        thread_metadata : Thread_metadata.t;
        message_count : int;
        member_count : int;
        total_message_sent : int;
        applied_tags : string list;
        newly_created : bool option;
        last_message_id : string option;
        rate_limit_per_user : int option;
    }

    and stage = {
        common : common;
        bitrate : int;
        user_limit : int;
        rtc_region : string option;
        video_quality_mode : int;
    }

    and forum = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        available_tags : Forum_tag.t list;
        default_reaction_emoji : Emoji.t option;
        default_sort_order : int option;
        default_forum_layout : int option;
        default_thread_rate_limit_per_user : int option;
    }

    and media = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        available_tags : Forum_tag.t list;
        default_reaction_emoji : Emoji.t option;
        default_sort_order : int option;
        default_thread_rate_limit_per_user : int option;
    }

    val id : t -> string
    val type_ : t -> int
    val guild_id : t -> string option
    val name : t -> string option
    val position : t -> int option
    val permission_overwrites : t -> Overwrite.t list
    val parent_id : t -> string option
    val nsfw : t -> bool
    val flags : t -> int
    val permissions : t -> Permission.t option

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val send : Rest.t -> t -> string -> unit
    val send_file : Rest.t -> t -> Attachment.t -> unit
    val fetch : Rest.t -> string -> t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
end

include (struct

    module Thread_metadata = struct
        type t = {
            archived : bool;
            auto_archive_duration : int;
            archive_timestamp : string option;
            locked : bool;
            invitable : bool option;
            create_timestamp : string option;
        } [@@deriving show, eq]

        let archived (t : t) : bool = t.archived
        let auto_archive_duration (t : t) : int = t.auto_archive_duration
        let archive_timestamp (t : t) : string option = t.archive_timestamp
        let locked (t : t) : bool = t.locked
        let invitable (t : t) : bool option = t.invitable
        let create_timestamp (t : t) : string option = t.create_timestamp

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { archived =
                        json |> member "archived" |> to_bool_option
                        |> Option.value ~default:false;
                      auto_archive_duration =
                        json |> member "auto_archive_duration" |> to_int_option
                        |> Option.value ~default:0;
                      archive_timestamp =
                        json |> member "archive_timestamp" |> to_string_option;
                      locked =
                        json |> member "locked" |> to_bool_option
                        |> Option.value ~default:false;
                      invitable = json |> member "invitable" |> to_bool_option;
                      create_timestamp =
                        json |> member "create_timestamp" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Forum_tag = struct
        type t = {
            id : string;
            name : string;
            moderated : bool;
            emoji_id : string option;
            emoji_name : string option;
        } [@@deriving show, eq]

        let id (t : t) : string = t.id
        let name (t : t) : string = t.name
        let moderated (t : t) : bool = t.moderated
        let emoji_id (t : t) : string option = t.emoji_id
        let emoji_name (t : t) : string option = t.emoji_name

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { id = json |> member "id" |> to_string;
                      name = json |> member "name" |> to_string;
                      moderated =
                        json |> member "moderated" |> to_bool_option
                        |> Option.value ~default:false;
                      emoji_id = json |> member "emoji_id" |> to_string_option;
                      emoji_name = json |> member "emoji_name" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    type t =
        | Text of text
        | Direct of direct
        | Voice of voice
        | Group of group
        | Category of category
        | News of news
        | Thread of thread
        | Stage of stage
        | Forum of forum
        | Media of media
        | Unknown of common
        | Partial of common

    and common = {
        id : string;
        type_ : int;
        guild_id : string option;
        name : string option;
        position : int option;
        permission_overwrites : Overwrite.t list;
        parent_id : string option;
        nsfw : bool;
        flags : int;
        permissions : Permission.t option;
    }

    and text = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        default_auto_archive_duration : int option;
        default_thread_rate_limit_per_user : int option;
    }

    and direct = {
        common : common;
        last_message_id : string option;
        recipients : User.t list;
    }

    and voice = {
        common : common;
        bitrate : int;
        user_limit : int;
        rtc_region : string option;
        video_quality_mode : int;
    }

    and group = {
        common : common;
        last_message_id : string option;
        icon : string option;
        owner_id : string option;
        recipients : User.t list;
    }

    and category = { common : common }

    and news = {
        common : common;
        topic : string option;
        last_message_id : string option;
        default_auto_archive_duration : int option;
    }

    and thread = {
        common : common;
        owner_id : string option;
        thread_metadata : Thread_metadata.t;
        message_count : int;
        member_count : int;
        total_message_sent : int;
        applied_tags : string list;
        newly_created : bool option;
        last_message_id : string option;
        rate_limit_per_user : int option;
    }

    and stage = {
        common : common;
        bitrate : int;
        user_limit : int;
        rtc_region : string option;
        video_quality_mode : int;
    }

    and forum = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        available_tags : Forum_tag.t list;
        default_reaction_emoji : Emoji.t option;
        default_sort_order : int option;
        default_forum_layout : int option;
        default_thread_rate_limit_per_user : int option;
    }

    and media = {
        common : common;
        topic : string option;
        last_message_id : string option;
        rate_limit_per_user : int option;
        available_tags : Forum_tag.t list;
        default_reaction_emoji : Emoji.t option;
        default_sort_order : int option;
        default_thread_rate_limit_per_user : int option;
    }
    [@@deriving show, eq]

    let common_of : t -> common = function
        | Text c -> c.common
        | Direct c -> c.common
        | Voice c -> c.common
        | Group c -> c.common
        | Category c -> c.common
        | News c -> c.common
        | Thread c -> c.common
        | Stage c -> c.common
        | Forum c -> c.common
        | Media c -> c.common
        | Unknown c -> c
        | Partial c -> c

    let id (c : t) : string = (common_of c).id
    let type_ (c : t) : int = (common_of c).type_
    let guild_id (c : t) : string option = (common_of c).guild_id
    let name (c : t) : string option = (common_of c).name
    let position (c : t) : int option = (common_of c).position
    let permission_overwrites (c : t) : Overwrite.t list =
        (common_of c).permission_overwrites
    let parent_id (c : t) : string option = (common_of c).parent_id
    let nsfw (c : t) : bool = (common_of c).nsfw
    let flags (c : t) : int = (common_of c).flags
    let permissions (c : t) : Permission.t option = (common_of c).permissions

    let empty_common (id : string) : common =
        { id;
          type_ = 0;
          guild_id = None;
          name = None;
          position = None;
          permission_overwrites = [];
          parent_id = None;
          nsfw = false;
          flags = 0;
          permissions = None }

    let create (id : string) : t = Partial (empty_common id)

    let parse_overwrites (json : Yojson.Safe.t) : Overwrite.t list =
        match Yojson.Safe.Util.member "permission_overwrites" json with
        | `List l ->
            List.filter_map
                (fun o ->
                   match Overwrite.of_yojson o with
                   | Ok overwrite -> Some overwrite
                   | Error _ -> None)
                l
        | _ -> []

    let parse_users (json : Yojson.Safe.t) : User.t list =
        match Yojson.Safe.Util.member "recipients" json with
        | `List l ->
            List.filter_map
                (fun u ->
                   match User.of_yojson u with
                   | Ok user -> Some user
                   | Error _ -> None)
                l
        | _ -> []

    let parse_forum_tags (json : Yojson.Safe.t) : Forum_tag.t list =
        match Yojson.Safe.Util.member "available_tags" json with
        | `List l ->
            List.filter_map
                (fun t ->
                   match Forum_tag.of_yojson t with
                   | Ok tag -> Some tag
                   | Error _ -> None)
                l
        | _ -> []

    let parse_reaction_emoji (json : Yojson.Safe.t) : Emoji.t option =
        match Yojson.Safe.Util.member "default_reaction_emoji" json with
        | `Null -> None
        | e ->
            (match Emoji.of_yojson e with
             | Ok emoji -> Some emoji
             | Error _ -> None)

    let parse_common (json : Yojson.Safe.t) : common =
        let open Yojson.Safe.Util in
        { id = json |> member "id" |> to_string;
          type_ =
            json |> member "type" |> to_int_option |> Option.value ~default:0;
          guild_id = json |> member "guild_id" |> to_string_option;
          name = json |> member "name" |> to_string_option;
          position = json |> member "position" |> to_int_option;
          permission_overwrites = parse_overwrites json;
          parent_id = json |> member "parent_id" |> to_string_option;
          nsfw =
            json |> member "nsfw" |> to_bool_option
            |> Option.value ~default:false;
          flags =
            json |> member "flags" |> to_int_option |> Option.value ~default:0;
          permissions =
            (match json |> member "permissions" with
             | `Null -> None
             | p -> Some (Permission.of_yojson p)) }

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let c = parse_common json in
            let s name = json |> member name |> to_string_option in
            let i name = json |> member name |> to_int_option in
            let id name d =
                json |> member name |> to_int_option
                |> Option.value ~default:d
            in
            let string_list name =
                match json |> member name with
                | `List l ->
                    List.filter_map
                        (function `String v -> Some v | _ -> None)
                        l
                | _ -> []
            in
            match c.type_ with
            | 0 ->
                Ok
                    (Text
                       { common = c;
                         topic = s "topic";
                         last_message_id = s "last_message_id";
                         rate_limit_per_user = i "rate_limit_per_user";
                         default_auto_archive_duration =
                           i "default_auto_archive_duration";
                         default_thread_rate_limit_per_user =
                           i "default_thread_rate_limit_per_user" })
            | 1 ->
                Ok
                    (Direct
                       { common = c;
                         last_message_id = s "last_message_id";
                         recipients = parse_users json })
            | 2 ->
                Ok
                    (Voice
                       { common = c;
                         bitrate = id "bitrate" 0;
                         user_limit = id "user_limit" 0;
                         rtc_region = s "rtc_region";
                         video_quality_mode = id "video_quality_mode" 1 })
            | 3 ->
                Ok
                    (Group
                       { common = c;
                         last_message_id = s "last_message_id";
                         icon = s "icon";
                         owner_id = s "owner_id";
                         recipients = parse_users json })
            | 4 -> Ok (Category { common = c })
            | 5 ->
                Ok
                    (News
                       { common = c;
                         topic = s "topic";
                         last_message_id = s "last_message_id";
                         default_auto_archive_duration =
                           i "default_auto_archive_duration" })
            | 10 | 11 | 12 ->
                let thread_metadata =
                    match json |> member "thread_metadata" with
                    | `Null ->
                        { Thread_metadata.archived = false;
                          auto_archive_duration = 0;
                          archive_timestamp = None;
                          locked = false;
                          invitable = None;
                          create_timestamp = None }
                    | m ->
                        (match Thread_metadata.of_yojson m with
                         | Ok metadata -> metadata
                         | Error msg -> raise (Failure msg))
                in
                Ok
                    (Thread
                       { common = c;
                         owner_id = s "owner_id";
                         thread_metadata;
                         message_count = id "message_count" 0;
                         member_count = id "member_count" 0;
                         total_message_sent = id "total_message_sent" 0;
                         applied_tags = string_list "applied_tags";
                         newly_created =
                           json |> member "newly_created" |> to_bool_option;
                         last_message_id = s "last_message_id";
                         rate_limit_per_user = i "rate_limit_per_user" })
            | 13 ->
                Ok
                    (Stage
                       { common = c;
                         bitrate = id "bitrate" 0;
                         user_limit = id "user_limit" 0;
                         rtc_region = s "rtc_region";
                         video_quality_mode = id "video_quality_mode" 1 })
            | 15 ->
                Ok
                    (Forum
                       { common = c;
                         topic = s "topic";
                         last_message_id = s "last_message_id";
                         rate_limit_per_user = i "rate_limit_per_user";
                         available_tags = parse_forum_tags json;
                         default_reaction_emoji = parse_reaction_emoji json;
                         default_sort_order = i "default_sort_order";
                         default_forum_layout = i "default_forum_layout";
                         default_thread_rate_limit_per_user =
                           i "default_thread_rate_limit_per_user" })
            | 16 ->
                Ok
                    (Media
                       { common = c;
                         topic = s "topic";
                         last_message_id = s "last_message_id";
                         rate_limit_per_user = i "rate_limit_per_user";
                         available_tags = parse_forum_tags json;
                         default_reaction_emoji = parse_reaction_emoji json;
                         default_sort_order = i "default_sort_order";
                         default_thread_rate_limit_per_user =
                           i "default_thread_rate_limit_per_user" })
            | n -> Ok (Unknown { c with type_ = n })
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok c -> c
        | Error msg -> failwith (path ^ ": " ^ msg)

    let send (rest : Rest.t) (c : t) (content : string) : unit =
        let path = "/channels/" ^ (common_of c).id ^ "/messages" in
        let body =
            `Assoc [ ("content", `String content) ] |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let send_file (rest : Rest.t) (c : t) (attachment : Attachment.t) : unit =
        let path = "/channels/" ^ (common_of c).id ^ "/messages" in
        let files =
            [ (Attachment.name attachment, Attachment.content attachment,
               Attachment.content_type attachment) ]
        in
        let code, resp = Rest.request rest ~files Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/channels/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Channel)
