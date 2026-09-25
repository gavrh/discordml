let gateway_version : string = "10"
let gateway : string =
    "wss://gateway.discord.gg/?v="
    ^ gateway_version

type t = {
    nothing : string;
} [@@deriving show, eq]

let create (shard : int) : t option = None
