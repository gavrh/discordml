module type User = sig
    type t

    val id : t -> string
    val username : t -> string
    val global_name : t -> string option
    val bot : t -> bool

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val show : t -> string
end

include (struct

    type t = {
        id : string;
        username : string;
        global_name : string option;
        bot : bool;
    } [@@deriving show]

    let id (u : t) : string = u.id
    let username (u : t) : string = u.username
    let global_name (u : t) : string option = u.global_name
    let bot (u : t) : bool = u.bot

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { id = json |> member "id" |> to_string;
                  username = json |> member "username" |> to_string;
                  global_name = json |> member "global_name" |> to_string_option;
                  bot =
                    json |> member "bot" |> to_bool_option
                    |> Option.value ~default:false }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : User)
