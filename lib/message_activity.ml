module type Message_activity = sig
    type t = {
        type_ : int;
        party_id : string option;
    }

    val type_ : t -> int
    val party_id : t -> string option

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type t = {
        type_ : int;
        party_id : string option;
    } [@@deriving show, eq]

    let type_ (t : t) : int = t.type_
    let party_id (t : t) : string option = t.party_id

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { type_ =
                    json |> member "type" |> to_int_option
                    |> Option.value ~default:0;
                  party_id = json |> member "party_id" |> to_string_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : Message_activity)
