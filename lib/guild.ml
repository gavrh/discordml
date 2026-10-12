module type Guild = sig
    type t
    val id : t -> string
    val name : t -> string
    val icon : t -> string option
    val owner_id : t -> string option
    val unavailable : t -> bool
    val member_count : t -> int option
    val channels : t -> Channel.t list
    val roles : t -> Role.t list
    val emojis : t -> Emoji.t list
    val stickers : t -> Sticker.t list
    val members : t -> Member.t list
    val description : t -> string option
    val splash : t -> string option
    val discovery_splash : t -> string option
    val features : t -> string list
    val banner : t -> string option
    val region : t -> string option
    val afk_channel_id : t -> string option
    val afk_timeout : t -> int
    val system_channel_id : t -> string option
    val system_channel_flags : t -> int
    val rules_channel_id : t -> string option
    val public_updates_channel_id : t -> string option
    val preferred_locale : t -> string option
    val verification_level : t -> int
    val default_message_notifications : t -> int
    val explicit_content_filter : t -> int
    val mfa_level : t -> int
    val premium_tier : t -> int
    val premium_subscription_count : t -> int option
    val nsfw_level : t -> int
    val vanity_url_code : t -> string option
    val widget_enabled : t -> bool
    val widget_channel_id : t -> string option
    val max_members : t -> int option
    val max_presences : t -> int option
    val max_video_channel_users : t -> int option
    val approximate_member_count : t -> int option
    val approximate_presence_count : t -> int option
    val premium_progress_bar_enabled : t -> bool
    val safety_alerts_channel_id : t -> string option
    val threads : t -> Channel.t list
    val presences : t -> Presence.t list
    val scheduled_events : t -> Guild_scheduled_event.t list
    val stage_instances : t -> Stage_instance.t list
    val welcome_screen : t -> Welcome_screen.t option

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val fetch : Rest.t -> string -> t

    val pp : Format.formatter -> t -> unit
    val show : t -> string
end

