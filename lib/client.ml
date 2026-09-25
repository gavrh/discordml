type client = {
    token : string;
    id : string option;
}

let create (t: string) : client = { token = t; id = None }

let string_of_client (c : client) : string =
    Printf.sprintf "{ token: %s; id: %s; }"
    c.token
    (Util.string_of_option c.id) 

let start (c : client) = nan
