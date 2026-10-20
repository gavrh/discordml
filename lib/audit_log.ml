module type Audit_log = sig
  type change_value =
    | String of string
    | Integer of int
    | Bool of bool
    | Strings of string list
    | Channels of Channel.t list
    | Roles of Role.t list
    | Overwrites of Channel.Overwrite.t list
    | Null

  type change = {
    key : string;
    old_value : change_value option;
    new_value : change_value option;
  }

  type entry_info = {
    application_id : string option;
    channel_id : string option;
    count : int option;
    delete_member_days : string option;
    id : string option;
    members_removed : string option;
    message_id : string option;
    role_name : string option;
    type_ : string option;
    integration_type : string option;
  }

  type entry = {
    target_id : string option;
    changes : change list;
    user_id : string option;
    id : string;
    action_type : int;
    options : entry_info option;
    reason : string option;
  }

  type t = {
    audit_log_entries : entry list;
    users : User.t list;
    webhooks : Webhook.t list;
    integrations : Integration.t list;
    threads : Channel.t list;
    application_commands : Application_command.t list;
    auto_moderation_rules : Auto_moderation.t list;
    guild_scheduled_events : Guild_scheduled_event.t list;
  }

  val audit_log_entries : t -> entry list
  val users : t -> User.t list
  val webhooks : t -> Webhook.t list
  val integrations : t -> Integration.t list
  val threads : t -> Channel.t list
  val application_commands : t -> Application_command.t list
  val auto_moderation_rules : t -> Auto_moderation.t list
  val guild_scheduled_events : t -> Guild_scheduled_event.t list
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result
end

