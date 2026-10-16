module type Client = sig
    type t

    val token : t -> string option

    val create : int -> t
    val start : env:Eio_unix.Stdenv.base -> t -> string -> unit

    val guild : t -> string -> Guild.t option
    val channel : t -> string -> Channel.t option
    val member : t -> guild_id:string -> user_id:string -> Member.t option
    val presence :
        t -> guild_id:string -> user_id:string -> Presence.t option
    val message :
        t -> channel_id:string -> message_id:string -> Message.t option
    val user : t -> User.t option
    val rest : t -> Rest.t

    val guilds : t -> Guild.t list
    val channels : t -> guild_id:string -> Channel.t list
    val members : t -> guild_id:string -> Member.t list
    val messages : t -> channel_id:string -> Message.t list

    val on_ready : t -> (t -> unit) -> unit
    val on_resumed : t -> (t -> unit) -> unit
    val on_application_command_permissions_update : t -> (t -> unit) -> unit
    val on_auto_moderation_rule_create : t -> (t -> unit) -> unit
    val on_auto_moderation_rule_update : t -> (t -> unit) -> unit
    val on_auto_moderation_rule_delete : t -> (t -> unit) -> unit
    val on_auto_moderation_action_execution : t -> (t -> unit) -> unit
    val on_channel_create : t -> (t -> unit) -> unit
    val on_channel_update : t -> (t -> unit) -> unit
    val on_channel_delete : t -> (t -> unit) -> unit
    val on_channel_info : t -> (t -> unit) -> unit
    val on_channel_pins_update : t -> (t -> unit) -> unit
    val on_thread_create : t -> (t -> unit) -> unit
    val on_thread_update : t -> (t -> unit) -> unit
    val on_thread_delete : t -> (t -> unit) -> unit
    val on_thread_list_sync : t -> (t -> unit) -> unit
    val on_thread_member_update : t -> (t -> unit) -> unit
    val on_thread_members_update : t -> (t -> unit) -> unit
    val on_voice_channel_status_update : t -> (t -> unit) -> unit
    val on_voice_channel_start_time_update : t -> (t -> unit) -> unit
    val on_entitlement_create : t -> (t -> unit) -> unit
    val on_entitlement_update : t -> (t -> unit) -> unit
    val on_entitlement_delete : t -> (t -> unit) -> unit
    val on_subscription_create : t -> (t -> unit) -> unit
    val on_subscription_update : t -> (t -> unit) -> unit
    val on_subscription_delete : t -> (t -> unit) -> unit
    val on_guild_create : t -> (t -> unit) -> unit
    val on_guild_update : t -> (t -> unit) -> unit
    val on_guild_delete : t -> (t -> unit) -> unit
    val on_guild_audit_log_entry_create : t -> (t -> unit) -> unit
    val on_guild_ban_add : t -> (t -> unit) -> unit
    val on_guild_ban_remove : t -> (t -> unit) -> unit
    val on_guild_emojis_update : t -> (t -> unit) -> unit
    val on_guild_stickers_update : t -> (t -> unit) -> unit
    val on_guild_integrations_update : t -> (t -> unit) -> unit
    val on_guild_member_add : t -> (t -> unit) -> unit
    val on_guild_member_remove : t -> (t -> unit) -> unit
    val on_guild_member_update : t -> (t -> unit) -> unit
    val on_guild_members_chunk : t -> (t -> unit) -> unit
    val on_guild_role_create : t -> (t -> unit) -> unit
    val on_guild_role_update : t -> (t -> unit) -> unit
    val on_guild_role_delete : t -> (t -> unit) -> unit
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
    val on_invite_create : t -> (t -> unit) -> unit
    val on_invite_delete : t -> (t -> unit) -> unit
    val on_message : t -> (t -> Message.t -> unit) -> unit
    val on_message_update : t -> (t -> unit) -> unit
    val on_message_delete : t -> (t -> unit) -> unit
    val on_message_delete_bulk : t -> (t -> unit) -> unit
    val on_message_reaction_add : t -> (t -> unit) -> unit
    val on_message_reaction_remove : t -> (t -> unit) -> unit
    val on_message_reaction_remove_all : t -> (t -> unit) -> unit
    val on_message_reaction_remove_emoji : t -> (t -> unit) -> unit
    val on_message_poll_vote_add : t -> (t -> unit) -> unit
    val on_message_poll_vote_remove : t -> (t -> unit) -> unit
    val on_presence_update : t -> (t -> unit) -> unit
    val on_stage_instance_create : t -> (t -> unit) -> unit
    val on_stage_instance_update : t -> (t -> unit) -> unit
    val on_stage_instance_delete : t -> (t -> unit) -> unit
    val on_typing_start : t -> (t -> unit) -> unit
    val on_user_update : t -> (t -> unit) -> unit
    val on_voice_channel_effect_send : t -> (t -> unit) -> unit
    val on_voice_state_update : t -> (t -> unit) -> unit
    val on_voice_server_update : t -> (t -> unit) -> unit
    val on_webhooks_update : t -> (t -> unit) -> unit
    val show : t -> string
