module type Presence = sig
  type timestamps = { start : int option; end_ : int option }
  type party_size = { current_size : int; max_size : int }
  type party = { id : string option; size : party_size option }

  type assets = {
    large_image : string option;
    large_text : string option;
    small_image : string option;
    small_text : string option;
  }

  type secrets = {
    join : string option;
    spectate : string option;
    match_ : string option;
  }

  type activity_button = { label : string; url : string }

  type activity = {
    name : string;
    type_ : int;
    url : string option;
    created_at : int;
    timestamps : timestamps option;
    application_id : string option;
    details : string option;
    state : string option;
    emoji : Emoji.t option;
    party : party option;
    assets : assets option;
    secrets : secrets option;
    instance : bool option;
    flags : int;
    buttons : activity_button list;
  }

  type client_status = {
    desktop : string option;
    mobile : string option;
    web : string option;
  }

  type t = {
    user : User.t;
    guild_id : string option;
    status : string;
    activities : activity list;
    client_status : client_status option;
  }

  val user : t -> User.t
  val guild_id : t -> string option
  val status : t -> string
  val activities : t -> activity list
  val client_status : t -> client_status option
  val activity_of_yojson : Yojson.Safe.t -> (activity, string) result
  val pp_activity : Format.formatter -> activity -> unit
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type timestamps = { start : int option; end_ : int option }
    [@@deriving show, eq]

    type party_size = { current_size : int; max_size : int }
    [@@deriving show, eq]

    type party = { id : string option; size : party_size option }
    [@@deriving show, eq]

    type assets = {
      large_image : string option;
      large_text : string option;
      small_image : string option;
      small_text : string option;
    }
    [@@deriving show, eq]

    type secrets = {
      join : string option;
      spectate : string option;
      match_ : string option;
    }
    [@@deriving show, eq]

    type activity_button = { label : string; url : string }
    [@@deriving show, eq]

    type activity = {
      name : string;
      type_ : int;
      url : string option;
      created_at : int;
      timestamps : timestamps option;
      application_id : string option;
      details : string option;
      state : string option;
      emoji : Emoji.t option;
      party : party option;
      assets : assets option;
      secrets : secrets option;
      instance : bool option;
      flags : int;
      buttons : activity_button list;
    }
    [@@deriving show, eq]

    type client_status = {
      desktop : string option;
      mobile : string option;
      web : string option;
    }
    [@@deriving show, eq]

    type t = {
      user : User.t;
      guild_id : string option;
      status : string;
      activities : activity list;
      client_status : client_status option;
    }
    [@@deriving show, eq]

    let user (p : t) : User.t = p.user
    let guild_id (p : t) : string option = p.guild_id
    let status (p : t) : string = p.status
    let activities (p : t) : activity list = p.activities
    let client_status (p : t) : client_status option = p.client_status

    let option_int (json : Yojson.Safe.t) (name : string) : int option =
      Yojson.Safe.Util.(json |> member name |> to_int_option)

    let option_string (json : Yojson.Safe.t) (name : string) : string option =
      Yojson.Safe.Util.(json |> member name |> to_string_option)

    let parse_timestamps (json : Yojson.Safe.t) : timestamps =
      { start = option_int json "start"; end_ = option_int json "end" }

    let parse_party (json : Yojson.Safe.t) : party =
      let open Yojson.Safe.Util in
      let size =
        match json |> member "size" with
        | `List [ `Int current_size; `Int max_size ] ->
            Some { current_size; max_size }
        | _ -> None
      in
      { id = json |> member "id" |> to_string_option; size }

    let parse_assets (json : Yojson.Safe.t) : assets =
      {
        large_image = option_string json "large_image";
        large_text = option_string json "large_text";
        small_image = option_string json "small_image";
        small_text = option_string json "small_text";
      }

    let parse_secrets (json : Yojson.Safe.t) : secrets =
      {
        join = option_string json "join";
        spectate = option_string json "spectate";
        match_ = option_string json "match";
      }

    let parse_button (json : Yojson.Safe.t) : activity_button =
      {
        label = option_string json "label" |> Option.value ~default:"";
        url = option_string json "url" |> Option.value ~default:"";
      }

    let parse_option (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> 'a) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> Some (f v)

    let activity_of_yojson (a : Yojson.Safe.t) : (activity, string) result =
      let open Yojson.Safe.Util in
      try
        let emoji =
          match a |> member "emoji" with
          | `Null -> None
          | e -> (
              match Emoji.of_yojson e with
              | Ok emoji -> Some emoji
              | Error msg -> raise (Failure msg))
        in
        Ok
          {
            name = a |> member "name" |> to_string;
            type_ =
              a |> member "type" |> to_int_option |> Option.value ~default:0;
            url = a |> member "url" |> to_string_option;
            created_at =
              a |> member "created_at" |> to_int_option
              |> Option.value ~default:0;
            timestamps = parse_option a "timestamps" parse_timestamps;
            application_id = a |> member "application_id" |> to_string_option;
            details = a |> member "details" |> to_string_option;
            state = a |> member "state" |> to_string_option;
            emoji;
            party = parse_option a "party" parse_party;
            assets = parse_option a "assets" parse_assets;
            secrets = parse_option a "secrets" parse_secrets;
            instance = a |> member "instance" |> to_bool_option;
            flags =
              a |> member "flags" |> to_int_option |> Option.value ~default:0;
            buttons =
              (match a |> member "buttons" with
              | `List b -> List.map parse_button b
              | _ -> []);
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let user =
          match User.of_yojson (json |> member "user") with
          | Ok user -> user
          | Error msg -> raise (Failure msg)
        in
        let activities =
          match json |> member "activities" with
          | `List l ->
              List.filter_map
                (fun a ->
                  match activity_of_yojson a with
                  | Ok activity -> Some activity
                  | Error _ -> None)
                l
          | _ -> []
        in
        let client_status =
          match json |> member "client_status" with
          | `Null -> None
          | c ->
              Some
                {
                  desktop = c |> member "desktop" |> to_string_option;
                  mobile = c |> member "mobile" |> to_string_option;
                  web = c |> member "web" |> to_string_option;
                }
        in
        Ok
          {
            user;
            guild_id = json |> member "guild_id" |> to_string_option;
            status =
              json |> member "status" |> to_string_option
              |> Option.value ~default:"offline";
            activities;
            client_status;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Presence)
