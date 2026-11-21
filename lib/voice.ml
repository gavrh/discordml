type state = P_voice.state =
  | Disconnected
  | Connecting
  | Connected
  | Reconnecting
  | Closed

type t = P_voice.t

module type Voice = sig
  val guild_id : t -> string
  val channel_id : t -> string
  val state : t -> state
  val ssrc : t -> int option
  val self_mute : t -> bool
  val self_deaf : t -> bool
  val on_state_change : t -> (t -> state -> unit) -> unit
  val play : t -> source:(unit -> int array option) -> unit
  val set_self_mute : t -> bool -> unit
  val set_self_deaf : t -> bool -> unit
  val leave : t -> unit
end

include (P_voice : Voice)
