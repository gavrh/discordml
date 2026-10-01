module type Event = sig
    type t =
        | Ready
        | Resumed
        | Application_command_permissions_update
        | Auto_moderation_rule_create
        | Auto_moderation_rule_update
        | Auto_moderation_rule_delete
        | Auto_moderation_action_execution
        | Channel_create
        | Channel_update
        | Channel_delete
        | Channel_info
        | Channel_pins_update
        | Thread_create
        | Thread_update
        | Thread_delete
        | Thread_list_sync
        | Thread_member_update
        | Thread_members_update
        | Voice_channel_status_update
        | Voice_channel_start_time_update
        | Entitlement_create
        | Entitlement_update
        | Entitlement_delete
        | Subscription_create
        | Subscription_update
        | Subscription_delete
        | Guild_create
        | Guild_update
        | Guild_delete
        | Guild_audit_log_entry_create
        | Guild_ban_add
        | Guild_ban_remove
        | Guild_emojis_update
        | Guild_stickers_update
        | Guild_integrations_update
        | Guild_member_add
        | Guild_member_remove
        | Guild_member_update
        | Guild_members_chunk
        | Guild_role_create
        | Guild_role_update
        | Guild_role_delete
        | Guild_scheduled_event_create
        | Guild_scheduled_event_update
        | Guild_scheduled_event_delete
        | Guild_scheduled_event_user_add
        | Guild_scheduled_event_user_remove
        | Guild_soundboard_sound_create
        | Guild_soundboard_sound_update
        | Guild_soundboard_sound_delete
        | Guild_soundboard_sounds_update
        | Soundboard_sounds
        | Integration_create
        | Integration_update
        | Integration_delete
        | Interaction_create
        | Invite_create
        | Invite_delete
        | Message_create
        | Message_update
        | Message_delete
        | Message_delete_bulk
        | Message_reaction_add
        | Message_reaction_remove
        | Message_reaction_remove_all
        | Message_reaction_remove_emoji
        | Message_poll_vote_add
        | Message_poll_vote_remove
        | Presence_update
        | Stage_instance_create
        | Stage_instance_update
        | Stage_instance_delete
        | Typing_start
        | User_update
        | Voice_channel_effect_send
        | Voice_state_update
        | Voice_server_update
        | Webhooks_update

    val of_string : string -> t option
    val to_string : t -> string
end

