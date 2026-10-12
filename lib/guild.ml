module type Guild = sig
    type t
    val id : t -> string

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val fetch : Rest.t -> string -> t

    val show : t -> string
end

include (struct

    type t = {
        id : string;
    } [@@deriving show, eq]

    let id (g : t) = g.id

    let create (i : string) : t = { id = i; }

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try Ok { id = json |> member "id" |> to_string }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok g -> g
        | Error msg -> failwith (path ^ ": " ^ msg)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/guilds/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Guild)