include (struct

    type t = {
        id : string;
        name : string;
        icon : string option;
        owner_id : string option;
        unavailable : bool;
        member_count : int option;
        channels : Channel.t list;
        roles : Role.t list;
        emojis : Emoji.t list;
        stickers : Sticker.t list;
        members : Member.t list;
        description : string option;
        splash : string option;
        discovery_splash : string option;
        features : string list;
        banner : string option;
        region : string option;
        afk_channel_id : string option;
        afk_timeout : int;
        system_channel_id : string option;
        system_channel_flags : int;
        rules_channel_id : string option;
        public_updates_channel_id : string option;
        preferred_locale : string option;
        verification_level : int;
        default_message_notifications : int;
        explicit_content_filter : int;
        mfa_level : int;
        premium_tier : int;
        premium_subscription_count : int option;
        nsfw_level : int;
        vanity_url_code : string option;
        widget_enabled : bool;
        widget_channel_id : string option;
        max_members : int option;
        max_presences : int option;
        max_video_channel_users : int option;
        approximate_member_count : int option;
        approximate_presence_count : int option;
        premium_progress_bar_enabled : bool;
        safety_alerts_channel_id : string option;
        threads : Channel.t list;
        presences : Presence.t list;
        scheduled_events : Guild_scheduled_event.t list;
        stage_instances : Stage_instance.t list;
        welcome_screen : Welcome_screen.t option;
    } [@@deriving show, eq]

    let id (g : t) = g.id
    let name (g : t) = g.name
    let icon (g : t) = g.icon
    let owner_id (g : t) = g.owner_id
    let unavailable (g : t) = g.unavailable
    let member_count (g : t) = g.member_count
    let channels (g : t) = g.channels
    let roles (g : t) = g.roles
    let emojis (g : t) = g.emojis
    let stickers (g : t) = g.stickers
    let members (g : t) = g.members
    let description (g : t) = g.description
    let splash (g : t) = g.splash
    let discovery_splash (g : t) = g.discovery_splash
    let features (g : t) = g.features
    let banner (g : t) = g.banner
    let region (g : t) = g.region
    let afk_channel_id (g : t) = g.afk_channel_id
    let afk_timeout (g : t) = g.afk_timeout
    let system_channel_id (g : t) = g.system_channel_id
    let system_channel_flags (g : t) = g.system_channel_flags
    let rules_channel_id (g : t) = g.rules_channel_id
    let public_updates_channel_id (g : t) = g.public_updates_channel_id
    let preferred_locale (g : t) = g.preferred_locale
    let verification_level (g : t) = g.verification_level
    let default_message_notifications (g : t) =
        g.default_message_notifications
    let explicit_content_filter (g : t) = g.explicit_content_filter
    let mfa_level (g : t) = g.mfa_level
    let premium_tier (g : t) = g.premium_tier
    let premium_subscription_count (g : t) = g.premium_subscription_count
    let nsfw_level (g : t) = g.nsfw_level
    let vanity_url_code (g : t) = g.vanity_url_code
    let widget_enabled (g : t) = g.widget_enabled
    let widget_channel_id (g : t) = g.widget_channel_id
    let max_members (g : t) = g.max_members
    let max_presences (g : t) = g.max_presences
    let max_video_channel_users (g : t) = g.max_video_channel_users
    let approximate_member_count (g : t) = g.approximate_member_count
    let approximate_presence_count (g : t) = g.approximate_presence_count
    let premium_progress_bar_enabled (g : t) = g.premium_progress_bar_enabled
    let safety_alerts_channel_id (g : t) = g.safety_alerts_channel_id
    let threads (g : t) = g.threads
    let presences (g : t) = g.presences
    let scheduled_events (g : t) = g.scheduled_events
    let stage_instances (g : t) = g.stage_instances
    let welcome_screen (g : t) = g.welcome_screen

    let create (i : string) : t =
        { id = i;
          name = "";
          icon = None;
          owner_id = None;
          unavailable = false;
          member_count = None;
          channels = [];
          roles = [];
          emojis = [];
          stickers = [];
          members = [];
          description = None;
          splash = None;
          discovery_splash = None;
          features = [];
          banner = None;
          region = None;
          afk_channel_id = None;
          afk_timeout = 0;
          system_channel_id = None;
          system_channel_flags = 0;
          rules_channel_id = None;
          public_updates_channel_id = None;
          preferred_locale = None;
          verification_level = 0;
          default_message_notifications = 0;
          explicit_content_filter = 0;
          mfa_level = 0;
          premium_tier = 0;
          premium_subscription_count = None;
          nsfw_level = 0;
          vanity_url_code = None;
          widget_enabled = false;
          widget_channel_id = None;
          max_members = None;
          max_presences = None;
          max_video_channel_users = None;
          approximate_member_count = None;
          approximate_presence_count = None;
          premium_progress_bar_enabled = false;
          safety_alerts_channel_id = None;
          threads = [];
          presences = [];
          scheduled_events = [];
          stage_instances = [];
          welcome_screen = None }

    let parse_list (json : Yojson.Safe.t) (name : string)
            (f : Yojson.Safe.t -> ('a, string) result) : 'a list =
        match Yojson.Safe.Util.member name json with
        | `List l ->
            List.map
                (fun item ->
                   match f item with
                   | Ok value -> value
                   | Error msg -> raise (Failure msg))
                l
        | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let i name d =
                json |> member name |> to_int_option |> Option.value ~default:d
            in
            let b name d =
                json |> member name |> to_bool_option |> Option.value ~default:d
            in
            Ok
                { id = json |> member "id" |> to_string;
                  name = json |> member "name" |> to_string;
                  icon = json |> member "icon" |> to_string_option;
                  owner_id = json |> member "owner_id" |> to_string_option;
                  unavailable = b "unavailable" false;
                  member_count = json |> member "member_count" |> to_int_option;
                  channels = parse_list json "channels" Channel.of_yojson;
                  roles = parse_list json "roles" Role.of_yojson;
                  emojis = parse_list json "emojis" Emoji.of_yojson;
                  stickers = parse_list json "stickers" Sticker.of_yojson;
                  members = parse_list json "members" Member.of_yojson;
                  description = json |> member "description" |> to_string_option;
                  splash = json |> member "splash" |> to_string_option;
                  discovery_splash =
                    json |> member "discovery_splash" |> to_string_option;
                  features =
                    (match json |> member "features" with
                     | `List l ->
                         List.filter_map
                             (function `String s -> Some s | _ -> None)
                             l
                     | _ -> []);
                  banner = json |> member "banner" |> to_string_option;
                  region = json |> member "region" |> to_string_option;
                  afk_channel_id =
                    json |> member "afk_channel_id" |> to_string_option;
                  afk_timeout = i "afk_timeout" 0;
                  system_channel_id =
                    json |> member "system_channel_id" |> to_string_option;
                  system_channel_flags = i "system_channel_flags" 0;
                  rules_channel_id =
                    json |> member "rules_channel_id" |> to_string_option;
                  public_updates_channel_id =
                    json |> member "public_updates_channel_id"
                    |> to_string_option;
                  preferred_locale =
                    json |> member "preferred_locale" |> to_string_option;
                  verification_level = i "verification_level" 0;
                  default_message_notifications =
                    i "default_message_notifications" 0;
                  explicit_content_filter = i "explicit_content_filter" 0;
                  mfa_level = i "mfa_level" 0;
                  premium_tier = i "premium_tier" 0;
                  premium_subscription_count =
                    json |> member "premium_subscription_count" |> to_int_option;
                  nsfw_level = i "nsfw_level" 0;
                  vanity_url_code =
                    json |> member "vanity_url_code" |> to_string_option;
                  widget_enabled = b "widget_enabled" false;
                  widget_channel_id =
                    json |> member "widget_channel_id" |> to_string_option;
                  max_members = json |> member "max_members" |> to_int_option;
                  max_presences = json |> member "max_presences" |> to_int_option;
                  max_video_channel_users =
                    json |> member "max_video_channel_users" |> to_int_option;
                  approximate_member_count =
                    json |> member "approximate_member_count" |> to_int_option;
                  approximate_presence_count =
                    json |> member "approximate_presence_count" |> to_int_option;
                  premium_progress_bar_enabled =
                    b "premium_progress_bar_enabled" false;
                  safety_alerts_channel_id =
                    json |> member "safety_alerts_channel_id"
                    |> to_string_option;
                  threads = parse_list json "threads" Channel.of_yojson;
                  presences = parse_list json "presences" Presence.of_yojson;
                  scheduled_events =
                    parse_list json "guild_scheduled_events"
                      Guild_scheduled_event.of_yojson;
                  stage_instances =
                    parse_list json "stage_instances" Stage_instance.of_yojson;
                  welcome_screen =
                    (match json |> member "welcome_screen" with
                     | `Null -> None
                     | w ->
                         (match Welcome_screen.of_yojson w with
                          | Ok ws -> Some ws
                          | Error msg -> raise (Failure msg))) }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok g -> g
        | Error msg -> failwith (path ^ ": " ^ msg)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/guilds/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Guild)
