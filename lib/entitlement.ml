module type Entitlement = sig
  type t = {
    id : string;
    sku_id : string;
    application_id : string;
    user_id : string option;
    type_ : int;
    deleted : bool;
    starts_at : string option;
    ends_at : string option;
    guild_id : string option;
    consumed : bool option;
  }

  val id : t -> string
  val sku_id : t -> string
  val application_id : t -> string
  val user_id : t -> string option
  val type_ : t -> int
  val deleted : t -> bool
  val starts_at : t -> string option
  val ends_at : t -> string option
  val guild_id : t -> string option
  val consumed : t -> bool option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      id : string;
      sku_id : string;
      application_id : string;
      user_id : string option;
      type_ : int;
      deleted : bool;
      starts_at : string option;
      ends_at : string option;
      guild_id : string option;
      consumed : bool option;
    }
    [@@deriving show, eq]

    let id (e : t) : string = e.id
    let sku_id (e : t) : string = e.sku_id
    let application_id (e : t) : string = e.application_id
    let user_id (e : t) : string option = e.user_id
    let type_ (e : t) : int = e.type_
    let deleted (e : t) : bool = e.deleted
    let starts_at (e : t) : string option = e.starts_at
    let ends_at (e : t) : string option = e.ends_at
    let guild_id (e : t) : string option = e.guild_id
    let consumed (e : t) : bool option = e.consumed

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string;
            sku_id = json |> member "sku_id" |> to_string;
            application_id = json |> member "application_id" |> to_string;
            user_id = json |> member "user_id" |> to_string_option;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            deleted =
              json |> member "deleted" |> to_bool_option
              |> Option.value ~default:false;
            starts_at = json |> member "starts_at" |> to_string_option;
            ends_at = json |> member "ends_at" |> to_string_option;
            guild_id = json |> member "guild_id" |> to_string_option;
            consumed = json |> member "consumed" |> to_bool_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Entitlement)
