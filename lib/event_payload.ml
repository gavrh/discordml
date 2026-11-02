module Message_delete = struct
  type t = {
    id : string;
    channel_id : string;
    guild_id : string option;
    message : Message.t option;
  }

  let id (t : t) : string = t.id
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let message (t : t) : Message.t option = t.message
end

module Message_delete_bulk = struct
  type t = {
    ids : string list;
    channel_id : string;
    guild_id : string option;
    messages : Message.t list;
    channel : Channel.t option;
  }

  let ids (t : t) : string list = t.ids
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let messages (t : t) : Message.t list = t.messages
  let channel (t : t) : Channel.t option = t.channel
end

module Reaction_details = struct
  type t = { burst : bool; type_ : int }

  let burst (t : t) : bool = t.burst
  let type_ (t : t) : int = t.type_
end

module Message_reaction = struct
  type t = {
    reaction : Reaction.t;
    user_id : string;
    user : User.t option;
    details : Reaction_details.t;
  }

  let reaction (t : t) : Reaction.t = t.reaction
  let user_id (t : t) : string = t.user_id
  let user (t : t) : User.t option = t.user
  let details (t : t) : Reaction_details.t = t.details
end

module Message_reaction_remove_all = struct
  type t = {
    message_id : string;
    channel_id : string;
    guild_id : string option;
    message : Message.t option;
    reactions : Reaction.t list;
  }

  let message_id (t : t) : string = t.message_id
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let message (t : t) : Message.t option = t.message
  let reactions (t : t) : Reaction.t list = t.reactions
end

module Message_reaction_remove_emoji = struct
  type t = {
    message_id : string;
    channel_id : string;
    guild_id : string option;
    emoji : Emoji.t;
    reaction : Reaction.t option;
  }

  let message_id (t : t) : string = t.message_id
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let emoji (t : t) : Emoji.t = t.emoji
  let reaction (t : t) : Reaction.t option = t.reaction
end

module Message_poll_vote = struct
  type t = {
    user_id : string;
    channel_id : string;
    message_id : string;
    guild_id : string option;
    answer_id : int;
    poll : Poll.t option;
  }

  let user_id (t : t) : string = t.user_id
  let channel_id (t : t) : string = t.channel_id
  let message_id (t : t) : string = t.message_id
  let guild_id (t : t) : string option = t.guild_id
  let answer_id (t : t) : int = t.answer_id
  let poll (t : t) : Poll.t option = t.poll
end

module Guild_delete = struct
  type t = { id : string; unavailable : bool; guild : Guild.t option }

  let id (t : t) : string = t.id
  let unavailable (t : t) : bool = t.unavailable
  let guild (t : t) : Guild.t option = t.guild
end

module Role_delete = struct
  type t = { guild_id : string; role_id : string; role : Role.t option }

  let guild_id (t : t) : string = t.guild_id
  let role_id (t : t) : string = t.role_id
  let role (t : t) : Role.t option = t.role
end

module Member_remove = struct
  type t = { guild_id : string; user : User.t; member : Member.t option }

  let guild_id (t : t) : string = t.guild_id
  let user (t : t) : User.t = t.user
  let member (t : t) : Member.t option = t.member
end

module Guild_members_chunk = struct
  type t = {
    guild_id : string;
    members : Member.t list;
    presences : Presence.t list;
    guild : Guild.t option;
    count : int;
    index : int;
    nonce : string option;
    not_found : string list;
  }

  let guild_id (t : t) : string = t.guild_id
  let members (t : t) : Member.t list = t.members
  let presences (t : t) : Presence.t list = t.presences
  let guild (t : t) : Guild.t option = t.guild
  let count (t : t) : int = t.count
  let index (t : t) : int = t.index
  let nonce (t : t) : string option = t.nonce
  let not_found (t : t) : string list = t.not_found
end

module Channel_delete = struct
  type t = {
    id : string;
    guild_id : string option;
    type_ : int option;
    channel : Channel.t option;
  }

  let id (t : t) : string = t.id
  let guild_id (t : t) : string option = t.guild_id
  let type_ (t : t) : int option = t.type_
  let channel (t : t) : Channel.t option = t.channel
end

module Channel_pins_update = struct
  type t = {
    channel_id : string;
    guild_id : string option;
    last_pin_timestamp : string option;
    channel : Channel.t option;
  }

  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let last_pin_timestamp (t : t) : string option = t.last_pin_timestamp
  let channel (t : t) : Channel.t option = t.channel
end

module Thread_list_sync = struct
  type t = {
    guild_id : string;
    channel_ids : string list;
    threads : Channel.t list;
    members : Thread_member.t list;
    guild : Guild.t option;
  }

  let guild_id (t : t) : string = t.guild_id
  let channel_ids (t : t) : string list = t.channel_ids
  let threads (t : t) : Channel.t list = t.threads
  let members (t : t) : Thread_member.t list = t.members
  let guild (t : t) : Guild.t option = t.guild
