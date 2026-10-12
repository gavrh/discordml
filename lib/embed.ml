module type Embed = sig
    module Author : sig
        type t = {
            name : string;
            url : string option;
            icon_url : string option;
            proxy_icon_url : string option;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Footer : sig
        type t = {
            text : string;
            icon_url : string option;
            proxy_icon_url : string option;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Image : sig
        type t = {
            url : string;
            proxy_url : string option;
            height : int option;
            width : int option;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Video : sig
        type t = {
            url : string option;
            proxy_url : string option;
            height : int option;
            width : int option;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Provider : sig
        type t = {
            name : string option;
            url : string option;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    module Field : sig
        type t = {
            name : string;
            value : string;
            inline : bool;
        }

        val pp : Format.formatter -> t -> unit
        val equal : t -> t -> bool
        val of_yojson : Yojson.Safe.t -> (t, string) result
    end

    type t = {
        title : string option;
        type_ : string option;
        description : string option;
        url : string option;
        timestamp : string option;
        color : int option;
        footer : Footer.t option;
        image : Image.t option;
        thumbnail : Image.t option;
        video : Video.t option;
        provider : Provider.t option;
        author : Author.t option;
        fields : Field.t list;
    }

    val title : t -> string option
    val type_ : t -> string option
    val description : t -> string option
    val url : t -> string option
    val timestamp : t -> string option
    val color : t -> int option
    val footer : t -> Footer.t option
    val image : t -> Image.t option
    val thumbnail : t -> Image.t option
    val video : t -> Video.t option
    val provider : t -> Provider.t option
    val author : t -> Author.t option
    val fields : t -> Field.t list

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    module Author = struct
        type t = {
            name : string;
            url : string option;
            icon_url : string option;
            proxy_icon_url : string option;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { name = json |> member "name" |> to_string;
                      url = json |> member "url" |> to_string_option;
                      icon_url = json |> member "icon_url" |> to_string_option;
                      proxy_icon_url =
                        json |> member "proxy_icon_url" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Footer = struct
        type t = {
            text : string;
            icon_url : string option;
            proxy_icon_url : string option;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { text = json |> member "text" |> to_string;
                      icon_url = json |> member "icon_url" |> to_string_option;
                      proxy_icon_url =
                        json |> member "proxy_icon_url" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Image = struct
        type t = {
            url : string;
            proxy_url : string option;
            height : int option;
            width : int option;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { url = json |> member "url" |> to_string;
                      proxy_url = json |> member "proxy_url" |> to_string_option;
                      height = json |> member "height" |> to_int_option;
                      width = json |> member "width" |> to_int_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Video = struct
        type t = {
            url : string option;
            proxy_url : string option;
            height : int option;
            width : int option;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { url = json |> member "url" |> to_string_option;
                      proxy_url = json |> member "proxy_url" |> to_string_option;
                      height = json |> member "height" |> to_int_option;
                      width = json |> member "width" |> to_int_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Provider = struct
        type t = {
            name : string option;
            url : string option;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { name = json |> member "name" |> to_string_option;
                      url = json |> member "url" |> to_string_option }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    module Field = struct
        type t = {
            name : string;
            value : string;
            inline : bool;
        } [@@deriving show, eq]

        let of_yojson (json : Yojson.Safe.t) : (t, string) result =
            let open Yojson.Safe.Util in
            try
                Ok
                    { name = json |> member "name" |> to_string;
                      value = json |> member "value" |> to_string;
                      inline =
                        json |> member "inline" |> to_bool_option
                        |> Option.value ~default:false }
            with
            | Type_error (msg, _) -> Error msg
            | Undefined (msg, _) -> Error msg
    end

    type t = {
        title : string option;
        type_ : string option;
        description : string option;
        url : string option;
        timestamp : string option;
        color : int option;
        footer : Footer.t option;
        image : Image.t option;
        thumbnail : Image.t option;
        video : Video.t option;
        provider : Provider.t option;
        author : Author.t option;
        fields : Field.t list;
    } [@@deriving show, eq]

    let title (e : t) : string option = e.title
    let type_ (e : t) : string option = e.type_
    let description (e : t) : string option = e.description
    let url (e : t) : string option = e.url
    let timestamp (e : t) : string option = e.timestamp
    let color (e : t) : int option = e.color
    let footer (e : t) : Footer.t option = e.footer
    let image (e : t) : Image.t option = e.image
    let thumbnail (e : t) : Image.t option = e.thumbnail
    let video (e : t) : Video.t option = e.video
    let provider (e : t) : Provider.t option = e.provider
    let author (e : t) : Author.t option = e.author
    let fields (e : t) : Field.t list = e.fields

    let field_opt (json : Yojson.Safe.t) (name : string)
            (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
        match Yojson.Safe.Util.member name json with
        | `Null -> None
        | v ->
            (match f v with
             | Ok x -> Some x
             | Error msg -> raise (Failure msg))

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let fields =
                match json |> member "fields" with
                | `List l ->
                    List.map
                        (fun f ->
                           match Field.of_yojson f with
                           | Ok field -> field
                           | Error msg -> raise (Failure msg))
                        l
                | _ -> []
            in
            Ok
                { title = json |> member "title" |> to_string_option;
                  type_ = json |> member "type" |> to_string_option;
                  description = json |> member "description" |> to_string_option;
                  url = json |> member "url" |> to_string_option;
                  timestamp = json |> member "timestamp" |> to_string_option;
                  color = json |> member "color" |> to_int_option;
                  footer = field_opt json "footer" Footer.of_yojson;
                  image = field_opt json "image" Image.of_yojson;
                  thumbnail = field_opt json "thumbnail" Image.of_yojson;
                  video = field_opt json "video" Video.of_yojson;
                  provider = field_opt json "provider" Provider.of_yojson;
                  author = field_opt json "author" Author.of_yojson;
                  fields }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

end : Embed)
