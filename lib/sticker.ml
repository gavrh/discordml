module type Sticker = sig
  type t

  val id : t -> string
  val name : t -> string
  val description : t -> string option
  val tags : t -> string option
  val type_ : t -> int
  val format_type : t -> int
  val available : t -> bool
  val guild_id : t -> string option
  val sort_value : t -> int option
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
end

include (
  struct
    type t = {
      id : string;
      name : string;
      description : string option;
      tags : string option;
      type_ : int;
      format_type : int;
      available : bool;
      guild_id : string option;
      sort_value : int option;
    }
    [@@deriving show, eq]

    let id (s : t) : string = s.id
    let name (s : t) : string = s.name
    let description (s : t) : string option = s.description
    let tags (s : t) : string option = s.tags
    let type_ (s : t) : int = s.type_
    let format_type (s : t) : int = s.format_type
    let available (s : t) : bool = s.available
    let guild_id (s : t) : string option = s.guild_id
    let sort_value (s : t) : int option = s.sort_value

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string;
            name = json |> member "name" |> to_string;
            description = json |> member "description" |> to_string_option;
            tags = json |> member "tags" |> to_string_option;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            format_type =
              json |> member "format_type" |> to_int_option
              |> Option.value ~default:0;
            available =
              json |> member "available" |> to_bool_option
              |> Option.value ~default:false;
            guild_id = json |> member "guild_id" |> to_string_option;
            sort_value = json |> member "sort_value" |> to_int_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Sticker)