end

module Thread_members_update = struct
  type t = {
    thread_id : string;
    guild_id : string option;
    added : Thread_member.t list;
    removed : Thread_member.t list;
    removed_user_ids : string list;
    member_count : int;
    thread : Channel.t option;
  }

  let thread_id (t : t) : string = t.thread_id
  let guild_id (t : t) : string option = t.guild_id
  let added (t : t) : Thread_member.t list = t.added
  let removed (t : t) : Thread_member.t list = t.removed
  let removed_user_ids (t : t) : string list = t.removed_user_ids
  let member_count (t : t) : int = t.member_count
  let thread (t : t) : Channel.t option = t.thread
end

module Webhooks_update = struct
  type t = {
    guild_id : string option;
    channel_id : string;
    channel : Channel.t option;
  }

  let guild_id (t : t) : string option = t.guild_id
  let channel_id (t : t) : string = t.channel_id
  let channel (t : t) : Channel.t option = t.channel
end

module Invite_create = struct
  type t = {
    code : string;
    channel_id : string;
    guild_id : string option;
    invite : Invite.t option;
  }

  let code (t : t) : string = t.code
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
  let invite (t : t) : Invite.t option = t.invite
end

module Invite_delete = struct
  type t = { code : string; channel_id : string; guild_id : string option }

  let code (t : t) : string = t.code
  let channel_id (t : t) : string = t.channel_id
  let guild_id (t : t) : string option = t.guild_id
end

module Application_command_permissions_update = struct
  type permission = { id : string; type_ : int; permission : Permission.t }
  type permission = { id : string; type_ : int; permission : bool }
  type t = {
    id : string;
    application_id : string;
    guild_id : string;
    permissions : permission list;
  }

  let id (t : t) : string = t.id
  let application_id (t : t) : string = t.application_id
  let guild_id (t : t) : string = t.guild_id
  let permissions (t : t) : permission list = t.permissions
  let permission_id (p : permission) : string = p.id
  let permission_type (p : permission) : int = p.type_
  let permission_permission (p : permission) : Permission.t = p.permission
end

module Auto_moderation_rule_delete = struct
  type t = {
    guild_id : string;
    rule_id : string;
    rule : Auto_moderation.t option;
  }

  let guild_id (t : t) : string = t.guild_id
  let rule_id (t : t) : string = t.rule_id
  let rule (t : t) : Auto_moderation.t option = t.rule
end

module Auto_moderation_action_execution = struct
  type t = {
    guild_id : string;
    rule_id : string;
    rule_trigger_type : int;
    user_id : string;
    action : Auto_moderation.action;
    channel_id : string option;
    message_id : string option;
    alert_system_message_id : string option;
    content : string option;
    matched_keyword : string option;
    matched_content : string option;
  }

  let guild_id (t : t) : string = t.guild_id
  let rule_id (t : t) : string = t.rule_id
  let rule_trigger_type (t : t) : int = t.rule_trigger_type
  let user_id (t : t) : string = t.user_id
  let action (t : t) : Auto_moderation.action = t.action
  let channel_id (t : t) : string option = t.channel_id
  let message_id (t : t) : string option = t.message_id

  let alert_system_message_id (t : t) : string option =
    t.alert_system_message_id

  let content (t : t) : string option = t.content
  let matched_keyword (t : t) : string option = t.matched_keyword
  let matched_content (t : t) : string option = t.matched_content
end

module Guild_scheduled_event_user = struct
  type t = {
    guild_id : string;
    event_id : string;
    user_id : string;
    event : Guild_scheduled_event.t option;
    user : User.t option;
  }

  let guild_id (t : t) : string = t.guild_id
  let event_id (t : t) : string = t.event_id
  let user_id (t : t) : string = t.user_id
  let event (t : t) : Guild_scheduled_event.t option = t.event
  let user (t : t) : User.t option = t.user
end

module Integration_delete = struct
  type t = {
    id : string;
    guild_id : string;
    application_id : string option;
    integration : Integration.t option;
  }

  let id (t : t) : string = t.id
  let guild_id (t : t) : string = t.guild_id
  let application_id (t : t) : string option = t.application_id
  let integration (t : t) : Integration.t option = t.integration
end

module Guild_audit_log_entry = struct
  type t = {
    guild_id : string;
    entry : Audit_log.entry;
    guild : Guild.t option;
  }

  let guild_id (t : t) : string = t.guild_id
  let entry (t : t) : Audit_log.entry = t.entry
  let guild (t : t) : Guild.t option = t.guild
end
