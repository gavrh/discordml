module type Client = sig
  type t

  val token : t -> string option
  val create : int -> t
  val start : env:Eio_unix.Stdenv.base -> t -> string -> unit
  val guild : t -> string -> Guild.t option
  val channel : t -> string -> Channel.t option
  val member : t -> guild_id:string -> user_id:string -> Member.t option
  val presence : t -> guild_id:string -> user_id:string -> Presence.t option
  val message : t -> channel_id:string -> message_id:string -> Message.t option
  val user_by_id : t -> string -> User.t option
  val role : t -> guild_id:string -> role_id:string -> Role.t option
  val reaction : t -> message_id:string -> emoji:string -> Reaction.t option

  val thread_member :
    t -> thread_id:string -> user_id:string -> Thread_member.t option

  val scheduled_event :
    t -> guild_id:string -> event_id:string -> Guild_scheduled_event.t option

  val stage_instance :
    t -> guild_id:string -> channel_id:string -> Stage_instance.t option

  val auto_moderation_rule :
    t -> guild_id:string -> rule_id:string -> Auto_moderation.t option

  val user : t -> User.t option
  val rest : t -> Rest.t
  val guilds : t -> Guild.t list
  val channels : t -> guild_id:string -> Channel.t list
  val members : t -> guild_id:string -> Member.t list
  val messages : t -> channel_id:string -> Message.t list
  val fetch_channel : t -> string -> Channel.t
  val fetch_guild : t -> string -> Guild.t
  val fetch_member : t -> guild_id:string -> user_id:string -> Member.t
  val on_ready : t -> (t -> unit) -> unit
  val on_resumed : t -> (t -> unit) -> unit
  val on_application_command_permissions_update : t -> (t -> unit) -> unit
  val on_auto_moderation_rule_create : t -> (t -> unit) -> unit
  val on_auto_moderation_rule_update : t -> (t -> unit) -> unit
  val on_auto_moderation_rule_delete : t -> (t -> unit) -> unit
  val on_auto_moderation_action_execution : t -> (t -> unit) -> unit
  val on_channel_create : t -> (t -> Channel.t -> unit) -> unit

  val on_channel_update :
    t -> (t -> Channel.t option -> Channel.t -> unit) -> unit

  val on_channel_delete :
    t -> (t -> Event_payload.Channel_delete.t -> unit) -> unit

  val on_channel_info : t -> (t -> unit) -> unit

  val on_channel_pins_update :
    t -> (t -> Event_payload.Channel_pins_update.t -> unit) -> unit

  val on_thread_create : t -> (t -> Channel.t -> bool -> unit) -> unit

  val on_thread_update :
    t -> (t -> Channel.t option -> Channel.t -> unit) -> unit

  val on_thread_delete :
    t -> (t -> Event_payload.Channel_delete.t -> unit) -> unit

  val on_thread_list_sync :
    t -> (t -> Event_payload.Thread_list_sync.t -> unit) -> unit

  val on_thread_member_update :
    t -> (t -> Thread_member.t option -> Thread_member.t -> unit) -> unit

  val on_thread_members_update :
    t -> (t -> Event_payload.Thread_members_update.t -> unit) -> unit

  val on_voice_channel_status_update : t -> (t -> unit) -> unit
  val on_voice_channel_start_time_update : t -> (t -> unit) -> unit
  val on_entitlement_create : t -> (t -> unit) -> unit
  val on_entitlement_update : t -> (t -> unit) -> unit
  val on_entitlement_delete : t -> (t -> unit) -> unit
  val on_subscription_create : t -> (t -> unit) -> unit
  val on_subscription_update : t -> (t -> unit) -> unit
  val on_subscription_delete : t -> (t -> unit) -> unit
  val on_guild_create : t -> (t -> Guild.t -> unit) -> unit
  val on_guild_update : t -> (t -> Guild.t option -> Guild.t -> unit) -> unit
  val on_guild_delete : t -> (t -> Event_payload.Guild_delete.t -> unit) -> unit
  val on_guild_audit_log_entry_create : t -> (t -> unit) -> unit
  val on_guild_ban_add : t -> (t -> string -> Guild_ban.t -> unit) -> unit
  val on_guild_ban_remove : t -> (t -> string -> Guild_ban.t -> unit) -> unit

  val on_guild_emojis_update :
    t -> (t -> string -> Emoji.t list -> Emoji.t list -> unit) -> unit

  val on_guild_stickers_update :
    t -> (t -> string -> Sticker.t list -> Sticker.t list -> unit) -> unit

  val on_guild_integrations_update :
    t -> (t -> string -> Guild.t option -> unit) -> unit

  val on_guild_member_add : t -> (t -> string -> Member.t -> unit) -> unit

  val on_guild_member_remove :
    t -> (t -> Event_payload.Member_remove.t -> unit) -> unit

  val on_guild_member_update :
    t -> (t -> string -> Member.t option -> Member.t -> unit) -> unit

  val on_guild_members_chunk :
    t -> (t -> Event_payload.Guild_members_chunk.t -> unit) -> unit

  val on_guild_role_create : t -> (t -> string -> Role.t -> unit) -> unit

  val on_guild_role_update :
    t -> (t -> string -> Role.t option -> Role.t -> unit) -> unit

  val on_guild_role_delete :
    t -> (t -> Event_payload.Role_delete.t -> unit) -> unit

  val on_guild_scheduled_event_create : t -> (t -> unit) -> unit
  val on_guild_scheduled_event_update : t -> (t -> unit) -> unit
  val on_guild_scheduled_event_delete : t -> (t -> unit) -> unit
  val on_guild_scheduled_event_user_add : t -> (t -> unit) -> unit
  val on_guild_scheduled_event_user_remove : t -> (t -> unit) -> unit
  val on_guild_soundboard_sound_create : t -> (t -> unit) -> unit
  val on_guild_soundboard_sound_update : t -> (t -> unit) -> unit
  val on_guild_soundboard_sound_delete : t -> (t -> unit) -> unit
  val on_guild_soundboard_sounds_update : t -> (t -> unit) -> unit
  val on_soundboard_sounds : t -> (t -> unit) -> unit
  val on_integration_create : t -> (t -> unit) -> unit
  val on_integration_update : t -> (t -> unit) -> unit
  val on_integration_delete : t -> (t -> unit) -> unit
  val on_interaction_create : t -> (t -> unit) -> unit
  val on_invite_create : t -> (t -> Invite.t -> unit) -> unit
  val on_invite_delete : t -> (t -> Invite.t -> unit) -> unit
  val on_message : t -> (t -> Message.t -> unit) -> unit

  val on_message_update :
    t -> (t -> Message.t option -> Message_update.t -> unit) -> unit

  val on_message_delete :
    t -> (t -> Event_payload.Message_delete.t -> unit) -> unit

  val on_message_delete_bulk :
    t -> (t -> Event_payload.Message_delete_bulk.t -> unit) -> unit

  val on_message_reaction_add :
    t -> (t -> Event_payload.Message_reaction.t -> unit) -> unit

  val on_message_reaction_remove :
    t -> (t -> Event_payload.Message_reaction.t -> unit) -> unit

  val on_message_reaction_remove_all :
    t -> (t -> Event_payload.Message_reaction_remove_all.t -> unit) -> unit

  val on_message_reaction_remove_emoji :
    t -> (t -> Event_payload.Message_reaction_remove_emoji.t -> unit) -> unit

  val on_message_poll_vote_add :
    t -> (t -> Event_payload.Message_poll_vote.t -> unit) -> unit

  val on_message_poll_vote_remove :
    t -> (t -> Event_payload.Message_poll_vote.t -> unit) -> unit

  val on_presence_update :
    t -> (t -> Presence.t option -> Presence.t -> unit) -> unit

  val on_stage_instance_create : t -> (t -> unit) -> unit
  val on_stage_instance_update : t -> (t -> unit) -> unit
  val on_stage_instance_delete : t -> (t -> unit) -> unit
  val on_typing_start : t -> (t -> Typing.t -> unit) -> unit
  val on_user_update : t -> (t -> User.t option -> User.t -> unit) -> unit
  val on_voice_channel_effect_send : t -> (t -> unit) -> unit
  val on_voice_state_update : t -> (t -> unit) -> unit
  val on_voice_server_update : t -> (t -> unit) -> unit
  val on_webhooks_update : t -> (t -> unit) -> unit
  val show : t -> string
end

