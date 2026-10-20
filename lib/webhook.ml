module type Webhook = sig
  type webhook_guild = { id : string; name : string; icon : string option }

  type t = {
    id : string;
    type_ : int;
    guild_id : string option;
    channel_id : string option;
    user : User.t option;
    name : string option;
    avatar : string option;
    token : string option;
        [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    application_id : string option;
    source_guild : webhook_guild option;
    source_channel : Channel.t option;
    url : string option;
  }

  val id : t -> string
  val type_ : t -> int
  val guild_id : t -> string option
  val channel_id : t -> string option
  val user : t -> User.t option
  val name : t -> string option
  val avatar : t -> string option
  val token : t -> string option
  val application_id : t -> string option
  val source_guild : t -> webhook_guild option
  val source_channel : t -> Channel.t option
  val url : t -> string option
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type webhook_guild = { id : string; name : string; icon : string option }
    [@@deriving show, eq]

    type t = {
      id : string;
      type_ : int;
      guild_id : string option;
      channel_id : string option;
      user : User.t option;
      name : string option;
      avatar : string option;
      token : string option;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
      application_id : string option;
      source_guild : webhook_guild option;
      source_channel : Channel.t option;
      url : string option;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    }
    [@@deriving show, eq]

    let id (w : t) : string = w.id
    let type_ (w : t) : int = w.type_
    let guild_id (w : t) : string option = w.guild_id
    let channel_id (w : t) : string option = w.channel_id
    let user (w : t) : User.t option = w.user
    let name (w : t) : string option = w.name
    let avatar (w : t) : string option = w.avatar
    let token (w : t) : string option = w.token
    let application_id (w : t) : string option = w.application_id
    let source_guild (w : t) : webhook_guild option = w.source_guild
    let source_channel (w : t) : Channel.t option = w.source_channel
    let url (w : t) : string option = w.url

    let parse_opt (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> ('a, string) result) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> (
          match f v with Ok x -> Some x | Error msg -> raise (Failure msg))

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let source_guild =
          match json |> member "source_guild" with
          | `Null -> None
          | g ->
              Some
                {
                  id = g |> member "id" |> to_string;
                  name = g |> member "name" |> to_string;
                  icon = g |> member "icon" |> to_string_option;
                }
        in
        Ok
          {
            id = json |> member "id" |> to_string;
            type_ =
              json |> member "type" |> to_int_option |> Option.value ~default:0;
            guild_id = json |> member "guild_id" |> to_string_option;
            channel_id = json |> member "channel_id" |> to_string_option;
            user = parse_opt json "user" User.of_yojson;
            name = json |> member "name" |> to_string_option;
            avatar = json |> member "avatar" |> to_string_option;
            token = json |> member "token" |> to_string_option;
            application_id = json |> member "application_id" |> to_string_option;
            source_guild;
            source_channel = parse_opt json "source_channel" Channel.of_yojson;
            url = json |> member "url" |> to_string_option;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Webhook)
