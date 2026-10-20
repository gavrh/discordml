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
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Command_option : sig
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
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
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
  end :
    Application_command)