end

include (struct

    type t = {
        mutable token : string option;
        intents : int;
        guilds : (string, Guild.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        guilds_mutex : Eio.Mutex.t [@opaque];
        channels : (string, Channel.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        channels_mutex : Eio.Mutex.t [@opaque];
        members : ((string * string), Member.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        members_mutex : Eio.Mutex.t [@opaque];
        presences : ((string * string), Presence.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        presences_mutex : Eio.Mutex.t [@opaque];
        messages : ((string * string), Message.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        messages_mutex : Eio.Mutex.t [@opaque];
        decode_errors : string list Atomic.t [@opaque];
        shards : (int, Discord_private.P_shard.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        shards_mutex : Eio.Mutex.t [@opaque];
        handlers : (Discord_private.P_event.t, (t -> unit) list) Hashtbl.t Atomic.t [@opaque];
        message_handlers : (t -> Message.t -> unit) list Atomic.t [@opaque];
        mutable user : User.t option [@printer fun fmt u ->
            match u with
            | Some u -> Format.pp_print_string fmt (User.show u)
            | None -> Format.pp_print_string fmt "None"];
        mutable rest : Rest.t option [@opaque];
    } [@@deriving show]

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

    let user (c : t) : User.t option = c.user

    let rest (c : t) : Rest.t =
        match c.rest with
        | Some r -> r
        | None -> failwith "client: not started"

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
                (fun (cid, _) m acc ->
                   if cid = channel_id then m :: acc else acc)
                c.messages [])

    let log_decode_error (c : t) (name : string) (msg : string) : unit =
        let rec log () =
            let logged = Atomic.get c.decode_errors in
            if not (List.mem name logged) then
                if Atomic.compare_and_set c.decode_errors logged
                       (name :: logged)
                then prerr_endline (name ^ " decode failed: " ^ msg)
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

    let put_member (c : t) (guild_id : string) (user_id : string)
        (m : Member.t) : unit =
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

    let cache_event (c : t) (event : Discord_private.P_event.t)
        (json : Yojson.Safe.t) : unit =
        let open Yojson.Safe.Util in
        let name = Discord_private.P_event.to_string event in
        let decode of_yojson on_ok =
            match of_yojson json with
            | Ok v -> on_ok v
            | Error msg -> log_decode_error c name msg
        in
        match event with
        | Discord_private.P_event.Guild_create
        | Discord_private.P_event.Guild_update ->
            decode Guild.of_yojson (fun g ->
                Eio.Mutex.use_rw ~protect:true c.guilds_mutex (fun () ->
                    Hashtbl.replace c.guilds (Guild.id g) g);
                put_guild_channels c name (Guild.id g) json;
                List.iter
                    (fun m ->
                       put_member c (Guild.id g) (User.id (Member.user m)) m)
                    (Guild.members g))
        | Discord_private.P_event.Guild_delete ->
            (match json |> member "id" |> to_string_option with
             | Some guild_id ->
                 Eio.Mutex.use_rw ~protect:true c.guilds_mutex (fun () ->
                     Hashtbl.remove c.guilds guild_id);
                 drop_guild_channels c guild_id;
                 drop_guild_members c guild_id;
                 drop_guild_presences c guild_id
             | None -> ())
        | Discord_private.P_event.Channel_create
        | Discord_private.P_event.Channel_update
        | Discord_private.P_event.Thread_create
        | Discord_private.P_event.Thread_update ->
            decode Channel.of_yojson (put_channel c)
        | Discord_private.P_event.Channel_delete
        | Discord_private.P_event.Thread_delete ->
            (match json |> member "id" |> to_string_option with
             | Some cid -> remove_channel c cid
             | None -> ())
        | Discord_private.P_event.Guild_member_add
        | Discord_private.P_event.Guild_member_update ->
            (match Member.of_yojson json with
             | Ok m ->
                 (match json |> member "guild_id" |> to_string_option with
                  | Some guild_id ->
                      put_member c guild_id (User.id (Member.user m)) m
                  | None -> ())
             | Error msg -> log_decode_error c name msg)
        | Discord_private.P_event.Guild_member_remove ->
            (match json |> member "guild_id" |> to_string_option with
             | Some guild_id ->
                 (match
                      json |> member "user" |> member "id" |> to_string_option
                  with
                  | Some user_id -> remove_member c guild_id user_id
                  | None -> ())
             | None -> ())
        | Discord_private.P_event.Presence_update ->
            (match Presence.of_yojson json with
             | Ok p ->
                 (match Presence.guild_id p with
                  | Some guild_id ->
                      put_presence c guild_id (User.id (Presence.user p)) p
                  | None -> ())
             | Error msg -> log_decode_error c name msg)
        | Discord_private.P_event.Message_update ->
            decode Message.of_yojson (put_message c)
        | Discord_private.P_event.Message_delete ->
            (match ( json |> member "channel_id" |> to_string_option,
                     json |> member "id" |> to_string_option ) with
             | Some channel_id, Some message_id ->
                 remove_message c channel_id message_id
             | _ -> ())
        | Discord_private.P_event.Message_delete_bulk ->
            (match json |> member "channel_id" |> to_string_option with
             | Some channel_id ->
                 (match json |> member "ids" with
                  | `List ids ->
                      List.iter
                          (function
                            | `String message_id ->
                                remove_message c channel_id message_id
                            | _ -> ())
                          ids
                  | _ -> ())
             | None -> ())
        | _ -> ()

    let add_handler (c : t) (event : Discord_private.P_event.t) (f : t -> unit) : unit =
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

    let add_message_handler (c : t) (f : t -> Message.t -> unit) : unit =
        let rec add () =
            let old = Atomic.get c.message_handlers in
            if not (Atomic.compare_and_set c.message_handlers old (f :: old))
            then add ()
        in
        add ()

    let on_ready (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Ready f

    let on_resumed (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Resumed f

    let on_application_command_permissions_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Application_command_permissions_update f

    let on_auto_moderation_rule_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Auto_moderation_rule_create f

    let on_auto_moderation_rule_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Auto_moderation_rule_update f

    let on_auto_moderation_rule_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Auto_moderation_rule_delete f

    let on_auto_moderation_action_execution (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Auto_moderation_action_execution f

    let on_channel_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Channel_create f

    let on_channel_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Channel_update f

    let on_channel_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Channel_delete f

    let on_channel_info (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Channel_info f

    let on_channel_pins_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Channel_pins_update f

    let on_thread_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_create f

    let on_thread_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_update f

    let on_thread_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_delete f

    let on_thread_list_sync (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_list_sync f

    let on_thread_member_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_member_update f

    let on_thread_members_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Thread_members_update f

    let on_voice_channel_status_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Voice_channel_status_update f

    let on_voice_channel_start_time_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Voice_channel_start_time_update f

    let on_entitlement_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Entitlement_create f

    let on_entitlement_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Entitlement_update f

    let on_entitlement_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Entitlement_delete f

    let on_subscription_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Subscription_create f

    let on_subscription_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Subscription_update f

    let on_subscription_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Subscription_delete f

    let on_guild_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_create f

    let on_guild_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_update f

    let on_guild_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_delete f

    let on_guild_audit_log_entry_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_audit_log_entry_create f

    let on_guild_ban_add (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_ban_add f

    let on_guild_ban_remove (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_ban_remove f

    let on_guild_emojis_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_emojis_update f

    let on_guild_stickers_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_stickers_update f

    let on_guild_integrations_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_integrations_update f

    let on_guild_member_add (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_member_add f

    let on_guild_member_remove (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_member_remove f

    let on_guild_member_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_member_update f

    let on_guild_members_chunk (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_members_chunk f

    let on_guild_role_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_role_create f

    let on_guild_role_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_role_update f

    let on_guild_role_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_role_delete f

    let on_guild_scheduled_event_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_scheduled_event_create f

    let on_guild_scheduled_event_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_scheduled_event_update f

    let on_guild_scheduled_event_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_scheduled_event_delete f

    let on_guild_scheduled_event_user_add (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_scheduled_event_user_add f

    let on_guild_scheduled_event_user_remove (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_scheduled_event_user_remove f

    let on_guild_soundboard_sound_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_soundboard_sound_create f

    let on_guild_soundboard_sound_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_soundboard_sound_update f

    let on_guild_soundboard_sound_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_soundboard_sound_delete f

    let on_guild_soundboard_sounds_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Guild_soundboard_sounds_update f

    let on_soundboard_sounds (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Soundboard_sounds f

    let on_integration_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Integration_create f

    let on_integration_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Integration_update f

    let on_integration_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Integration_delete f

    let on_interaction_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Interaction_create f

    let on_invite_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Invite_create f

    let on_invite_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Invite_delete f

    let on_message (c : t) (f : t -> Message.t -> unit) : unit =
        add_message_handler c f

    let on_message_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_update f

    let on_message_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_delete f

    let on_message_delete_bulk (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_delete_bulk f

    let on_message_reaction_add (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_reaction_add f

    let on_message_reaction_remove (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_reaction_remove f

    let on_message_reaction_remove_all (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_reaction_remove_all f

    let on_message_reaction_remove_emoji (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_reaction_remove_emoji f

    let on_message_poll_vote_add (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_poll_vote_add f

    let on_message_poll_vote_remove (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Message_poll_vote_remove f

    let on_presence_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Presence_update f

    let on_stage_instance_create (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Stage_instance_create f

    let on_stage_instance_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Stage_instance_update f

    let on_stage_instance_delete (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Stage_instance_delete f

    let on_typing_start (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Typing_start f

    let on_user_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.User_update f

    let on_voice_channel_effect_send (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Voice_channel_effect_send f

    let on_voice_state_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Voice_state_update f

    let on_voice_server_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Voice_server_update f

    let on_webhooks_update (c : t) (f : t -> unit) : unit =
        add_handler c Discord_private.P_event.Webhooks_update f


    let create (i : int) : t = {
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
        decode_errors = Atomic.make [];
        shards = Hashtbl.create 0;
        shards_mutex = Eio.Mutex.create ();
        handlers = Atomic.make (Hashtbl.create 0);
        message_handlers = Atomic.make [];
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
            | Some Discord_private.P_event.Message_create ->
                (match Message.of_yojson json with
                 | Ok message ->
                     put_message c message;
                     List.iter
                         (fun f -> Eio.Fiber.fork ~sw (fun () -> f c message))
                         (Atomic.get c.message_handlers)
                 | Error msg ->
                     log_decode_error c "MESSAGE_CREATE" msg)
            | Some event ->
                cache_event c event json;
                (match event with
                 | Discord_private.P_event.Ready ->
                     (match User.of_yojson (json |> member "user") with
                      | Ok user -> c.user <- Some user
                      | Error _ -> ())
                 | _ -> ());
                let handlers =
                    match Hashtbl.find_opt (Atomic.get c.handlers) event with
                    | Some l -> l
                    | None -> []
                in
                List.iter
                    (fun f -> Eio.Fiber.fork ~sw (fun () -> f c))
                    handlers
        in
        let rec spawn i =
            if i < info.shards then begin
                let shard =
                    Discord_private.P_shard.connect ~url:info.url
                        ~id:i ~num_shards:info.shards ~token ~intents:c.intents
                in
                Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
                    Hashtbl.replace c.shards i shard);
                Eio.Fiber.fork ~sw (fun () ->
                    Fun.protect
                        ~finally:(fun () ->
                            Eio.Mutex.use_rw ~protect:true c.shards_mutex (fun () ->
                                Hashtbl.remove c.shards i))
                        (fun () ->
                            Discord_private.P_shard.run ~net ~dispatch clock
                                shard));
                if (i + 1) mod info.max_concurrency = 0
                   && i + 1 < info.shards then
                    Eio.Time.sleep clock 5.;
                spawn (i + 1)
            end
        in
        spawn 0

end : Client)
