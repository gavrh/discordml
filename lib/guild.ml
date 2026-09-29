module type Guild = sig
    type t
    val id : t -> string

    val create : string -> t

    val show : t -> string
end

include (struct

    type t = {
        id : string;
    } [@@deriving show, eq]

    let id (g : t) = g.id

    let create (i : string) : t = { id = i; }

end : Guild)
