module type Application_command = sig
  type command_type = Chat_input | User | Message | Unknown of int

  module Choice : sig
    type value = String of string | Integer of int | Number of float

    type t = {
      name : string;
      value : value;
      name_localizations : (string * string) list;
    }

    val name : t -> string
    val value : t -> value
    val name_localizations : t -> (string * string) list

    val make :
      name:string ->
      value:value ->
      ?name_localizations:(string * string) list ->
      unit ->
      t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
    val to_yojson : t -> Yojson.Safe.t
  end

  module Command_option : sig
    type value =
      | String of string
      | Integer of int
      | Boolean of bool
      | Number of float

    type t = {
      type_ : int;
      name : string;
      description : string;
      required : bool option;
      choices : Choice.t list;
      options : t list;
      channel_types : int list;
      min_value : float option;
      max_value : float option;
      min_length : int option;
      max_length : int option;
      autocomplete : bool option;
      name_localizations : (string * string) list;
      description_localizations : (string * string) list;
      focused : bool option;
      value : value option;
    }

    val type_ : t -> int
    val name : t -> string
    val description : t -> string
    val required : t -> bool option
    val choices : t -> Choice.t list
    val options : t -> t list
    val channel_types : t -> int list
    val min_value : t -> float option
    val max_value : t -> float option
    val min_length : t -> int option
    val max_length : t -> int option
    val autocomplete : t -> bool option
    val name_localizations : t -> (string * string) list
    val description_localizations : t -> (string * string) list
    val focused : t -> bool option
    val value : t -> value option

    val make :
      type_:int ->
      name:string ->
      description:string ->
      ?required:bool ->
      ?choices:Choice.t list ->
      ?options:t list ->
      ?channel_types:int list ->
      ?min_value:float ->
      ?max_value:float ->
      ?min_length:int ->
      ?max_length:int ->
      ?autocomplete:bool ->
      ?name_localizations:(string * string) list ->
      ?description_localizations:(string * string) list ->
      unit ->
      t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
    val to_yojson : t -> Yojson.Safe.t
  end

  type t = {
    id : string;
    application_id : string;
    name : string;
    description : string;
    type_ : command_type;
    options : Command_option.t list;
    guild_id : string option;
    default_member_permissions : Permission.t option;
    dm_permission : bool option;
    default_permission : bool option;
    nsfw : bool option;
    version : string;
    name_localizations : (string * string) list;
    description_localizations : (string * string) list;
    integration_types : int list;
    contexts : int list;
  }

  val id : t -> string
  val application_id : t -> string
  val name : t -> string
  val description : t -> string
  val type_ : t -> command_type
  val options : t -> Command_option.t list
  val guild_id : t -> string option
  val default_member_permissions : t -> Permission.t option
  val dm_permission : t -> bool option
  val default_permission : t -> bool option
  val nsfw : t -> bool option
  val version : t -> string
  val name_localizations : t -> (string * string) list
  val description_localizations : t -> (string * string) list
  val integration_types : t -> int list
  val contexts : t -> int list
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val to_yojson : t -> Yojson.Safe.t

  val make :
    name:string ->
    description:string ->
    type_:command_type ->
    ?options:Command_option.t list ->
    ?guild_id:string ->
    ?default_member_permissions:Permission.t ->
    ?dm_permission:bool ->
    ?default_permission:bool ->
    ?nsfw:bool ->
    ?name_localizations:(string * string) list ->
    ?description_localizations:(string * string) list ->
    ?integration_types:int list ->
    ?contexts:int list ->
    unit ->
    t

  val list :
    Rest.t -> application_id:string -> ?guild_id:string -> unit -> t list

  val fetch :
    Rest.t ->
    application_id:string ->
    command_id:string ->
    ?guild_id:string ->
    unit ->
    t

  val create : Rest.t -> application_id:string -> ?guild_id:string -> t -> t

  val edit :
    Rest.t ->
    application_id:string ->
    command_id:string ->
    ?guild_id:string ->
    t ->
    t

  val delete :
    Rest.t ->
    application_id:string ->
    command_id:string ->
    ?guild_id:string ->
    unit ->
    unit

  val bulk_overwrite :
    Rest.t -> application_id:string -> ?guild_id:string -> t list -> t list
