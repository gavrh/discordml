module type Guild_scheduled_event = sig
  type entity_metadata = { location : string option }

  type t = {
    id : string;
    guild_id : string;
    channel_id : string option;
    creator_id : string option;
    name : string;
    description : string option;
    scheduled_start_time : string;
    scheduled_end_time : string option;
    privacy_level : int;
    status : int;
    entity_type : int;
    entity_id : string option;
    entity_metadata : entity_metadata option;
    creator : User.t option;
    user_count : int option;
    image : string option;
  }

  val id : t -> string
  val guild_id : t -> string
  val channel_id : t -> string option
  val creator_id : t -> string option
  val name : t -> string
  val description : t -> string option
  val scheduled_start_time : t -> string
  val scheduled_end_time : t -> string option
  val privacy_level : t -> int
  val status : t -> int
  val entity_type : t -> int
  val entity_id : t -> string option
  val entity_metadata : t -> entity_metadata option
  val creator : t -> User.t option
  val user_count : t -> int option
  val image : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result

  val create :
    Rest.t ->
    guild_id:string ->
    name:string ->
    scheduled_start_time:string ->
    entity_type:int ->
    ?privacy_level:int ->
    ?channel_id:string ->
    ?description:string ->
    ?scheduled_end_time:string ->
    ?location:string ->
    ?image:string ->
    unit ->
    t

  val fetch :
    Rest.t ->
    guild_id:string ->
    event_id:string ->
    ?with_user_count:bool ->
    unit ->
    t

  val list :
    Rest.t -> guild_id:string -> ?with_user_count:bool -> unit -> t list

  val edit :
    Rest.t ->
    guild_id:string ->
    event_id:string ->
    ?name:string ->
    ?description:string ->
    ?scheduled_start_time:string ->
    ?scheduled_end_time:string ->
    ?privacy_level:int ->
    ?status:int ->
    ?entity_type:int ->
    ?channel_id:string ->
    ?location:string ->
    ?image:string ->
    unit ->
    t

  val delete : Rest.t -> guild_id:string -> event_id:string -> unit

  val list_interested_users :
    Rest.t ->
    guild_id:string ->
    event_id:string ->
    ?with_member:bool ->
    ?before:string ->
    ?after:string ->
    ?limit:int ->
    unit ->
    User.t list
end

