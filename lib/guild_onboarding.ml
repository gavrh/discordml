module type Guild_onboarding = sig
  type prompt_option = {
    id : string;
    channel_ids : string list;
    role_ids : string list;
    emoji : Emoji.t option;
    title : string;
    description : string option;
  }

  type prompt = {
    id : string;
    type_ : int;
    options : prompt_option list;
    title : string;
    single_select : bool;
    required : bool;
    in_onboarding : bool;
  }

  type t = {
    guild_id : string;
    prompts : prompt list;
    default_channel_ids : string list;
    enabled : bool;
    mode : int;
  }

  val guild_id : t -> string
  val prompts : t -> prompt list
  val default_channel_ids : t -> string list
  val enabled : t -> bool
  val mode : t -> int
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type prompt_option = {
      id : string;
      channel_ids : string list;
      role_ids : string list;
      emoji : Emoji.t option;
      title : string;
      description : string option;
    }
    [@@deriving show, eq]

    type prompt = {
      id : string;
      type_ : int;
      options : prompt_option list;
      title : string;
      single_select : bool;
      required : bool;
      in_onboarding : bool;
    }
    [@@deriving show, eq]

    type t = {
      guild_id : string;
      prompts : prompt list;
      default_channel_ids : string list;
      enabled : bool;
      mode : int;
    }
    [@@deriving show, eq]

    let guild_id (o : t) : string = o.guild_id
    let prompts (o : t) : prompt list = o.prompts
    let default_channel_ids (o : t) : string list = o.default_channel_ids
    let enabled (o : t) : bool = o.enabled
    let mode (o : t) : int = o.mode

    let string_list (json : Yojson.Safe.t) : string list =
      match json with
      | `List l ->
          List.filter_map (function `String s -> Some s | _ -> None) l
      | _ -> []

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let prompts =
          match json |> member "prompts" with
          | `List l ->
              List.map
                (fun p ->
                  let options =
                    match p |> member "options" with
                    | `List ol ->
                        List.map
                          (fun o ->
                            let emoji =
                              match o |> member "emoji" with
                              | `Null -> None
                              | e -> (
                                  match Emoji.of_yojson e with
                                  | Ok emoji -> Some emoji
                                  | Error msg -> raise (Failure msg))
                            in
                            {
                              id = o |> member "id" |> to_string;
                              channel_ids =
                                string_list (o |> member "channel_ids");
                              role_ids = string_list (o |> member "role_ids");
                              emoji;
                              title = o |> member "title" |> to_string;
                              description =
                                o |> member "description" |> to_string_option;
                            })
                          ol
                    | _ -> []
                  in
                  {
                    id = p |> member "id" |> to_string;
                    type_ =
                      p |> member "type" |> to_int_option
                      |> Option.value ~default:0;
                    options;
                    title = p |> member "title" |> to_string;
                    single_select =
                      p |> member "single_select" |> to_bool_option
                      |> Option.value ~default:false;
                    required =
                      p |> member "required" |> to_bool_option
                      |> Option.value ~default:false;
                    in_onboarding =
                      p |> member "in_onboarding" |> to_bool_option
                      |> Option.value ~default:false;
                  })
                l
          | _ -> []
        in
        Ok
          {
            guild_id = json |> member "guild_id" |> to_string;
            prompts;
            default_channel_ids =
              string_list (json |> member "default_channel_ids");
            enabled =
              json |> member "enabled" |> to_bool_option
              |> Option.value ~default:false;
            mode =
              json |> member "mode" |> to_int_option |> Option.value ~default:0;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
      | Failure msg -> Error msg
  end :
    Guild_onboarding)
