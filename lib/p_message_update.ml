let replace_opt (update : 'a option) (existing : 'a option) : 'a option =
  match update with Some value -> Some value | None -> existing

let apply (m : Message.t) (u : Message_update.t) : Message.t =
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
    referenced_message = replace_opt u.referenced_message m.referenced_message;
    interaction = replace_opt u.interaction m.interaction;
    poll = replace_opt u.poll m.poll;
    message_snapshots =
      Option.value u.message_snapshots ~default:m.message_snapshots;
    role_subscription_data =
      replace_opt u.role_subscription_data m.role_subscription_data;
    activity = replace_opt u.activity m.activity;
    position = replace_opt u.position m.position;
  }
