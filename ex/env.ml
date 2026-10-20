let trim = String.trim

let strip_quotes value =
  let length = String.length value in
  if length >= 2 then
    match (value.[0], value.[length - 1]) with
    | '"', '"' | '\'', '\'' -> String.sub value 1 (length - 2)
    | _ -> value
  else value

let strip_inline_comment value =
  let length = String.length value in
  let rec find index quote =
    if index >= length then value
    else
      match (quote, value.[index]) with
      | Some opening, character when character = opening ->
          find (index + 1) None
      | Some _, _ -> find (index + 1) quote
      | None, (('"' | '\'') as character) when index = 0 ->
          find (index + 1) (Some character)
      | None, '#'
        when index = 0 || value.[index - 1] = ' ' || value.[index - 1] = '\t' ->
          String.sub value 0 index |> trim
      | None, _ -> find (index + 1) None
  in
  find 0 None

let without_export line =
  if String.length line >= 7 && String.sub line 0 7 = "export " then
    String.sub line 7 (String.length line - 7) |> trim
  else line

let set_env line =
  match String.index_opt line '=' with
  | None -> ()
  | Some index ->
      let key = String.sub line 0 index |> trim in
      let value =
        String.sub line (index + 1) (String.length line - index - 1)
        |> trim |> strip_inline_comment |> strip_quotes
      in
      if key <> "" && Sys.getenv_opt key = None then Unix.putenv key value

let load_dotenv path =
  if Sys.file_exists path then
    In_channel.with_open_text path (fun channel ->
        let rec read () =
          match In_channel.input_line channel with
          | None -> ()
          | Some line ->
              let line = trim line in
              if line <> "" && line.[0] <> '#' then
                set_env (without_export line);
              read ()
        in
        read ())
