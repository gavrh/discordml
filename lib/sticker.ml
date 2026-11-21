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
  val list : Rest.t -> guild_id:string -> t list

  val create :
    Rest.t ->
    guild_id:string ->
    name:string ->
    tags:string ->
    file:Attachment.t ->
    ?description:string ->
    unit ->
    t

  val edit :
    Rest.t ->
    guild_id:string ->
    sticker_id:string ->
    ?name:string ->
    ?description:string ->
    ?tags:string ->
    unit ->
    t

  val delete : Rest.t -> guild_id:string -> sticker_id:string -> unit
  val fetch : Rest.t -> string -> t
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

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok sticker -> sticker
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok sticker -> sticker
          | Error msg -> failwith (path ^ ": " ^ msg))

    let opt (name : string) (value : 'a option) (f : 'a -> Yojson.Safe.t) =
      Option.map (fun v -> (name, f v)) value

    let list (rest : Rest.t) ~(guild_id : string) : t list =
      let path = "/guilds/" ^ guild_id ^ "/stickers" in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let create (rest : Rest.t) ~(guild_id : string) ~(name : string)
        ~(tags : string) ~(file : Attachment.t) ?description () : t =
      let path = "/guilds/" ^ guild_id ^ "/stickers" in
      let body =
        `Assoc
          (("name", `String name)
          :: ("tags", `String tags)
          :: List.filter_map
               (fun x -> x)
               [ opt "description" description (fun v -> `String v) ])
        |> Yojson.Safe.to_string
      in
      let files =
        [
          ( Attachment.name file,
            Attachment.content file,
            Attachment.content_type file );
        ]
      in
      let code, resp =
        Rest.request rest ~body ~files ~file_field:"file" Rest.Post path
      in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let edit (rest : Rest.t) ~(guild_id : string) ~(sticker_id : string) ?name
        ?description ?tags () : t =
      let path = "/guilds/" ^ guild_id ^ "/stickers/" ^ sticker_id in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "name" name (fun v -> `String v);
               opt "description" description (fun v -> `String v);
               opt "tags" tags (fun v -> `String v);
             ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Patch path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete (rest : Rest.t) ~(guild_id : string) ~(sticker_id : string) :
        unit =
      let path = "/guilds/" ^ guild_id ^ "/stickers/" ^ sticker_id in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let fetch (rest : Rest.t) (id : string) : t =
      let path = "/stickers/" ^ id in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp
  end :
    Sticker)
