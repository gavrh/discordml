let path (base : string) (params : (string * string) list) : string =
  match params with
  | [] -> base
  | _ ->
      List.fold_left
        (fun uri (key, value) -> Uri.add_query_param' uri (key, value))
        (Uri.of_string base) params
      |> Uri.to_string

let bool (value : bool) : string = string_of_bool value
