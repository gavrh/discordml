module type Client = sig
    type t

    val token : t -> string option

    val create : int -> t
    val start : env:Eio_unix.Stdenv.base -> t -> string -> unit

    val guild : t -> string -> Guild.t option
    val user : t -> User.t option
    val rest : t -> Rest.t

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

    let user (c : t) : User.t option = c.user

    let rest (c : t) : Rest.t =
        match c.rest with
        | Some r -> r
        | None -> failwith "client: not started"

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
        let code, body = Rest.request rest Rest.Get "/gateway/bot" in
        if code <> 200 then
            failwith (Printf.sprintf "gateway/bot: HTTP %d: %s" code body);
        let url, shards, max_concurrency =
            let json = Yojson.Safe.from_string body in
            let open Yojson.Safe.Util in
            ( json |> member "url" |> to_string,
              json |> member "shards" |> to_int,
              json |> member "session_start_limit" |> member "max_concurrency"
              |> to_int )
        in
        let open Yojson.Safe.Util in
        let dispatch (name : string) (json : Yojson.Safe.t) : unit =
            match Discord_private.P_event.of_string name with
            | None -> ()
            | Some Discord_private.P_event.Message_create ->
                (match Message.of_yojson json with
                 | Ok message ->
                     List.iter
                         (fun f -> Eio.Fiber.fork ~sw (fun () -> f c message))
                         (Atomic.get c.message_handlers)
                 | Error _ -> ())
            | Some event ->
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
            if i < shards then begin
                let shard =
                    Discord_private.P_shard.connect ~url
                        ~id:i ~num_shards:shards ~token ~intents:c.intents
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
                if (i + 1) mod max_concurrency = 0 then
                    Eio.Time.sleep clock 5.;
                spawn (i + 1)
            end
        in
        spawn 0

end : Client)
