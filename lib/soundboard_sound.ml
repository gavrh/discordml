module type Soundboard_sound = sig
  type t = {
    name : string;
    sound_id : string;
    volume : float;
    emoji_id : string option;
    emoji_name : string option;
    guild_id : string option;
    available : bool;
    user_id : string option;
  }

  val name : t -> string
  val sound_id : t -> string
  val volume : t -> float
  val emoji_id : t -> string option
  val emoji_name : t -> string option
  val guild_id : t -> string option
  val available : t -> bool
  val user_id : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      name : string;
      sound_id : string;
      volume : float;
      emoji_id : string option;
      emoji_name : string option;
      guild_id : string option;
      available : bool;
      user_id : string option;
    }
    [@@deriving show, eq]

    let name (s : t) : string = s.name
    let sound_id (s : t) : string = s.sound_id
    let volume (s : t) : float = s.volume
    let emoji_id (s : t) : string option = s.emoji_id
    let emoji_name (s : t) : string option = s.emoji_name
    let guild_id (s : t) : string option = s.guild_id
    let available (s : t) : bool = s.available
    let user_id (s : t) : string option = s.user_id

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            name = json |> member "name" |> to_string;
            sound_id = json |> member "sound_id" |> to_string;
            volume =
              json |> member "volume" |> to_float_option
              |> Option.value ~default:0.;
            emoji_id = json |> member "emoji_id" |> to_string_option;
            emoji_name = json |> member "emoji_name" |> to_string_option;
            guild_id = json |> member "guild_id" |> to_string_option;
            available =
              json |> member "available" |> to_bool_option
              |> Option.value ~default:false;
            user_id = json |> member "user_id" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Soundboard_sound)
