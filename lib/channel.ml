module type Channel = sig
    type t

    val id : t -> string
    val type_ : t -> int
    val guild_id : t -> string option
    val name : t -> string option
    val parent_id : t -> string option
    val topic : t -> string option
    val position : t -> int option

    val create : string -> t
    val of_yojson : Yojson.Safe.t -> (t, string) result

    val send : Rest.t -> t -> string -> unit
    val send_file : Rest.t -> t -> Attachment.t -> unit
    val fetch : Rest.t -> string -> t

    val pp : Format.formatter -> t -> unit
    val equal : t -> t -> bool
    val show : t -> string
end

include (struct

    type t = {
        id : string;
        type_ : int;
        guild_id : string option;
        name : string option;
        parent_id : string option;
        topic : string option;
        position : int option;
    } [@@deriving show, eq]

    let id (c : t) : string = c.id
    let type_ (c : t) : int = c.type_
    let guild_id (c : t) : string option = c.guild_id
    let name (c : t) : string option = c.name
    let parent_id (c : t) : string option = c.parent_id
    let topic (c : t) : string option = c.topic
    let position (c : t) : int option = c.position

    let create (id : string) : t =
        { id;
          type_ = 0;
          guild_id = None;
          name = None;
          parent_id = None;
          topic = None;
          position = None }

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            Ok
                { id = json |> member "id" |> to_string;
                  type_ =
                    json |> member "type" |> to_int_option
                    |> Option.value ~default:0;
                  guild_id = json |> member "guild_id" |> to_string_option;
                  name = json |> member "name" |> to_string_option;
                  parent_id = json |> member "parent_id" |> to_string_option;
                  topic = json |> member "topic" |> to_string_option;
                  position = json |> member "position" |> to_int_option }
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

    let send_file (rest : Rest.t) (c : t) (attachment : Attachment.t) : unit =
        let path = "/channels/" ^ c.id ^ "/messages" in
        let files =
            [ (Attachment.name attachment, Attachment.content attachment,
               Attachment.content_type attachment) ]
        in
        let code, resp = Rest.request rest ~files Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let fetch (rest : Rest.t) (id : string) : t =
        let path = "/channels/" ^ id in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        decode path resp

end : Channel)
