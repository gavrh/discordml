type t = {
    id : string;
} [@@deriving show, eq]

let create (i : string) : t = { id = i; }
