module type Oauth2 = sig
  type t = {
    access_token : string;
        [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    refresh_token : string option;
        [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
    expires_in : int;
    scopes : string list;
    token_type : string;
  }

  val access_token : t -> string
  val refresh_token : t -> string option
  val expires_in : t -> int
  val scopes : t -> string list
  val token_type : t -> string
  val pp : Format.formatter -> t -> unit
  val equal : t -> t -> bool
  val show : t -> string
  val of_yojson : Yojson.Safe.t -> (t, string) result

  val authorization_url :
    client_id:string ->
    scopes:string list ->
    redirect_uri:string ->
    ?permissions:int ->
    ?guild_id:string ->
    ?disable_guild_select:bool ->
    unit ->
    string

  val exchange_code :
    Rest.t ->
    client_id:string ->
    client_secret:string ->
    code:string ->
    redirect_uri:string ->
    t

  val refresh :
    Rest.t ->
    client_id:string ->
    client_secret:string ->
    refresh_token:string ->
    t
end

include (
  struct
    type t = {
      access_token : string;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
      refresh_token : string option;
          [@printer fun fmt _ -> Format.pp_print_string fmt "<redacted>"]
      expires_in : int;
      scopes : string list;
      token_type : string;
    }
    [@@deriving show, eq]

    let access_token (t : t) : string = t.access_token
    let refresh_token (t : t) : string option = t.refresh_token
    let expires_in (t : t) : int = t.expires_in
    let scopes (t : t) : string list = t.scopes
    let token_type (t : t) : string = t.token_type

    let split_scopes (scope : string option) : string list =
      match scope with
      | None -> []
      | Some scope ->
          String.split_on_char ' ' scope
          |> List.filter (fun value -> value <> "")

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
      let open Yojson.Safe.Util in
      try
        Ok
          {
            access_token = json |> member "access_token" |> to_string;
            refresh_token = json |> member "refresh_token" |> to_string_option;
            expires_in =
              json |> member "expires_in" |> to_int_option
              |> Option.value ~default:0;
            scopes = split_scopes (json |> member "scope" |> to_string_option);
            token_type = json |> member "token_type" |> to_string;
          }
      with
      | Type_error (msg, _) -> Error msg
      | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
      match of_yojson (Yojson.Safe.from_string resp) with
      | Ok value -> value
      | Error msg -> failwith (path ^ ": " ^ msg)

    let authorization_url ~(client_id : string) ~(scopes : string list)
        ~(redirect_uri : string) ?permissions ?guild_id ?disable_guild_select ()
        : string =
      let params =
        [
          ("response_type", "code");
          ("client_id", client_id);
          ("scope", String.concat " " scopes);
          ("redirect_uri", redirect_uri);
        ]
        @ (match permissions with
          | Some value -> [ ("permissions", string_of_int value) ]
          | None -> [])
        @ (match guild_id with
          | Some value -> [ ("guild_id", value) ]
          | None -> [])
        @
        match disable_guild_select with
        | Some value -> [ ("disable_guild_select", P_query.bool value) ]
        | None -> []
      in
      List.fold_left
        (fun uri (key, value) -> Uri.add_query_param' uri (key, value))
        (Uri.of_string "https://discord.com/oauth2/authorize")
        params
      |> Uri.to_string

    let form_body (params : (string * string) list) : string =
      Uri.encoded_of_query
        (List.map (fun (key, value) -> (key, [ value ])) params)

    let request (rest : Rest.t) (params : (string * string) list) : t =
      let path = "/oauth2/token" in
      let body = form_body params in
      let code, resp =
        Rest.request rest ~authorization:""
          ~content_type:"application/x-www-form-urlencoded" ~body Rest.Post path
      in
      if code < 200 || code >= 300 then
        failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp);
      decode path resp

    let exchange_code (rest : Rest.t) ~(client_id : string)
        ~(client_secret : string) ~(code : string) ~(redirect_uri : string) : t
        =
      request rest
        [
          ("grant_type", "authorization_code");
          ("code", code);
          ("redirect_uri", redirect_uri);
          ("client_id", client_id);
          ("client_secret", client_secret);
        ]

    let refresh (rest : Rest.t) ~(client_id : string) ~(client_secret : string)
        ~(refresh_token : string) : t =
      request rest
        [
          ("grant_type", "refresh_token");
          ("refresh_token", refresh_token);
          ("client_id", client_id);
          ("client_secret", client_secret);
        ]
  end :
    Oauth2)
