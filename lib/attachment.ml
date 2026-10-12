module type Attachment = sig
    type t

    val create : ?content_type:string -> name:string -> string -> t
    val id : t -> string option
    val name : t -> string
    val content : t -> string
    val content_type : t -> string option
    val description : t -> string option
    val size : t -> int option
    val url : t -> string option
    val proxy_url : t -> string option
    val height : t -> int option
    val width : t -> int option
    val ephemeral : t -> bool
    val duration : t -> int option
    val waveform : t -> string option
    val flags : t -> int option

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val pp : Format.formatter -> t -> unit
    val show : t -> string
end

include (struct

    type t = {
        name : string;
        content : string;
        content_type : string option;
        id : string option;
        description : string option;
        size : int option;
        url : string option;
        proxy_url : string option;
        height : int option;
        width : int option;
        ephemeral : bool;
        duration : int option;
        waveform : string option;
        flags : int option;
    } [@@deriving show]

    let create ?content_type ~name (content : string) : t =
        { name;
          content;
          content_type;
          id = None;
          description = None;
          size = None;
          url = None;
          proxy_url = None;
          height = None;
          width = None;
          ephemeral = false;
          duration = None;
          waveform = None;
          flags = None }

    let id (a : t) : string option = a.id
    let name (a : t) : string = a.name
    let content (a : t) : string = a.content
    let content_type (a : t) : string option = a.content_type
    let description (a : t) : string option = a.description
    let size (a : t) : int option = a.size
    let url (a : t) : string option = a.url
    let proxy_url (a : t) : string option = a.proxy_url
    let height (a : t) : int option = a.height
    let width (a : t) : int option = a.width
    let ephemeral (a : t) : bool = a.ephemeral
    let duration (a : t) : int option = a.duration
    let waveform (a : t) : string option = a.waveform
    let flags (a : t) : int option = a.flags

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { name = json |> member "filename" |> to_string;
                  content = "";
                  content_type = json |> member "content_type" |> to_string_option;
                  id = json |> member "id" |> to_string_option;
                  description = json |> member "description" |> to_string_option;
                  size = json |> member "size" |> to_int_option;
                  url = json |> member "url" |> to_string_option;
                  proxy_url = json |> member "proxy_url" |> to_string_option;
                  height = json |> member "height" |> to_int_option;
                  width = json |> member "width" |> to_int_option;
                  ephemeral =
                    json |> member "ephemeral" |> to_bool_option
                    |> Option.value ~default:false;
                  duration = json |> member "duration" |> to_int_option;
                  waveform = json |> member "waveform" |> to_string_option;
                  flags = json |> member "flags" |> to_int_option }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : Attachment)
