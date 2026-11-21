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

  val list :
    Rest.t ->
    application_id:string ->
    ?user_id:string ->
    ?sku_ids:string list ->
    ?before:string ->
    ?after:string ->
    ?limit:int ->
    ?guild_id:string ->
    ?exclude_ended:bool ->
    ?exclude_deleted:bool ->
    unit ->
    t list

  val fetch : Rest.t -> application_id:string -> entitlement_id:string -> t
  val consume : Rest.t -> application_id:string -> entitlement_id:string -> unit

  val create_test :
    Rest.t ->
    application_id:string ->
    sku_id:string ->
    owner_id:string ->
    owner_type:int ->
    unit ->
    t

  val delete_test :
    Rest.t -> application_id:string -> entitlement_id:string -> unit
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

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok entitlement -> entitlement
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok entitlement -> entitlement
          | Error msg -> failwith (path ^ ": " ^ msg))

    let list (rest : Rest.t) ~(application_id : string) ?user_id ?sku_ids
        ?before ?after ?limit ?guild_id ?exclude_ended ?exclude_deleted () :
        t list =
      let params =
        (match user_id with Some v -> [ ("user_id", v) ] | None -> [])
        @ (match sku_ids with
          | Some values -> [ ("sku_ids", String.concat "," values) ]
          | None -> [])
        @ (match before with Some v -> [ ("before", v) ] | None -> [])
        @ (match after with Some v -> [ ("after", v) ] | None -> [])
        @ (match limit with
          | Some v -> [ ("limit", string_of_int v) ]
          | None -> [])
        @ (match guild_id with Some v -> [ ("guild_id", v) ] | None -> [])
        @ (match exclude_ended with
          | Some v -> [ ("exclude_ended", P_query.bool v) ]
          | None -> [])
        @
        match exclude_deleted with
        | Some v -> [ ("exclude_deleted", P_query.bool v) ]
        | None -> []
      in
      let path =
        P_query.path
          ("/applications/" ^ application_id ^ "/entitlements")
          params
      in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let fetch (rest : Rest.t) ~(application_id : string)
        ~(entitlement_id : string) : t =
      let path =
        "/applications/" ^ application_id ^ "/entitlements/" ^ entitlement_id
      in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp

    let consume (rest : Rest.t) ~(application_id : string)
        ~(entitlement_id : string) : unit =
      let path =
        "/applications/" ^ application_id ^ "/entitlements/" ^ entitlement_id
        ^ "/consume"
      in
      let code, resp = Rest.request rest Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let create_test (rest : Rest.t) ~(application_id : string)
        ~(sku_id : string) ~(owner_id : string) ~(owner_type : int) () : t =
      let path = "/applications/" ^ application_id ^ "/entitlements" in
      let body =
        `Assoc
          [
            ("sku_id", `String sku_id);
            ("owner_id", `String owner_id);
            ("owner_type", `Int owner_type);
          ]
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete_test (rest : Rest.t) ~(application_id : string)
        ~(entitlement_id : string) : unit =
      let path =
        "/applications/" ^ application_id ^ "/entitlements/" ^ entitlement_id
      in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)
  end :
    Entitlement)
