module type Invite = sig
  type invite_guild = {
    id : string;
    name : string;
    splash : string option;
    banner : string option;
    description : string option;
    icon : string option;
    features : string list;
    verification_level : int;
    vanity_url_code : string option;
    nsfw_level : int;
    premium_subscription_count : int;
  }

  type invite_stage_instance = {
    members : Member.t list;
    participant_count : int;
    speaker_count : int;
    topic : string;
  }

  type t = {
    type_ : int;
    code : string;
    guild : invite_guild option;
    channel : Channel.t option;
    inviter : User.t option;
    target_type : int option;
    target_user : User.t option;
    approximate_presence_count : int option;
    approximate_member_count : int option;
    expires_at : string option;
    stage_instance : invite_stage_instance option;
    guild_scheduled_event : Guild_scheduled_event.t option;
  }

  val type_ : t -> int
  val code : t -> string
  val guild : t -> invite_guild option
  val channel : t -> Channel.t option
  val inviter : t -> User.t option
  val target_type : t -> int option
  val target_user : t -> User.t option
  val approximate_presence_count : t -> int option
  val approximate_member_count : t -> int option
  val expires_at : t -> string option
  val stage_instance : t -> invite_stage_instance option
  val guild_scheduled_event : t -> Guild_scheduled_event.t option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type invite_guild = {
      id : string;
      name : string;
      splash : string option;
      banner : string option;
      description : string option;
      icon : string option;
      features : string list;
      verification_level : int;
      vanity_url_code : string option;
      nsfw_level : int;
      premium_subscription_count : int;
    }
    [@@deriving show, eq]

    type invite_stage_instance = {
      members : Member.t list;
      participant_count : int;
      speaker_count : int;
      topic : string;
    }
    [@@deriving show, eq]

    type t = {
      type_ : int;
      code : string;
      guild : invite_guild option;
      channel : Channel.t option;
      inviter : User.t option;
      target_type : int option;
      target_user : User.t option;
      approximate_presence_count : int option;
      approximate_member_count : int option;
      expires_at : string option;
      stage_instance : invite_stage_instance option;
      guild_scheduled_event : Guild_scheduled_event.t option;
    }
    [@@deriving show, eq]

    let type_ (i : t) : int = i.type_
    let code (i : t) : string = i.code
    let guild (i : t) : invite_guild option = i.guild
    let channel (i : t) : Channel.t option = i.channel
    let inviter (i : t) : User.t option = i.inviter
    let target_type (i : t) : int option = i.target_type
    let target_user (i : t) : User.t option = i.target_user

    let approximate_presence_count (i : t) : int option =
      i.approximate_presence_count

    let approximate_member_count (i : t) : int option =
      i.approximate_member_count

    let expires_at (i : t) : string option = i.expires_at
    let stage_instance (i : t) : invite_stage_instance option = i.stage_instance

    let guild_scheduled_event (i : t) : Guild_scheduled_event.t option =
      i.guild_scheduled_event

    let string_list (json : Yojson.Safe.t) : string list =
      match json with
      | `List l ->
          List.filter_map (function `String s -> Some s | _ -> None) l
      | _ -> []

    let parse_opt (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> (
          match f v with Ok x -> Some x | Error msg -> raise (Failure msg))

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let guild =
          match json |> member "guild" with
          | `Null -> None
          | g ->
              Some
                {
                  id = g |> member "id" |> to_string;
                  name = g |> member "name" |> to_string;
                  splash = g |> member "splash" |> to_string_option;
                  banner = g |> member "banner" |> to_string_option;
                  description = g |> member "description" |> to_string_option;
                  icon = g |> member "icon" |> to_string_option;
                  features = string_list (g |> member "features");
                  verification_level =
                    g
                    |> member "verification_level"
                    |> to_int_option |> Option.value ~default:0;
                  vanity_url_code =
                    g |> member "vanity_url_code" |> to_string_option;
                  nsfw_level =
                    g |> member "nsfw_level" |> to_int_option
                    |> Option.value ~default:0;
                  premium_subscription_count =
                    g
                    |> member "premium_subscription_count"
                    |> to_int_option |> Option.value ~default:0;
                }
        in
        let stage_instance =
          match json |> member "stage_instance" with
          | `Null -> None
          | s ->
              let members =
                match s |> member "members" with
                | `List l ->
                    List.filter_map
                      (fun m ->
                        match Member.of_yojson m with
                        | Ok member -> Some member
                        | Error _ -> None)
                      l
                | _ -> []
              in
              Some
                {
                  members;
                  participant_count =
                    s |> member "participant_count" |> to_int_option
                    |> Option.value ~default:0;
                  speaker_count =
                    s |> member "speaker_count" |> to_int_option
                    |> Option.value ~default:0;
                  topic =
                    s |> member "topic" |> to_string_option
                    |> Option.value ~default:"";
                }
        in
        Ok
          {
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            code = json |> member "code" |> to_string;
            guild;
            channel = parse_opt json "channel" Channel.of_yojson;
            inviter = parse_opt json "inviter" User.of_yojson;
            target_type = json |> member "target_type" |> to_int_option;
            target_user = parse_opt json "target_user" User.of_yojson;
            approximate_presence_count =
              json |> member "approximate_presence_count" |> to_int_option;
            approximate_member_count =
              json |> member "approximate_member_count" |> to_int_option;
            expires_at = json |> member "expires_at" |> to_string_option;
            stage_instance;
            guild_scheduled_event =
              parse_opt json "guild_scheduled_event"
                Guild_scheduled_event.of_yojson;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Invite)
