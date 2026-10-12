module type User = sig
    type t

    val id : t -> string
    val username : t -> string
    val global_name : t -> string option
    val discriminator : t -> string option
    val avatar : t -> string option
    val bot : t -> bool

    val of_yojson : Yojson.Safe.t -> (t, string) result
    val fetch : Rest.t -> string -> t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
end

include (struct

    type t = {
        id : string;
        username : string;
        global_name : string option;
        discriminator : string option;
        avatar : string option;
        bot : bool;
    } [@@deriving show, eq]

    let id (u : t) : string = u.id
    let username (u : t) : string = u.username
    let global_name (u : t) : string option = u.global_name
    let discriminator (u : t) : string option = u.discriminator
    let avatar (u : t) : string option = u.avatar
    let bot (u : t) : bool = u.bot

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { id = json |> member "id" |> to_string;
                  username = json |> member "username" |> to_string;
                  global_name = json |> member "global_name" |> to_string_option;
                  discriminator =
                    json |> member "discriminator" |> to_string_option;
                  avatar = json |> member "avatar" |> to_string_option;
                  bot =
                    json |> member "bot" |> to_bool_option
                    |> Option.value ~default:false }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok u -> u
        | Error msg -> failwith (path ^ ": " ^ msg)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/users/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : User)
