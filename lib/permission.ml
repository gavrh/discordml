module type Permission = sig
    type t = int64

    val of_yojson : Yojson.Safe.t -> t
    val of_string : string -> t
    val to_string : t -> string
    val has : t -> t -> bool

    val create_instant_invite : t
    val kick_members : t
    val ban_members : t
    val administrator : t
    val manage_channels : t
    val manage_guild : t
    val add_reactions : t
    val view_audit_log : t
    val priority_speaker : t
    val stream : t
    val view_channel : t
    val send_messages : t
    val send_tts_messages : t
    val manage_messages : t
    val embed_links : t
    val attach_files : t
    val read_message_history : t
    val mention_everyone : t
    val use_external_emojis : t
    val view_guild_insights : t
    val connect : t
    val speak : t
    val mute_members : t
    val deafen_members : t
    val move_members : t
    val use_vad : t
    val change_nickname : t
    val manage_nicknames : t
    val manage_roles : t
    val manage_webhooks : t
    val manage_guild_expressions : t
    val use_application_commands : t
    val request_to_speak : t
    val manage_events : t
    val manage_threads : t
    val create_public_threads : t
    val create_private_threads : t
    val use_external_stickers : t
    val send_messages_in_threads : t
    val use_embedded_activities : t
    val moderate_members : t
    val view_creator_monetization_analytics : t
    val use_soundboard : t
    val create_guild_expressions : t
    val create_events : t
    val use_external_sounds : t
    val send_voice_messages : t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
end

include (struct
    type t = int64

    let bit n = Int64.shift_left 1L n

    let create_instant_invite = bit 0
    let kick_members = bit 1
    let ban_members = bit 2
    let administrator = bit 3
    let manage_channels = bit 4
    let manage_guild = bit 5
    let add_reactions = bit 6
    let view_audit_log = bit 7
    let priority_speaker = bit 8
    let stream = bit 9
    let view_channel = bit 10
    let send_messages = bit 11
    let send_tts_messages = bit 12
    let manage_messages = bit 13
    let embed_links = bit 14
    let attach_files = bit 15
    let read_message_history = bit 16
    let mention_everyone = bit 17
    let use_external_emojis = bit 18
    let view_guild_insights = bit 19
    let connect = bit 20
    let speak = bit 21
    let mute_members = bit 22
    let deafen_members = bit 23
    let move_members = bit 24
    let use_vad = bit 25
    let change_nickname = bit 26
    let manage_nicknames = bit 27
    let manage_roles = bit 28
    let manage_webhooks = bit 29
    let manage_guild_expressions = bit 30
    let use_application_commands = bit 31
    let request_to_speak = bit 32
    let manage_events = bit 33
    let manage_threads = bit 34
    let create_public_threads = bit 35
    let create_private_threads = bit 36
    let use_external_stickers = bit 37
    let send_messages_in_threads = bit 38
    let use_embedded_activities = bit 39
    let moderate_members = bit 40
    let view_creator_monetization_analytics = bit 41
    let use_soundboard = bit 42
    let create_guild_expressions = bit 43
    let create_events = bit 44
    let use_external_sounds = bit 45
    let send_voice_messages = bit 46

    let of_string (s : string) : t =
        match Int64.of_string_opt s with Some v -> v | None -> 0L

    let to_string (t : t) : string = Int64.to_string t

    let has (t : t) (flag : t) : bool = Int64.logand t flag <> 0L

    let of_yojson (json : Yojson.Safe.t) : t =
        match json with
        | `String s -> of_string s
        | `Int n -> Int64.of_int n
        | `Intlit s -> of_string s
        | `Float f -> Int64.of_float f
        | _ -> 0L

    let pp (fmt : Format.formatter) (t : t) : unit =
        Format.fprintf fmt "%Ld" t

    let equal = Int64.equal
    let show (t : t) : string = Int64.to_string t

end : Permission)