include (
  struct
    type entity_metadata = { location : string option } [@@deriving show, eq]

    type t = {
      id : string;
      guild_id : string;
      channel_id : string option;
      creator_id : string option;
      name : string;
      description : string option;
      scheduled_start_time : string;
      scheduled_end_time : string option;
      privacy_level : int;
      status : int;
      entity_type : int;
      entity_id : string option;
      entity_metadata : entity_metadata option;
      creator : User.t option;
      user_count : int option;
      image : string option;
    }
    [@@deriving show, eq]

    let id (e : t) : string = e.id
    let guild_id (e : t) : string = e.guild_id
    let channel_id (e : t) : string option = e.channel_id
    let creator_id (e : t) : string option = e.creator_id
    let name (e : t) : string = e.name
    let description (e : t) : string option = e.description
    let scheduled_start_time (e : t) : string = e.scheduled_start_time
    let scheduled_end_time (e : t) : string option = e.scheduled_end_time
    let privacy_level (e : t) : int = e.privacy_level
    let status (e : t) : int = e.status
    let entity_type (e : t) : int = e.entity_type
    let entity_id (e : t) : string option = e.entity_id
    let entity_metadata (e : t) : entity_metadata option = e.entity_metadata
    let creator (e : t) : User.t option = e.creator
    let user_count (e : t) : int option = e.user_count
    let image (e : t) : string option = e.image

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let entity_metadata =
          match json |> member "entity_metadata" with
          | `Null -> None
          | m -> Some { location = m |> member "location" |> to_string_option }
        in
        let creator =
          match json |> member "creator" with
          | `Null -> None
          | c -> (
              match User.of_yojson c with
              | Ok user -> Some user
              | Error msg -> raise (Failure msg))
        in
        Ok
          {
            id = json |> member "id" |> to_string;
            guild_id = json |> member "guild_id" |> to_string;
            channel_id = json |> member "channel_id" |> to_string_option;
            creator_id = json |> member "creator_id" |> to_string_option;
            name = json |> member "name" |> to_string;
            description = json |> member "description" |> to_string_option;
            scheduled_start_time =
              json
              |> member "scheduled_start_time"
              |> to_string_option |> Option.value ~default:"";
            scheduled_end_time =
              json |> member "scheduled_end_time" |> to_string_option;
            privacy_level =
              json |> member "privacy_level" |> to_int_option
              |> Option.value ~default:0;
            status =
              json |> member "status" |> to_int_option
              |> Option.value ~default:0;
            entity_type =
              json |> member "entity_type" |> to_int_option
              |> Option.value ~default:0;
            entity_id = json |> member "entity_id" |> to_string_option;
            entity_metadata;
            creator;
            user_count = json |> member "user_count" |> to_int_option;
            image = json |> member "image" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok event -> event
      | Error msg -> failwith (path ^ ": " ^ msg)

    let decode_list (path : string) (resp : string) : t list =
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          match of_yojson json with
          | Ok event -> event
          | Error msg -> failwith (path ^ ": " ^ msg))

    let opt (name : string) (value : 'a option) (f : 'a -> Yojson.Safe.t) =
      Option.map (fun v -> (name, f v)) value

    let entity_metadata_json (location : string option) : Yojson.Safe.t option =
      Option.map (fun value -> `Assoc [ ("location", `String value) ]) location

    let create (rest : Rest.t) ~(guild_id : string) ~(name : string)
        ~(scheduled_start_time : string) ~(entity_type : int)
        ?(privacy_level = 2) ?channel_id ?description ?scheduled_end_time
        ?location ?image () : t =
      let path = "/guilds/" ^ guild_id ^ "/scheduled-events" in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "channel_id" channel_id (fun v -> `String v);
               opt "entity_metadata" (entity_metadata_json location) (fun v ->
                   v);
               Some ("name", `String name);
               Some ("privacy_level", `Int privacy_level);
               Some ("scheduled_start_time", `String scheduled_start_time);
               opt "scheduled_end_time" scheduled_end_time (fun v -> `String v);
               opt "description" description (fun v -> `String v);
               Some ("entity_type", `Int entity_type);
               opt "image" image (fun v -> `String v);
             ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Post path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let fetch (rest : Rest.t) ~(guild_id : string) ~(event_id : string)
        ?with_user_count () : t =
      let params =
        match with_user_count with
        | Some v -> [ ("with_user_count", P_query.bool v) ]
        | None -> []
      in
      let path =
        P_query.path
          ("/guilds/" ^ guild_id ^ "/scheduled-events/" ^ event_id)
          params
      in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode path resp

    let list (rest : Rest.t) ~(guild_id : string) ?with_user_count () : t list =
      let params =
        match with_user_count with
        | Some v -> [ ("with_user_count", P_query.bool v) ]
        | None -> []
      in
      let path =
        P_query.path ("/guilds/" ^ guild_id ^ "/scheduled-events") params
      in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      decode_list path resp

    let edit (rest : Rest.t) ~(guild_id : string) ~(event_id : string) ?name
        ?description ?scheduled_start_time ?scheduled_end_time ?privacy_level
        ?status ?entity_type ?channel_id ?location ?image () : t =
      let path = "/guilds/" ^ guild_id ^ "/scheduled-events/" ^ event_id in
      let body =
        `Assoc
          (List.filter_map
             (fun x -> x)
             [
               opt "name" name (fun v -> `String v);
               opt "description" description (fun v -> `String v);
               opt "scheduled_start_time" scheduled_start_time (fun v ->
                   `String v);
               opt "scheduled_end_time" scheduled_end_time (fun v -> `String v);
               opt "privacy_level" privacy_level (fun v -> `Int v);
               opt "status" status (fun v -> `Int v);
               opt "entity_type" entity_type (fun v -> `Int v);
               opt "channel_id" channel_id (fun v -> `String v);
               opt "entity_metadata" (entity_metadata_json location) (fun v ->
                   v);
               opt "image" image (fun v -> `String v);
             ])
        |> Yojson.Safe.to_string
      in
      let code, resp = Rest.request rest ~body Rest.Patch path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp);
      decode path resp

    let delete (rest : Rest.t) ~(guild_id : string) ~(event_id : string) : unit
        =
      let path = "/guilds/" ^ guild_id ^ "/scheduled-events/" ^ event_id in
      let code, resp = Rest.request rest Rest.Delete path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let list_interested_users (rest : Rest.t) ~(guild_id : string)
        ~(event_id : string) ?with_member ?before ?after ?limit () : User.t list
        =
      let params =
        (match with_member with
          | Some v -> [ ("with_member", P_query.bool v) ]
          | None -> [])
        @ (match before with Some v -> [ ("before", v) ] | None -> [])
        @ (match after with Some v -> [ ("after", v) ] | None -> [])
        @
        match limit with
        | Some v -> [ ("limit", string_of_int v) ]
        | None -> []
      in
      let path =
        P_query.path
          ("/guilds/" ^ guild_id ^ "/scheduled-events/" ^ event_id ^ "/users")
          params
      in
      let code, resp = Rest.request rest Rest.Get path in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
      Yojson.Safe.from_string resp
      |> Yojson.Safe.Util.to_list
      |> List.map (fun json ->
          let user = Yojson.Safe.Util.member "user" json in
          match User.of_yojson user with
          | Ok user -> user
          | Error msg -> failwith (path ^ ": " ^ msg))
  end :
    Guild_scheduled_event)
