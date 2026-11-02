module type Voice_state = sig
  type t = {
    guild_id : string option;
    channel_id : string option;
    user_id : string;
    member : Member.t option;
    session_id : string;
    deaf : bool option;
    mute : bool option;
    self_deaf : bool option;
    self_mute : bool option;
    self_stream : bool option;
    self_video : bool option;
    suppress : bool option;
    request_to_speak_timestamp : string option;
  }

  val guild_id : t -> string option
  val channel_id : t -> string option
  val user_id : t -> string
  val member : t -> Member.t option
  val session_id : t -> string
  val deaf : t -> bool option
  val mute : t -> bool option
  val self_deaf : t -> bool option
  val self_mute : t -> bool option
  val self_stream : t -> bool option
  val self_video : t -> bool option
  val suppress : t -> bool option
  val request_to_speak_timestamp : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      guild_id : string option;
      channel_id : string option;
      user_id : string;
      member : Member.t option;
      session_id : string;
      deaf : bool option;
      mute : bool option;
      self_deaf : bool option;
      self_mute : bool option;
      self_stream : bool option;
      self_video : bool option;
      suppress : bool option;
      request_to_speak_timestamp : string option;
    }
    [@@deriving show, eq]

    let guild_id (v : t) : string option = v.guild_id
    let channel_id (v : t) : string option = v.channel_id
    let user_id (v : t) : string = v.user_id
    let member (v : t) : Member.t option = v.member
    let session_id (v : t) : string = v.session_id
    let deaf (v : t) : bool option = v.deaf
    let mute (v : t) : bool option = v.mute
    let self_deaf (v : t) : bool option = v.self_deaf
    let self_mute (v : t) : bool option = v.self_mute
    let self_stream (v : t) : bool option = v.self_stream
    let self_video (v : t) : bool option = v.self_video
    let suppress (v : t) : bool option = v.suppress

    let request_to_speak_timestamp (v : t) : string option =
      v.request_to_speak_timestamp

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let member_ =
          match json |> member "member" with
          | `Null -> None
          | m -> (
              match Member.of_yojson m with
              | Ok member -> Some member
              | Error msg -> raise (Failure msg))
        in
        Ok
          {
            guild_id = json |> member "guild_id" |> to_string_option;
            channel_id = json |> member "channel_id" |> to_string_option;
            user_id = json |> member "user_id" |> to_string;
            member = member_;
            session_id = json |> member "session_id" |> to_string;
            deaf = json |> member "deaf" |> to_bool_option;
            mute = json |> member "mute" |> to_bool_option;
            self_deaf = json |> member "self_deaf" |> to_bool_option;
            self_mute = json |> member "self_mute" |> to_bool_option;
            self_stream = json |> member "self_stream" |> to_bool_option;
            self_video = json |> member "self_video" |> to_bool_option;
            suppress = json |> member "suppress" |> to_bool_option;
            request_to_speak_timestamp =
              json |> member "request_to_speak_timestamp" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Voice_state)
