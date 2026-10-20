module type Role = sig
  type t

  val id : t -> string
  val name : t -> string
  val color : t -> int
  val hoist : t -> bool
  val position : t -> int
  val permissions : t -> Permission.t
  val managed : t -> bool
  val mentionable : t -> bool
  val icon : t -> string option
  val unicode_emoji : t -> string option
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
      color : int;
      hoist : bool;
      position : int;
      permissions : Permission.t;
      managed : bool;
      mentionable : bool;
      icon : string option;
      unicode_emoji : string option;
    }
    [@@deriving show, eq]

    let id (r : t) : string = r.id
    let name (r : t) : string = r.name
    let color (r : t) : int = r.color
    let hoist (r : t) : bool = r.hoist
    let position (r : t) : int = r.position
    let permissions (r : t) : Permission.t = r.permissions
    let managed (r : t) : bool = r.managed
    let mentionable (r : t) : bool = r.mentionable
    let icon (r : t) : string option = r.icon
    let unicode_emoji (r : t) : string option = r.unicode_emoji

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string;
            name = json |> member "name" |> to_string;
            color =
              json |> member "color" |> to_int_option |> Option.value ~default:0;
            hoist =
              json |> member "hoist" |> to_bool_option
              |> Option.value ~default:false;
            position =
              json |> member "position" |> to_int_option
              |> Option.value ~default:0;
            permissions = Permission.of_yojson (json |> member "permissions");
            managed =
              json |> member "managed" |> to_bool_option
              |> Option.value ~default:false;
            mentionable =
              json |> member "mentionable" |> to_bool_option
              |> Option.value ~default:false;
            icon = json |> member "icon" |> to_string_option;
            unicode_emoji = json |> member "unicode_emoji" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Role)
