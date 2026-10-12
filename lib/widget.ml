module type Widget = sig
    type settings = {
        enabled : bool;
        channel_id : string option;
    }

    type member = {
        id : string;
        username : string;
        discriminator : string;
        avatar : string option;
        status : string;
        avatar_url : string;
        activity : Presence.activity option;
    }

    type t = {
        id : string;
        name : string;
        instant_invite : string option;
        channels : Channel.t list;
        members : member list;
        presence_count : int;
    }

    val id : t -> string
    val name : t -> string
    val instant_invite : t -> string option
    val channels : t -> Channel.t list
    val members : t -> member list
    val presence_count : t -> int

    val pp : Format.formatter -> t -> unit
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type settings = {
        enabled : bool;
        channel_id : string option;
    } [@@deriving show, eq]

    type member = {
        id : string;
        username : string;
        discriminator : string;
        avatar : string option;
        status : string;
        avatar_url : string;
        activity : Presence.activity option;
    } [@@deriving show]

    type t = {
        id : string;
        name : string;
        instant_invite : string option;
        channels : Channel.t list;
        members : member list;
        presence_count : int;
    } [@@deriving show]

    let id (w : t) : string = w.id
    let name (w : t) : string = w.name
    let instant_invite (w : t) : string option = w.instant_invite
    let channels (w : t) : Channel.t list = w.channels
    let members (w : t) : member list = w.members
    let presence_count (w : t) : int = w.presence_count

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let channels =
                match json |> member "channels" with
                | `List l ->
                    List.filter_map
                        (fun c ->
                           match Channel.of_yojson c with
                           | Ok channel -> Some channel
                           | Error _ -> None)
                        l
                | _ -> []
            in
            let members =
                match json |> member "members" with
                | `List l ->
                    List.map
                        (fun m ->
                           { id = m |> member "id" |> to_string;
                             username = m |> member "username" |> to_string;
                             discriminator =
                               m |> member "discriminator" |> to_string_option
                               |> Option.value ~default:"";
                             avatar = m |> member "avatar" |> to_string_option;
                             status =
                               m |> member "status" |> to_string_option
                               |> Option.value ~default:"offline";
                             avatar_url =
                               m |> member "avatar_url" |> to_string_option
                               |> Option.value ~default:"";
                             activity =
                               (match m |> member "activity" with
                                | `Null -> None
                                | a ->
                                    (match Presence.activity_of_yojson a with
                                     | Ok activity -> Some activity
                                     | Error _ -> None)) })
                        l
                | _ -> []
            in
            Ok
                { id = json |> member "id" |> to_string;
                  name = json |> member "name" |> to_string;
                  instant_invite =
                    json |> member "instant_invite" |> to_string_option;
                  channels;
                  members;
                  presence_count =
                    json |> member "presence_count" |> to_int_option
                    |> Option.value ~default:0 }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : Widget)
