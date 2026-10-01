module type Intent = sig
    val guilds : int
    val guild_members : int
    val guild_moderation : int
    val guild_expressions : int
    val guild_integrations : int
    val guild_webhoooks : int
    val guild_invites : int
    val guild_voice_states : int
    val guild_presences : int
    val guild_messages : int
    val guild_message_reactions : int
    val guild_message_typing : int
    val direct_messages : int
    val direct_message_reactions : int
    val direct_message_typing : int
    val message_content : int
    val guild_scheduled_events : int
    val auto_moderation_configuration : int
    val auto_moderation_execution : int
    val guild_message_polls : int
    val direct_message_polls : int
    val all : int
end

module type Client = sig
    module Intent : Intent

    type t
    type ctx

    val token : t -> string option

    val create : int -> t
    val start :
        env:< net : 'a Eio.Net.t; clock : 'b Eio.Time.clock; .. > ->
        t -> string -> unit

    val id : ctx -> string option
    val guild : ctx -> string -> Guild.t option

    val on_ready : t -> (ctx -> unit) -> unit

    val show : t -> string
end

include (struct

    module Intent = struct
        let guilds = 1 lsl 0
        let guild_members = 1 lsl 1
        let guild_moderation = 1 lsl 2
        let guild_expressions = 1 lsl 3
        let guild_integrations = 1 lsl 4
        let guild_webhoooks = 1 lsl 5
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
        let all =
            guilds lor
            guild_members lor
            guild_moderation lor
            guild_expressions lor
            guild_integrations lor
            guild_webhoooks lor
            guild_invites lor
            guild_invites lor
            guild_voice_states lor
            guild_presences lor
            guild_messages lor
            guild_message_reactions lor
            guild_message_typing lor
            direct_messages lor
            direct_message_reactions lor
            direct_message_typing lor
            message_content lor
            guild_scheduled_events lor
            auto_moderation_configuration lor
            auto_moderation_execution lor
            guild_message_polls lor
            direct_message_polls
    end

    type t = {
        token : string option;
        mutable id : string option;
        intents : int;
        guilds : (string, Guild.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        guilds_mutex : Eio.Mutex.t [@opaque];
        shards : (int, Discord_private.P_shard.t) Hashtbl.t [@printer fun fmt tbl -> Format.fprintf fmt "[ ...%d ]" (Hashtbl.length tbl)];
        shards_mutex : Eio.Mutex.t [@opaque];
        mutable on_ready : (t -> unit) list [@opaque];
    } [@@deriving show]

    type ctx = t

    let token (c : t) : string option = c.token
    let id (c : ctx) : string option = c.id

    let guild (c : ctx) (gid : string) : Guild.t option =
        Eio.Mutex.use_ro c.guilds_mutex (fun () -> Hashtbl.find_opt c.guilds gid)

    let on_ready (c : t) (f : ctx -> unit) : unit =
        c.on_ready <- f :: c.on_ready

    let create (i : int) : t = {
        token = None;
        id = None;
        intents = i;
        guilds = Hashtbl.create 0;
        guilds_mutex = Eio.Mutex.create ();
        shards = Hashtbl.create 0;
        shards_mutex = Eio.Mutex.create ();
        on_ready = [];
    }

    let start ~env (c : t) (token : string) : unit =
        let net = Eio.Stdenv.net env in
        let clock = Eio.Stdenv.clock env in
        Eio.Switch.run @@ fun sw ->
        let info = Discord_private.P_rest.gateway_bot ~sw ~net ~token in
        let handle_ready (r : Discord_private.P_shard.ready) =
            c.id <- Some r.user_id;
            List.iter (fun f -> Eio.Fiber.fork ~sw (fun () -> f c)) c.on_ready
        in
        let rec spawn i =
            if i < info.shards then begin
                let shard =
                    Discord_private.P_shard.connect ~sw ~net ~url:info.url
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
                            Discord_private.P_shard.run ~on_ready:handle_ready
                                clock shard));
                if (i + 1) mod info.max_concurrency = 0 then
                    Eio.Time.sleep clock 5.;
                spawn (i + 1)
            end
        in
        spawn 0

end : Client)
