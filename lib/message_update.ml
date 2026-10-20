module type Message_update = sig
  type t = {
    id : string;
    channel_id : string;
    guild_id : string option;
    content : string option;
    author : User.t option;
    member : Member.t option;
    attachments : Attachment.t list option;
    embeds : Embed.t list option;
    mentions : User.t list option;
    mention_roles : string list option;
    mention_everyone : bool option;
    mention_channels : Message.mention_channel list option;
    components : Component.t list option;
    edited_timestamp : string option;
    pinned : bool option;
    flags : int option;
    tts : bool option;
    type_ : int option;
    timestamp : string option;
    reactions : Reaction.t list option;
    sticker_items : Sticker.t list option;
    nonce : string option;
    webhook_id : string option;
    application_id : string option;
    thread : Channel.t option;
    referenced_message : Message.t option;
    interaction : Message.interaction_metadata option;
    poll : Poll.t option;
    message_snapshots : Message.snapshot list option;
    role_subscription_data : Role_subscription_data.t option;
    activity : Message_activity.t option;
    position : int option;
  }

  val id : t -> string
  val channel_id : t -> string
  val guild_id : t -> string option
  val content : t -> string option
  val author : t -> User.t option
  val member : t -> Member.t option
  val attachments : t -> Attachment.t list option
  val embeds : t -> Embed.t list option
  val mentions : t -> User.t list option
  val mention_roles : t -> string list option
  val mention_everyone : t -> bool option
  val mention_channels : t -> Message.mention_channel list option
  val components : t -> Component.t list option
  val edited_timestamp : t -> string option
  val pinned : t -> bool option
  val flags : t -> int option
  val tts : t -> bool option
  val type_ : t -> int option
  val timestamp : t -> string option
  val reactions : t -> Reaction.t list option
  val sticker_items : t -> Sticker.t list option
  val nonce : t -> string option
  val webhook_id : t -> string option
  val application_id : t -> string option
  val thread : t -> Channel.t option
  val referenced_message : t -> Message.t option
  val interaction : t -> Message.interaction_metadata option
  val poll : t -> Poll.t option
  val message_snapshots : t -> Message.snapshot list option
  val role_subscription_data : t -> Role_subscription_data.t option
  val activity : t -> Message_activity.t option
  val position : t -> int option
  val of_yojson : Yojson.Safe.t -> (t, string) result
  val apply : Message.t -> t -> Message.t
end

