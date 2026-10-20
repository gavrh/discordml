module type Thread_member = sig
  type t

  val id : t -> string option
  val user_id : t -> string option
  val join_timestamp : t -> string
  val flags : t -> int
  val member : t -> Member.t option
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
end

include (
  struct
    type t = {
      id : string option;
      user_id : string option;
      join_timestamp : string;
      flags : int;
      member : Member.t option;
    }
    [@@deriving show, eq]

    let id (t : t) : string option = t.id
    let user_id (t : t) : string option = t.user_id
    let join_timestamp (t : t) : string = t.join_timestamp
    let flags (t : t) : int = t.flags
    let member (t : t) : Member.t option = t.member

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let member_result =
          match json |> member "member" with
          | `Null -> Ok None
          | m -> (
              match Member.of_yojson m with
              | Ok member -> Ok (Some member)
              | Error msg -> Error msg)
        in
        match member_result with
        | Error msg -> Error msg
        | Ok member_opt ->
            Ok
              {
                id = json |> member "id" |> to_string_option;
                user_id = json |> member "user_id" |> to_string_option;
                join_timestamp =
                  json |> member "join_timestamp" |> to_string_option
                  |> Option.value ~default:"";
                flags =
                  json |> member "flags" |> to_int_option
                  |> Option.value ~default:0;
                member = member_opt;
              }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Thread_member)
