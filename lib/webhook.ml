module type Webhook = sig
  type webhook_guild = { id : string; name : string; icon : string option }

  type t = {
    id : string;
    type_ : int;
    guild_id : string option;
    channel_id : string option;
    user : User.t option;
    name : string option;
    avatar : string option;
    token : string option;
        [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    application_id : string option;
    source_guild : webhook_guild option;
    source_channel : Channel.t option;
    url : string option;
  }

  val id : t -> string
  val type_ : t -> int
  val guild_id : t -> string option
  val channel_id : t -> string option
  val user : t -> User.t option
  val name : t -> string option
  val avatar : t -> string option
  val token : t -> string option
  val application_id : t -> string option
  val source_guild : t -> webhook_guild option
  val source_channel : t -> Channel.t option
  val url : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result

  val create :
    Rest.t -> channel_id:string -> name:string -> ?avatar:string -> unit -> t

  val fetch : Rest.t -> string -> t
  val list : Rest.t -> channel_id:string -> t list

  val edit :
    Rest.t ->
    t ->
    ?name:string ->
    ?avatar:string ->
    ?channel_id:string ->
    unit ->
    t

  val delete : Rest.t -> t -> unit

  val execute :
    Rest.t ->
    t ->
    ?content:string ->
    ?username:string ->
    ?avatar_url:string ->
    ?tts:bool ->
    ?embeds:Yojson.Safe.t list ->
    ?components:Yojson.Safe.t list ->
    ?files:Attachment.t list ->
    ?thread_id:string ->
    ?wait:bool ->
    unit ->
    Message.t option
end

include (
  struct
    type webhook_guild = { id : string; name : string; icon : string option }
    [@@deriving show, eq]

    type t = {
      id : string;
      type_ : int;
      guild_id : string option;
      channel_id : string option;
      user : User.t option;
      name : string option;
      avatar : string option;
      token : string option;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
      application_id : string option;
      source_guild : webhook_guild option;
      source_channel : Channel.t option;
      url : string option;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    }
    [@@deriving show, eq]

    let id (w : t) : string = w.id
    let type_ (w : t) : int = w.type_
    let guild_id (w : t) : string option = w.guild_id
    let channel_id (w : t) : string option = w.channel_id
    let user (w : t) : User.t option = w.user
    let name (w : t) : string option = w.name
    let avatar (w : t) : string option = w.avatar
    let token (w : t) : string option = w.token
    let application_id (w : t) : string option = w.application_id
    let source_guild (w : t) : webhook_guild option = w.source_guild
    let source_channel (w : t) : Channel.t option = w.source_channel
    let url (w : t) : string option = w.url

    let parse_opt (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> (
          match f v with Ok x -> Some x | Error msg -> raise (Failure msg))

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let source_guild =
          match json |> member "source_guild" with
          | `Null -> None
          | g ->
              Some
                {
                  id = g |> member "id" |> to_string;
                  name = g |> member "name" |> to_string;
                  icon = g |> member "icon" |> to_string_option;
                }
        in
        Ok
          {
            id = json |> member "id" |> to_string;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            guild_id = json |> member "guild_id" |> to_string_option;
            channel_id = json |> member "channel_id" |> to_string_option;
            user = parse_opt json "user" User.of_yojson;
            name = json |> member "name" |> to_string_option;
            avatar = json |> member "avatar" |> to_string_option;
            token = json |> member "token" |> to_string_option;
            application_id = json |> member "application_id" |> to_string_option;
            source_guild;
            source_channel = parse_opt json "source_channel" Channel.of_yojson;
            url = json |> member "url" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok w -> w
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok w -> w
          | Error msg -> failwith (path ^ ": " ^ msg))

    let opt (name : string) (value : 'a option) (f : 'a -> Yojson.Safe.t) =
      Option.map (fun v -> (name, f v)) value

    let create (rest : Rest.t) ~(channel_id : string) ~(name : string) ?avatar
        () : t =
      let path = "/channels/" ^ channel_id ^ "/webhooks" in
      let body =
        `Assoc
          (("name", `String name)
          :: List.filter_map
               (fun x -> x)
               [ opt "avatar" avatar (fun v -> `String v) ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let fetch (rest : Rest.t) (id : string) : t =
      let path = "/webhooks/" ^ id in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp

    let list (rest : Rest.t) ~(channel_id : string) : t list =
      let path = "/channels/" ^ channel_id ^ "/webhooks" in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let edit (rest : Rest.t) (w : t) ?name ?avatar ?channel_id () : t =
      let path = "/webhooks/" ^ w.id in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "name" name (fun v -> `String v);
               opt "avatar" avatar (fun v -> `String v);
               opt "channel_id" channel_id (fun v -> `String v);
             ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Patch path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete (rest : Rest.t) (w : t) : unit =
      let path = "/webhooks/" ^ w.id in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let execute (rest : Rest.t) (w : t) ?content ?username ?avatar_url ?tts
        ?embeds ?components ?files ?thread_id ?(wait = false) () :
        Message.t option =
      let token =
        match w.token with
        | Some token -> token
        | None -> failwith ("webhook " ^ w.id ^ " has no token")
      in
      let params =
        (if wait then [ ("wait", "true") ] else [])
        @ (match thread_id with Some id -> [ ("thread_id", id) ] | None -> [])
        @
        match components with
        | Some _ -> [ ("with_components", "true") ]
        | None -> []
      in
      let path = P_query.path ("/webhooks/" ^ w.id ^ "/" ^ token) params in
      let display_path =
        P_query.path ("/webhooks/" ^ w.id ^ "/<redacted>") params
      in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "content" content (fun v -> `String v);
               opt "username" username (fun v -> `String v);
               opt "avatar_url" avatar_url (fun v -> `String v);
               opt "tts" tts (fun v -> `Bool v);
               opt "embeds" embeds (fun v -> `List v);
               opt "components" components (fun v -> `List v);
             ])
        |> Yojson.Safe.to_string
      in
      let files =
        match files with
        | None -> []
        | Some attachments ->
            List.map
              (fun (a : Attachment.t) ->
                ( Attachment.name a,
                  Attachment.content a,
                  Attachment.content_type a ))
              attachments
      in
      let code, resp = Rest.request rest ~body ~files Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" display_path code resp);
      if not wait then None
      else
        Some
          (match Message.of_yojson (Yojson.Safe.from_string resp) with
          | Ok m -> m
          | Error msg -> failwith (display_path ^ ": " ^ msg))
  end :
    Webhook)
