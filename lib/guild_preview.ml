module type Guild_preview = sig
  type t = {
    id : string;
    name : string;
    icon : string option;
    splash : string option;
    discovery_splash : string option;
    emojis : Emoji.t list;
    features : string list;
    approximate_member_count : int;
    approximate_presence_count : int;
    description : string option;
    stickers : Sticker.t list;
  }

  val id : t -> string
  val name : t -> string
  val icon : t -> string option
  val splash : t -> string option
  val discovery_splash : t -> string option
  val emojis : t -> Emoji.t list
  val features : t -> string list
  val approximate_member_count : t -> int
  val approximate_presence_count : t -> int
  val description : t -> string option
  val stickers : t -> Sticker.t list
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type t = {
      id : string;
      name : string;
      icon : string option;
      splash : string option;
      discovery_splash : string option;
      emojis : Emoji.t list;
      features : string list;
      approximate_member_count : int;
      approximate_presence_count : int;
      description : string option;
      stickers : Sticker.t list;
    }
    [@@deriving show, eq]

    let id (g : t) : string = g.id
    let name (g : t) : string = g.name
    let icon (g : t) : string option = g.icon
    let splash (g : t) : string option = g.splash
    let discovery_splash (g : t) : string option = g.discovery_splash
    let emojis (g : t) : Emoji.t list = g.emojis
    let features (g : t) : string list = g.features
    let approximate_member_count (g : t) : int = g.approximate_member_count
    let approximate_presence_count (g : t) : int = g.approximate_presence_count
    let description (g : t) : string option = g.description
    let stickers (g : t) : Sticker.t list = g.stickers

    let string_list (json : Yojson.Safe.t) : string list =
      match json with
      | `List l ->
          List.filter_map (function `String s -> Some s | _ -> None) l
      | _ -> []

    let parse_list (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : 'a list =
      match Yojson.Safe.Util.member name json with
      | `List l ->
          List.filter_map
            (fun item ->
              match f item with Ok value -> Some value | Error _ -> None)
            l
      | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            id = json |> member "id" |> to_string;
            name = json |> member "name" |> to_string;
            icon = json |> member "icon" |> to_string_option;
            splash = json |> member "splash" |> to_string_option;
            discovery_splash =
              json |> member "discovery_splash" |> to_string_option;
            emojis = parse_list json "emojis" Emoji.of_yojson;
            features = string_list (json |> member "features");
            approximate_member_count =
              json
              |> member "approximate_member_count"
              |> to_int_option |> Option.value ~default:0;
            approximate_presence_count =
              json
              |> member "approximate_presence_count"
              |> to_int_option |> Option.value ~default:0;
            description = json |> member "description" |> to_string_option;
            stickers = parse_list json "stickers" Sticker.of_yojson;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Guild_preview)
