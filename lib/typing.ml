module type Typing = sig
  type t = {
    channel_id : string;
    guild_id : string option;
    user_id : string;
    timestamp : string option;
    member : Member.t option;
  }

  val channel_id : t -> string
  val guild_id : t -> string option
  val user_id : t -> string
  val timestamp : t -> string option
  val member : t -> Member.t option
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val with_member : t -> Member.t -> t
end

include (
  struct
    type t = {
      channel_id : string;
      guild_id : string option;
      user_id : string;
      timestamp : string option;
      member : Member.t option;
    }

    let channel_id (t : t) : string = t.channel_id
    let guild_id (t : t) : string option = t.guild_id
    let user_id (t : t) : string = t.user_id
    let timestamp (t : t) : string option = t.timestamp
    let member (t : t) : Member.t option = t.member

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let channel_id = json |> member "channel_id" |> to_string in
        let user_id = json |> member "user_id" |> to_string in
        let member_opt =
          match json |> member "member" with
          | `Null -> None
          | json -> (
              match Member.of_yojson json with
              | Ok member -> Some member
              | Error _ -> None)
        in
        let guild_id =
          match json |> member "guild_id" with
          | `String value -> Some value
          | _ -> None
        in
        let timestamp =
          match json |> member "timestamp" with
          | `Int value -> Some (string_of_int value)
          | `Intlit value -> Some value
          | `String value -> Some value
          | _ -> None
        in
        Ok { channel_id; guild_id; user_id; timestamp; member = member_opt }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let with_member (t : t) (member : Member.t) : t =
      { t with member = Some member }
  end :
    Typing)
