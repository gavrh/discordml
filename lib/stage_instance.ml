module type Stage_instance = sig
  type t = {
    id : string;
    guild_id : string;
    channel_id : string;
    topic : string;
    privacy_level : int;
    discoverable_disabled : bool;
    guild_scheduled_event_id : string option;
  }

  val id : t -> string
  val guild_id : t -> string
  val channel_id : t -> string
  val topic : t -> string
  val privacy_level : t -> int
  val discoverable_disabled : t -> bool
  val guild_scheduled_event_id : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      id : string;
      guild_id : string;
      channel_id : string;
      topic : string;
      privacy_level : int;
      discoverable_disabled : bool;
      guild_scheduled_event_id : string option;
    }
    [@@deriving show, eq]

    let id (s : t) : string = s.id
    let guild_id (s : t) : string = s.guild_id
    let channel_id (s : t) : string = s.channel_id
    let topic (s : t) : string = s.topic
    let privacy_level (s : t) : int = s.privacy_level
    let discoverable_disabled (s : t) : bool = s.discoverable_disabled

    let guild_scheduled_event_id (s : t) : string option =
      s.guild_scheduled_event_id

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string;
            guild_id = json |> member "guild_id" |> to_string;
            channel_id = json |> member "channel_id" |> to_string;
            topic = json |> member "topic" |> to_string;
            privacy_level =
              json |> member "privacy_level" |> to_int_option
              |> Option.value ~default:0;
            discoverable_disabled =
              json
              |> member "discoverable_disabled"
              |> to_bool_option
              |> Option.value ~default:false;
            guild_scheduled_event_id =
              json |> member "guild_scheduled_event_id" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Stage_instance)