end

include (
  struct
    type command_type = Chat_input | User | Message | Unknown of int
    [@@deriving show, eq]

    let command_type_of_int = function
      | 1 -> Chat_input
      | 2 -> User
      | 3 -> Message
      | n -> Unknown n

    let localizations (json : Yojson.Safe.t) : (string * string) list =
      match json with
      | `Assoc l ->
          List.filter_map (function k, `String v -> Some (k, v) | _ -> None) l
      | _ -> []

    let int_list (json : Yojson.Safe.t) : int list =
      match json with
      | `List l -> List.filter_map (function `Int n -> Some n | _ -> None) l
      | _ -> []

    let localizations_to_yojson (localizations : (string * string) list) :
        Yojson.Safe.t =
      `Assoc
        (List.map
           (fun (locale, value) -> (locale, `String value))
           localizations)

    let int_list_to_yojson (values : int list) : Yojson.Safe.t =
      `List (List.map (fun value -> `Int value) values)

    let optional_string (key : string) (value : string option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `String value) ]

    let optional_bool (key : string) (value : bool option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `Bool value) ]

    let optional_float (key : string) (value : float option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `Float value) ]

    let optional_int (key : string) (value : int option) :
        (string * Yojson.Safe.t) list =
      match value with None -> [] | Some value -> [ (key, `Int value) ]

    module Choice = struct
      type value = String of string | Integer of int | Number of float
      [@@deriving show, eq]

      type t = {
        name : string;
        value : value;
        name_localizations : (string * string) list;
      }
      [@@deriving show, eq]

      let name (c : t) : string = c.name
      let value (c : t) : value = c.value

      let name_localizations (c : t) : (string * string) list =
        c.name_localizations

      let make ~(name : string) ~(value : value) ?(name_localizations = []) () :
          t =
        { name; value; name_localizations }

      let to_yojson (c : t) : Yojson.Safe.t =
        let value =
          match c.value with
          | String value -> `String value
          | Integer value -> `Int value
          | Number value -> `Float value
        in
        `Assoc
          ([ ("name", `String c.name); ("value", value) ]
          @
          if c.name_localizations = [] then []
          else
            [
              ( "name_localizations",
                localizations_to_yojson c.name_localizations );
            ])

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let value =
            match json |> member "value" with
            | `String s -> String s
            | `Int n -> Integer n
            | `Intlit s -> Integer (int_of_string s)
            | `Float f -> Number f
            | _ -> String ""
          in
          Ok
            {
              name = json |> member "name" |> to_string;
              value;
              name_localizations =
                localizations (json |> member "name_localizations");
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
    end

    module Command_option = struct
      type value =
        | String of string
        | Integer of int
        | Boolean of bool
        | Number of float
      [@@deriving show, eq]

      type t = {
        type_ : int;
        name : string;
        description : string;
        required : bool option;
        choices : Choice.t list;
        options : t list;
        channel_types : int list;
        min_value : float option;
        max_value : float option;
        min_length : int option;
        max_length : int option;
        autocomplete : bool option;
        name_localizations : (string * string) list;
        description_localizations : (string * string) list;
        focused : bool option;
        value : value option;
      }
      [@@deriving show, eq]

      let type_ (t : t) : int = t.type_
      let name (t : t) : string = t.name
      let description (t : t) : string = t.description
      let required (t : t) : bool option = t.required
      let choices (t : t) : Choice.t list = t.choices
      let options (t : t) : t list = t.options
      let channel_types (t : t) : int list = t.channel_types
      let min_value (t : t) : float option = t.min_value
      let max_value (t : t) : float option = t.max_value
      let min_length (t : t) : int option = t.min_length
      let max_length (t : t) : int option = t.max_length
      let autocomplete (t : t) : bool option = t.autocomplete

      let name_localizations (t : t) : (string * string) list =
        t.name_localizations

      let description_localizations (t : t) : (string * string) list =
        t.description_localizations

      let focused (t : t) : bool option = t.focused
      let value (t : t) : value option = t.value

      let make ~(type_ : int) ~(name : string) ~(description : string) ?required
          ?(choices = []) ?(options = []) ?(channel_types = []) ?min_value
          ?max_value ?min_length ?max_length ?autocomplete
          ?(name_localizations = []) ?(description_localizations = []) () : t =
        {
          type_;
          name;
          description;
          required;
          choices;
          options;
          channel_types;
          min_value;
          max_value;
          min_length;
          max_length;
          autocomplete;
          name_localizations;
          description_localizations;
          focused = None;
          value = None;
        }

      let rec to_yojson (t : t) : Yojson.Safe.t =
        `Assoc
          ([
             ("type", `Int t.type_);
             ("name", `String t.name);
             ("description", `String t.description);
           ]
          @ optional_bool "required" t.required
          @ (if t.choices = [] then []
             else [ ("choices", `List (List.map Choice.to_yojson t.choices)) ])
          @ (if t.options = [] then []
             else [ ("options", `List (List.map to_yojson t.options)) ])
          @ (if t.channel_types = [] then []
             else [ ("channel_types", int_list_to_yojson t.channel_types) ])
          @ optional_float "min_value" t.min_value
          @ optional_float "max_value" t.max_value
          @ optional_int "min_length" t.min_length
          @ optional_int "max_length" t.max_length
          @ optional_bool "autocomplete" t.autocomplete
          @ (if t.name_localizations = [] then []
             else
               [
                 ( "name_localizations",
                   localizations_to_yojson t.name_localizations );
               ])
          @
          if t.description_localizations = [] then []
          else
            [
              ( "description_localizations",
                localizations_to_yojson t.description_localizations );
            ])

      let value_of_json (json : Yojson.Safe.t) : value option =
        match json with
        | `Null -> None
        | `String value -> Some (String value)
        | `Int value -> Some (Integer value)
        | `Intlit value -> Some (Integer (int_of_string value))
        | `Bool value -> Some (Boolean value)
        | `Float value -> Some (Number value)
        | _ -> None

      let rec of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let choices =
            match json |> member "choices" with
            | `List l ->
                List.map
                  (fun c ->
                    match Choice.of_yojson c with
                    | Ok choice -> choice
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          let options =
            match json |> member "options" with
            | `List l ->
                List.map
                  (fun o ->
                    match of_yojson o with
                    | Ok option -> option
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          Ok
            {
              type_ =
                json |> member "type" |> to_int_option
                |> Option.value ~default:0;
              name = json |> member "name" |> to_string;
              description =
                json |> member "description" |> to_string_option
                |> Option.value ~default:"";
              required = json |> member "required" |> to_bool_option;
              choices;
              options;
              channel_types = int_list (json |> member "channel_types");
              min_value = json |> member "min_value" |> to_float_option;
              max_value = json |> member "max_value" |> to_float_option;
              min_length = json |> member "min_length" |> to_int_option;
              max_length = json |> member "max_length" |> to_int_option;
              autocomplete = json |> member "autocomplete" |> to_bool_option;
              name_localizations =
                localizations (json |> member "name_localizations");
              description_localizations =
                localizations (json |> member "description_localizations");
              focused = json |> member "focused" |> to_bool_option;
              value = value_of_json (json |> member "value");
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    type t = {
      id : string;
      application_id : string;
      name : string;
      description : string;
      type_ : command_type;
      options : Command_option.t list;
      guild_id : string option;
      default_member_permissions : Permission.t option;
      dm_permission : bool option;
      default_permission : bool option;
      nsfw : bool option;
      version : string;
      name_localizations : (string * string) list;
      description_localizations : (string * string) list;
      integration_types : int list;
      contexts : int list;
    }
    [@@deriving show, eq]

    let id (c : t) : string = c.id
    let application_id (c : t) : string = c.application_id
    let name (c : t) : string = c.name
    let description (c : t) : string = c.description
    let type_ (c : t) : command_type = c.type_
    let options (c : t) : Command_option.t list = c.options
    let guild_id (c : t) : string option = c.guild_id

    let default_member_permissions (c : t) : Permission.t option =
      c.default_member_permissions

    let dm_permission (c : t) : bool option = c.dm_permission
    let default_permission (c : t) : bool option = c.default_permission
    let nsfw (c : t) : bool option = c.nsfw
    let version (c : t) : string = c.version

    let name_localizations (c : t) : (string * string) list =
      c.name_localizations

    let description_localizations (c : t) : (string * string) list =
      c.description_localizations

    let integration_types (c : t) : int list = c.integration_types
    let contexts (c : t) : int list = c.contexts

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let options =
          match json |> member "options" with
          | `List l ->
              List.map
                (fun o ->
                  match Command_option.of_yojson o with
                  | Ok option -> option
                  | Error msg -> raise (Failure msg))
                l
          | _ -> []
        in
        Ok
          {
            id = json |> member "id" |> to_string;
            application_id = json |> member "application_id" |> to_string;
            name = json |> member "name" |> to_string;
            description =
              json |> member "description" |> to_string_option
              |> Option.value ~default:"";
            type_ =
              command_type_of_int
                (json |> member "type" |> to_int_option
               |> Option.value ~default:1);
            options;
            guild_id = json |> member "guild_id" |> to_string_option;
            default_member_permissions =
              (match json |> member "default_member_permissions" with
              | `Null -> None
              | p -> Some (Permission.of_yojson p));
            dm_permission = json |> member "dm_permission" |> to_bool_option;
            default_permission =
              json |> member "default_permission" |> to_bool_option;
            nsfw = json |> member "nsfw" |> to_bool_option;
            version =
              json |> member "version" |> to_string_option
              |> Option.value ~default:"";
            name_localizations =
              localizations (json |> member "name_localizations");
            description_localizations =
              localizations (json |> member "description_localizations");
            integration_types = int_list (json |> member "integration_types");
            contexts = int_list (json |> member "contexts");
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let command_type_to_int = function
      | Chat_input -> 1
      | User -> 2
      | Message -> 3
      | Unknown value -> value

    let make ~(name : string) ~(description : string) ~(type_ : command_type)
        ?(options = []) ?guild_id ?default_member_permissions ?dm_permission
        ?default_permission ?nsfw ?(name_localizations = [])
        ?(description_localizations = []) ?(integration_types = [])
        ?(contexts = []) () : t =
      {
        id = "";
        application_id = "";
        name;
        description;
        type_;
        options;
        guild_id;
        default_member_permissions;
        dm_permission;
        default_permission;
        nsfw;
        version = "";
        name_localizations;
        description_localizations;
        integration_types;
        contexts;
      }

    let to_yojson (c : t) : Yojson.Safe.t =
      let optional_nonempty key value =
        if value = "" then [] else [ (key, `String value) ]
      in
      `Assoc
        (optional_nonempty "id" c.id
        @ optional_nonempty "application_id" c.application_id
        @ [
            ("name", `String c.name);
            ("description", `String c.description);
            ("type", `Int (command_type_to_int c.type_));
          ]
        @ (if c.options = [] then []
           else
             [
               ("options", `List (List.map Command_option.to_yojson c.options));
             ])
        @ optional_string "guild_id" c.guild_id
        @ (match c.default_member_permissions with
          | None -> []
          | Some permissions ->
              [
                ( "default_member_permissions",
                  `String (Permission.to_string permissions) );
              ])
        @ optional_bool "dm_permission" c.dm_permission
        @ optional_bool "default_permission" c.default_permission
        @ optional_bool "nsfw" c.nsfw
        @ optional_nonempty "version" c.version
        @ (if c.name_localizations = [] then []
           else
             [
               ( "name_localizations",
                 localizations_to_yojson c.name_localizations );
             ])
        @ (if c.description_localizations = [] then []
           else
             [
               ( "description_localizations",
                 localizations_to_yojson c.description_localizations );
             ])
        @ (if c.integration_types = [] then []
           else
             [ ("integration_types", int_list_to_yojson c.integration_types) ])
        @
        if c.contexts = [] then []
        else [ ("contexts", int_list_to_yojson c.contexts) ])

    let commands_path ~(application_id : string) ~(guild_id : string option) :
        string =
      match guild_id with
      | None -> "/applications/" ^ application_id ^ "/commands"
      | Some guild_id ->
          "/applications/" ^ application_id ^ "/guilds/" ^ guild_id
          ^ "/commands"

    let registration_payload ?(include_type = true) (c : t) : Yojson.Safe.t =
      `Assoc
        ([ ("name", `String c.name); ("description", `String c.description) ]
        @ (if include_type then [ ("type", `Int (command_type_to_int c.type_)) ]
           else [])
        @ (if c.options = [] then []
           else
             [
               ("options", `List (List.map Command_option.to_yojson c.options));
             ])
        @ (match c.default_member_permissions with
          | None -> []
          | Some permissions ->
              [
                ( "default_member_permissions",
                  `String (Permission.to_string permissions) );
              ])
        @ optional_bool "dm_permission" c.dm_permission
        @ optional_bool "default_permission" c.default_permission
        @ optional_bool "nsfw" c.nsfw
        @ (if c.name_localizations = [] then []
           else
             [
               ( "name_localizations",
                 localizations_to_yojson c.name_localizations );
             ])
        @ (if c.description_localizations = [] then []
           else
             [
               ( "description_localizations",
                 localizations_to_yojson c.description_localizations );
             ])
        @ (if c.integration_types = [] then []
           else
             [ ("integration_types", int_list_to_yojson c.integration_types) ])
        @
        if c.contexts = [] then []
        else [ ("contexts", int_list_to_yojson c.contexts) ])

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok command -> command
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok command -> command
          | Error msg -> failwith (path ^ ": " ^ msg))

    let list (rest : Rest.t) ~(application_id : string)
        ?(guild_id : string option) () : t list =
      let path = commands_path ~application_id ~guild_id in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let fetch (rest : Rest.t) ~(application_id : string) ~(command_id : string)
        ?(guild_id : string option) () : t =
      let path = commands_path ~application_id ~guild_id ^ "/" ^ command_id in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp

    let create (rest : Rest.t) ~(application_id : string)
        ?(guild_id : string option) (command : t) : t =
      let path = commands_path ~application_id ~guild_id in
      let body = registration_payload command |> Yojson.Safe.to_string in
      let code, resp = Rest.request rest ~body Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let edit (rest : Rest.t) ~(application_id : string) ~(command_id : string)
        ?(guild_id : string option) (command : t) : t =
      let path = commands_path ~application_id ~guild_id ^ "/" ^ command_id in
      let body =
        registration_payload ~include_type:false command
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Patch path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete (rest : Rest.t) ~(application_id : string) ~(command_id : string)
        ?(guild_id : string option) () : unit =
      let path = commands_path ~application_id ~guild_id ^ "/" ^ command_id in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let bulk_overwrite (rest : Rest.t) ~(application_id : string)
        ?(guild_id : string option) (commands : t list) : t list =
      let path = commands_path ~application_id ~guild_id in
      let body =
        `List (List.map registration_payload commands) |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Put path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PUT %s: HTTP %d: %s" path code resp);
      decode_list path resp
  end :
    Application_command)
