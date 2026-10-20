module type Emoji = sig
  type t

  val id : t -> string option
  val name : t -> string option
  val identifier : t -> string
  val roles : t -> string list
  val require_colons : t -> bool
  val managed : t -> bool
  val animated : t -> bool
  val available : t -> bool
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
end

include (
  struct
    type t = {
      id : string option;
      name : string option;
      roles : string list;
      require_colons : bool;
      managed : bool;
      animated : bool;
      available : bool;
    }
    [@@deriving show, eq]

    let id (e : t) : string option = e.id
    let name (e : t) : string option = e.name

    let identifier (e : t) : string =
      match (e.id, e.name) with
      | Some id, Some name -> name ^ ":" ^ id
      | Some id, None -> id
      | None, Some name -> name
      | None, None -> ""

    let roles (e : t) : string list = e.roles
    let require_colons (e : t) : bool = e.require_colons
    let managed (e : t) : bool = e.managed
    let animated (e : t) : bool = e.animated
    let available (e : t) : bool = e.available

    let string_list (json : Yojson.Safe.t) : string list =
      match json with
      | `List l ->
          List.filter_map (function `String s -> Some s | _ -> None) l
      | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string_option;
            name = json |> member "name" |> to_string_option;
            roles = string_list (json |> member "roles");
            require_colons =
              json |> member "require_colons" |> to_bool_option
              |> Option.value ~default:false;
            managed =
              json |> member "managed" |> to_bool_option
              |> Option.value ~default:false;
            animated =
              json |> member "animated" |> to_bool_option
              |> Option.value ~default:false;
            available =
              json |> member "available" |> to_bool_option
              |> Option.value ~default:false;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Emoji)
