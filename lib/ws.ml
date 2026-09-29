module type Ws = sig
    type t

    val gateway_version : string
    val encoding : string
    val gateway : string

    val connect : sw:Eio.Switch.t -> net:'a Eio.Net.t -> t

    val send_text : t -> string -> unit
    val send_binary : t -> string -> unit
    val recv : t -> string option
    val close : t -> unit
    val is_closed : t -> bool
end

include (struct

    let gateway_version : string = "10"
    let encoding : string = "json"
    let gateway : string =
        "wss://gateway.discord.gg/?v=" ^ gateway_version ^ "&encoding=" ^ encoding

    type t = Websocket.t

    let connect ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) : t =
        Websocket.connect ~sw ~net gateway

    let send_text = Websocket.send_text
    let send_binary = Websocket.send_binary
    let recv = Websocket.recv
    let close = Websocket.close
    let is_closed = Websocket.is_closed

end : Ws)