include (
  struct
    type snapshot = {
      guild : Guild.t option;
      channel : Channel.t option;
      member : Member.t option;
      presence : Presence.t option;
      role : Role.t option;
      user : User.t option;
      thread_member : Thread_member.t option;
      thread_members : Thread_member.t list;
      emojis : Emoji.t list;
      stickers : Sticker.t list;
    }

    type t = {
      mutable token : string option;
      intents : int;
      guilds : (string, Guild.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      guilds_mutex : Eio.Mutex.t; [@opaque]
      channels : (string, Channel.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      channels_mutex : Eio.Mutex.t; [@opaque]
      members : (string * string, Member.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      members_mutex : Eio.Mutex.t; [@opaque]
      presences : (string * string, Presence.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      presences_mutex : Eio.Mutex.t; [@opaque]
      messages : (string * string, Message.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      messages_mutex : Eio.Mutex.t; [@opaque]
      users : (string, User.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      users_mutex : Eio.Mutex.t; [@opaque]
      roles : (string * string, Role.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      roles_mutex : Eio.Mutex.t; [@opaque]
      reactions : (string * string, Reaction.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      reactions_mutex : Eio.Mutex.t; [@opaque]
      thread_members : (string * string, Thread_member.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      thread_members_mutex : Eio.Mutex.t; [@opaque]
      scheduled_events : (string * string, Guild_scheduled_event.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      scheduled_events_mutex : Eio.Mutex.t; [@opaque]
      stage_instances : (string * string, Stage_instance.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      stage_instances_mutex : Eio.Mutex.t; [@opaque]
      auto_moderation_rules : (string * string, Auto_moderation.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      auto_moderation_rules_mutex : Eio.Mutex.t; [@opaque]
      decode_errors : string list Atomic.t; [@opaque]
      shards : (int, Discord_private.P_shard.t) Hashtbl.t;
          [@printer
            fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)]
      shards_mutex : Eio.Mutex.t; [@opaque]
      handlers :
        ( Discord_private.P_event.t,
          (t -> snapshot -> Yojson.Safe.t -> unit) list )
        Hashtbl.t
        Atomic.t;
          [@opaque]
      message_handlers : (t -> Message.t -> unit) list Atomic.t; [@opaque]
      message_update_handlers :
        (t -> Message.t option -> Message_update.t -> unit) list Atomic.t;
          [@opaque]
      message_delete_handlers :
        (t -> Event_payload.Message_delete.t -> unit) list Atomic.t;
          [@opaque]
      message_delete_bulk_handlers :
        (t -> Event_payload.Message_delete_bulk.t -> unit) list Atomic.t;
          [@opaque]
      message_reaction_add_handlers :
        (t -> Event_payload.Message_reaction.t -> unit) list Atomic.t;
          [@opaque]
      message_reaction_remove_handlers :
        (t -> Event_payload.Message_reaction.t -> unit) list Atomic.t;
          [@opaque]
      message_reaction_remove_all_handlers :
        (t -> Event_payload.Message_reaction_remove_all.t -> unit) list Atomic.t;
          [@opaque]
      message_reaction_remove_emoji_handlers :
        (t -> Event_payload.Message_reaction_remove_emoji.t -> unit) list
        Atomic.t;
          [@opaque]
      mutable user : User.t option;
          [@printer
            fun fmt u ->
              match u with
              | Some u -> Format.pp_print_string fmt (User.show u)
              | None -> Format.pp_print_string fmt "None"]
      mutable rest : Rest.t option; [@opaque]
    }
    [@@deriving show]

    let token (c : t) : string option = c.token

    let guild (c : t) (gid : string) : Guild.t option =
      Eio.Mutex.use_ro c.guilds_mutex (fun () -> Hashtbl.find_opt c.guilds gid)

    let channel (c : t) (cid : string) : Channel.t option =
      Eio.Mutex.use_ro c.channels_mutex (fun () ->
          Hashtbl.find_opt c.channels cid)

    let member (c : t) ~(guild_id : string) ~(user_id : string) :
        Member.t option =
      Eio.Mutex.use_ro c.members_mutex (fun () ->
          Hashtbl.find_opt c.members (guild_id, user_id))

    let presence (c : t) ~(guild_id : string) ~(user_id : string) :
        Presence.t option =
      Eio.Mutex.use_ro c.presences_mutex (fun () ->
          Hashtbl.find_opt c.presences (guild_id, user_id))

    let message (c : t) ~(channel_id : string) ~(message_id : string) :
        Message.t option =
      Eio.Mutex.use_ro c.messages_mutex (fun () ->
          Hashtbl.find_opt c.messages (channel_id, message_id))

    let user_by_id (c : t) (id : string) : User.t option =
      Eio.Mutex.use_ro c.users_mutex (fun () -> Hashtbl.find_opt c.users id)

    let role (c : t) ~(guild_id : string) ~(role_id : string) : Role.t option =
      Eio.Mutex.use_ro c.roles_mutex (fun () ->
          Hashtbl.find_opt c.roles (guild_id, role_id))

    let reaction (c : t) ~(message_id : string) ~(emoji : string) :
        Reaction.t option =
      Eio.Mutex.use_ro c.reactions_mutex (fun () ->
          Hashtbl.find_opt c.reactions (message_id, emoji))

    let thread_member (c : t) ~(thread_id : string) ~(user_id : string) :
        Thread_member.t option =
      Eio.Mutex.use_ro c.thread_members_mutex (fun () ->
          Hashtbl.find_opt c.thread_members (thread_id, user_id))

    let scheduled_event (c : t) ~(guild_id : string) ~(event_id : string) :
        Guild_scheduled_event.t option =
      Eio.Mutex.use_ro c.scheduled_events_mutex (fun () ->
          Hashtbl.find_opt c.scheduled_events (guild_id, event_id))

    let stage_instance (c : t) ~(guild_id : string) ~(channel_id : string) :
        Stage_instance.t option =
      Eio.Mutex.use_ro c.stage_instances_mutex (fun () ->
          Hashtbl.find_opt c.stage_instances (guild_id, channel_id))

    let auto_moderation_rule (c : t) ~(guild_id : string) ~(rule_id : string) :
        Auto_moderation.t option =
      Eio.Mutex.use_ro c.auto_moderation_rules_mutex (fun () ->
          Hashtbl.find_opt c.auto_moderation_rules (guild_id, rule_id))

    let user (c : t) : User.t option = c.user

    let rest (c : t) : Rest.t =
      match c.rest with Some r -> r | None -> failwith "client: not started"

    let guilds (c : t) : Guild.t list =
      Eio.Mutex.use_ro c.guilds_mutex (fun () ->
          Hashtbl.fold (fun _ g acc -> g :: acc) c.guilds [])

    let channels (c : t) ~(guild_id : string) : Channel.t list =
      Eio.Mutex.use_ro c.channels_mutex (fun () ->
          Hashtbl.fold
            (fun _ ch acc ->
              match Channel.guild_id ch with
              | Some g when g = guild_id -> ch :: acc
              | _ -> acc)
            c.channels [])

    let members (c : t) ~(guild_id : string) : Member.t list =
      Eio.Mutex.use_ro c.members_mutex (fun () ->
          Hashtbl.fold
            (fun (g, _) m acc -> if g = guild_id then m :: acc else acc)
            c.members [])

    let messages (c : t) ~(channel_id : string) : Message.t list =
      Eio.Mutex.use_ro c.messages_mutex (fun () ->
          Hashtbl.fold
            (fun (cid, _) m acc -> if cid = channel_id then m :: acc else acc)
            c.messages [])

    let log_decode_error (c : t) (name : string) (msg : string) : unit =
      let rec log () =
        let logged = Atomic.get c.decode_errors in
        if not (List.mem name logged) then
          if Atomic.compare_and_set c.decode_errors logged (name :: logged) then
            prerr_endline (name ^ " decode failed: " ^ msg)
          else log ()
      in
      log ()

    let put_channel (c : t) (ch : Channel.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.channels_mutex (fun () ->
          Hashtbl.replace c.channels (Channel.id ch) ch)

    let put_guild_channels (c : t) (name : string) (guild_id : string)
        (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      match json |> member "channels" with
      | `List channels ->
          List.iter
            (fun channel ->
              let channel =
                match channel with
                | `Assoc fields ->
                    `Assoc
                      (("guild_id", `String guild_id)
                      :: List.remove_assoc "guild_id" fields)
                | _ -> channel
              in
              match Channel.of_yojson channel with
              | Ok ch -> put_channel c ch
              | Error msg -> log_decode_error c name msg)
            channels
      | _ -> ()

    let remove_channel (c : t) (cid : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.channels_mutex (fun () ->
          Hashtbl.remove c.channels cid)

    let put_member (c : t) (guild_id : string) (user_id : string) (m : Member.t)
        : unit =
      Eio.Mutex.use_rw ~protect:true c.members_mutex (fun () ->
          Hashtbl.replace c.members (guild_id, user_id) m)

    let remove_member (c : t) (guild_id : string) (user_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.members_mutex (fun () ->
          Hashtbl.remove c.members (guild_id, user_id))

    let put_presence (c : t) (guild_id : string) (user_id : string)
        (p : Presence.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.presences_mutex (fun () ->
          Hashtbl.replace c.presences (guild_id, user_id) p)

    let put_message (c : t) (m : Message.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.messages_mutex (fun () ->
          Hashtbl.replace c.messages (Message.channel_id m, Message.id m) m)

    let remove_message (c : t) (channel_id : string) (message_id : string) :
        unit =
      Eio.Mutex.use_rw ~protect:true c.messages_mutex (fun () ->
          Hashtbl.remove c.messages (channel_id, message_id))

    let put_user (c : t) (u : User.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.users_mutex (fun () ->
          Hashtbl.replace c.users (User.id u) u)

    let put_role (c : t) (guild_id : string) (r : Role.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.roles_mutex (fun () ->
          Hashtbl.replace c.roles (guild_id, Role.id r) r)

    let remove_role (c : t) (guild_id : string) (role_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.roles_mutex (fun () ->
          Hashtbl.remove c.roles (guild_id, role_id))

    let put_reaction (c : t) (r : Reaction.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.reactions_mutex (fun () ->
          Hashtbl.replace c.reactions
            (Reaction.message_id r, Reaction.emoji_identifier r)
            r)

    let remove_reaction (c : t) ~(message_id : string) ~(emoji : string) : unit
        =
      Eio.Mutex.use_rw ~protect:true c.reactions_mutex (fun () ->
          Hashtbl.remove c.reactions (message_id, emoji))

    let drop_reactions (c : t) (message_ids : string list) : unit =
      Eio.Mutex.use_rw ~protect:true c.reactions_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (message_id, _) r ->
              if List.mem message_id message_ids then None else Some r)
            c.reactions)

    let refresh_message_reactions (c : t) (m : Message.t) : unit =
      drop_reactions c [ Message.id m ];
      List.iter (put_reaction c) (Message.reactions m)

    let put_thread_member (c : t) (thread_id : string) (tm : Thread_member.t) :
        unit =
      match Thread_member.user_id tm with
      | Some user_id ->
          Eio.Mutex.use_rw ~protect:true c.thread_members_mutex (fun () ->
              Hashtbl.replace c.thread_members (thread_id, user_id) tm)
      | None -> ()

    let remove_thread_member (c : t) (thread_id : string) (user_id : string) :
        unit =
      Eio.Mutex.use_rw ~protect:true c.thread_members_mutex (fun () ->
          Hashtbl.remove c.thread_members (thread_id, user_id))

    let put_scheduled_event (c : t) (e : Guild_scheduled_event.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.scheduled_events_mutex (fun () ->
          Hashtbl.replace c.scheduled_events
            (Guild_scheduled_event.guild_id e, Guild_scheduled_event.id e)
            e)

    let remove_scheduled_event (c : t) (guild_id : string) (event_id : string) :
        unit =
      Eio.Mutex.use_rw ~protect:true c.scheduled_events_mutex (fun () ->
          Hashtbl.remove c.scheduled_events (guild_id, event_id))

    let put_stage_instance (c : t) (s : Stage_instance.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.stage_instances_mutex (fun () ->
          Hashtbl.replace c.stage_instances
            (Stage_instance.guild_id s, Stage_instance.channel_id s)
            s)

    let remove_stage_instance (c : t) (guild_id : string) (channel_id : string)
        : unit =
      Eio.Mutex.use_rw ~protect:true c.stage_instances_mutex (fun () ->
          Hashtbl.remove c.stage_instances (guild_id, channel_id))

    let put_auto_moderation_rule (c : t) (r : Auto_moderation.t) : unit =
      Eio.Mutex.use_rw ~protect:true c.auto_moderation_rules_mutex (fun () ->
          Hashtbl.replace c.auto_moderation_rules
            (Auto_moderation.guild_id r, Auto_moderation.id r)
            r)

    let remove_auto_moderation_rule (c : t) (guild_id : string)
        (rule_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.auto_moderation_rules_mutex (fun () ->
          Hashtbl.remove c.auto_moderation_rules (guild_id, rule_id))

    let fetch_channel (c : t) (id : string) : Channel.t =
      match channel c id with
      | Some ch -> ch
      | None ->
          let ch = Channel.fetch (rest c) id in
          put_channel c ch;
          ch

    let fetch_guild (c : t) (id : string) : Guild.t =
      match guild c id with
      | Some g -> g
      | None ->
          let g = Guild.fetch (rest c) id in
          Eio.Mutex.use_rw ~protect:true c.guilds_mutex (fun () ->
              Hashtbl.replace c.guilds (Guild.id g) g);
          g

    let fetch_member (c : t) ~(guild_id : string) ~(user_id : string) : Member.t
        =
      match member c ~guild_id ~user_id with
      | Some m -> m
      | None ->
          let m = Member.fetch (rest c) ~guild_id ~user_id in
          put_member c guild_id (User.id (Member.user m)) m;
          m

    let channel_ids_for_guild (c : t) (guild_id : string) : string list =
      Eio.Mutex.use_ro c.channels_mutex (fun () ->
          Hashtbl.fold
            (fun channel_id ch acc ->
              match Channel.guild_id ch with
              | Some g when g = guild_id -> channel_id :: acc
              | _ -> acc)
            c.channels [])

    let drop_guild_channels (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.channels_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun _ ch ->
              match Channel.guild_id ch with
              | Some g when g = guild_id -> None
              | _ -> Some ch)
            c.channels)

    let drop_guild_members (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.members_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) m -> if g = guild_id then None else Some m)
            c.members)

    let drop_guild_presences (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.presences_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) p -> if g = guild_id then None else Some p)
            c.presences)

    let drop_guild_roles (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.roles_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) r -> if g = guild_id then None else Some r)
            c.roles)

    let drop_guild_scheduled_events (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.scheduled_events_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) e -> if g = guild_id then None else Some e)
            c.scheduled_events)

    let drop_guild_stage_instances (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.stage_instances_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) s -> if g = guild_id then None else Some s)
            c.stage_instances)

    let drop_guild_auto_moderation_rules (c : t) (guild_id : string) : unit =
      Eio.Mutex.use_rw ~protect:true c.auto_moderation_rules_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (g, _) r -> if g = guild_id then None else Some r)
            c.auto_moderation_rules)

    let drop_guild_thread_members (c : t) (thread_ids : string list) : unit =
      Eio.Mutex.use_rw ~protect:true c.thread_members_mutex (fun () ->
          Hashtbl.filter_map_inplace
            (fun (thread_id, _) tm ->
              if List.mem thread_id thread_ids then None else Some tm)
            c.thread_members)

    let drop_channel_messages (c : t) (channel_id : string) : string list =
      Eio.Mutex.use_rw ~protect:true c.messages_mutex (fun () ->
          let message_ids =
            Hashtbl.fold
              (fun (cid, message_id) _ acc ->
                if cid = channel_id then message_id :: acc else acc)
              c.messages []
          in
          List.iter
            (fun message_id ->
              Hashtbl.remove c.messages (channel_id, message_id))
            message_ids;
          message_ids)

    let drop_guild_messages (c : t) (channel_ids : string list) : string list =
      Eio.Mutex.use_rw ~protect:true c.messages_mutex (fun () ->
          let message_ids =
            Hashtbl.fold
              (fun (channel_id, message_id) _ acc ->
                if List.mem channel_id channel_ids then message_id :: acc
                else acc)
              c.messages []
          in
          Hashtbl.filter_map_inplace
            (fun (channel_id, _) m ->
              if List.mem channel_id channel_ids then None else Some m)
            c.messages;
          message_ids)

    let string_list (json : Yojson.Safe.t) : string list =
      match json with
      | `List l ->
          List.filter_map (function `String s -> Some s | _ -> None) l
      | _ -> []

    let cache_event (c : t) (event : Discord_private.P_event.t)
        (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      let name = Discord_private.P_event.to_string event in
      let decode of_yojson on_ok =
        match of_yojson json with
        | Ok v -> on_ok v
        | Error msg -> log_decode_error c name msg
      in
      let cache_guild (g : Guild.t) : unit =
        let guild_id = Guild.id g in
        Eio.Mutex.use_rw ~protect:true c.guilds_mutex (fun () ->
            Hashtbl.replace c.guilds guild_id g);
        put_guild_channels c name guild_id json;
        List.iter (put_channel c) (Guild.threads g);
        List.iter (put_role c guild_id) (Guild.roles g);
        List.iter (put_scheduled_event c) (Guild.scheduled_events g);
        List.iter (put_stage_instance c) (Guild.stage_instances g);
        List.iter
          (fun m ->
            put_member c guild_id (User.id (Member.user m)) m;
            put_user c (Member.user m))
          (Guild.members g);
        List.iter
          (fun p ->
            put_presence c guild_id (User.id (Presence.user p)) p;
            put_user c (Presence.user p))
          (Guild.presences g)
      in
      match event with
      | Discord_private.P_event.Ready -> (
          match User.of_yojson (json |> member "user") with
          | Ok u -> put_user c u
          | Error msg -> log_decode_error c name msg)
      | Discord_private.P_event.Guild_create
        when json |> member "unavailable" |> to_bool_option = Some true ->
          ()
      | Discord_private.P_event.Guild_create ->
          decode Guild.of_yojson cache_guild
      | Discord_private.P_event.Guild_update -> (
          match json |> member "id" |> to_string_option with
          | Some guild_id -> (
              match guild c guild_id with
              | Some old -> decode (Guild.merge old) cache_guild
              | None -> decode Guild.of_yojson cache_guild)
          | None -> ())
      | Discord_private.P_event.Guild_delete -> (
          match json |> member "id" |> to_string_option with
          | Some guild_id ->
              let unavailable =
                json |> member "unavailable" |> to_bool_option
                |> Option.value ~default:false
              in
              if not unavailable then begin
                let channel_ids = channel_ids_for_guild c guild_id in
                Eio.Mutex.use_rw ~protect:true c.guilds_mutex (fun () ->
                    Hashtbl.remove c.guilds guild_id);
                drop_guild_channels c guild_id;
                drop_guild_members c guild_id;
                drop_guild_presences c guild_id;
                drop_guild_roles c guild_id;
                drop_guild_scheduled_events c guild_id;
                drop_guild_stage_instances c guild_id;
                drop_guild_auto_moderation_rules c guild_id;
                drop_guild_thread_members c channel_ids;
                let message_ids = drop_guild_messages c channel_ids in
                drop_reactions c message_ids
              end
          | None -> ())
      | Discord_private.P_event.Channel_create
      | Discord_private.P_event.Channel_update ->
          decode Channel.of_yojson (put_channel c)
      | Discord_private.P_event.Thread_create ->
          decode Channel.of_yojson (fun ch ->
              put_channel c ch;
              match json |> member "member" with
              | `Null -> ()
              | member_json -> (
                  match Thread_member.of_yojson member_json with
                  | Ok tm -> put_thread_member c (Channel.id ch) tm
                  | Error msg -> log_decode_error c name msg))
      | Discord_private.P_event.Thread_update ->
          decode Channel.of_yojson (put_channel c)
      | Discord_private.P_event.Channel_delete
      | Discord_private.P_event.Thread_delete -> (
          match json |> member "id" |> to_string_option with
          | Some cid ->
              remove_channel c cid;
              drop_guild_thread_members c [ cid ];
              let message_ids = drop_channel_messages c cid in
              drop_reactions c message_ids
          | None -> ())
      | Discord_private.P_event.Guild_member_add
      | Discord_private.P_event.Guild_member_update -> (
          match Member.of_yojson json with
          | Ok m -> (
              match json |> member "guild_id" |> to_string_option with
              | Some guild_id ->
                  put_member c guild_id (User.id (Member.user m)) m;
                  put_user c (Member.user m)
              | None -> ())
          | Error msg -> log_decode_error c name msg)
      | Discord_private.P_event.Guild_member_remove -> (
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id -> (
              match
                json |> member "user" |> member "id" |> to_string_option
              with
              | Some user_id -> remove_member c guild_id user_id
              | None -> ())
          | None -> ())
      | Discord_private.P_event.Presence_update -> (
          match Presence.of_yojson json with
          | Ok p ->
              (match Presence.guild_id p with
              | Some guild_id ->
                  put_presence c guild_id (User.id (Presence.user p)) p
              | None -> ());
              put_user c (Presence.user p)
          | Error msg -> log_decode_error c name msg)
      | Discord_private.P_event.Message_update -> (
          match Message_update.of_yojson json with
          | Error msg -> log_decode_error c name msg
          | Ok update -> (
              match
                message c
                  ~channel_id:(Message_update.channel_id update)
                  ~message_id:(Message_update.id update)
              with
              | Some cached -> (
                  let merged = P_message_update.apply cached update in
                  put_message c merged;
                  match Message_update.reactions update with
                  | None -> ()
                  | Some _ -> refresh_message_reactions c merged)
              | None -> ()))
      | Discord_private.P_event.Message_delete -> (
          match
            ( json |> member "channel_id" |> to_string_option,
              json |> member "id" |> to_string_option )
          with
          | Some channel_id, Some message_id ->
              remove_message c channel_id message_id;
              drop_reactions c [ message_id ]
          | _ -> ())
      | Discord_private.P_event.Message_delete_bulk -> (
          match json |> member "channel_id" |> to_string_option with
          | Some channel_id -> (
              match json |> member "ids" with
              | `List ids ->
                  let message_ids =
                    List.filter_map
                      (function
                        | `String message_id -> Some message_id | _ -> None)
                      ids
                  in
                  List.iter (remove_message c channel_id) message_ids;
                  drop_reactions c message_ids
              | _ -> ())
          | None -> ())
      | Discord_private.P_event.Guild_role_create
      | Discord_private.P_event.Guild_role_update -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "role" )
          with
          | Some guild_id, role_json -> (
              match Role.of_yojson role_json with
              | Ok r -> put_role c guild_id r
              | Error msg -> log_decode_error c name msg)
          | _ -> ())
      | Discord_private.P_event.Guild_role_delete -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "role_id" |> to_string_option )
          with
          | Some guild_id, Some role_id -> remove_role c guild_id role_id
          | _ -> ())
      | Discord_private.P_event.Guild_scheduled_event_create
      | Discord_private.P_event.Guild_scheduled_event_update ->
          decode Guild_scheduled_event.of_yojson (put_scheduled_event c)
      | Discord_private.P_event.Guild_scheduled_event_delete -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "id" |> to_string_option )
          with
          | Some guild_id, Some event_id ->
              remove_scheduled_event c guild_id event_id
          | _ -> ())
      | Discord_private.P_event.Stage_instance_create
      | Discord_private.P_event.Stage_instance_update ->
          decode Stage_instance.of_yojson (put_stage_instance c)
      | Discord_private.P_event.Stage_instance_delete -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "channel_id" |> to_string_option )
          with
          | Some guild_id, Some channel_id ->
              remove_stage_instance c guild_id channel_id
          | _ -> ())
      | Discord_private.P_event.Auto_moderation_rule_create
      | Discord_private.P_event.Auto_moderation_rule_update ->
          decode Auto_moderation.of_yojson (put_auto_moderation_rule c)
      | Discord_private.P_event.Auto_moderation_rule_delete -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "id" |> to_string_option )
          with
          | Some guild_id, Some rule_id ->
              remove_auto_moderation_rule c guild_id rule_id
          | _ -> ())
      | Discord_private.P_event.Thread_member_update -> (
          match Thread_member.of_yojson json with
          | Ok tm -> (
              match Thread_member.id tm with
              | Some thread_id -> put_thread_member c thread_id tm
              | None -> ())
          | Error msg -> log_decode_error c name msg)
      | Discord_private.P_event.Thread_members_update -> (
          match json |> member "id" |> to_string_option with
          | Some thread_id -> (
              let cache_members field =
                match json |> member field with
                | `List members ->
                    List.iter
                      (fun member_json ->
                        match Thread_member.of_yojson member_json with
                        | Ok tm -> put_thread_member c thread_id tm
                        | Error msg -> log_decode_error c name msg)
                      members
                | _ -> ()
              in
              cache_members "added_members";
              cache_members "members";
              match json |> member "removed_member_ids" with
              | `List user_ids ->
                  List.iter
                    (function
                      | `String user_id ->
                          remove_thread_member c thread_id user_id
                      | _ -> ())
                    user_ids
              | _ -> ())
          | None -> ())
      | Discord_private.P_event.User_update ->
          decode User.of_yojson (put_user c)
      | Discord_private.P_event.Message_reaction_add -> (
          match Emoji.of_yojson (json |> member "emoji") with
          | Error msg -> log_decode_error c name msg
          | Ok emoji -> (
              match
                ( json |> member "channel_id" |> to_string_option,
                  json |> member "message_id" |> to_string_option,
                  json |> member "user_id" |> to_string_option )
              with
              | Some channel_id, Some message_id, Some user_id ->
                  let burst =
                    json |> member "burst" |> to_bool_option
                    |> Option.value ~default:false
                  in
                  let burst_colors =
                    string_list (json |> member "burst_colors")
                  in
                  let is_me =
                    match c.user with
                    | Some u -> User.id u = user_id
                    | None -> false
                  in
                  Eio.Mutex.use_rw ~protect:true c.reactions_mutex (fun () ->
                      let key = (message_id, Emoji.identifier emoji) in
                      match Hashtbl.find_opt c.reactions key with
                      | Some r ->
                          let details = Reaction.count_details r in
                          let old_burst =
                            Reaction.Count_details.burst details
                          in
                          let old_normal =
                            Reaction.Count_details.normal details
                          in
                          let count_details =
                            if burst then
                              Reaction.Count_details.make ~burst:(old_burst + 1)
                                ~normal:old_normal
                            else
                              Reaction.Count_details.make ~burst:old_burst
                                ~normal:(old_normal + 1)
                          in
                          let burst_colors =
                            if burst then
                              List.fold_left
                                (fun colors color ->
                                  if List.mem color colors then colors
                                  else colors @ [ color ])
                                (Reaction.burst_colors r) burst_colors
                            else Reaction.burst_colors r
                          in
                          Hashtbl.replace c.reactions key
                            (Reaction.make ~channel_id ~message_id ~emoji
                               ~count:(Reaction.count r + 1)
                               ~me:(Reaction.me r || is_me)
                               ~count_details ~burst_colors
                               ~me_burst:
                                 (Reaction.me_burst r || (is_me && burst)))
                      | None ->
                          let count_details =
                            Reaction.Count_details.make
                              ~burst:(if burst then 1 else 0)
                              ~normal:(if burst then 0 else 1)
                          in
                          Hashtbl.replace c.reactions key
                            (Reaction.make ~channel_id ~message_id ~emoji
                               ~count:1 ~me:is_me ~count_details ~burst_colors
                               ~me_burst:(is_me && burst)))
              | _ -> ()))
      | Discord_private.P_event.Message_reaction_remove -> (
          match Emoji.of_yojson (json |> member "emoji") with
          | Error msg -> log_decode_error c name msg
          | Ok emoji -> (
              match json |> member "message_id" |> to_string_option with
              | Some message_id ->
                  let burst =
                    json |> member "burst" |> to_bool_option
                    |> Option.value ~default:false
                  in
                  let user_id = json |> member "user_id" |> to_string_option in
                  let is_me =
                    match (c.user, user_id) with
                    | Some u, Some id -> User.id u = id
                    | _ -> false
                  in
                  Eio.Mutex.use_rw ~protect:true c.reactions_mutex (fun () ->
                      let key = (message_id, Emoji.identifier emoji) in
                      match Hashtbl.find_opt c.reactions key with
                      | None -> ()
                      | Some r ->
                          let count = Reaction.count r in
                          if count <= 1 then Hashtbl.remove c.reactions key
                          else begin
                            let details = Reaction.count_details r in
                            let old_burst =
                              Reaction.Count_details.burst details
                            in
                            let old_normal =
                              Reaction.Count_details.normal details
                            in
                            let count_details =
                              if burst then
                                Reaction.Count_details.make
                                  ~burst:(max 0 (old_burst - 1))
                                  ~normal:old_normal
                              else
                                Reaction.Count_details.make ~burst:old_burst
                                  ~normal:(max 0 (old_normal - 1))
                            in
                            Hashtbl.replace c.reactions key
                              (Reaction.make ~channel_id:(Reaction.channel_id r)
                                 ~message_id ~emoji:(Reaction.emoji r)
                                 ~count:(count - 1)
                                 ~me:
                                   (if is_me && not burst then false
                                    else Reaction.me r)
                                 ~count_details
                                 ~burst_colors:(Reaction.burst_colors r)
                                 ~me_burst:
                                   (if is_me && burst then false
                                    else Reaction.me_burst r))
                          end)
              | None -> ()))
      | Discord_private.P_event.Message_reaction_remove_all -> (
          match json |> member "message_id" |> to_string_option with
          | Some message_id -> drop_reactions c [ message_id ]
          | None -> ())
      | Discord_private.P_event.Message_reaction_remove_emoji -> (
          match Emoji.of_yojson (json |> member "emoji") with
          | Error msg -> log_decode_error c name msg
          | Ok emoji -> (
              match json |> member "message_id" |> to_string_option with
              | Some message_id ->
                  remove_reaction c ~message_id ~emoji:(Emoji.identifier emoji)
              | None -> ()))
      | _ -> ()

    let snapshot_event (c : t) (event : Discord_private.P_event.t)
        (json : Yojson.Safe.t) : snapshot =
      let find_member = member in
      let find_channel = channel in
      let find_guild = guild in
      let find_presence = presence in
      let find_user = user_by_id in
      let find_thread_member = thread_member in
      let open Yojson.Safe.Util in
      let empty =
        {
          guild = None;
          channel = None;
          member = None;
          presence = None;
          role = None;
          user = None;
          thread_member = None;
          thread_members = [];
          emojis = [];
          stickers = [];
        }
      in
      let with_guild guild_id =
        match guild_id with
        | Some guild_id -> { empty with guild = find_guild c guild_id }
        | None -> empty
      in
      match event with
      | Discord_private.P_event.Guild_update
      | Discord_private.P_event.Guild_delete ->
          with_guild (json |> member "id" |> to_string_option)
      | Discord_private.P_event.Guild_integrations_update
      | Discord_private.P_event.Guild_members_chunk ->
          with_guild (json |> member "guild_id" |> to_string_option)
      | Discord_private.P_event.Guild_role_update -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "role" |> member "id" |> to_string_option )
          with
          | Some guild_id, Some role_id ->
              { empty with role = role c ~guild_id ~role_id }
          | _ -> empty)
      | Discord_private.P_event.Guild_role_delete -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "role_id" |> to_string_option )
          with
          | Some guild_id, Some role_id ->
              { empty with role = role c ~guild_id ~role_id }
          | _ -> empty)
      | Discord_private.P_event.Guild_member_update
      | Discord_private.P_event.Guild_member_remove -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "user" |> member "id" |> to_string_option )
          with
          | Some guild_id, Some user_id ->
              { empty with member = find_member c ~guild_id ~user_id }
          | _ -> empty)
      | Discord_private.P_event.Guild_emojis_update -> (
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id -> (
              match guild c guild_id with
              | Some g -> { empty with guild = Some g; emojis = Guild.emojis g }
              | None -> empty)
          | None -> empty)
      | Discord_private.P_event.Guild_stickers_update -> (
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id -> (
              match guild c guild_id with
              | Some g ->
                  { empty with guild = Some g; stickers = Guild.stickers g }
              | None -> empty)
          | None -> empty)
      | Discord_private.P_event.Channel_update
      | Discord_private.P_event.Channel_delete
      | Discord_private.P_event.Thread_update
      | Discord_private.P_event.Thread_delete -> (
          match json |> member "id" |> to_string_option with
          | Some channel_id ->
              { empty with channel = find_channel c channel_id }
          | None -> empty)
      | Discord_private.P_event.Channel_pins_update -> (
          match json |> member "channel_id" |> to_string_option with
          | Some channel_id ->
              { empty with channel = find_channel c channel_id }
          | None -> empty)
      | Discord_private.P_event.Thread_list_sync ->
          with_guild (json |> member "guild_id" |> to_string_option)
      | Discord_private.P_event.Thread_member_update -> (
          match
            ( json |> member "id" |> to_string_option,
              json |> member "user_id" |> to_string_option )
          with
          | Some thread_id, Some user_id ->
              {
                empty with
                thread_member = find_thread_member c ~thread_id ~user_id;
              }
          | _ -> empty)
      | Discord_private.P_event.Thread_members_update -> (
          match json |> member "id" |> to_string_option with
          | Some thread_id ->
              let thread_members =
                string_list (json |> member "removed_member_ids")
                |> List.filter_map (fun user_id ->
                    find_thread_member c ~thread_id ~user_id)
              in
              { empty with channel = find_channel c thread_id; thread_members }
          | None -> empty)
      | Discord_private.P_event.Presence_update -> (
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "user" |> member "id" |> to_string_option )
          with
          | Some guild_id, Some user_id ->
              { empty with presence = find_presence c ~guild_id ~user_id }
          | _ -> empty)
      | Discord_private.P_event.User_update -> (
          match json |> member "id" |> to_string_option with
          | Some user_id -> { empty with user = find_user c user_id }
          | None -> empty)
      | _ -> empty

    type reaction_event = {
      channel_id : string;
      message_id : string;
      guild_id : string option;
      user_id : string;
      emoji : Emoji.t;
      burst : bool;
      type_ : int;
      burst_colors : string list;
    }

    let reaction_event_of_yojson (json : Yojson.Safe.t) :
        (reaction_event, string) result =
      let open Yojson.Safe.Util in
      try
        let emoji =
          match Emoji.of_yojson (json |> member "emoji") with
          | Ok emoji -> emoji
          | Error msg -> raise (Failure msg)
        in
        Ok
          {
            channel_id = json |> member "channel_id" |> to_string;
            message_id = json |> member "message_id" |> to_string;
            guild_id = json |> member "guild_id" |> to_string_option;
            user_id = json |> member "user_id" |> to_string;
            emoji;
            burst =
              json |> member "burst" |> to_bool_option
              |> Option.value ~default:false;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            burst_colors = string_list (json |> member "burst_colors");
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let cache_payload_member (c : t) (name : string) (guild_id : string option)
        (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      match json |> member "member" with
      | `Null -> ()
      | member_json -> (
          match Member.of_yojson member_json with
          | Ok member ->
              (match guild_id with
              | Some guild_id ->
                  put_member c guild_id (User.id (Member.user member)) member
              | None -> ());
              put_user c (Member.user member)
          | Error msg -> log_decode_error c name msg)

    let reactions_for_message (c : t) (message_id : string) : Reaction.t list =
      Eio.Mutex.use_ro c.reactions_mutex (fun () ->
          Hashtbl.fold
            (fun (id, _) reaction acc ->
              if id = message_id then reaction :: acc else acc)
            c.reactions [])

    let dispatch_message_update ~sw (c : t) (json : Yojson.Safe.t) : unit =
      match Message_update.of_yojson json with
      | Error msg -> log_decode_error c "MESSAGE_UPDATE" msg
      | Ok update ->
          let old =
            message c
              ~channel_id:(Message_update.channel_id update)
              ~message_id:(Message_update.id update)
          in
          cache_event c Discord_private.P_event.Message_update json;
          (match Message_update.author update with
          | Some author -> put_user c author
          | None -> ());
          List.iter
            (fun f -> Eio.Fiber.fork ~sw (fun () -> f c old update))
            (Atomic.get c.message_update_handlers)

    let dispatch_message_delete ~sw (c : t) (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      match
        ( json |> member "channel_id" |> to_string_option,
          json |> member "id" |> to_string_option )
      with
      | Some channel_id, Some id ->
          let guild_id = json |> member "guild_id" |> to_string_option in
          let cached_message = message c ~channel_id ~message_id:id in
          cache_event c Discord_private.P_event.Message_delete json;
          let payload : Event_payload.Message_delete.t =
            { id; channel_id; guild_id; message = cached_message }
          in
          List.iter
            (fun f -> Eio.Fiber.fork ~sw (fun () -> f c payload))
            (Atomic.get c.message_delete_handlers)
      | _ -> ()

    let dispatch_message_delete_bulk ~sw (c : t) (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      match json |> member "channel_id" |> to_string_option with
      | Some channel_id ->
          let guild_id = json |> member "guild_id" |> to_string_option in
          let ids = string_list (json |> member "ids") in
          let messages =
            List.filter_map (fun id -> message c ~channel_id ~message_id:id) ids
          in
          let channel = channel c channel_id in
          cache_event c Discord_private.P_event.Message_delete_bulk json;
          let payload : Event_payload.Message_delete_bulk.t =
            { ids; channel_id; guild_id; messages; channel }
          in
          List.iter
            (fun f -> Eio.Fiber.fork ~sw (fun () -> f c payload))
            (Atomic.get c.message_delete_bulk_handlers)
      | None -> ()

    let added_reaction (update : reaction_event) (previous : Reaction.t option)
        (is_me : bool) : Reaction.t =
      match previous with
      | Some reaction ->
          let details = Reaction.count_details reaction in
          let count_details =
            if update.burst then
              Reaction.Count_details.make
                ~burst:(Reaction.Count_details.burst details + 1)
                ~normal:(Reaction.Count_details.normal details)
            else
              Reaction.Count_details.make
                ~burst:(Reaction.Count_details.burst details)
                ~normal:(Reaction.Count_details.normal details + 1)
          in
          let burst_colors =
            if update.burst then
              List.fold_left
                (fun colors color ->
                  if List.mem color colors then colors else colors @ [ color ])
                (Reaction.burst_colors reaction)
                update.burst_colors
            else Reaction.burst_colors reaction
          in
          Reaction.make
            ~channel_id:(Reaction.channel_id reaction)
            ~message_id:update.message_id ~emoji:(Reaction.emoji reaction)
            ~count:(Reaction.count reaction + 1)
            ~me:(Reaction.me reaction || (is_me && not update.burst))
            ~count_details ~burst_colors
            ~me_burst:(Reaction.me_burst reaction || (is_me && update.burst))
      | None ->
          let count_details =
            Reaction.Count_details.make
              ~burst:(if update.burst then 1 else 0)
              ~normal:(if update.burst then 0 else 1)
          in
          Reaction.make ~channel_id:update.channel_id
            ~message_id:update.message_id ~emoji:update.emoji ~count:1
            ~me:(is_me && not update.burst)
            ~count_details ~burst_colors:update.burst_colors
            ~me_burst:(is_me && update.burst)

    let removed_reaction (update : reaction_event)
        (previous : Reaction.t option) (is_me : bool) : Reaction.t =
      match previous with
      | Some reaction ->
          let count = Reaction.count reaction in
          let details = Reaction.count_details reaction in
          let count_details =
            if update.burst then
              Reaction.Count_details.make
                ~burst:(max 0 (Reaction.Count_details.burst details - 1))
                ~normal:(Reaction.Count_details.normal details)
            else
              Reaction.Count_details.make
                ~burst:(Reaction.Count_details.burst details)
                ~normal:(max 0 (Reaction.Count_details.normal details - 1))
          in
          Reaction.make
            ~channel_id:(Reaction.channel_id reaction)
            ~message_id:update.message_id ~emoji:(Reaction.emoji reaction)
            ~count:(max 0 (count - 1))
            ~me:
              (if is_me && not update.burst then false else Reaction.me reaction)
            ~count_details
            ~burst_colors:(Reaction.burst_colors reaction)
            ~me_burst:
              (if is_me && update.burst then false
               else Reaction.me_burst reaction)
      | None ->
          Reaction.make ~channel_id:update.channel_id
            ~message_id:update.message_id ~emoji:update.emoji ~count:0 ~me:false
            ~count_details:(Reaction.Count_details.make ~burst:0 ~normal:0)
            ~burst_colors:update.burst_colors ~me_burst:false

    let dispatch_reaction ~sw (c : t) (event : Discord_private.P_event.t)
        (json : Yojson.Safe.t) : unit =
      let name = Discord_private.P_event.to_string event in
      match reaction_event_of_yojson json with
      | Error msg -> log_decode_error c name msg
      | Ok update ->
          cache_payload_member c name update.guild_id json;
          let emoji = Emoji.identifier update.emoji in
          let previous = reaction c ~message_id:update.message_id ~emoji in
          cache_event c event json;
          let current = reaction c ~message_id:update.message_id ~emoji in
          let is_me =
            match c.user with
            | Some user -> User.id user = update.user_id
            | None -> false
          in
          let reaction =
            match current with
            | Some reaction -> reaction
            | None -> (
                match event with
                | Discord_private.P_event.Message_reaction_add ->
                    added_reaction update previous is_me
                | _ -> removed_reaction update previous is_me)
          in
          let user = user_by_id c update.user_id in
          let payload : Event_payload.Message_reaction.t =
            {
              reaction;
              user_id = update.user_id;
              user;
              details = { burst = update.burst; type_ = update.type_ };
            }
          in
          let handlers =
            match event with
            | Discord_private.P_event.Message_reaction_add ->
                Atomic.get c.message_reaction_add_handlers
            | _ -> Atomic.get c.message_reaction_remove_handlers
          in
          List.iter
            (fun f -> Eio.Fiber.fork ~sw (fun () -> f c payload))
            handlers

    let dispatch_reaction_remove_all ~sw (c : t) (json : Yojson.Safe.t) : unit =
      let open Yojson.Safe.Util in
      match
        ( json |> member "channel_id" |> to_string_option,
          json |> member "message_id" |> to_string_option )
      with
      | Some channel_id, Some message_id ->
          let guild_id = json |> member "guild_id" |> to_string_option in
          let cached_message = message c ~channel_id ~message_id in
          let reactions = reactions_for_message c message_id in
          cache_event c Discord_private.P_event.Message_reaction_remove_all json;
          let payload : Event_payload.Message_reaction_remove_all.t =
            {
              message_id;
              channel_id;
              guild_id;
              message = cached_message;
              reactions;
            }
          in
          List.iter
            (fun f -> Eio.Fiber.fork ~sw (fun () -> f c payload))
            (Atomic.get c.message_reaction_remove_all_handlers)
      | _ -> ()

    let dispatch_reaction_remove_emoji ~sw (c : t) (json : Yojson.Safe.t) : unit
        =
      let open Yojson.Safe.Util in
      let name = "MESSAGE_REACTION_REMOVE_EMOJI" in
      match Emoji.of_yojson (json |> member "emoji") with
      | Error msg -> log_decode_error c name msg
      | Ok emoji -> (
          match
            ( json |> member "channel_id" |> to_string_option,
              json |> member "message_id" |> to_string_option )
          with
          | Some channel_id, Some message_id ->
              let guild_id = json |> member "guild_id" |> to_string_option in
              let removed =
                reaction c ~message_id ~emoji:(Emoji.identifier emoji)
              in
              cache_event c
                Discord_private.P_event.Message_reaction_remove_emoji json;
              let payload : Event_payload.Message_reaction_remove_emoji.t =
                { message_id; channel_id; guild_id; emoji; reaction = removed }
              in
              List.iter
                (fun f -> Eio.Fiber.fork ~sw (fun () -> f c payload))
                (Atomic.get c.message_reaction_remove_emoji_handlers)
          | _ -> ())

    let add_handler (c : t) (event : Discord_private.P_event.t)
        (f : t -> snapshot -> Yojson.Safe.t -> unit) : unit =
      let rec add () =
        let old = Atomic.get c.handlers in
        let tbl = Hashtbl.copy old in
        let existing =
          match Hashtbl.find_opt tbl event with Some l -> l | None -> []
        in
        Hashtbl.replace tbl event (f :: existing);
        if not (Atomic.compare_and_set c.handlers old tbl) then add ()
      in
      add ()

    let add_untyped_handler (c : t) (event : Discord_private.P_event.t)
        (f : t -> unit) : unit =
      add_handler c event (fun t _ _ -> f t)

    let add_decoded_handler (c : t) (event : Discord_private.P_event.t)
        (of_yojson : Yojson.Safe.t -> ('a, string) result) (f : t -> 'a -> unit)
        : unit =
      add_handler c event (fun t _ json ->
          match of_yojson json with
          | Ok payload -> f t payload
          | Error msg ->
              log_decode_error c (Discord_private.P_event.to_string event) msg)

    let decode_list (c : t) (name : string)
        (of_yojson : Yojson.Safe.t -> ('a, string) result)
        (json : Yojson.Safe.t) (field : string) : 'a list =
      let open Yojson.Safe.Util in
      match json |> member field with
      | `List items ->
          List.filter_map
            (fun item ->
              match of_yojson item with
              | Ok value -> Some value
              | Error msg ->
                  log_decode_error c name msg;
                  None)
            items
      | _ -> []

    let add_message_handler (c : t) (f : t -> Message.t -> unit) : unit =
      let rec add () =
        let old = Atomic.get c.message_handlers in
        if not (Atomic.compare_and_set c.message_handlers old (f :: old)) then
          add ()
      in
      add ()

    let add_typed (r : 'a list Atomic.t) (f : 'a) : unit =
      let rec add () =
        let old = Atomic.get r in
        if not (Atomic.compare_and_set r old (f :: old)) then add ()
      in
      add ()

    let on_ready (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Ready f

    let on_resumed (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Resumed f

    let on_application_command_permissions_update (c : t) (f : t -> unit) : unit
        =
      add_untyped_handler c
        Discord_private.P_event.Application_command_permissions_update f

    let on_auto_moderation_rule_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Auto_moderation_rule_create
        f

    let on_auto_moderation_rule_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Auto_moderation_rule_update
        f

    let on_auto_moderation_rule_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Auto_moderation_rule_delete
        f

    let on_auto_moderation_action_execution (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Auto_moderation_action_execution f

    let on_channel_create (c : t) (f : t -> Channel.t -> unit) : unit =
      add_decoded_handler c Discord_private.P_event.Channel_create
        Channel.of_yojson f

    let on_channel_update (c : t)
        (f : t -> Channel.t option -> Channel.t -> unit) : unit =
      add_handler c Discord_private.P_event.Channel_update (fun t snap json ->
          match Channel.of_yojson json with
          | Ok channel -> f t snap.channel channel
          | Error msg -> log_decode_error c "CHANNEL_UPDATE" msg)

    let on_channel_delete (c : t)
        (f : t -> Event_payload.Channel_delete.t -> unit) : unit =
      add_handler c Discord_private.P_event.Channel_delete (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "id" |> to_string_option with
          | Some id ->
              let guild_id = json |> member "guild_id" |> to_string_option in
              let type_ = json |> member "type" |> to_int_option in
              f t { id; guild_id; type_; channel = snap.channel }
          | None -> log_decode_error c "CHANNEL_DELETE" "missing id")

    let on_channel_info (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Channel_info f

    let on_channel_pins_update (c : t)
        (f : t -> Event_payload.Channel_pins_update.t -> unit) : unit =
      add_handler c Discord_private.P_event.Channel_pins_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "channel_id" |> to_string_option with
          | Some channel_id ->
              let guild_id = json |> member "guild_id" |> to_string_option in
              let last_pin_timestamp =
                json |> member "last_pin_timestamp" |> to_string_option
              in
              f t
                {
                  channel_id;
                  guild_id;
                  last_pin_timestamp;
                  channel = snap.channel;
                }
          | None ->
              log_decode_error c "CHANNEL_PINS_UPDATE" "missing channel_id")

    let on_thread_create (c : t) (f : t -> Channel.t -> bool -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_create (fun t _ json ->
          match Channel.of_yojson json with
          | Ok channel ->
              let open Yojson.Safe.Util in
              let newly_created =
                json |> member "newly_created" |> to_bool_option
                |> Option.value ~default:false
              in
              f t channel newly_created
          | Error msg -> log_decode_error c "THREAD_CREATE" msg)

    let on_thread_update (c : t)
        (f : t -> Channel.t option -> Channel.t -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_update (fun t snap json ->
          match Channel.of_yojson json with
          | Ok channel -> f t snap.channel channel
          | Error msg -> log_decode_error c "THREAD_UPDATE" msg)

    let on_thread_delete (c : t)
        (f : t -> Event_payload.Channel_delete.t -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_delete (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "id" |> to_string_option with
          | Some id ->
              let guild_id = json |> member "guild_id" |> to_string_option in
              let type_ = json |> member "type" |> to_int_option in
              f t { id; guild_id; type_; channel = snap.channel }
          | None -> log_decode_error c "THREAD_DELETE" "missing id")

    let on_thread_list_sync (c : t)
        (f : t -> Event_payload.Thread_list_sync.t -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_list_sync (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id ->
              let channel_ids = string_list (json |> member "channel_ids") in
              let threads =
                decode_list c "THREAD_LIST_SYNC" Channel.of_yojson json
                  "threads"
              in
              let members =
                decode_list c "THREAD_LIST_SYNC" Thread_member.of_yojson json
                  "members"
              in
              f t
                { guild_id; channel_ids; threads; members; guild = snap.guild }
          | None -> log_decode_error c "THREAD_LIST_SYNC" "missing guild_id")

    let on_thread_member_update (c : t)
        (f : t -> Thread_member.t option -> Thread_member.t -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_member_update
        (fun t snap json ->
          match Thread_member.of_yojson json with
          | Ok thread_member -> f t snap.thread_member thread_member
          | Error msg -> log_decode_error c "THREAD_MEMBER_UPDATE" msg)

    let on_thread_members_update (c : t)
        (f : t -> Event_payload.Thread_members_update.t -> unit) : unit =
      add_handler c Discord_private.P_event.Thread_members_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "id" |> to_string_option with
          | Some thread_id ->
              let guild_id = json |> member "guild_id" |> to_string_option in
              let added =
                decode_list c "THREAD_MEMBERS_UPDATE" Thread_member.of_yojson
                  json "added_members"
              in
              let removed_user_ids =
                string_list (json |> member "removed_member_ids")
              in
              let member_count =
                json |> member "member_count" |> to_int_option
                |> Option.value ~default:0
              in
              f t
                {
                  thread_id;
                  guild_id;
                  added;
                  removed = snap.thread_members;
                  removed_user_ids;
                  member_count;
                  thread = snap.channel;
                }
          | None -> log_decode_error c "THREAD_MEMBERS_UPDATE" "missing id")

    let on_voice_channel_status_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Voice_channel_status_update
        f

    let on_voice_channel_start_time_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Voice_channel_start_time_update f

    let on_entitlement_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Entitlement_create f

    let on_entitlement_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Entitlement_update f

    let on_entitlement_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Entitlement_delete f

    let on_subscription_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Subscription_create f

    let on_subscription_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Subscription_update f

    let on_subscription_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Subscription_delete f

    let on_guild_create (c : t) (f : t -> Guild.t -> unit) : unit =
      add_decoded_handler c Discord_private.P_event.Guild_create Guild.of_yojson
        f

    let on_guild_update (c : t) (f : t -> Guild.t option -> Guild.t -> unit) :
        unit =
      add_handler c Discord_private.P_event.Guild_update (fun t snap json ->
          match Guild.of_yojson json with
          | Ok guild -> f t snap.guild guild
          | Error msg -> log_decode_error c "GUILD_UPDATE" msg)

    let on_guild_delete (c : t) (f : t -> Event_payload.Guild_delete.t -> unit)
        : unit =
      add_handler c Discord_private.P_event.Guild_delete (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "id" |> to_string_option with
          | Some id ->
              let unavailable =
                json |> member "unavailable" |> to_bool_option
                |> Option.value ~default:false
              in
              f t { id; unavailable; guild = snap.guild }
          | None -> ())

    let on_guild_audit_log_entry_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Guild_audit_log_entry_create
        f

    let on_guild_ban_add (c : t) (f : t -> string -> Guild_ban.t -> unit) : unit
        =
      add_handler c Discord_private.P_event.Guild_ban_add (fun t _ json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              Guild_ban.of_yojson json )
          with
          | Some guild_id, Ok ban -> f t guild_id ban
          | Some _, Error msg -> log_decode_error c "GUILD_BAN_ADD" msg
          | None, _ -> ())

    let on_guild_ban_remove (c : t) (f : t -> string -> Guild_ban.t -> unit) :
        unit =
      add_handler c Discord_private.P_event.Guild_ban_remove (fun t _ json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              Guild_ban.of_yojson json )
          with
          | Some guild_id, Ok ban -> f t guild_id ban
          | Some _, Error msg -> log_decode_error c "GUILD_BAN_REMOVE" msg
          | None, _ -> ())

    let on_guild_emojis_update (c : t)
        (f : t -> string -> Emoji.t list -> Emoji.t list -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_emojis_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id ->
              let emojis =
                decode_list c "GUILD_EMOJIS_UPDATE" Emoji.of_yojson json
                  "emojis"
              in
              f t guild_id snap.emojis emojis
          | None -> ())

    let on_guild_stickers_update (c : t)
        (f : t -> string -> Sticker.t list -> Sticker.t list -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_stickers_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id ->
              let stickers =
                decode_list c "GUILD_STICKERS_UPDATE" Sticker.of_yojson json
                  "stickers"
              in
              f t guild_id snap.stickers stickers
          | None -> ())

    let on_guild_integrations_update (c : t)
        (f : t -> string -> Guild.t option -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_integrations_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "guild_id" |> to_string_option with
          | Some guild_id -> f t guild_id snap.guild
          | None -> ())

    let on_guild_member_add (c : t) (f : t -> string -> Member.t -> unit) : unit
        =
      add_handler c Discord_private.P_event.Guild_member_add (fun t _ json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              Member.of_yojson json )
          with
          | Some guild_id, Ok member -> f t guild_id member
          | Some _, Error msg -> log_decode_error c "GUILD_MEMBER_ADD" msg
          | None, _ -> ())

    let on_guild_member_remove (c : t)
        (f : t -> Event_payload.Member_remove.t -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_member_remove
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              User.of_yojson (json |> member "user") )
          with
          | Some guild_id, Ok user ->
              f t { guild_id; user; member = snap.member }
          | Some _, Error msg -> log_decode_error c "GUILD_MEMBER_REMOVE" msg
          | None, _ -> ())

    let on_guild_member_update (c : t)
        (f : t -> string -> Member.t option -> Member.t -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_member_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              Member.of_yojson json )
          with
          | Some guild_id, Ok member -> f t guild_id snap.member member
          | Some _, Error msg -> log_decode_error c "GUILD_MEMBER_UPDATE" msg
          | None, _ -> ())

    let on_guild_members_chunk (c : t)
        (f : t -> Event_payload.Guild_members_chunk.t -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_members_chunk
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match json |> member "guild_id" |> to_string_option with
          | None -> log_decode_error c "GUILD_MEMBERS_CHUNK" "missing guild_id"
          | Some guild_id ->
              let members =
                decode_list c "GUILD_MEMBERS_CHUNK" Member.of_yojson json
                  "members"
              in
              let presences =
                decode_list c "GUILD_MEMBERS_CHUNK" Presence.of_yojson json
                  "presences"
              in
              let count =
                json |> member "chunk_count" |> to_int_option
                |> Option.value ~default:0
              in
              let index =
                json |> member "chunk_index" |> to_int_option
                |> Option.value ~default:0
              in
              let nonce = json |> member "nonce" |> to_string_option in
              let not_found = string_list (json |> member "not_found") in
              f t
                {
                  guild_id;
                  members;
                  presences;
                  guild = snap.guild;
                  count;
                  index;
                  nonce;
                  not_found;
                })

    let role_of_json (json : Yojson.Safe.t) : (Role.t, string) result =
      let open Yojson.Safe.Util in
      Role.of_yojson (json |> member "role")

    let on_guild_role_create (c : t) (f : t -> string -> Role.t -> unit) : unit
        =
      add_handler c Discord_private.P_event.Guild_role_create (fun t _ json ->
          let open Yojson.Safe.Util in
          match
            (json |> member "guild_id" |> to_string_option, role_of_json json)
          with
          | Some guild_id, Ok role -> f t guild_id role
          | Some _, Error msg -> log_decode_error c "GUILD_ROLE_CREATE" msg
          | None, _ -> ())

    let on_guild_role_update (c : t)
        (f : t -> string -> Role.t option -> Role.t -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_role_update
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match
            (json |> member "guild_id" |> to_string_option, role_of_json json)
          with
          | Some guild_id, Ok role -> f t guild_id snap.role role
          | Some _, Error msg -> log_decode_error c "GUILD_ROLE_UPDATE" msg
          | None, _ -> ())

    let on_guild_role_delete (c : t)
        (f : t -> Event_payload.Role_delete.t -> unit) : unit =
      add_handler c Discord_private.P_event.Guild_role_delete
        (fun t snap json ->
          let open Yojson.Safe.Util in
          match
            ( json |> member "guild_id" |> to_string_option,
              json |> member "role_id" |> to_string_option )
          with
          | Some guild_id, Some role_id ->
              f t { guild_id; role_id; role = snap.role }
          | _ -> ())

    let on_guild_scheduled_event_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Guild_scheduled_event_create
        f

    let on_guild_scheduled_event_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Guild_scheduled_event_update
        f

    let on_guild_scheduled_event_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Guild_scheduled_event_delete
        f

    let on_guild_scheduled_event_user_add (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_scheduled_event_user_add f

    let on_guild_scheduled_event_user_remove (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_scheduled_event_user_remove f

    let on_guild_soundboard_sound_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_soundboard_sound_create f

    let on_guild_soundboard_sound_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_soundboard_sound_update f

    let on_guild_soundboard_sound_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_soundboard_sound_delete f

    let on_guild_soundboard_sounds_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c
        Discord_private.P_event.Guild_soundboard_sounds_update f

    let on_soundboard_sounds (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Soundboard_sounds f

    let on_integration_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Integration_create f

    let on_integration_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Integration_update f

    let on_integration_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Integration_delete f

    let on_interaction_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Interaction_create f

    let on_invite_create (c : t) (f : t -> Invite.t -> unit) : unit =
      add_decoded_handler c Discord_private.P_event.Invite_create
        Invite.of_yojson f

    let on_invite_delete (c : t) (f : t -> Invite.t -> unit) : unit =
      add_decoded_handler c Discord_private.P_event.Invite_delete
        Invite.of_yojson f

    let on_message (c : t) (f : t -> Message.t -> unit) : unit =
      add_message_handler c f

    let on_message_update (c : t)
        (f : t -> Message.t option -> Message_update.t -> unit) : unit =
      add_typed c.message_update_handlers f

    let on_message_delete (c : t)
        (f : t -> Event_payload.Message_delete.t -> unit) : unit =
      add_typed c.message_delete_handlers f

    let on_message_delete_bulk (c : t)
        (f : t -> Event_payload.Message_delete_bulk.t -> unit) : unit =
      add_typed c.message_delete_bulk_handlers f

    let on_message_reaction_add (c : t)
        (f : t -> Event_payload.Message_reaction.t -> unit) : unit =
      add_typed c.message_reaction_add_handlers f

    let on_message_reaction_remove (c : t)
        (f : t -> Event_payload.Message_reaction.t -> unit) : unit =
      add_typed c.message_reaction_remove_handlers f

    let on_message_reaction_remove_all (c : t)
        (f : t -> Event_payload.Message_reaction_remove_all.t -> unit) : unit =
      add_typed c.message_reaction_remove_all_handlers f

    let on_message_reaction_remove_emoji (c : t)
        (f : t -> Event_payload.Message_reaction_remove_emoji.t -> unit) : unit
        =
      add_typed c.message_reaction_remove_emoji_handlers f

    let poll_vote_payload (c : t) (json : Yojson.Safe.t) :
        (Event_payload.Message_poll_vote.t, string) result =
      let open Yojson.Safe.Util in
      try
        let user_id = json |> member "user_id" |> to_string in
        let channel_id = json |> member "channel_id" |> to_string in
        let message_id = json |> member "message_id" |> to_string in
        let guild_id = json |> member "guild_id" |> to_string_option in
        let answer_id = json |> member "answer_id" |> to_int in
        let poll =
          match message c ~channel_id ~message_id with
          | Some message -> Message.poll message
          | None -> None
        in
        Ok
          ({ user_id; channel_id; message_id; guild_id; answer_id; poll }
            : Event_payload.Message_poll_vote.t)
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let on_message_poll_vote_add (c : t)
        (f : t -> Event_payload.Message_poll_vote.t -> unit) : unit =
      add_handler c Discord_private.P_event.Message_poll_vote_add
        (fun t _ json ->
          match poll_vote_payload t json with
          | Ok payload -> f t payload
          | Error msg -> log_decode_error c "MESSAGE_POLL_VOTE_ADD" msg)

    let on_message_poll_vote_remove (c : t)
        (f : t -> Event_payload.Message_poll_vote.t -> unit) : unit =
      add_handler c Discord_private.P_event.Message_poll_vote_remove
        (fun t _ json ->
          match poll_vote_payload t json with
          | Ok payload -> f t payload
          | Error msg -> log_decode_error c "MESSAGE_POLL_VOTE_REMOVE" msg)

    let on_presence_update (c : t)
        (f : t -> Presence.t option -> Presence.t -> unit) : unit =
      add_handler c Discord_private.P_event.Presence_update (fun t snap json ->
          match Presence.of_yojson json with
          | Ok presence -> f t snap.presence presence
          | Error msg -> log_decode_error c "PRESENCE_UPDATE" msg)

    let on_stage_instance_create (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Stage_instance_create f

    let on_stage_instance_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Stage_instance_update f

    let on_stage_instance_delete (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Stage_instance_delete f

    let on_typing_start (c : t) (f : t -> Typing.t -> unit) : unit =
      add_decoded_handler c Discord_private.P_event.Typing_start
        Typing.of_yojson (fun t typing ->
          let typing =
            match (Typing.member typing, Typing.guild_id typing) with
            | None, Some guild_id -> (
                match member t ~guild_id ~user_id:(Typing.user_id typing) with
                | Some member -> { typing with member = Some member }
                | None -> typing)
            | _ -> typing
          in
          (match Typing.member typing with
          | Some member -> put_user t (Member.user member)
          | None -> ());
          f t typing)

    let on_user_update (c : t) (f : t -> User.t option -> User.t -> unit) : unit
        =
      add_handler c Discord_private.P_event.User_update (fun t snap json ->
          match User.of_yojson json with
          | Ok user -> f t snap.user user
          | Error msg -> log_decode_error c "USER_UPDATE" msg)

    let on_voice_channel_effect_send (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Voice_channel_effect_send f

    let on_voice_state_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Voice_state_update f

    let on_voice_server_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Voice_server_update f

    let on_webhooks_update (c : t) (f : t -> unit) : unit =
      add_untyped_handler c Discord_private.P_event.Webhooks_update f

    let create (i : int) : t =
      {
        token = None;
        intents = i;
        guilds = Hashtbl.create 0;
        guilds_mutex = Eio.Mutex.create ();
        channels = Hashtbl.create 0;
        channels_mutex = Eio.Mutex.create ();
        members = Hashtbl.create 0;
        members_mutex = Eio.Mutex.create ();
        presences = Hashtbl.create 0;
        presences_mutex = Eio.Mutex.create ();
        messages = Hashtbl.create 0;
        messages_mutex = Eio.Mutex.create ();
        users = Hashtbl.create 0;
        users_mutex = Eio.Mutex.create ();
        roles = Hashtbl.create 0;
        roles_mutex = Eio.Mutex.create ();
        reactions = Hashtbl.create 0;
        reactions_mutex = Eio.Mutex.create ();
        thread_members = Hashtbl.create 0;
        thread_members_mutex = Eio.Mutex.create ();
        scheduled_events = Hashtbl.create 0;
        scheduled_events_mutex = Eio.Mutex.create ();
        stage_instances = Hashtbl.create 0;
        stage_instances_mutex = Eio.Mutex.create ();
        auto_moderation_rules = Hashtbl.create 0;
        auto_moderation_rules_mutex = Eio.Mutex.create ();
        decode_errors = Atomic.make [];
        shards = Hashtbl.create 0;
        shards_mutex = Eio.Mutex.create ();
        handlers = Atomic.make (Hashtbl.create 0);
        message_handlers = Atomic.make [];
        message_update_handlers = Atomic.make [];
        message_delete_handlers = Atomic.make [];
        message_delete_bulk_handlers = Atomic.make [];
        message_reaction_add_handlers = Atomic.make [];
        message_reaction_remove_handlers = Atomic.make [];
        message_reaction_remove_all_handlers = Atomic.make [];
        message_reaction_remove_emoji_handlers = Atomic.make [];
        user = None;
        rest = None;
      }

    let start ~(env : Eio_unix.Stdenv.base) (c : t) (token : string) : unit =
      let net = Eio.Stdenv.net env in
      let clock = Eio.Stdenv.clock env in
      Eio.Switch.run @@ fun sw ->
      c.token <- Some token;
      let rest = Rest.create ~sw ~net ~clock ~token in
      c.rest <- Some rest;
      let info = Rest.gateway_bot rest in
      if info.shards > info.sessions_remaining then
        Eio.Time.sleep clock info.sessions_reset_after;
      let open Yojson.Safe.Util in
      let dispatch (name : string) (json : Yojson.Safe.t) : unit =
        match Discord_private.P_event.of_string name with
        | None -> ()
        | Some Discord_private.P_event.Message_create -> (
            match Message.of_yojson json with
            | Ok message ->
                put_message c message;
                put_user c (Message.author message);
                List.iter (put_user c) (Message.mentions message);
                refresh_message_reactions c message;
                List.iter
                  (fun f -> Eio.Fiber.fork ~sw (fun () -> f c message))
                  (Atomic.get c.message_handlers)
            | Error msg -> log_decode_error c "MESSAGE_CREATE" msg)
        | Some Discord_private.P_event.Message_update ->
            dispatch_message_update ~sw c json
        | Some Discord_private.P_event.Message_delete ->
            dispatch_message_delete ~sw c json
        | Some Discord_private.P_event.Message_delete_bulk ->
            dispatch_message_delete_bulk ~sw c json
        | Some
            (( Discord_private.P_event.Message_reaction_add
             | Discord_private.P_event.Message_reaction_remove ) as event) ->
            dispatch_reaction ~sw c event json
        | Some Discord_private.P_event.Message_reaction_remove_all ->
            dispatch_reaction_remove_all ~sw c json
        | Some Discord_private.P_event.Message_reaction_remove_emoji ->
            dispatch_reaction_remove_emoji ~sw c json
        | Some event -> (
            let snap = snapshot_event c event json in
            cache_event c event json;
            (match event with
            | Discord_private.P_event.Ready -> (
                match User.of_yojson (json |> member "user") with
                | Ok user -> c.user <- Some user
                | Error _ -> ())
            | _ -> ());
            match event with
            | Discord_private.P_event.Guild_create
              when json |> member "unavailable" |> to_bool_option = Some true ->
                ()
            | _ ->
                let handlers =
                  match Hashtbl.find_opt (Atomic.get c.handlers) event with
                  | Some l -> l
                  | None -> []
                in
                List.iter
                  (fun f -> Eio.Fiber.fork ~sw (fun () -> f c snap json))
                  handlers)
      in
      let rec spawn i =
        if i < info.shards then begin
          let shard =
            Discord_private.P_shard.connect ~url:info.url ~id:i
              ~num_shards:info.shards ~token ~intents:c.intents
          in
          Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
              Hashtbl.replace c.shards i shard);
          Eio.Fiber.fork ~sw (fun () ->
              Fun.protect
                ~finally:(fun () ->
                  Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
                      Hashtbl.remove c.shards i))
                (fun () ->
                  Discord_private.P_shard.run ~net ~dispatch clock shard));
          if (i + 1) mod info.max_concurrency = 0 && i + 1 < info.shards then
            Eio.Time.sleep clock 5.;
          spawn (i + 1)
        end
      in
      spawn 0
  end :
    Client)
