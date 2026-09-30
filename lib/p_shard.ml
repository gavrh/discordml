module type Shard = sig
    type t

    val connect : sw:Eio.Switch.t -> net:'a Eio.Net.t -> int -> t

    val show : t -> string
end

include (struct

    type t = {
        id : int;
        conn : P_ws.t [@opaque];
    } [@@deriving show]

    let connect ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) (i : int) : t =
        { id = i; conn = P_ws.connect ~sw ~net ~url:P_ws.gateway }

end : Shard)