include (
  struct
    type change_value =
      | String of string
      | Integer of int
      | Bool of bool
      | Strings of string list
      | Channels of Channel.t list
      | Roles of Role.t list
      | Overwrites of Channel.Overwrite.t list
      | Null
    [@@deriving show, eq]

    type change = {
      key : string;
      old_value : change_value option;
      new_value : change_value option;
    }
    [@@deriving show, eq]

    type entry_info = {
      application_id : string option;
      channel_id : string option;
      count : int option;
      delete_member_days : string option;
      id : string option;
      members_removed : string option;
      message_id : string option;
      role_name : string option;
      type_ : string option;
      integration_type : string option;
    }
    [@@deriving show, eq]

    type entry = {
      target_id : string option;
      changes : change list;
      user_id : string option;
      id : string;
      action_type : int;
      options : entry_info option;
      reason : string option;
    }
    [@@deriving show, eq]

    type t = {
      audit_log_entries : entry list;
      users : User.t list;
      webhooks : Webhook.t list;
      integrations : Integration.t list;
      threads : Channel.t list;
      application_commands : Application_command.t list;
      auto_moderation_rules : Auto_moderation.t list;
      guild_scheduled_events : Guild_scheduled_event.t list;
    }
    [@@deriving show, eq]

    let audit_log_entries (a : t) : entry list = a.audit_log_entries
    let users (a : t) : User.t list = a.users
    let webhooks (a : t) : Webhook.t list = a.webhooks
    let integrations (a : t) : Integration.t list = a.integrations
    let threads (a : t) : Channel.t list = a.threads

    let application_commands (a : t) : Application_command.t list =
      a.application_commands

    let auto_moderation_rules (a : t) : Auto_moderation.t list =
      a.auto_moderation_rules

    let guild_scheduled_events (a : t) : Guild_scheduled_event.t list =
      a.guild_scheduled_events

    let all_or_none (l : 'a option list) : 'a list option =
      if List.for_all Option.is_some l then Some (List.map Option.get l)
      else None

    let rec parse_value (json : Yojson.Safe.t) : change_value =
      let open Yojson.Safe.Util in
      match json with
      | `String s -> String s
      | `Int n -> Integer n
      | `Intlit s -> Integer (int_of_string s)
      | `Float f -> Integer (int_of_float f)
      | `Bool b -> Bool b
      | `Null -> Null
      | `List l -> (
          if l = [] then Strings []
          else if List.for_all (function `String _ -> true | _ -> false) l
          then
            Strings
              (List.filter_map (function `String s -> Some s | _ -> None) l)
          else
            match
              all_or_none
                (List.map
                   (fun v ->
                     match Role.of_yojson v with
                     | Ok r -> Some r
                     | Error _ -> None)
                   l)
            with
            | Some roles -> Roles roles
            | None -> (
                match
                  all_or_none
                    (List.map
                       (fun v ->
                         match Channel.Overwrite.of_yojson v with
                         | Ok o -> Some o
                         | Error _ -> None)
                       l)
                with
                | Some overwrites -> Overwrites overwrites
                | None -> (
                    match
                      all_or_none
                        (List.map
                           (fun v ->
                             match Channel.of_yojson v with
                             | Ok c -> Some c
                             | Error _ -> None)
                           l)
                    with
                    | Some channels -> Channels channels
                    | None -> Null)))
      | `Assoc _ -> Null

    let parse_opt (json : Yojson.Safe.t) (name : string)
        (f : Yojson.Safe.t -> 'a) : 'a option =
      match Yojson.Safe.Util.member name json with
      | `Null -> None
      | v -> Some (f v)

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        let parse_list name f =
          match json |> member name with
          | `List l ->
              List.filter_map
                (fun item ->
                  match f item with Ok value -> Some value | Error _ -> None)
                l
          | _ -> []
        in
        let changes =
          match json |> member "audit_log_entries" with
          | `List l ->
              List.map
                (fun e ->
                  let changes =
                    match e |> member "changes" with
                    | `List cl ->
                        List.map
                          (fun c ->
                            {
                              key = c |> member "key" |> to_string;
                              old_value = parse_opt c "old_value" parse_value;
                              new_value = parse_opt c "new_value" parse_value;
                            })
                          cl
                    | _ -> []
                  in
                  let options =
                    parse_opt e "options" (fun o ->
                        {
                          application_id =
                            o |> member "application_id" |> to_string_option;
                          channel_id =
                            o |> member "channel_id" |> to_string_option;
                          count = o |> member "count" |> to_int_option;
                          delete_member_days =
                            o |> member "delete_member_days" |> to_string_option;
                          id = o |> member "id" |> to_string_option;
                          members_removed =
                            o |> member "members_removed" |> to_string_option;
                          message_id =
                            o |> member "message_id" |> to_string_option;
                          role_name =
                            o |> member "role_name" |> to_string_option;
                          type_ =
                            (match o |> member "type" with
                            | `String s -> Some s
                            | `Int n -> Some (string_of_int n)
                            | _ -> None);
                          integration_type =
                            o |> member "integration_type" |> to_string_option;
                        })
                  in
                  {
                    target_id = e |> member "target_id" |> to_string_option;
                    changes;
                    user_id = e |> member "user_id" |> to_string_option;
                    id = e |> member "id" |> to_string;
                    action_type =
                      e |> member "action_type" |> to_int_option
                      |> Option.value ~default:0;
                    options;
                    reason = e |> member "reason" |> to_string_option;
                  })
                l
          | _ -> []
        in
        Ok
          {
            audit_log_entries = changes;
            users = parse_list "users" User.of_yojson;
            webhooks = parse_list "webhooks" Webhook.of_yojson;
            integrations = parse_list "integrations" Integration.of_yojson;
            threads = parse_list "threads" Channel.of_yojson;
            application_commands =
              parse_list "application_commands" Application_command.of_yojson;
            auto_moderation_rules =
              parse_list "auto_moderation_rules" Auto_moderation.of_yojson;
            guild_scheduled_events =
              parse_list "guild_scheduled_events"
                Guild_scheduled_event.of_yojson;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg
  end :
    Audit_log)
