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
    val user : t -> string -> User.t option
    val member : t -> string -> Member.t option
    val role : t -> string -> Role.t option
    val channel : t -> string -> Channel.t option
    val message : t -> string -> Message.t option
    val attachment : t -> string -> Attachment.t option
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
    val option : t -> string -> Application_command.Command_option.t option
    val value : t -> string -> Application_command.Command_option.value option
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
    type t = { custom_id : string; components : Component.t list }

    val custom_id : t -> string
    val components : t -> Component.t list
    val values : t -> (string * string) list
    val field : t -> string -> string option
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
    val focused_option : t -> Application_command.Command_option.t option
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

  type mention_parse = Users | Roles | Everyone

  type allowed_mentions = {
    parse : mention_parse list;
    users : string list;
    roles : string list;
    everyone : bool option;
    replied_user : bool option;
  }

  val allowed_mentions :
    ?parse:mention_parse list ->
    ?users:string list ->
    ?roles:string list ->
    ?everyone:bool ->
    ?replied_user:bool ->
    unit ->
    allowed_mentions

  val reply :
    Rest.t ->
    t ->
    ?content:string ->
    ?embeds:Embed.t list ->
    ?components:Component.t list ->
    ?tts:bool ->
    ?ephemeral:bool ->
    ?allowed_mentions:allowed_mentions ->
    ?files:Attachment.Upload.t list ->
    unit ->
    unit

  val defer : Rest.t -> t -> ?ephemeral:bool -> unit -> unit
  val defer_update : Rest.t -> t -> unit

  val update :
    Rest.t ->
    t ->
    ?content:string ->
    ?embeds:Embed.t list ->
    ?components:Component.t list ->
    ?allowed_mentions:allowed_mentions ->
    ?files:Attachment.Upload.t list ->
    unit ->
    unit

  val autocomplete : Rest.t -> t -> Application_command.Choice.t list -> unit

  val modal :
    Rest.t ->
    t ->
    custom_id:string ->
    title:string ->
    components:Component.t list ->
    unit

  val follow_up :
    Rest.t ->
    t ->
    ?content:string ->
    ?embeds:Embed.t list ->
    ?components:Component.t list ->
    ?tts:bool ->
    ?ephemeral:bool ->
    ?allowed_mentions:allowed_mentions ->
    ?files:Attachment.Upload.t list ->
    unit ->
    Message.t

  val edit_original :
    Rest.t ->
    t ->
    ?content:string ->
    ?embeds:Embed.t list ->
    ?components:Component.t list ->
    ?allowed_mentions:allowed_mentions ->
    ?files:Attachment.Upload.t list ->
    unit ->
    Message.t

  val delete_original : Rest.t -> t -> unit

  val edit_follow_up :
    Rest.t ->
    t ->
    message_id:string ->
    ?content:string ->
    ?embeds:Embed.t list ->
    ?components:Component.t list ->
    ?allowed_mentions:allowed_mentions ->
    ?files:Attachment.Upload.t list ->
    unit ->
    Message.t

  val delete_follow_up : Rest.t -> t -> message_id:string -> unit
end

