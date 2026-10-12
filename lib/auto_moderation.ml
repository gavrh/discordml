module type Auto_moderation = sig
    type trigger_metadata = {
        keyword_filter : string list;
        regex_patterns : string list;
        presets : int list;
        allow_list : string list;
        mention_total_limit : int option;
        mention_raid_protection_enabled : bool;
    }

    type action_metadata = {
        channel_id : string option;
        duration_seconds : int option;
        custom_message : string option;
    }

    type action = {
        type_ : int;
        metadata : action_metadata option;
    }

    type t = {
        id : string;
        guild_id : string;
        name : string;
        creator_id : string;
        event_type : int;
        trigger_type : int;
        trigger_metadata : trigger_metadata;
        actions : action list;
        enabled : bool;
        exempt_roles : string list;
        exempt_channels : string list;
    }

    val id : t -> string
    val guild_id : t -> string
    val name : t -> string
    val creator_id : t -> string
    val event_type : t -> int
    val trigger_type : t -> int
    val trigger_metadata : t -> trigger_metadata
    val actions : t -> action list
    val enabled : t -> bool
    val exempt_roles : t -> string list
    val exempt_channels : t -> string list

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type trigger_metadata = {
        keyword_filter : string list;
        regex_patterns : string list;
        presets : int list;
        allow_list : string list;
        mention_total_limit : int option;
        mention_raid_protection_enabled : bool;
    } [@@deriving show, eq]

    type action_metadata = {
        channel_id : string option;
        duration_seconds : int option;
        custom_message : string option;
    } [@@deriving show, eq]

    type action = {
        type_ : int;
        metadata : action_metadata option;
    } [@@deriving show, eq]

    type t = {
        id : string;
        guild_id : string;
        name : string;
        creator_id : string;
        event_type : int;
        trigger_type : int;
        trigger_metadata : trigger_metadata;
        actions : action list;
        enabled : bool;
        exempt_roles : string list;
        exempt_channels : string list;
    } [@@deriving show, eq]

    let id (r : t) : string = r.id
    let guild_id (r : t) : string = r.guild_id
    let name (r : t) : string = r.name
    let creator_id (r : t) : string = r.creator_id
    let event_type (r : t) : int = r.event_type
    let trigger_type (r : t) : int = r.trigger_type
    let trigger_metadata (r : t) : trigger_metadata = r.trigger_metadata
    let actions (r : t) : action list = r.actions
    let enabled (r : t) : bool = r.enabled
    let exempt_roles (r : t) : string list = r.exempt_roles
    let exempt_channels (r : t) : string list = r.exempt_channels

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map (function `String s -> Some s | _ -> None) l
        | _ -> []

    let int_list (json : Yojson.Safe.t) : int list =
        match json with
        | `List l -> List.filter_map (function `Int n -> Some n | _ -> None) l
        | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let tm = json |> member "trigger_metadata" in
            let trigger_metadata =
                { keyword_filter = string_list (tm |> member "keyword_filter");
                  regex_patterns = string_list (tm |> member "regex_patterns");
                  presets = int_list (tm |> member "presets");
                  allow_list = string_list (tm |> member "allow_list");
                  mention_total_limit =
                    tm |> member "mention_total_limit" |> to_int_option;
                  mention_raid_protection_enabled =
                    tm |> member "mention_raid_protection_enabled"
                    |> to_bool_option |> Option.value ~default:false }
            in
            let actions =
                match json |> member "actions" with
                | `List l ->
                    List.map
                        (fun a ->
                           let metadata =
                               match a |> member "metadata" with
                               | `Null -> None
                               | m ->
                                   Some
                                       { channel_id =
                                           m |> member "channel_id"
                                           |> to_string_option;
                                         duration_seconds =
                                           m |> member "duration_seconds"
                                           |> to_int_option;
                                         custom_message =
                                           m |> member "custom_message"
                                           |> to_string_option }
                           in
                           { type_ =
                               a |> member "type" |> to_int_option
                               |> Option.value ~default:0;
                             metadata })
                        l
                | _ -> []
            in
            Ok
                { id = json |> member "id" |> to_string;
                  guild_id = json |> member "guild_id" |> to_string;
                  name = json |> member "name" |> to_string;
                  creator_id = json |> member "creator_id" |> to_string;
                  event_type =
                    json |> member "event_type" |> to_int_option
                    |> Option.value ~default:0;
                  trigger_type =
                    json |> member "trigger_type" |> to_int_option
                    |> Option.value ~default:0;
                  trigger_metadata;
                  actions;
                  enabled =
                    json |> member "enabled" |> to_bool_option
                    |> Option.value ~default:false;
                  exempt_roles = string_list (json |> member "exempt_roles");
                  exempt_channels =
                    string_list (json |> member "exempt_channels") }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : Auto_moderation)
