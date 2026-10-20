module type Role_subscription_data = sig
  type t = {
    role_subscription_listing_id : string;
    tier_name : string;
    total_months_subscribed : int;
    is_renewal : bool;
  }

  val role_subscription_listing_id : t -> string
  val tier_name : t -> string
  val total_months_subscribed : t -> int
  val is_renewal : t -> bool
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      role_subscription_listing_id : string;
      tier_name : string;
      total_months_subscribed : int;
      is_renewal : bool;
    }
    [@@deriving show, eq]

    let role_subscription_listing_id (t : t) : string =
      t.role_subscription_listing_id

    let tier_name (t : t) : string = t.tier_name
    let total_months_subscribed (t : t) : int = t.total_months_subscribed
    let is_renewal (t : t) : bool = t.is_renewal

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            role_subscription_listing_id =
              json |> member "role_subscription_listing_id" |> to_string;
            tier_name = json |> member "tier_name" |> to_string;
            total_months_subscribed =
              json
              |> member "total_months_subscribed"
              |> to_int_option |> Option.value ~default:0;
            is_renewal =
              json |> member "is_renewal" |> to_bool_option
              |> Option.value ~default:false;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Role_subscription_data)