include (
  struct
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

    let log_decode_error (name : string) (msg : string) : unit =
      prerr_endline (name ^ " decode failed: " ^ msg)

    let parse_map (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : (string * 'a) list =
      match Yojson.Safe.Util.member name json with
      | `Assoc l ->
          List.filter_map
            (fun (k, v) ->
              match f v with
              | Ok x -> Some (k, x)
              | Error msg ->
                  log_decode_error ("resolved " ^ name) (k ^ ": " ^ msg);
                  None)
            l
      | _ -> []

    let parse_members (json : Yojson.Safe.t) (users : (string * User.t) list) :
        (string * Member.t) list =
      match Yojson.Safe.Util.member "members" json with
      | `Assoc l ->
          List.filter_map
            (fun (k, v) ->
              match List.assoc_opt k users with
              | None ->
                  log_decode_error "resolved members"
                    (k ^ ": missing user in resolved users");
                  None
              | Some user -> (
                  match Member.of_yojson_partial ~user v with
                  | Ok member -> Some (k, member)
                  | Error msg ->
                      log_decode_error "resolved members" (k ^ ": " ^ msg);
                      None))
            l
      | _ -> []

    let resolved_message_author (users : (string * User.t) list)
        (json : Yojson.Safe.t) : User.t option =
      let open Yojson.Safe.Util in
      match json |> member "author" with
      | `Assoc fields -> (
          match List.assoc_opt "id" fields with
          | Some (`String id) -> (
              match List.assoc_opt id users with
              | Some user -> Some user
              | None -> (
                  match User.of_yojson (`Assoc fields) with
                  | Ok user -> Some user
                  | Error _ -> None))
          | _ -> None)
      | _ -> None

    let parse_messages (json : Yojson.Safe.t) (users : (string * User.t) list) :
        (string * Message.t) list =
      match Yojson.Safe.Util.member "messages" json with
      | `Assoc l ->
          List.filter_map
            (fun (k, v) ->
              let author = resolved_message_author users v in
              match Message.of_yojson_partial ?author v with
              | Ok message -> Some (k, message)
              | Error msg ->
                  log_decode_error "resolved messages" (k ^ ": " ^ msg);
                  None)
            l
      | _ -> []

    let parse_opt (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> (
          match f v with Ok x -> Some x | Error msg -> raise (Failure msg))

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
      }
      [@@deriving show]

      let users (t : t) : (string * User.t) list = t.users
      let members (t : t) : (string * Member.t) list = t.members
      let roles (t : t) : (string * Role.t) list = t.roles
      let channels (t : t) : (string * Channel.t) list = t.channels
      let messages (t : t) : (string * Message.t) list = t.messages
      let attachments (t : t) : (string * Attachment.t) list = t.attachments
      let user (t : t) (id : string) : User.t option = List.assoc_opt id t.users

      let member (t : t) (id : string) : Member.t option =
        List.assoc_opt id t.members

      let role (t : t) (id : string) : Role.t option = List.assoc_opt id t.roles

      let channel (t : t) (id : string) : Channel.t option =
        List.assoc_opt id t.channels

      let message (t : t) (id : string) : Message.t option =
        List.assoc_opt id t.messages

      let attachment (t : t) (id : string) : Attachment.t option =
        List.assoc_opt id t.attachments

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        try
          let users = parse_map json "users" User.of_yojson in
          Ok
            {
              users;
              members = parse_members json users;
              roles = parse_map json "roles" Role.of_yojson;
              channels = parse_map json "channels" Channel.of_yojson;
              messages = parse_messages json users;
              attachments = parse_map json "attachments" Attachment.of_yojson;
            }
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
      }
      [@@deriving show]

      let id (t : t) : string = t.id
      let name (t : t) : string = t.name
      let type_ (t : t) : int = t.type_
      let resolved (t : t) : Resolved.t option = t.resolved

      let options (t : t) : Application_command.Command_option.t list =
        t.options

      let option (t : t) (name : string) :
          Application_command.Command_option.t option =
        let rec find options =
          match options with
          | [] -> None
          | option :: rest -> (
              if Application_command.Command_option.name option = name then
                Some option
              else
                match
                  find (Application_command.Command_option.options option)
                with
                | Some _ as found -> found
                | None -> find rest)
        in
        find t.options

      let value (t : t) (name : string) :
          Application_command.Command_option.value option =
        match option t name with
        | None -> None
        | Some option -> Application_command.Command_option.value option

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
                    match Application_command.Command_option.of_yojson o with
                    | Ok option -> option
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          Ok
            {
              id = json |> member "id" |> to_string;
              name = json |> member "name" |> to_string;
              type_ =
                json |> member "type" |> to_int_option
                |> Option.value ~default:0;
              resolved = parse_opt json "resolved" Resolved.of_yojson;
              options;
              guild_id = json |> member "guild_id" |> to_string_option;
              target_id = json |> member "target_id" |> to_string_option;
            }
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
      }
      [@@deriving show]

      let custom_id (t : t) : string = t.custom_id
      let component_type (t : t) : int = t.component_type
      let values (t : t) : string list = t.values
      let resolved (t : t) : Resolved.t option = t.resolved

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          Ok
            {
              custom_id = json |> member "custom_id" |> to_string;
              component_type =
                json |> member "component_type" |> to_int_option
                |> Option.value ~default:0;
              values = string_list (json |> member "values");
              resolved = parse_opt json "resolved" Resolved.of_yojson;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Modal_data = struct
      type t = { custom_id : string; components : Component.t list }
      [@@deriving show]

      let custom_id (t : t) : string = t.custom_id
      let components (t : t) : Component.t list = t.components

      let values (t : t) : (string * string) list =
        let rec collect acc components =
          List.fold_left
            (fun acc component ->
              match component with
              | Component.Action_row children -> collect acc children
              | Component.Text_input input -> (
                  match Component.Text_input.value input with
                  | Some value ->
                      (Component.Text_input.custom_id input, value) :: acc
                  | None -> acc)
              | _ -> acc)
            acc components
        in
        List.rev (collect [] t.components)

      let field (t : t) (custom_id : string) : string option =
        List.assoc_opt custom_id (values t)

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
          Ok { custom_id = json |> member "custom_id" |> to_string; components }
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
      }
      [@@deriving show]

      let id (t : t) : string = t.id
      let name (t : t) : string = t.name
      let type_ (t : t) : int = t.type_

      let options (t : t) : Application_command.Command_option.t list =
        t.options

      let focused_option (t : t) : Application_command.Command_option.t option =
        let rec find options =
          match options with
          | [] -> None
          | option :: rest -> (
              match Application_command.Command_option.focused option with
              | Some true -> Some option
              | _ -> (
                  match
                    find (Application_command.Command_option.options option)
                  with
                  | Some _ as focused -> focused
                  | None -> find rest))
        in
        find t.options

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let options =
            match json |> member "options" with
            | `List l ->
                List.map
                  (fun o ->
                    match Application_command.Command_option.of_yojson o with
                    | Ok option -> option
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          Ok
            {
              id = json |> member "id" |> to_string;
              name = json |> member "name" |> to_string;
              type_ =
                json |> member "type" |> to_int_option
                |> Option.value ~default:0;
              options;
            }
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
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
      version : int;
      message : Message.t option;
      app_permissions : Permission.t option;
      locale : string option;
      guild_locale : string option;
    }
    [@@deriving show]

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
            (json |> member "type" |> to_int_option |> Option.value ~default:0)
        in
        let data =
          match type_ with
          | Application_command -> (
              match parse_opt json "data" Command_data.of_yojson with
              | Some d -> Some (Command_data d)
              | None -> None)
          | Message_component -> (
              match parse_opt json "data" Component_data.of_yojson with
              | Some d -> Some (Component_data d)
              | None -> None)
          | Modal_submit -> (
              match parse_opt json "data" Modal_data.of_yojson with
              | Some d -> Some (Modal_data d)
              | None -> None)
          | Autocomplete -> (
              match parse_opt json "data" Autocomplete_data.of_yojson with
              | Some d -> Some (Autocomplete_data d)
              | None -> None)
          | Ping | Unknown _ -> None
        in
        Ok
          {
            id = json |> member "id" |> to_string;
            application_id = json |> member "application_id" |> to_string;
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
            guild_locale = json |> member "guild_locale" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    type mention_parse = Users | Roles | Everyone

    type allowed_mentions = {
      parse : mention_parse list;
      users : string list;
      roles : string list;
      everyone : bool option;
      replied_user : bool option;
    }

    let allowed_mentions ?(parse = []) ?(users = []) ?(roles = []) ?everyone
        ?replied_user () : allowed_mentions =
      { parse; users; roles; everyone; replied_user }

    let optional_string (key : string) (value : string option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `String value) ]

    let optional_int (key : string) (value : int option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `Int value) ]

    let optional_bool (key : string) (value : bool option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `Bool value) ]

    let optional_list (key : string) (value : Yojson.Safe.t list option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `List value) ]

    let optional_nonempty_list (key : string) (value : Yojson.Safe.t list) :
        (string * Yojson.Safe.t) list =
      match value with [] -> [] | value -> [ (key, `List value) ]

    let embed_author_to_yojson (author : Embed.Author.t) : Yojson.Safe.t =
      `Assoc
        ([ ("name", `String author.name) ]
        @ optional_string "url" author.url
        @ optional_string "icon_url" author.icon_url
        @ optional_string "proxy_icon_url" author.proxy_icon_url)

    let embed_footer_to_yojson (footer : Embed.Footer.t) : Yojson.Safe.t =
      `Assoc
        ([ ("text", `String footer.text) ]
        @ optional_string "icon_url" footer.icon_url
        @ optional_string "proxy_icon_url" footer.proxy_icon_url)

    let embed_image_to_yojson (image : Embed.Image.t) : Yojson.Safe.t =
      `Assoc
        ([ ("url", `String image.url) ]
        @ optional_string "proxy_url" image.proxy_url
        @ optional_int "height" image.height
        @ optional_int "width" image.width)

    let embed_video_to_yojson (video : Embed.Video.t) : Yojson.Safe.t =
      `Assoc
        (optional_string "url" video.url
        @ optional_string "proxy_url" video.proxy_url
        @ optional_int "height" video.height
        @ optional_int "width" video.width)

    let embed_provider_to_yojson (provider : Embed.Provider.t) : Yojson.Safe.t =
      `Assoc
        (optional_string "name" provider.name
        @ optional_string "url" provider.url)

    let embed_field_to_yojson (field : Embed.Field.t) : Yojson.Safe.t =
      `Assoc
        [
          ("name", `String field.name);
          ("value", `String field.value);
          ("inline", `Bool field.inline);
        ]

    let embed_to_yojson (embed : Embed.t) : Yojson.Safe.t =
      let optional_object key f = function
        | None -> []
        | Some value -> [ (key, f value) ]
      in
      `Assoc
        (optional_string "title" (Embed.title embed)
        @ optional_string "type" (Embed.type_ embed)
        @ optional_string "description" (Embed.description embed)
        @ optional_string "url" (Embed.url embed)
        @ optional_string "timestamp" (Embed.timestamp embed)
        @ optional_int "color" (Embed.color embed)
        @ optional_object "footer" embed_footer_to_yojson (Embed.footer embed)
        @ optional_object "image" embed_image_to_yojson (Embed.image embed)
        @ optional_object "thumbnail" embed_image_to_yojson
            (Embed.thumbnail embed)
        @ optional_object "video" embed_video_to_yojson (Embed.video embed)
        @ optional_object "provider" embed_provider_to_yojson
            (Embed.provider embed)
        @ optional_object "author" embed_author_to_yojson (Embed.author embed)
        @ optional_nonempty_list "fields"
            (List.map embed_field_to_yojson (Embed.fields embed)))

    let emoji_to_yojson (emoji : Emoji.t) : Yojson.Safe.t =
      `Assoc
        (optional_string "id" (Emoji.id emoji)
        @ optional_string "name" (Emoji.name emoji)
        @ optional_bool "animated"
            (if Emoji.animated emoji then Some true else None))

    let button_style_to_int = function
      | Component.Primary -> 1
      | Component.Secondary -> 2
      | Component.Success -> 3
      | Component.Danger -> 4
      | Component.Link -> 5
      | Component.Premium -> 6
      | Component.Unknown style -> style

    let text_input_style_to_int = function
      | Component.Short -> 1
      | Component.Paragraph -> 2
      | Component.Unknown style -> style

    let default_value_type_to_string = function
      | Component.User -> "user"
      | Component.Role -> "role"
      | Component.Channel -> "channel"
      | Component.Unknown value_type -> value_type

    let select_option_to_yojson (option : Component.Select_option.t) :
        Yojson.Safe.t =
      `Assoc
        ([
           ("label", `String option.label);
           ("value", `String option.value);
           ("default", `Bool option.default);
         ]
        @ optional_string "description" option.description
        @
        match option.emoji with
        | None -> []
        | Some emoji -> [ ("emoji", emoji_to_yojson emoji) ])

    let default_value_to_yojson (value : Component.Default_value.t) :
        Yojson.Safe.t =
      `Assoc
        [
          ("id", `String (Component.Default_value.id value));
          ( "type",
            `String
              (default_value_type_to_string
                 (Component.Default_value.type_ value)) );
        ]

    let select_to_yojson (select : Component.Select.t) (type_ : int) :
        Yojson.Safe.t =
      `Assoc
        ([
           ("type", `Int type_);
           ("custom_id", `String (Component.Select.custom_id select));
         ]
        @ optional_nonempty_list "options"
            (List.map select_option_to_yojson (Component.Select.options select))
        @ optional_string "placeholder" (Component.Select.placeholder select)
        @ [
            ("min_values", `Int (Component.Select.min_values select));
            ("max_values", `Int (Component.Select.max_values select));
            ("disabled", `Bool (Component.Select.disabled select));
          ]
        @ optional_bool "required" (Component.Select.required select)
        @ optional_nonempty_list "channel_types"
            (List.map
               (fun channel_type -> `Int channel_type)
               (Component.Select.channel_types select))
        @ optional_nonempty_list "default_values"
            (List.map default_value_to_yojson
               (Component.Select.default_values select)))

    let button_to_yojson (button : Component.Button.t) : Yojson.Safe.t =
      `Assoc
        ([
           ("type", `Int 2);
           ("style", `Int (button_style_to_int (Component.Button.style button)));
           ("disabled", `Bool (Component.Button.disabled button));
         ]
        @ optional_string "label" (Component.Button.label button)
        @ optional_string "custom_id" (Component.Button.custom_id button)
        @ optional_string "url" (Component.Button.url button)
        @ optional_string "sku_id" (Component.Button.sku_id button)
        @
        match Component.Button.emoji button with
        | None -> []
        | Some emoji -> [ ("emoji", emoji_to_yojson emoji) ])

    let text_input_to_yojson (input : Component.Text_input.t) : Yojson.Safe.t =
      `Assoc
        ([
           ("type", `Int 4);
           ("custom_id", `String (Component.Text_input.custom_id input));
           ( "style",
             `Int (text_input_style_to_int (Component.Text_input.style input))
           );
           ("label", `String (Component.Text_input.label input));
         ]
        @ optional_int "min_length" (Component.Text_input.min_length input)
        @ optional_int "max_length" (Component.Text_input.max_length input)
        @ optional_bool "required" (Component.Text_input.required input)
        @ optional_string "value" (Component.Text_input.value input)
        @ optional_string "placeholder" (Component.Text_input.placeholder input)
        )

    let rec component_to_yojson (component : Component.t) : Yojson.Safe.t =
      match component with
      | Component.Action_row children ->
          `Assoc
            [
              ("type", `Int 1);
              ("components", `List (List.map component_to_yojson children));
            ]
      | Component.Button button -> button_to_yojson button
      | Component.String_select select -> select_to_yojson select 3
      | Component.User_select select -> select_to_yojson select 5
      | Component.Role_select select -> select_to_yojson select 6
      | Component.Mentionable_select select -> select_to_yojson select 7
      | Component.Channel_select select -> select_to_yojson select 8
      | Component.Text_input input -> text_input_to_yojson input
      | Component.Unknown unknown -> `Assoc [ ("type", `Int unknown) ]

    let mention_parse_to_string = function
      | Users -> "users"
      | Roles -> "roles"
      | Everyone -> "everyone"

    let allowed_mentions_to_yojson (mentions : allowed_mentions) : Yojson.Safe.t
        =
      let strings values =
        `List (List.map (fun value -> `String value) values)
      in
      `Assoc
        ((if mentions.parse = [] then []
          else
            [
              ( "parse",
                strings (List.map mention_parse_to_string mentions.parse) );
            ])
        @ (if mentions.users = [] then []
           else [ ("users", strings mentions.users) ])
        @ (if mentions.roles = [] then []
           else [ ("roles", strings mentions.roles) ])
        @ optional_bool "everyone" mentions.everyone
        @ optional_bool "replied_user" mentions.replied_user)

    let message_payload_to_yojson ?content ?embeds ?components ?tts ?ephemeral
        ?allowed_mentions () : Yojson.Safe.t =
      `Assoc
        (optional_string "content" content
        @ optional_list "embeds" (Option.map (List.map embed_to_yojson) embeds)
        @ optional_list "components"
            (Option.map (List.map component_to_yojson) components)
        @ optional_bool "tts" tts
        @ (match ephemeral with Some true -> [ ("flags", `Int 64) ] | _ -> [])
        @
        match allowed_mentions with
        | None -> []
        | Some mentions ->
            [ ("allowed_mentions", allowed_mentions_to_yojson mentions) ])

    let file_parts (uploads : Attachment.Upload.t list) :
        (string * string * string option) list =
      List.map
        (fun upload ->
          ( Attachment.Upload.name upload,
            Attachment.Upload.content upload,
            Attachment.Upload.content_type upload ))
        uploads

    let send_json (rest : Rest.t) ?(files = []) (meth : Rest.meth)
        (path : string) (body : string) : int * string =
      let files =
        match files with
        | [] -> None
        | attachments -> Some (file_parts attachments)
      in
      Rest.request rest ?files ~body meth path

    let callback (rest : Rest.t) (interaction : t) (callback_type : int) ?data
        ?files () : unit =
      let path =
        "/interactions/" ^ interaction.id ^ "/" ^ interaction.token
        ^ "/callback"
      in
      let body =
        `Assoc
          (("type", `Int callback_type)
          :: (match data with None -> [] | Some data -> [ ("data", data) ]))
        |> Yojson.Safe.to_string
      in
      let code, resp = send_json rest ?files Rest.Post path body in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let ensure_interaction (interaction : t) (action : string)
        (allowed : interaction_type list) : unit =
      if not (List.mem interaction.type_ allowed) then
        failwith
          (Printf.sprintf
             "interaction %s: %s is not supported for %s interactions"
             interaction.id action
             (show_interaction_type interaction.type_))

    let reply (rest : Rest.t) (interaction : t) ?content ?embeds ?components
        ?tts ?ephemeral ?allowed_mentions ?files () : unit =
      ensure_interaction interaction "reply"
        [ Application_command; Message_component; Modal_submit ];
      let data =
        message_payload_to_yojson ?content ?embeds ?components ?tts ?ephemeral
          ?allowed_mentions ()
      in
      callback rest interaction 4 ~data ?files ()

    let defer (rest : Rest.t) (interaction : t) ?ephemeral () : unit =
      ensure_interaction interaction "defer"
        [ Application_command; Message_component; Modal_submit ];
      let data =
        `Assoc
          (match ephemeral with Some true -> [ ("flags", `Int 64) ] | _ -> [])
      in
      callback rest interaction 5 ~data ()

    let defer_update (rest : Rest.t) (interaction : t) : unit =
      ensure_interaction interaction "defer_update"
        [ Message_component; Modal_submit ];
      callback rest interaction 6 ()

    let update (rest : Rest.t) (interaction : t) ?content ?embeds ?components
        ?allowed_mentions ?files () : unit =
      ensure_interaction interaction "update"
        [ Message_component; Modal_submit ];
      let data =
        message_payload_to_yojson ?content ?embeds ?components ?allowed_mentions
          ()
      in
      callback rest interaction 7 ~data ?files ()

    let autocomplete (rest : Rest.t) (interaction : t)
        (choices : Application_command.Choice.t list) : unit =
      ensure_interaction interaction "autocomplete" [ Autocomplete ];
      let data =
        `Assoc
          [
            ( "choices",
              `List (List.map Application_command.Choice.to_yojson choices) );
          ]
      in
      callback rest interaction 8 ~data ()

    let modal (rest : Rest.t) (interaction : t) ~custom_id ~title ~components :
        unit =
      ensure_interaction interaction "modal"
        [ Application_command; Message_component ];
      let data =
        `Assoc
          [
            ("custom_id", `String custom_id);
            ("title", `String title);
            ("components", `List (List.map component_to_yojson components));
          ]
      in
      callback rest interaction 9 ~data ()

    let webhook_path (interaction : t) (suffix : string) : string =
      "/webhooks/" ^ interaction.application_id ^ "/" ^ interaction.token
      ^ suffix

    let message_response (method_name : string) (path : string) (code : int)
        (resp : string) : Message.t =
      if code < 200 || code >= 300 then
        failwith
          (Printf.sprintf "%s %s: HTTP %d: %s" method_name path code resp);
      match Message.of_yojson (Yojson.Safe.from_string resp) with
      | Ok message -> message
      | Error msg -> failwith (path ^ ": " ^ msg)

    let follow_up (rest : Rest.t) (interaction : t) ?content ?embeds ?components
        ?tts ?ephemeral ?allowed_mentions ?files () : Message.t =
      ensure_interaction interaction "follow_up"
        [ Application_command; Message_component; Modal_submit ];
      let path = webhook_path interaction "?wait=true" in
      let body =
        message_payload_to_yojson ?content ?embeds ?components ?tts ?ephemeral
          ?allowed_mentions ()
        |> Yojson.Safe.to_string
      in
      let code, resp = send_json rest ?files Rest.Post path body in
      message_response "POST" path code resp

    let edit_original (rest : Rest.t) (interaction : t) ?content ?embeds
        ?components ?allowed_mentions ?files () : Message.t =
      ensure_interaction interaction "edit_original"
        [ Application_command; Message_component; Modal_submit ];
      let path = webhook_path interaction "/messages/@original" in
      let body =
        message_payload_to_yojson ?content ?embeds ?components ?allowed_mentions
          ()
        |> Yojson.Safe.to_string
      in
      let code, resp = send_json rest ?files Rest.Patch path body in
      message_response "PATCH" path code resp

    let delete_original (rest : Rest.t) (interaction : t) : unit =
      ensure_interaction interaction "delete_original"
        [ Application_command; Message_component; Modal_submit ];
      let path = webhook_path interaction "/messages/@original" in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let edit_follow_up (rest : Rest.t) (interaction : t) ~message_id ?content
        ?embeds ?components ?allowed_mentions ?files () : Message.t =
      ensure_interaction interaction "edit_follow_up"
        [ Application_command; Message_component; Modal_submit ];
      let path = webhook_path interaction ("/messages/" ^ message_id) in
      let body =
        message_payload_to_yojson ?content ?embeds ?components ?allowed_mentions
          ()
        |> Yojson.Safe.to_string
      in
      let code, resp = send_json rest ?files Rest.Patch path body in
      message_response "PATCH" path code resp

    let delete_follow_up (rest : Rest.t) (interaction : t) ~message_id : unit =
      ensure_interaction interaction "delete_follow_up"
        [ Application_command; Message_component; Modal_submit ];
      let path = webhook_path interaction ("/messages/" ^ message_id) in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)
  end :
    Interaction)
