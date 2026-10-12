module type Attachment = sig
    type t

    val create : ?content_type:string -> name:string -> string -> t
    val name : t -> string
    val content : t -> string
    val content_type : t -> string option

    val pp : Format.formatter -> t -> unit
end

include (struct

    type t = {
        name : string;
        content : string;
        content_type : string option;
    } [@@deriving show]

    let create ?content_type ~name (content : string) : t =
        { name; content; content_type }

    let name (a : t) : string = a.name
    let content (a : t) : string = a.content
    let content_type (a : t) : string option = a.content_type

end : Attachment)
