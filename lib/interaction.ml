module type Interaction = sig
    type interaction_type =
        | Ping
        | Application_command
        | Message_component
        | Autocomplete
        | Modal_submit
        | Unknown of int

    module Resolved : sig
        type t = {
            users : (string * User.t) list;
            members : (string * Member.t) list;
            roles : (string * Role.t) list;
            channels : (string * Channel.t) list;
            messages : (string * Message.t) list;
            attachments : (string * Attachment.t) list;
        }

        val users : t -> (string * User.t) list
        val members : t -> (string * Member.t) list
        val roles : t -> (string * Role.t) list
        val channels : t -> (string * Channel.t) list
        val messages : t -> (string * Message.t) list
        val attachments : t -> (string * Attachment.t) list

        val pp : Format.formatter -> t -> unit
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Command_data : sig
        type t = {
            id : string;
            name : string;
            type_ : int;
            resolved : Resolved.t option;
            options : Application_command.Command_option.t list;
            guild_id : string option;
            target_id : string option;
        }

        val id : t -> string
        val name : t -> string
        val type_ : t -> int
        val resolved : t -> Resolved.t option
        val options : t -> Application_command.Command_option.t list
        val guild_id : t -> string option
        val target_id : t -> string option

        val pp : Format.formatter -> t -> unit
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Component_data : sig
        type t = {
            custom_id : string;
            component_type : int;
            values : string list;
            resolved : Resolved.t option;
        }

        val custom_id : t -> string
        val component_type : t -> int
        val values : t -> string list
        val resolved : t -> Resolved.t option

        val pp : Format.formatter -> t -> unit
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Modal_data : sig
        type t = {
            custom_id : string;
            components : Component.t list;
        }

        val custom_id : t -> string
        val components : t -> Component.t list

        val pp : Format.formatter -> t -> unit
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Autocomplete_data : sig
        type t = {
            id : string;
            name : string;
            type_ : int;
            options : Application_command.Command_option.t list;
        }

        val id : t -> string
        val name : t -> string
        val type_ : t -> int
        val options : t -> Application_command.Command_option.t list

        val pp : Format.formatter -> t -> unit
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    type data =
        | Command_data of Command_data.t
        | Component_data of Component_data.t
        | Modal_data of Modal_data.t
        | Autocomplete_data of Autocomplete_data.t

    type t = {
        id : string;
        application_id : string;
        type_ : interaction_type;
        data : data option;
        guild_id : string option;
        channel : Channel.t option;
        channel_id : string option;
        member : Member.t option;
        user : User.t option;
        token : string;
        version : int;
        message : Message.t option;
        app_permissions : Permission.t option;
        locale : string option;
        guild_locale : string option;
    }

    val id : t -> string
    val application_id : t -> string
    val type_ : t -> interaction_type
    val data : t -> data option
    val guild_id : t -> string option
    val channel : t -> Channel.t option
    val channel_id : t -> string option
    val member : t -> Member.t option
    val user : t -> User.t option
    val token : t -> string
    val version : t -> int
    val message : t -> Message.t option
    val app_permissions : t -> Permission.t option
    val locale : t -> string option
    val guild_locale : t -> string option

    val pp : Format.formatter -> t -> unit
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type interaction_type =
        | Ping
        | Application_command
        | Message_component
        | Autocomplete
        | Modal_submit
        | Unknown of int
    [@@deriving show]

    let interaction_type_of_int = function
        | 1 -> Ping
        | 2 -> Application_command
        | 3 -> Message_component
        | 4 -> Autocomplete
        | 5 -> Modal_submit
        | n -> Unknown n

    let parse_map (json : Yojson.Safe.t) (name : string)
            (f : Yojson.Safe.t -> ('a, string) result) : (string * 'a) list =
        match Yojson.Safe.Util.member name json with
        | `Assoc l ->
            List.filter_map
                (fun (k, v) ->
                   match f v with Ok x -> Some (k, x) | Error _ -> None)
                l
        | _ -> []

    let parse_opt (json : Yojson.Safe.t) (name : string)
            (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
        match Yojson.Safe.Util.member name json with
        | `Null -> None
        | v ->
            (match f v with
             | Ok x -> Some x
             | Error msg -> raise (Failure msg))

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map (function `String s -> Some s | _ -> None) l
        | _ -> []

    module Resolved = struct
        type t = {
            users : (string * User.t) list;
            members : (string * Member.t) list;
            roles : (string * Role.t) list;
            channels : (string * Channel.t) list;
            messages : (string * Message.t) list;
            attachments : (string * Attachment.t) list;
        } [@@deriving show]

        let users (t : t) : (string * User.t) list = t.users
        let members (t : t) : (string * Member.t) list = t.members
        let roles (t : t) : (string * Role.t) list = t.roles
        let channels (t : t) : (string * Channel.t) list = t.channels
        let messages (t : t) : (string * Message.t) list = t.messages
        let attachments (t : t) : (string * Attachment.t) list = t.attachments

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            try
                Ok
                    { users = parse_map json "users" User.of_yojson;
                      members = parse_map json "members" Member.of_yojson;
                      roles = parse_map json "roles" Role.of_yojson;
                      channels = parse_map json "channels" Channel.of_yojson;
                      messages = parse_map json "messages" Message.of_yojson;
                      attachments =
                        parse_map json "attachments" Attachment.of_yojson }
            with
            | Yojson.Safe.Util.Type_error (msg, _) -> Error msg
            | Yojson.Safe.Util.Undefined (msg, _) -> Error msg
            | Failure msg -> Error msg
    end

    module Command_data = struct
        type t = {
            id : string;
            name : string;
            type_ : int;
            resolved : Resolved.t option;
            options : Application_command.Command_option.t list;
            guild_id : string option;
            target_id : string option;
        } [@@deriving show]

        let id (t : t) : string = t.id
        let name (t : t) : string = t.name
        let type_ (t : t) : int = t.type_
        let resolved (t : t) : Resolved.t option = t.resolved
        let options (t : t) : Application_command.Command_option.t list =
            t.options
        let guild_id (t : t) : string option = t.guild_id
        let target_id (t : t) : string option = t.target_id

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                let options =
                    match json |> member "options" with
                    | `List l ->
                        List.map
                            (fun o ->
                               match Application_command.Command_option.of_yojson o
                               with
                               | Ok option -> option
                               | Error msg -> raise (Failure msg))
                            l
                    | _ -> []
                in
                Ok
                    { id = json |> member "id" |> to_string;
                      name = json |> member "name" |> to_string;
                      type_ =
                        json |> member "type" |> to_int_option
                        |> Option.value ~default:0;
                      resolved = parse_opt json "resolved" Resolved.of_yojson;
                      options;
                      guild_id = json |> member "guild_id" |> to_string_option;
                      target_id = json |> member "target_id" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
            | Failure msg -> Error msg
    end

    module Component_data = struct
        type t = {
            custom_id : string;
            component_type : int;
            values : string list;
            resolved : Resolved.t option;
        } [@@deriving show]

        let custom_id (t : t) : string = t.custom_id
        let component_type (t : t) : int = t.component_type
        let values (t : t) : string list = t.values
        let resolved (t : t) : Resolved.t option = t.resolved

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { custom_id = json |> member "custom_id" |> to_string;
                      component_type =
                        json |> member "component_type" |> to_int_option
                        |> Option.value ~default:0;
                      values = string_list (json |> member "values");
                      resolved = parse_opt json "resolved" Resolved.of_yojson }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
            | Failure msg -> Error msg
    end

    module Modal_data = struct
        type t = {
            custom_id : string;
            components : Component.t list;
        } [@@deriving show]

        let custom_id (t : t) : string = t.custom_id
        let components (t : t) : Component.t list = t.components

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                let components =
                    match json |> member "components" with
                    | `List l ->
                        List.map
                            (fun c ->
                               match Component.of_yojson c with
                               | Ok component -> component
                               | Error msg -> raise (Failure msg))
                            l
                    | _ -> []
                in
                Ok
                    { custom_id = json |> member "custom_id" |> to_string;
                      components }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
            | Failure msg -> Error msg
    end

    module Autocomplete_data = struct
        type t = {
            id : string;
            name : string;
            type_ : int;
            options : Application_command.Command_option.t list;
        } [@@deriving show]

        let id (t : t) : string = t.id
        let name (t : t) : string = t.name
        let type_ (t : t) : int = t.type_
        let options (t : t) : Application_command.Command_option.t list =
            t.options

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                let options =
                    match json |> member "options" with
                    | `List l ->
                        List.map
                            (fun o ->
                               match Application_command.Command_option.of_yojson o
                               with
                               | Ok option -> option
                               | Error msg -> raise (Failure msg))
                            l
                    | _ -> []
                in
                Ok
                    { id = json |> member "id" |> to_string;
                      name = json |> member "name" |> to_string;
                      type_ =
                        json |> member "type" |> to_int_option
                        |> Option.value ~default:0;
                      options }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
            | Failure msg -> Error msg
    end

    type data =
        | Command_data of Command_data.t
        | Component_data of Component_data.t
        | Modal_data of Modal_data.t
        | Autocomplete_data of Autocomplete_data.t
    [@@deriving show]

    type t = {
        id : string;
        application_id : string;
        type_ : interaction_type;
        data : data option;
        guild_id : string option;
        channel : Channel.t option;
        channel_id : string option;
        member : Member.t option;
        user : User.t option;
        token : string;
        version : int;
        message : Message.t option;
        app_permissions : Permission.t option;
        locale : string option;
        guild_locale : string option;
    } [@@deriving show]

    let id (t : t) : string = t.id
    let application_id (t : t) : string = t.application_id
    let type_ (t : t) : interaction_type = t.type_
    let data (t : t) : data option = t.data
    let guild_id (t : t) : string option = t.guild_id
    let channel (t : t) : Channel.t option = t.channel
    let channel_id (t : t) : string option = t.channel_id
    let member (t : t) : Member.t option = t.member
    let user (t : t) : User.t option = t.user
    let token (t : t) : string = t.token
    let version (t : t) : int = t.version
    let message (t : t) : Message.t option = t.message
    let app_permissions (t : t) : Permission.t option = t.app_permissions
    let locale (t : t) : string option = t.locale
    let guild_locale (t : t) : string option = t.guild_locale

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let type_ =
                interaction_type_of_int
                    (json |> member "type" |> to_int_option
                     |> Option.value ~default:0)
            in
            let data =
                match type_ with
                | Application_command ->
                    (match parse_opt json "data" Command_data.of_yojson with
                     | Some d -> Some (Command_data d)
                     | None -> None)
                | Message_component ->
                    (match parse_opt json "data" Component_data.of_yojson with
                     | Some d -> Some (Component_data d)
                     | None -> None)
                | Modal_submit ->
                    (match parse_opt json "data" Modal_data.of_yojson with
                     | Some d -> Some (Modal_data d)
                     | None -> None)
                | Autocomplete ->
                    (match parse_opt json "data" Autocomplete_data.of_yojson with
                     | Some d -> Some (Autocomplete_data d)
                     | None -> None)
                | Ping | Unknown _ -> None
            in
            Ok
                { id = json |> member "id" |> to_string;
                  application_id =
                    json |> member "application_id" |> to_string;
                  type_;
                  data;
                  guild_id = json |> member "guild_id" |> to_string_option;
                  channel = parse_opt json "channel" Channel.of_yojson;
                  channel_id = json |> member "channel_id" |> to_string_option;
                  member = parse_opt json "member" Member.of_yojson;
                  user = parse_opt json "user" User.of_yojson;
                  token =
                    json |> member "token" |> to_string_option
                    |> Option.value ~default:"";
                  version =
                    json |> member "version" |> to_int_option
                    |> Option.value ~default:0;
                  message = parse_opt json "message" Message.of_yojson;
                  app_permissions =
                    (match json |> member "app_permissions" with
                     | `Null -> None
                     | p -> Some (Permission.of_yojson p));
                  locale = json |> member "locale" |> to_string_option;
                  guild_locale =
                    json |> member "guild_locale" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Interaction)
