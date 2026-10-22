type t = { client : Cohttp_eio.Client.t; sw : Eio.Switch.t; token : string }

let endpoint : string = "https://discord.com/api/v10"

let user_agent : string =
  "DiscordBot (https://github.com/gavrh/discordml, 0.1.0)"

let https () =
  let authenticator =
    match Ca_certs.authenticator () with
    | Ok a -> a
    | Error (`Msg m) -> failwith ("rest: ca-certs: " ^ m)
  in
  let tls_config =
    match Tls.Config.client ~authenticator () with
    | Ok c -> c
    | Error (`Msg m) -> failwith ("rest: tls config: " ^ m)
  in
  fun uri raw ->
    let host =
      Uri.host uri
      |> Option.map (fun x -> Domain_name.(host_exn (of_string_exn x)))
    in
    Tls_eio.client_of_flow ?host tls_config raw

let create ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) ~(token : string) : t =
  Mirage_crypto_rng_unix.use_default ();
  let client = Cohttp_eio.Client.make ~https:(Some (https ())) net in
  { client; sw; token }

let cohttp_meth (meth : string) =
  match meth with
  | "GET" -> `GET
  | "POST" -> `POST
  | "PUT" -> `PUT
  | "PATCH" -> `PATCH
  | "DELETE" -> `DELETE
  | meth -> invalid_arg ("p_http: unsupported method: " ^ meth)

let random_boundary () : string =
  let raw = Mirage_crypto_rng.generate 16 in
  let b = Buffer.create 32 in
  String.iter (fun c -> Printf.bprintf b "%02x" (Char.code c)) raw;
  Buffer.contents b

let escape_filename (name : string) : string =
  let b = Buffer.create (String.length name) in
  String.iter
    (fun c ->
      match c with
      | '\r' | '\n' -> ()
      | '"' -> Buffer.add_string b "%22"
      | '\\' -> Buffer.add_string b "%5C"
      | c -> Buffer.add_char b c)
    name;
  Buffer.contents b

let multipart_body (boundary : string) (body : string option)
    (files : (string * string * string option) list) : string =
  let b = Buffer.create 1024 in
  let crlf () = Buffer.add_string b "\r\n" in
  (match body with
  | Some json ->
      Buffer.add_string b ("--" ^ boundary);
      crlf ();
      Buffer.add_string b
        "Content-Disposition: form-data; name=\"payload_json\"";
      crlf ();
      Buffer.add_string b "Content-Type: application/json";
      crlf ();
      crlf ();
      Buffer.add_string b json;
      crlf ()
  | None -> ());
  List.iteri
    (fun i (filename, content, content_type) ->
      Buffer.add_string b ("--" ^ boundary);
      crlf ();
      Buffer.add_string b
        (Printf.sprintf
           "Content-Disposition: form-data; name=\"files[%d]\"; filename=\"%s\""
           i (escape_filename filename));
      crlf ();
      let content_type =
        Option.value content_type ~default:"application/octet-stream"
      in
      if String.contains content_type '\r' || String.contains content_type '\n'
      then failwith "rest: attachment content_type must not contain CR/LF";
      Buffer.add_string b ("Content-Type: " ^ content_type);
      crlf ();
      crlf ();
      Buffer.add_string b content;
      crlf ())
    files;
  Buffer.add_string b ("--" ^ boundary ^ "--");
  crlf ();
  Buffer.contents b

let send (t : t) ?(headers = []) ?(body : string option)
    ?(files : (string * string * string option) list = []) ~(meth : string)
    (path : string) =
  let uri = Uri.of_string (endpoint ^ path) in
  let content_type, body =
    if files = [] then ("application/json", body)
    else
      let boundary = random_boundary () in
      ( "multipart/form-data; boundary=" ^ boundary,
        Some (multipart_body boundary body files) )
  in
  let all_headers =
    Http.Header.of_list
      (("Authorization", "Bot " ^ t.token)
      :: ("User-Agent", user_agent)
      :: ("Content-Type", content_type)
      :: headers)
  in
  let body = Option.map Cohttp_eio.Body.of_string body in
  let resp, resp_body =
    Cohttp_eio.Client.call t.client ~sw:t.sw ?body ~headers:all_headers
      (cohttp_meth meth) uri
  in
  let body = Eio.Buf_read.(parse_exn take_all) resp_body ~max_size:10_000_000 in
  (resp, body)
