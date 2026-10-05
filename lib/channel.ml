module type Channel = sig
    type t

    val id : t -> string

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val send : Rest.t -> t -> string -> unit
    val fetch : Rest.t -> string -> t

    val show : t -> string
end

include (struct

    type t = {
        id : string;
    } [@@deriving show, eq]

    let id (c : t) : string = c.id

    let create (id : string) : t = { id }

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try Ok { id = json |> member "id" |> to_string }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg

    let decode (path : string) (resp : string) : t =
        match of_yojson (Yojson.Safe.from_string resp) with
        | Ok c -> c
        | Error msg -> failwith (path ^ ": " ^ msg)

    let send (rest : Rest.t) (c : t) (content : string) : unit =
        let path = "/channels/" ^ c.id ^ "/messages" in
        let body =
            `Assoc [ ("content", `String content) ] |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/channels/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Channel)
