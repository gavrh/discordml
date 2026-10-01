module type Intent = sig
    type t = int

    val guilds : t
    val guild_members : t
    val guild_moderation : t
    val guild_expressions : t
    val guild_integrations : t
    val guild_webhooks : t
    val guild_invites : t
    val guild_voice_states : t
    val guild_presences : t
    val guild_messages : t
    val guild_message_reactions : t
    val guild_message_typing : t
    val direct_messages : t
    val direct_message_reactions : t
    val direct_message_typing : t
    val message_content : t
    val guild_scheduled_events : t
    val auto_moderation_configuration : t
    val auto_moderation_execution : t
    val guild_message_polls : t
    val direct_message_polls : t
    val privileged : t
    val standard : t
    val all : t

    val has : t -> t -> bool
end

include (struct

    type t = int

    let guilds = 1 lsl 0
    let guild_members = 1 lsl 1
    let guild_moderation = 1 lsl 2
    let guild_expressions = 1 lsl 3
    let guild_integrations = 1 lsl 4
    let guild_webhooks = 1 lsl 5
    let guild_invites = 1 lsl 6
    let guild_voice_states = 1 lsl 7
    let guild_presences = 1 lsl 8
    let guild_messages = 1 lsl 9
    let guild_message_reactions = 1 lsl 10
    let guild_message_typing = 1 lsl 11
    let direct_messages = 1 lsl 12
    let direct_message_reactions = 1 lsl 13
    let direct_message_typing = 1 lsl 14
    let message_content = 1 lsl 15
    let guild_scheduled_events = 1 lsl 16
    let auto_moderation_configuration = 1 lsl 20
    let auto_moderation_execution = 1 lsl 21
    let guild_message_polls = 1 lsl 24
    let direct_message_polls = 1 lsl 25

    let privileged = guild_members lor guild_presences lor message_content

    let standard =
        guilds lor
        guild_moderation lor
        guild_expressions lor
        guild_integrations lor
        guild_webhooks lor
        guild_invites lor
        guild_voice_states lor
        guild_messages lor
        guild_message_reactions lor
        guild_message_typing lor
        direct_messages lor
        direct_message_reactions lor
        direct_message_typing lor
        guild_scheduled_events lor
        auto_moderation_configuration lor
        auto_moderation_execution lor
        guild_message_polls lor
        direct_message_polls

    let all = standard lor privileged

    let has (intents : t) (flag : t) : bool = intents land flag = flag

end : Intent)