include (struct

    type t =
        | Ready
        | Resumed
        | Application_command_permissions_update
        | Auto_moderation_rule_create
        | Auto_moderation_rule_update
        | Auto_moderation_rule_delete
        | Auto_moderation_action_execution
        | Channel_create
        | Channel_update
        | Channel_delete
        | Channel_info
        | Channel_pins_update
        | Thread_create
        | Thread_update
        | Thread_delete
        | Thread_list_sync
        | Thread_member_update
        | Thread_members_update
        | Voice_channel_status_update
        | Voice_channel_start_time_update
        | Entitlement_create
        | Entitlement_update
        | Entitlement_delete
        | Subscription_create
        | Subscription_update
        | Subscription_delete
        | Guild_create
        | Guild_update
        | Guild_delete
        | Guild_audit_log_entry_create
        | Guild_ban_add
        | Guild_ban_remove
        | Guild_emojis_update
        | Guild_stickers_update
        | Guild_integrations_update
        | Guild_member_add
        | Guild_member_remove
        | Guild_member_update
        | Guild_members_chunk
        | Guild_role_create
        | Guild_role_update
        | Guild_role_delete
        | Guild_scheduled_event_create
        | Guild_scheduled_event_update
        | Guild_scheduled_event_delete
        | Guild_scheduled_event_user_add
        | Guild_scheduled_event_user_remove
        | Guild_soundboard_sound_create
        | Guild_soundboard_sound_update
        | Guild_soundboard_sound_delete
        | Guild_soundboard_sounds_update
        | Soundboard_sounds
        | Integration_create
        | Integration_update
        | Integration_delete
        | Interaction_create
        | Invite_create
        | Invite_delete
        | Message_create
        | Message_update
        | Message_delete
        | Message_delete_bulk
        | Message_reaction_add
        | Message_reaction_remove
        | Message_reaction_remove_all
        | Message_reaction_remove_emoji
        | Message_poll_vote_add
        | Message_poll_vote_remove
        | Presence_update
        | Stage_instance_create
        | Stage_instance_update
        | Stage_instance_delete
        | Typing_start
        | User_update
        | Voice_channel_effect_send
        | Voice_state_update
        | Voice_server_update
        | Webhooks_update

    let of_string = function
        | "READY" -> Some Ready
        | "RESUMED" -> Some Resumed
        | "APPLICATION_COMMAND_PERMISSIONS_UPDATE" ->
            Some Application_command_permissions_update
        | "AUTO_MODERATION_RULE_CREATE" -> Some Auto_moderation_rule_create
        | "AUTO_MODERATION_RULE_UPDATE" -> Some Auto_moderation_rule_update
        | "AUTO_MODERATION_RULE_DELETE" -> Some Auto_moderation_rule_delete
        | "AUTO_MODERATION_ACTION_EXECUTION" ->
            Some Auto_moderation_action_execution
        | "CHANNEL_CREATE" -> Some Channel_create
        | "CHANNEL_UPDATE" -> Some Channel_update
        | "CHANNEL_DELETE" -> Some Channel_delete
        | "CHANNEL_INFO" -> Some Channel_info
        | "CHANNEL_PINS_UPDATE" -> Some Channel_pins_update
        | "THREAD_CREATE" -> Some Thread_create
        | "THREAD_UPDATE" -> Some Thread_update
        | "THREAD_DELETE" -> Some Thread_delete
        | "THREAD_LIST_SYNC" -> Some Thread_list_sync
        | "THREAD_MEMBER_UPDATE" -> Some Thread_member_update
        | "THREAD_MEMBERS_UPDATE" -> Some Thread_members_update
        | "VOICE_CHANNEL_STATUS_UPDATE" -> Some Voice_channel_status_update
        | "VOICE_CHANNEL_START_TIME_UPDATE" ->
            Some Voice_channel_start_time_update
        | "ENTITLEMENT_CREATE" -> Some Entitlement_create
        | "ENTITLEMENT_UPDATE" -> Some Entitlement_update
        | "ENTITLEMENT_DELETE" -> Some Entitlement_delete
        | "SUBSCRIPTION_CREATE" -> Some Subscription_create
        | "SUBSCRIPTION_UPDATE" -> Some Subscription_update
        | "SUBSCRIPTION_DELETE" -> Some Subscription_delete
        | "GUILD_CREATE" -> Some Guild_create
        | "GUILD_UPDATE" -> Some Guild_update
        | "GUILD_DELETE" -> Some Guild_delete
        | "GUILD_AUDIT_LOG_ENTRY_CREATE" -> Some Guild_audit_log_entry_create
        | "GUILD_BAN_ADD" -> Some Guild_ban_add
        | "GUILD_BAN_REMOVE" -> Some Guild_ban_remove
        | "GUILD_EMOJIS_UPDATE" -> Some Guild_emojis_update
        | "GUILD_STICKERS_UPDATE" -> Some Guild_stickers_update
        | "GUILD_INTEGRATIONS_UPDATE" -> Some Guild_integrations_update
        | "GUILD_MEMBER_ADD" -> Some Guild_member_add
        | "GUILD_MEMBER_REMOVE" -> Some Guild_member_remove
        | "GUILD_MEMBER_UPDATE" -> Some Guild_member_update
        | "GUILD_MEMBERS_CHUNK" -> Some Guild_members_chunk
        | "GUILD_ROLE_CREATE" -> Some Guild_role_create
        | "GUILD_ROLE_UPDATE" -> Some Guild_role_update
        | "GUILD_ROLE_DELETE" -> Some Guild_role_delete
        | "GUILD_SCHEDULED_EVENT_CREATE" -> Some Guild_scheduled_event_create
        | "GUILD_SCHEDULED_EVENT_UPDATE" -> Some Guild_scheduled_event_update
        | "GUILD_SCHEDULED_EVENT_DELETE" -> Some Guild_scheduled_event_delete
        | "GUILD_SCHEDULED_EVENT_USER_ADD" ->
            Some Guild_scheduled_event_user_add
        | "GUILD_SCHEDULED_EVENT_USER_REMOVE" ->
            Some Guild_scheduled_event_user_remove
        | "GUILD_SOUNDBOARD_SOUND_CREATE" ->
            Some Guild_soundboard_sound_create
        | "GUILD_SOUNDBOARD_SOUND_UPDATE" ->
            Some Guild_soundboard_sound_update
        | "GUILD_SOUNDBOARD_SOUND_DELETE" ->
            Some Guild_soundboard_sound_delete
        | "GUILD_SOUNDBOARD_SOUNDS_UPDATE" ->
            Some Guild_soundboard_sounds_update
        | "SOUNDBOARD_SOUNDS" -> Some Soundboard_sounds
        | "INTEGRATION_CREATE" -> Some Integration_create
        | "INTEGRATION_UPDATE" -> Some Integration_update
        | "INTEGRATION_DELETE" -> Some Integration_delete
        | "INTERACTION_CREATE" -> Some Interaction_create
        | "INVITE_CREATE" -> Some Invite_create
        | "INVITE_DELETE" -> Some Invite_delete
        | "MESSAGE_CREATE" -> Some Message_create
        | "MESSAGE_UPDATE" -> Some Message_update
        | "MESSAGE_DELETE" -> Some Message_delete
        | "MESSAGE_DELETE_BULK" -> Some Message_delete_bulk
        | "MESSAGE_REACTION_ADD" -> Some Message_reaction_add
        | "MESSAGE_REACTION_REMOVE" -> Some Message_reaction_remove
        | "MESSAGE_REACTION_REMOVE_ALL" -> Some Message_reaction_remove_all
        | "MESSAGE_REACTION_REMOVE_EMOJI" ->
            Some Message_reaction_remove_emoji
        | "MESSAGE_POLL_VOTE_ADD" -> Some Message_poll_vote_add
        | "MESSAGE_POLL_VOTE_REMOVE" -> Some Message_poll_vote_remove
        | "PRESENCE_UPDATE" -> Some Presence_update
        | "STAGE_INSTANCE_CREATE" -> Some Stage_instance_create
        | "STAGE_INSTANCE_UPDATE" -> Some Stage_instance_update
        | "STAGE_INSTANCE_DELETE" -> Some Stage_instance_delete
        | "TYPING_START" -> Some Typing_start
        | "USER_UPDATE" -> Some User_update
        | "VOICE_CHANNEL_EFFECT_SEND" -> Some Voice_channel_effect_send
        | "VOICE_STATE_UPDATE" -> Some Voice_state_update
        | "VOICE_SERVER_UPDATE" -> Some Voice_server_update
        | "WEBHOOKS_UPDATE" -> Some Webhooks_update
        | _ -> None

    let to_string = function
        | Ready -> "READY"
        | Resumed -> "RESUMED"
        | Application_command_permissions_update ->
            "APPLICATION_COMMAND_PERMISSIONS_UPDATE"
        | Auto_moderation_rule_create -> "AUTO_MODERATION_RULE_CREATE"
        | Auto_moderation_rule_update -> "AUTO_MODERATION_RULE_UPDATE"
        | Auto_moderation_rule_delete -> "AUTO_MODERATION_RULE_DELETE"
        | Auto_moderation_action_execution ->
            "AUTO_MODERATION_ACTION_EXECUTION"
        | Channel_create -> "CHANNEL_CREATE"
        | Channel_update -> "CHANNEL_UPDATE"
        | Channel_delete -> "CHANNEL_DELETE"
        | Channel_info -> "CHANNEL_INFO"
        | Channel_pins_update -> "CHANNEL_PINS_UPDATE"
        | Thread_create -> "THREAD_CREATE"
        | Thread_update -> "THREAD_UPDATE"
        | Thread_delete -> "THREAD_DELETE"
        | Thread_list_sync -> "THREAD_LIST_SYNC"
        | Thread_member_update -> "THREAD_MEMBER_UPDATE"
        | Thread_members_update -> "THREAD_MEMBERS_UPDATE"
        | Voice_channel_status_update -> "VOICE_CHANNEL_STATUS_UPDATE"
        | Voice_channel_start_time_update ->
            "VOICE_CHANNEL_START_TIME_UPDATE"
        | Entitlement_create -> "ENTITLEMENT_CREATE"
        | Entitlement_update -> "ENTITLEMENT_UPDATE"
        | Entitlement_delete -> "ENTITLEMENT_DELETE"
        | Subscription_create -> "SUBSCRIPTION_CREATE"
        | Subscription_update -> "SUBSCRIPTION_UPDATE"
        | Subscription_delete -> "SUBSCRIPTION_DELETE"
        | Guild_create -> "GUILD_CREATE"
        | Guild_update -> "GUILD_UPDATE"
        | Guild_delete -> "GUILD_DELETE"
        | Guild_audit_log_entry_create -> "GUILD_AUDIT_LOG_ENTRY_CREATE"
        | Guild_ban_add -> "GUILD_BAN_ADD"
        | Guild_ban_remove -> "GUILD_BAN_REMOVE"
        | Guild_emojis_update -> "GUILD_EMOJIS_UPDATE"
        | Guild_stickers_update -> "GUILD_STICKERS_UPDATE"
        | Guild_integrations_update -> "GUILD_INTEGRATIONS_UPDATE"
        | Guild_member_add -> "GUILD_MEMBER_ADD"
        | Guild_member_remove -> "GUILD_MEMBER_REMOVE"
        | Guild_member_update -> "GUILD_MEMBER_UPDATE"
        | Guild_members_chunk -> "GUILD_MEMBERS_CHUNK"
        | Guild_role_create -> "GUILD_ROLE_CREATE"
        | Guild_role_update -> "GUILD_ROLE_UPDATE"
        | Guild_role_delete -> "GUILD_ROLE_DELETE"
        | Guild_scheduled_event_create -> "GUILD_SCHEDULED_EVENT_CREATE"
        | Guild_scheduled_event_update -> "GUILD_SCHEDULED_EVENT_UPDATE"
        | Guild_scheduled_event_delete -> "GUILD_SCHEDULED_EVENT_DELETE"
        | Guild_scheduled_event_user_add -> "GUILD_SCHEDULED_EVENT_USER_ADD"
        | Guild_scheduled_event_user_remove ->
            "GUILD_SCHEDULED_EVENT_USER_REMOVE"
        | Guild_soundboard_sound_create -> "GUILD_SOUNDBOARD_SOUND_CREATE"
        | Guild_soundboard_sound_update -> "GUILD_SOUNDBOARD_SOUND_UPDATE"
        | Guild_soundboard_sound_delete -> "GUILD_SOUNDBOARD_SOUND_DELETE"
        | Guild_soundboard_sounds_update -> "GUILD_SOUNDBOARD_SOUNDS_UPDATE"
        | Soundboard_sounds -> "SOUNDBOARD_SOUNDS"
        | Integration_create -> "INTEGRATION_CREATE"
        | Integration_update -> "INTEGRATION_UPDATE"
        | Integration_delete -> "INTEGRATION_DELETE"
        | Interaction_create -> "INTERACTION_CREATE"
        | Invite_create -> "INVITE_CREATE"
        | Invite_delete -> "INVITE_DELETE"
        | Message_create -> "MESSAGE_CREATE"
        | Message_update -> "MESSAGE_UPDATE"
        | Message_delete -> "MESSAGE_DELETE"
        | Message_delete_bulk -> "MESSAGE_DELETE_BULK"
        | Message_reaction_add -> "MESSAGE_REACTION_ADD"
        | Message_reaction_remove -> "MESSAGE_REACTION_REMOVE"
        | Message_reaction_remove_all -> "MESSAGE_REACTION_REMOVE_ALL"
        | Message_reaction_remove_emoji -> "MESSAGE_REACTION_REMOVE_EMOJI"
        | Message_poll_vote_add -> "MESSAGE_POLL_VOTE_ADD"
        | Message_poll_vote_remove -> "MESSAGE_POLL_VOTE_REMOVE"
        | Presence_update -> "PRESENCE_UPDATE"
        | Stage_instance_create -> "STAGE_INSTANCE_CREATE"
        | Stage_instance_update -> "STAGE_INSTANCE_UPDATE"
        | Stage_instance_delete -> "STAGE_INSTANCE_DELETE"
        | Typing_start -> "TYPING_START"
        | User_update -> "USER_UPDATE"
        | Voice_channel_effect_send -> "VOICE_CHANNEL_EFFECT_SEND"
        | Voice_state_update -> "VOICE_STATE_UPDATE"
        | Voice_server_update -> "VOICE_SERVER_UPDATE"
        | Webhooks_update -> "WEBHOOKS_UPDATE"

end : Event)
