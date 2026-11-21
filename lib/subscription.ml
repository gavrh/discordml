module type Subscription = sig
  type t = {
    id : string;
    user_id : string;
    sku_ids : string list;
    entitlement_ids : string list;
    renewal_sku_ids : string list;
    current_period_start : string;
    current_period_end : string;
    status : int;
    canceled_at : string option;
    created_at : string;
  }

  val id : t -> string
  val user_id : t -> string
  val sku_ids : t -> string list
  val entitlement_ids : t -> string list
  val renewal_sku_ids : t -> string list
  val current_period_start : t -> string
  val current_period_end : t -> string
  val status : t -> int
  val canceled_at : t -> string option
  val created_at : t -> string
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result

  val list :
    Rest.t ->
    sku_id:string ->
    user_id:string ->
    ?before:string ->
    ?after:string ->
    ?limit:int ->
    unit ->
    t list

  val fetch : Rest.t -> sku_id:string -> subscription_id:string -> t
end

include (
  struct
    type t = {
      id : string;
      user_id : string;
      sku_ids : string list;
      entitlement_ids : string list;
      renewal_sku_ids : string list;
      current_period_start : string;
      current_period_end : string;
      status : int;
      canceled_at : string option;
      created_at : string;
    }
    [@@deriving show, eq]

    let id (s : t) : string = s.id
    let user_id (s : t) : string = s.user_id
    let sku_ids (s : t) : string list = s.sku_ids
    let entitlement_ids (s : t) : string list = s.entitlement_ids
    let renewal_sku_ids (s : t) : string list = s.renewal_sku_ids
    let current_period_start (s : t) : string = s.current_period_start
    let current_period_end (s : t) : string = s.current_period_end
    let status (s : t) : int = s.status
    let canceled_at (s : t) : string option = s.canceled_at
    let created_at (s : t) : string = s.created_at

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
            id = json |> member "id" |> to_string;
            user_id = json |> member "user_id" |> to_string;
            sku_ids = string_list (json |> member "sku_ids");
            entitlement_ids = string_list (json |> member "entitlement_ids");
            renewal_sku_ids = string_list (json |> member "renewal_sku_ids");
            current_period_start =
              json |> member "current_period_start" |> to_string;
            current_period_end =
              json |> member "current_period_end" |> to_string;
            status =
              json |> member "status" |> to_int_option
              |> Option.value ~default:0;
            canceled_at = json |> member "canceled_at" |> to_string_option;
            created_at = json |> member "created_at" |> to_string;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok subscription -> subscription
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok subscription -> subscription
          | Error msg -> failwith (path ^ ": " ^ msg))

    let list (rest : Rest.t) ~(sku_id : string) ~(user_id : string) ?before
        ?after ?limit () : t list =
      let params =
        ("user_id", user_id)
        :: ((match before with Some v -> [ ("before", v) ] | None -> [])
           @ (match after with Some v -> [ ("after", v) ] | None -> [])
           @
           match limit with
           | Some v -> [ ("limit", string_of_int v) ]
           | None -> [])
      in
      let path = P_query.path ("/skus/" ^ sku_id ^ "/subscriptions") params in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let fetch (rest : Rest.t) ~(sku_id : string) ~(subscription_id : string) : t
        =
      let path = "/skus/" ^ sku_id ^ "/subscriptions/" ^ subscription_id in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp
  end :
    Subscription)