include (
  struct
    type t = {
      id : string;
      channel_id : string;
      guild_id : string option;
      content : string option;
      author : User.t option;
      member : Member.t option;
      attachments : Attachment.t list option;
      embeds : Embed.t list option;
      mentions : User.t list option;
      mention_roles : string list option;
      mention_everyone : bool option;
      mention_channels : Message.mention_channel list option;
      components : Component.t list option;
      edited_timestamp : string option;
      pinned : bool option;
      flags : int option;
      tts : bool option;
      type_ : int option;
      timestamp : string option;
      reactions : Reaction.t list option;
      sticker_items : Sticker.t list option;
      nonce : string option;
      webhook_id : string option;
      application_id : string option;
      thread : Channel.t option;
      referenced_message : Message.t option;
      interaction : Message.interaction_metadata option;
      poll : Poll.t option;
      message_snapshots : Message.snapshot list option;
      role_subscription_data : Role_subscription_data.t option;
      activity : Message_activity.t option;
      position : int option;
    }

    let id (u : t) : string = u.id
    let channel_id (u : t) : string = u.channel_id
    let guild_id (u : t) : string option = u.guild_id
    let content (u : t) : string option = u.content
    let author (u : t) : User.t option = u.author
    let member (u : t) : Member.t option = u.member
    let attachments (u : t) : Attachment.t list option = u.attachments
    let embeds (u : t) : Embed.t list option = u.embeds
    let mentions (u : t) : User.t list option = u.mentions
    let mention_roles (u : t) : string list option = u.mention_roles
    let mention_everyone (u : t) : bool option = u.mention_everyone

    let mention_channels (u : t) : Message.mention_channel list option =
      u.mention_channels

    let components (u : t) : Component.t list option = u.components
    let edited_timestamp (u : t) : string option = u.edited_timestamp
    let pinned (u : t) : bool option = u.pinned
    let flags (u : t) : int option = u.flags
    let tts (u : t) : bool option = u.tts
    let type_ (u : t) : int option = u.type_
    let timestamp (u : t) : string option = u.timestamp
    let reactions (u : t) : Reaction.t list option = u.reactions
    let sticker_items (u : t) : Sticker.t list option = u.sticker_items
    let nonce (u : t) : string option = u.nonce
    let webhook_id (u : t) : string option = u.webhook_id
    let application_id (u : t) : string option = u.application_id
    let thread (u : t) : Channel.t option = u.thread
    let referenced_message (u : t) : Message.t option = u.referenced_message

    let interaction (u : t) : Message.interaction_metadata option =
      u.interaction

    let poll (u : t) : Poll.t option = u.poll

    let message_snapshots (u : t) : Message.snapshot list option =
      u.message_snapshots

    let role_subscription_data (u : t) : Role_subscription_data.t option =
      u.role_subscription_data

    let activity (u : t) : Message_activity.t option = u.activity
    let position (u : t) : int option = u.position

    let string_list_opt (json : Yojson.Safe.t) : string list option =
      match json with
      | `List l ->
          Some (List.filter_map (function `String s -> Some s | _ -> None) l)
      | _ -> None

    let parse_opt (json : Yojson.Safe.t)
        (of_yojson : Yojson.Safe.t -> ('a, string) result) : 'a option =
      match json with
      | `Null -> None
      | v -> ( match of_yojson v with Ok x -> Some x | Error _ -> None)

    let parse_list (json : Yojson.Safe.t)
        (of_yojson : Yojson.Safe.t -> ('a, string) result) : 'a list option =
      match json with
      | `List l ->
          Some
            (List.filter_map
               (fun v ->
                 match of_yojson v with Ok x -> Some x | Error _ -> None)
               l)
      | _ -> None

    let safe_option (f : Yojson.Safe.t -> 'a option) (json : Yojson.Safe.t) :
        'a option =
      try f json with
      | Yojson.Safe.Util.Type_error _ -> None
      | Yojson.Safe.Util.Undefined _ -> None

    let string_opt = safe_option Yojson.Safe.Util.to_string_option
    let bool_opt = safe_option Yojson.Safe.Util.to_bool_option
    let int_opt = safe_option Yojson.Safe.Util.to_int_option

    let mention_channel_of_yojson (json : Yojson.Safe.t) :
        (Message.mention_channel, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            Message.id = json |> member "id" |> to_string;
            guild_id = json |> member "guild_id" |> to_string;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            name = json |> member "name" |> to_string;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let interaction_of_yojson (json : Yojson.Safe.t) :
        (Message.interaction_metadata, string) result =
      let open Yojson.Safe.Util in
      try
        let user =
          match User.of_yojson (json |> member "user") with
          | Ok user -> user
          | Error msg -> raise (Failure msg)
        in
        Ok
          {
            Message.id = json |> member "id" |> to_string;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            name = json |> member "name" |> to_string;
            user;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let snapshot_of_yojson (json : Yojson.Safe.t) :
        (Message.snapshot, string) result =
      let open Yojson.Safe.Util in
      match Message.of_yojson (json |> member "message") with
      | Ok message -> Ok { Message.message }
      | Error msg -> Error msg

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let id = json |> member "id" |> to_string in
        let channel_id = json |> member "channel_id" |> to_string in
        let author = parse_opt (json |> member "author") User.of_yojson in
        let member_opt =
          match author with
          | Some author ->
              parse_opt
                (json |> member "member")
                (Member.of_yojson_partial ~user:author)
          | None -> parse_opt (json |> member "member") Member.of_yojson
        in
        Ok
          {
            id;
            channel_id;
            guild_id = string_opt (json |> member "guild_id");
            content = string_opt (json |> member "content");
            author;
            member = member_opt;
            attachments =
              parse_list (json |> member "attachments") Attachment.of_yojson;
            embeds = parse_list (json |> member "embeds") Embed.of_yojson;
            mentions = parse_list (json |> member "mentions") User.of_yojson;
            mention_roles = string_list_opt (json |> member "mention_roles");
            mention_everyone = bool_opt (json |> member "mention_everyone");
            mention_channels =
              parse_list
                (json |> member "mention_channels")
                mention_channel_of_yojson;
            components =
              parse_list (json |> member "components") Component.of_yojson;
            edited_timestamp = string_opt (json |> member "edited_timestamp");
            pinned = bool_opt (json |> member "pinned");
            flags = int_opt (json |> member "flags");
            tts = bool_opt (json |> member "tts");
            type_ = int_opt (json |> member "type");
            timestamp = string_opt (json |> member "timestamp");
            reactions =
              parse_list
                (json |> member "reactions")
                (Reaction.of_yojson ~channel_id ~message_id:id);
            sticker_items =
              parse_list (json |> member "sticker_items") Sticker.of_yojson;
            nonce = string_opt (json |> member "nonce");
            webhook_id = string_opt (json |> member "webhook_id");
            application_id = string_opt (json |> member "application_id");
            thread = parse_opt (json |> member "thread") Channel.of_yojson;
            referenced_message =
              parse_opt (json |> member "referenced_message") Message.of_yojson;
            interaction =
              parse_opt (json |> member "interaction") interaction_of_yojson;
            poll = parse_opt (json |> member "poll") Poll.of_yojson;
            message_snapshots =
              parse_list (json |> member "message_snapshots") snapshot_of_yojson;
            role_subscription_data =
              parse_opt
                (json |> member "role_subscription_data")
                Role_subscription_data.of_yojson;
            activity =
              parse_opt (json |> member "activity") Message_activity.of_yojson;
            position = int_opt (json |> member "position");
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let replace_opt (update : 'a option) (existing : 'a option) : 'a option =
      match update with Some value -> Some value | None -> existing

    let apply (m : Message.t) (u : t) : Message.t =
      {
        m with
        guild_id = replace_opt u.guild_id m.guild_id;
        content = Option.value u.content ~default:m.content;
        author = Option.value u.author ~default:m.author;
        member = replace_opt u.member m.member;
        attachments = Option.value u.attachments ~default:m.attachments;
        embeds = Option.value u.embeds ~default:m.embeds;
        mentions = Option.value u.mentions ~default:m.mentions;
        mention_roles = Option.value u.mention_roles ~default:m.mention_roles;
        mention_everyone =
          Option.value u.mention_everyone ~default:m.mention_everyone;
        mention_channels =
          Option.value u.mention_channels ~default:m.mention_channels;
        components = Option.value u.components ~default:m.components;
        edited_timestamp = replace_opt u.edited_timestamp m.edited_timestamp;
        pinned = Option.value u.pinned ~default:m.pinned;
        flags = Option.value u.flags ~default:m.flags;
        tts = Option.value u.tts ~default:m.tts;
        type_ = Option.value u.type_ ~default:m.type_;
        timestamp = replace_opt u.timestamp m.timestamp;
        reactions = Option.value u.reactions ~default:m.reactions;
        sticker_items = Option.value u.sticker_items ~default:m.sticker_items;
        nonce = replace_opt u.nonce m.nonce;
        webhook_id = replace_opt u.webhook_id m.webhook_id;
        application_id = replace_opt u.application_id m.application_id;
        thread = replace_opt u.thread m.thread;
        referenced_message =
          replace_opt u.referenced_message m.referenced_message;
        interaction = replace_opt u.interaction m.interaction;
        poll = replace_opt u.poll m.poll;
        message_snapshots =
          Option.value u.message_snapshots ~default:m.message_snapshots;
        role_subscription_data =
          replace_opt u.role_subscription_data m.role_subscription_data;
        activity = replace_opt u.activity m.activity;
        position = replace_opt u.position m.position;
      }
  end :
    Message_update)
