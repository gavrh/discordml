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
    members : Member.t list;
    guild : Guild.t option;
    count : int;
    index : int;
    nonce : string option;
    not_found : string list;
  }

  let members (t : t) : Member.t list = t.members
  let guild (t : t) : Guild.t option = t.guild
  let count (t : t) : int = t.count
  let index (t : t) : int = t.index
  let nonce (t : t) : string option = t.nonce
  let not_found (t : t) : string list = t.not_found
end
