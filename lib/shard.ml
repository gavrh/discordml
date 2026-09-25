type t = {
    id : int;
    conn : Ws.t;
} [@@deriving show, eq]

let create (i : int) : t =
    match Ws.create i with
    | None -> failwith (Printf.sprintf "Failed to init gateway connection (Shard %d)" i)
    | Some ws -> { id = i; conn = ws }
