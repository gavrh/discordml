module type Guild_ban = sig
    type t = {
        user : User.t;
        reason : string option;
    }

    val user : t -> User.t
    val reason : t -> string option

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type t = {
        user : User.t;
        reason : string option;
    } [@@deriving show, eq]

    let user (b : t) : User.t = b.user
    let reason (b : t) : string option = b.reason

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let user =
                match User.of_yojson (json |> member "user") with
                | Ok user -> user
                | Error msg -> raise (Failure msg)
            in
            Ok
                { user;
                  reason = json |> member "reason" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Guild_ban)
