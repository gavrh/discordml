module type Member = sig
    type t

    val user : t -> User.t
    val nick : t -> string option
    val roles : t -> string list
    val joined_at : t -> string option
    val premium_since : t -> string option
    val deaf : t -> bool
    val mute : t -> bool
    val pending : t -> bool
    val communication_disabled_until : t -> string option
    val avatar : t -> string option

    val of_yojson : Yojson.Safe.t -> (t, string) result
    val of_yojson_partial : user:User.t -> Yojson.Safe.t -> (t, string) result

    val fetch : Rest.t -> guild_id:string -> user_id:string -> t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
end

include (struct

    type t = {
        user : User.t;
        nick : string option;
        roles : string list;
        joined_at : string option;
        premium_since : string option;
        deaf : bool;
        mute : bool;
        pending : bool;
        communication_disabled_until : string option;
        avatar : string option;
    } [@@deriving show, eq]

    let user (m : t) : User.t = m.user
    let nick (m : t) : string option = m.nick
    let roles (m : t) : string list = m.roles
    let joined_at (m : t) : string option = m.joined_at
    let premium_since (m : t) : string option = m.premium_since
    let deaf (m : t) : bool = m.deaf
    let mute (m : t) : bool = m.mute
    let pending (m : t) : bool = m.pending
    let communication_disabled_until (m : t) : string option =
        m.communication_disabled_until
    let avatar (m : t) : string option = m.avatar

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map
                (function `String s -> Some s | _ -> None)
                l
        | _ -> []

    let of_yojson_partial ~(user : User.t) (json : Yojson.Safe.t) :
        (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { user;
                  nick = json |> member "nick" |> to_string_option;
                  roles = string_list (json |> member "roles");
                  joined_at = json |> member "joined_at" |> to_string_option;
                  premium_since =
                    json |> member "premium_since" |> to_string_option;
                  deaf =
                    json |> member "deaf" |> to_bool_option
                    |> Option.value ~default:false;
                  mute =
                    json |> member "mute" |> to_bool_option
                    |> Option.value ~default:false;
                  pending =
                    json |> member "pending" |> to_bool_option
                    |> Option.value ~default:false;
                  communication_disabled_until =
                    json |> member "communication_disabled_until"
                    |> to_string_option;
                  avatar = json |> member "avatar" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            match User.of_yojson (json |> member "user") with
            | Ok user -> of_yojson_partial ~user json
            | Error msg -> Error msg
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok m -> m
        | Error msg -> failwith (path ^ ": " ^ msg)

    let fetch (rest : Rest.t) ~(guild_id : string) ~(user_id : string) : t =
        let path = "/guilds/" ^ guild_id ^ "/members/" ^ user_id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Member)
