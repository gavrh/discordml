module type Component = sig
  type button_style =
    | Primary
    | Secondary
    | Success
    | Danger
    | Link
    | Premium
    | Unknown of int

  type text_input_style = Short | Paragraph | Unknown of int
  type default_value_type = User | Role | Channel | Unknown of string

  module Select_option : sig
    type t = {
      label : string;
      value : string;
      description : string option;
      emoji : Emoji.t option;
      default : bool;
    }

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Default_value : sig
    type t = { id : string; type_ : default_value_type }

    val id : t -> string
    val type_ : t -> default_value_type
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Button : sig
    type t = {
      style : button_style;
      label : string option;
      emoji : Emoji.t option;
      custom_id : string option;
      url : string option;
      disabled : bool;
      sku_id : string option;
    }

    val style : t -> button_style
    val label : t -> string option
    val emoji : t -> Emoji.t option
    val custom_id : t -> string option
    val url : t -> string option
    val disabled : t -> bool
    val sku_id : t -> string option
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Select : sig
    type t = {
      custom_id : string;
      options : Select_option.t list;
      placeholder : string option;
      min_values : int;
      max_values : int;
      disabled : bool;
      required : bool option;
      channel_types : int list;
      default_values : Default_value.t list;
    }

    val custom_id : t -> string
    val options : t -> Select_option.t list
    val placeholder : t -> string option
    val min_values : t -> int
    val max_values : t -> int
    val disabled : t -> bool
    val required : t -> bool option
    val channel_types : t -> int list
    val default_values : t -> Default_value.t list
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  module Text_input : sig
    type t = {
      custom_id : string;
      style : text_input_style;
      label : string;
      min_length : int option;
      max_length : int option;
      required : bool option;
      value : string option;
      placeholder : string option;
    }

    val custom_id : t -> string
    val style : t -> text_input_style
    val label : t -> string
    val min_length : t -> int option
    val max_length : t -> int option
    val required : t -> bool option
    val value : t -> string option
    val placeholder : t -> string option
    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val of_yojson : Yojson.Safe.t -> (t, string) result
  end

  type t =
    | Action_row of t list
    | Button of Button.t
    | String_select of Select.t
    | User_select of Select.t
    | Role_select of Select.t
    | Mentionable_select of Select.t
    | Channel_select of Select.t
    | Text_input of Text_input.t
    | Unknown of int

  val type_of : t -> int
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type button_style =
      | Primary
      | Secondary
      | Success
      | Danger
      | Link
      | Premium
      | Unknown of int
    [@@deriving show, eq]

    let button_style_of_int = function
      | 1 -> Primary
      | 2 -> Secondary
      | 3 -> Success
      | 4 -> Danger
      | 5 -> Link
      | 6 -> Premium
      | n -> Unknown n

    type text_input_style = Short | Paragraph | Unknown of int
    [@@deriving show, eq]

    let text_input_style_of_int = function
      | 1 -> Short
      | 2 -> Paragraph
      | n -> Unknown n

    type default_value_type = User | Role | Channel | Unknown of string
    [@@deriving show, eq]

    let default_value_type_of_string = function
      | "user" -> User
      | "role" -> Role
      | "channel" -> Channel
      | s -> Unknown s

    module Select_option = struct
      type t = {
        label : string;
        value : string;
        description : string option;
        emoji : Emoji.t option;
        default : bool;
      }
      [@@deriving show, eq]

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let emoji =
            match json |> member "emoji" with
            | `Null -> None
            | e -> (
                match Emoji.of_yojson e with
                | Ok emoji -> Some emoji
                | Error msg -> raise (Failure msg))
          in
          Ok
            {
              label = json |> member "label" |> to_string;
              value = json |> member "value" |> to_string;
              description = json |> member "description" |> to_string_option;
              emoji;
              default =
                json |> member "default" |> to_bool_option
                |> Option.value ~default:false;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Default_value = struct
      type t = { id : string; type_ : default_value_type } [@@deriving show, eq]

      let id (t : t) : string = t.id
      let type_ (t : t) : default_value_type = t.type_

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          Ok
            {
              id = json |> member "id" |> to_string;
              type_ =
                default_value_type_of_string (json |> member "type" |> to_string);
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
    end

    module Button = struct
      type t = {
        style : button_style;
        label : string option;
        emoji : Emoji.t option;
        custom_id : string option;
        url : string option;
        disabled : bool;
        sku_id : string option;
      }
      [@@deriving show, eq]

      let style (t : t) : button_style = t.style
      let label (t : t) : string option = t.label
      let emoji (t : t) : Emoji.t option = t.emoji
      let custom_id (t : t) : string option = t.custom_id
      let url (t : t) : string option = t.url
      let disabled (t : t) : bool = t.disabled
      let sku_id (t : t) : string option = t.sku_id

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let emoji =
            match json |> member "emoji" with
            | `Null -> None
            | e -> (
                match Emoji.of_yojson e with
                | Ok emoji -> Some emoji
                | Error msg -> raise (Failure msg))
          in
          Ok
            {
              style =
                button_style_of_int
                  (json |> member "style" |> to_int_option
                 |> Option.value ~default:0);
              label = json |> member "label" |> to_string_option;
              emoji;
              custom_id = json |> member "custom_id" |> to_string_option;
              url = json |> member "url" |> to_string_option;
              disabled =
                json |> member "disabled" |> to_bool_option
                |> Option.value ~default:false;
              sku_id = json |> member "sku_id" |> to_string_option;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Select = struct
      type t = {
        custom_id : string;
        options : Select_option.t list;
        placeholder : string option;
        min_values : int;
        max_values : int;
        disabled : bool;
        required : bool option;
        channel_types : int list;
        default_values : Default_value.t list;
      }
      [@@deriving show, eq]

      let custom_id (t : t) : string = t.custom_id
      let options (t : t) : Select_option.t list = t.options
      let placeholder (t : t) : string option = t.placeholder
      let min_values (t : t) : int = t.min_values
      let max_values (t : t) : int = t.max_values
      let disabled (t : t) : bool = t.disabled
      let required (t : t) : bool option = t.required
      let channel_types (t : t) : int list = t.channel_types
      let default_values (t : t) : Default_value.t list = t.default_values

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          let options =
            match json |> member "options" with
            | `List l ->
                List.map
                  (fun o ->
                    match Select_option.of_yojson o with
                    | Ok option -> option
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          let default_values =
            match json |> member "default_values" with
            | `List l ->
                List.map
                  (fun v ->
                    match Default_value.of_yojson v with
                    | Ok value -> value
                    | Error msg -> raise (Failure msg))
                  l
            | _ -> []
          in
          let channel_types =
            match json |> member "channel_types" with
            | `List l ->
                List.filter_map (function `Int n -> Some n | _ -> None) l
            | _ -> []
          in
          Ok
            {
              custom_id = json |> member "custom_id" |> to_string;
              options;
              placeholder = json |> member "placeholder" |> to_string_option;
              min_values =
                json |> member "min_values" |> to_int_option
                |> Option.value ~default:1;
              max_values =
                json |> member "max_values" |> to_int_option
                |> Option.value ~default:1;
              disabled =
                json |> member "disabled" |> to_bool_option
                |> Option.value ~default:false;
              required = json |> member "required" |> to_bool_option;
              channel_types;
              default_values;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg
    end

    module Text_input = struct
      type t = {
        custom_id : string;
        style : text_input_style;
        label : string;
        min_length : int option;
        max_length : int option;
        required : bool option;
        value : string option;
        placeholder : string option;
      }
      [@@deriving show, eq]

      let custom_id (t : t) : string = t.custom_id
      let style (t : t) : text_input_style = t.style
      let label (t : t) : string = t.label
      let min_length (t : t) : int option = t.min_length
      let max_length (t : t) : int option = t.max_length
      let required (t : t) : bool option = t.required
      let value (t : t) : string option = t.value
      let placeholder (t : t) : string option = t.placeholder

      let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
          Ok
            {
              custom_id = json |> member "custom_id" |> to_string;
              style =
                text_input_style_of_int
                  (json |> member "style" |> to_int_option
                 |> Option.value ~default:0);
              label = json |> member "label" |> to_string;
              min_length = json |> member "min_length" |> to_int_option;
              max_length = json |> member "max_length" |> to_int_option;
              required = json |> member "required" |> to_bool_option;
              value = json |> member "value" |> to_string_option;
              placeholder = json |> member "placeholder" |> to_string_option;
            }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
    end

    type t =
      | Action_row of t list
      | Button of Button.t
      | String_select of Select.t
      | User_select of Select.t
      | Role_select of Select.t
      | Mentionable_select of Select.t
      | Channel_select of Select.t
      | Text_input of Text_input.t
      | Unknown of int
    [@@deriving show, eq]

    let type_of = function
      | Action_row _ -> 1
      | Button _ -> 2
      | String_select _ -> 3
      | Text_input _ -> 4
      | User_select _ -> 5
      | Role_select _ -> 6
      | Mentionable_select _ -> 7
      | Channel_select _ -> 8
      | Unknown n -> n

    let rec of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let type_ =
          json |> member "type" |> to_int_option |> Option.value ~default:0
        in
        match type_ with
        | 1 ->
            let components =
              match json |> member "components" with
              | `List l ->
                  List.map
                    (fun c ->
                      match of_yojson c with
                      | Ok component -> component
                      | Error msg -> raise (Failure msg))
                    l
              | _ -> []
            in
            Ok (Action_row components)
        | 2 -> (
            match Button.of_yojson json with
            | Ok button -> Ok (Button button)
            | Error msg -> Error msg)
        | 3 -> (
            match Select.of_yojson json with
            | Ok select -> Ok (String_select select)
            | Error msg -> Error msg)
        | 4 -> (
            match Text_input.of_yojson json with
            | Ok input -> Ok (Text_input input)
            | Error msg -> Error msg)
        | 5 -> (
            match Select.of_yojson json with
            | Ok select -> Ok (User_select select)
            | Error msg -> Error msg)
        | 6 -> (
            match Select.of_yojson json with
            | Ok select -> Ok (Role_select select)
            | Error msg -> Error msg)
        | 7 -> (
            match Select.of_yojson json with
            | Ok select -> Ok (Mentionable_select select)
            | Error msg -> Error msg)
        | 8 -> (
            match Select.of_yojson json with
            | Ok select -> Ok (Channel_select select)
            | Error msg -> Error msg)
        | n -> Ok (Unknown n)
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Component)
