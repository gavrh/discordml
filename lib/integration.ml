module type Integration = sig
    type account = {
        id : string;
        name : string;
    }

    type application = {
        id : string;
        name : string;
        icon : string option;
        description : string;
        bot : User.t option;
    }

    type t = {
        id : string;
        name : string;
        type_ : string;
        enabled : bool;
        syncing : bool option;
        role_id : string option;
        enable_emoticons : bool option;
        expire_behavior : int;
        expire_grace_period : int;
        user : User.t option;
        account : account;
        synced_at : string option;
        subscriber_count : int option;
        revoked : bool option;
        application : application option;
        scopes : string list;
        guild_id : string option;
    }

    val id : t -> string
    val name : t -> string
    val type_ : t -> string
    val enabled : t -> bool
    val syncing : t -> bool option
    val role_id : t -> string option
    val enable_emoticons : t -> bool option
    val expire_behavior : t -> int
    val expire_grace_period : t -> int
    val user : t -> User.t option
    val account : t -> account
    val synced_at : t -> string option
    val subscriber_count : t -> int option
    val revoked : t -> bool option
    val application : t -> application option
    val scopes : t -> string list
    val guild_id : t -> string option

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type account = {
        id : string;
        name : string;
    } [@@deriving show, eq]

    type application = {
        id : string;
        name : string;
        icon : string option;
        description : string;
        bot : User.t option;
    } [@@deriving show, eq]

    type t = {
        id : string;
        name : string;
        type_ : string;
        enabled : bool;
        syncing : bool option;
        role_id : string option;
        enable_emoticons : bool option;
        expire_behavior : int;
        expire_grace_period : int;
        user : User.t option;
        account : account;
        synced_at : string option;
        subscriber_count : int option;
        revoked : bool option;
        application : application option;
        scopes : string list;
        guild_id : string option;
    } [@@deriving show, eq]

    let id (i : t) : string = i.id
    let name (i : t) : string = i.name
    let type_ (i : t) : string = i.type_
    let enabled (i : t) : bool = i.enabled
    let syncing (i : t) : bool option = i.syncing
    let role_id (i : t) : string option = i.role_id
    let enable_emoticons (i : t) : bool option = i.enable_emoticons
    let expire_behavior (i : t) : int = i.expire_behavior
    let expire_grace_period (i : t) : int = i.expire_grace_period
    let user (i : t) : User.t option = i.user
    let account (i : t) : account = i.account
    let synced_at (i : t) : string option = i.synced_at
    let subscriber_count (i : t) : int option = i.subscriber_count
    let revoked (i : t) : bool option = i.revoked
    let application (i : t) : application option = i.application
    let scopes (i : t) : string list = i.scopes
    let guild_id (i : t) : string option = i.guild_id

    let string_list (json : Yojson.Safe.t) : string list =
        match json with
        | `List l ->
            List.filter_map (function `String s -> Some s | _ -> None) l
        | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let account =
                match json |> member "account" with
                | `Null -> { id = ""; name = "" }
                | a ->
                    { id = a |> member "id" |> to_string;
                      name = a |> member "name" |> to_string }
            in
            let user =
                match json |> member "user" with
                | `Null -> None
                | u ->
                    (match User.of_yojson u with
                     | Ok user -> Some user
                     | Error msg -> raise (Failure msg))
            in
            let application =
                match json |> member "application" with
                | `Null -> None
                | a ->
                    let bot =
                        match a |> member "bot" with
                        | `Null -> None
                        | b ->
                            (match User.of_yojson b with
                             | Ok bot -> Some bot
                             | Error msg -> raise (Failure msg))
                    in
                    Some
                        { id = a |> member "id" |> to_string;
                          name = a |> member "name" |> to_string;
                          icon = a |> member "icon" |> to_string_option;
                          description =
                            a |> member "description" |> to_string_option
                            |> Option.value ~default:"";
                          bot }
            in
            Ok
                { id = json |> member "id" |> to_string;
                  name = json |> member "name" |> to_string;
                  type_ =
                    json |> member "type" |> to_string_option
                    |> Option.value ~default:"";
                  enabled =
                    json |> member "enabled" |> to_bool_option
                    |> Option.value ~default:false;
                  syncing = json |> member "syncing" |> to_bool_option;
                  role_id = json |> member "role_id" |> to_string_option;
                  enable_emoticons =
                    json |> member "enable_emoticons" |> to_bool_option;
                  expire_behavior =
                    json |> member "expire_behavior" |> to_int_option
                    |> Option.value ~default:0;
                  expire_grace_period =
                    json |> member "expire_grace_period" |> to_int_option
                    |> Option.value ~default:0;
                  user;
                  account;
                  synced_at = json |> member "synced_at" |> to_string_option;
                  subscriber_count =
                    json |> member "subscriber_count" |> to_int_option;
                  revoked = json |> member "revoked" |> to_bool_option;
                  application;
                  scopes = string_list (json |> member "scopes");
                  guild_id = json |> member "guild_id" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Integration)
