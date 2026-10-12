module type Welcome_screen = sig
    type channel = {
        channel_id : string;
        description : string;
        emoji_id : string option;
        emoji_name : string option;
    }

    type t = {
        description : string option;
        welcome_channels : channel list;
    }

    val description : t -> string option
    val welcome_channels : t -> channel list

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
    val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (struct

    type channel = {
        channel_id : string;
        description : string;
        emoji_id : string option;
        emoji_name : string option;
    } [@@deriving show, eq]

    type t = {
        description : string option;
        welcome_channels : channel list;
    } [@@deriving show, eq]

    let description (w : t) : string option = w.description
    let welcome_channels (w : t) : channel list = w.welcome_channels

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let welcome_channels =
                match json |> member "welcome_channels" with
                | `List l ->
                    List.map
                        (fun c ->
                           { channel_id = c |> member "channel_id" |> to_string;
                             description =
                               c |> member "description" |> to_string_option
                               |> Option.value ~default:"";
                             emoji_id = c |> member "emoji_id" |> to_string_option;
                             emoji_name =
                               c |> member "emoji_name" |> to_string_option })
                        l
                | _ -> []
            in
            Ok
                { description = json |> member "description" |> to_string_option;
                  welcome_channels }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

end : Welcome_screen)
