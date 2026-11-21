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
  val list : Rest.t -> guild_id:string -> t list

  val create :
    Rest.t ->
    guild_id:string ->
    name:string ->
    image:string ->
    ?roles:string list ->
    unit ->
    t

  val edit :
    Rest.t ->
    guild_id:string ->
    emoji_id:string ->
    ?name:string ->
    ?roles:string list ->
    unit ->
    t

  val delete : Rest.t -> guild_id:string -> emoji_id:string -> unit
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

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok emoji -> emoji
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok emoji -> emoji
          | Error msg -> failwith (path ^ ": " ^ msg))

    let opt (name : string) (value : 'a option) (f : 'a -> Yojson.Safe.t) =
      Option.map (fun v -> (name, f v)) value

    let strings (values : string list) : Yojson.Safe.t =
      `List (List.map (fun value -> `String value) values)

    let list (rest : Rest.t) ~(guild_id : string) : t list =
      let path = "/guilds/" ^ guild_id ^ "/emojis" in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let create (rest : Rest.t) ~(guild_id : string) ~(name : string)
        ~(image : string) ?roles () : t =
      let path = "/guilds/" ^ guild_id ^ "/emojis" in
      let body =
        `Assoc
          (("name", `String name)
          :: ("image", `String image)
          :: List.filter_map
               (fun x -> x)
               [ opt "roles" roles (fun v -> strings v) ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let edit (rest : Rest.t) ~(guild_id : string) ~(emoji_id : string) ?name
        ?roles () : t =
      let path = "/guilds/" ^ guild_id ^ "/emojis/" ^ emoji_id in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "name" name (fun v -> `String v);
               opt "roles" roles (fun v -> strings v);
             ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Patch path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete (rest : Rest.t) ~(guild_id : string) ~(emoji_id : string) : unit
        =
      let path = "/guilds/" ^ guild_id ^ "/emojis/" ^ emoji_id in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)
  end :
    Emoji)
