module type Guild = sig
    type t
    val id : t -> string
    val name : t -> string
    val icon : t -> string option
    val owner_id : t -> string option
    val unavailable : t -> bool
    val member_count : t -> int option
    val channels : t -> Channel.t list
    val roles : t -> Yojson.Safe.t list

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val fetch : Rest.t -> string -> t

    val pp : Format.formatter -> t -> unit
    val show : t -> string
end

include (struct

    type t = {
        id : string;
        name : string;
        icon : string option;
        owner_id : string option;
        unavailable : bool;
        member_count : int option;
        channels : Channel.t list;
        roles : Yojson.Safe.t list;
    } [@@deriving show, eq]

    let id (g : t) = g.id
    let name (g : t) = g.name
    let icon (g : t) = g.icon
    let owner_id (g : t) = g.owner_id
    let unavailable (g : t) = g.unavailable
    let member_count (g : t) = g.member_count
    let channels (g : t) = g.channels
    let roles (g : t) = g.roles

    let create (i : string) : t =
        { id = i;
          name = "";
          icon = None;
          owner_id = None;
          unavailable = false;
          member_count = None;
          channels = [];
          roles = [] }

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let channels =
                match json |> member "channels" with
                | `List l ->
                    List.map
                        (fun c ->
                           match Channel.of_yojson c with
                           | Ok channel -> channel
                           | Error msg -> raise (Failure msg))
                        l
                | _ -> []
            in
            let roles =
                match json |> member "roles" with `List l -> l | _ -> []
            in
            Ok
                { id = json |> member "id" |> to_string;
                  name = json |> member "name" |> to_string;
                  icon = json |> member "icon" |> to_string_option;
                  owner_id = json |> member "owner_id" |> to_string_option;
                  unavailable =
                    json |> member "unavailable" |> to_bool_option
                    |> Option.value ~default:false;
                  member_count = json |> member "member_count" |> to_int_option;
                  channels; roles }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok g -> g
        | Error msg -> failwith (path ^ ": " ^ msg)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/guilds/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Guild)
