module type Guild_template = sig
    type t = {
        code : string;
        name : string;
        description : string option;
        usage_count : int;
        creator_id : string;
        creator : User.t;
        created_at : string;
        updated_at : string;
        source_guild_id : string;
        serialized_source_guild : Guild.t;
        is_dirty : bool option;
    }

    val code : t -> string
    val name : t -> string
    val description : t -> string option
    val usage_count : t -> int
    val creator_id : t -> string
    val creator : t -> User.t
    val created_at : t -> string
    val updated_at : t -> string
    val source_guild_id : t -> string
    val serialized_source_guild : t -> Guild.t
    val is_dirty : t -> bool option

    val pp : Format.formatter -> t -> unit
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type t = {
        code : string;
        name : string;
        description : string option;
        usage_count : int;
        creator_id : string;
        creator : User.t;
        created_at : string;
        updated_at : string;
        source_guild_id : string;
        serialized_source_guild : Guild.t;
        is_dirty : bool option;
    } [@@deriving show]

    let code (t : t) : string = t.code
    let name (t : t) : string = t.name
    let description (t : t) : string option = t.description
    let usage_count (t : t) : int = t.usage_count
    let creator_id (t : t) : string = t.creator_id
    let creator (t : t) : User.t = t.creator
    let created_at (t : t) : string = t.created_at
    let updated_at (t : t) : string = t.updated_at
    let source_guild_id (t : t) : string = t.source_guild_id
    let serialized_source_guild (t : t) : Guild.t = t.serialized_source_guild
    let is_dirty (t : t) : bool option = t.is_dirty

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let creator =
                match User.of_yojson (json |> member "creator") with
                | Ok user -> user
                | Error msg -> raise (Failure msg)
            in
            let serialized_source_guild =
                match Guild.of_yojson (json |> member "serialized_source_guild") with
                | Ok guild -> guild
                | Error msg -> raise (Failure msg)
            in
            Ok
                { code = json |> member "code" |> to_string;
                  name = json |> member "name" |> to_string;
                  description = json |> member "description" |> to_string_option;
                  usage_count =
                    json |> member "usage_count" |> to_int_option
                    |> Option.value ~default:0;
                  creator_id = json |> member "creator_id" |> to_string;
                  creator;
                  created_at =
                    json |> member "created_at" |> to_string_option
                    |> Option.value ~default:"";
                  updated_at =
                    json |> member "updated_at" |> to_string_option
                    |> Option.value ~default:"";
                  source_guild_id =
                    json |> member "source_guild_id" |> to_string;
                  serialized_source_guild;
                  is_dirty = json |> member "is_dirty" |> to_bool_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Guild_template)
