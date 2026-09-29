module type Channel = sig
    type t

    val show : t -> string
end

include (struct

    type t = {
        id : string;
    } [@@deriving show, eq]

end : Channel)
