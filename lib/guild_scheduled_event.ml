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
end

include (struct

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
    } [@@deriving show, eq]

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
                | c ->
                    (match User.of_yojson c with
                     | Ok user -> Some user
                     | Error msg -> raise (Failure msg))
            in
            Ok
                { id = json |> member "id" |> to_string;
                  guild_id = json |> member "guild_id" |> to_string;
                  channel_id = json |> member "channel_id" |> to_string_option;
                  creator_id = json |> member "creator_id" |> to_string_option;
                  name = json |> member "name" |> to_string;
                  description = json |> member "description" |> to_string_option;
                  scheduled_start_time =
                    json |> member "scheduled_start_time" |> to_string_option
                    |> Option.value ~default:"";
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
                  image = json |> member "image" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Guild_scheduled_event)
