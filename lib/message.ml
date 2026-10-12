module type Message = sig
    type t

    val id : t -> string
    val channel_id : t -> string
    val channel : t -> Channel.t
    val content : t -> string
    val author : t -> User.t

    val of_yojson : Yojson.Safe.t -> (t, string) result

    val show : t -> string

    val reply : Rest.t -> t -> string -> unit
    val reply_file : Rest.t -> t -> Attachment.t -> unit
    val edit : Rest.t -> t -> string -> unit
    val delete : Rest.t -> t -> unit

    val list :
        Rest.t ->
        channel_id:string ->
        ?before:string ->
        ?after:string ->
        ?limit:int ->
        unit ->
        t list
end

include (struct

    type t = {
        id : string;
        channel_id : string;
        content : string;
        author : User.t [@printer fun fmt a -> Format.pp_print_string fmt (User.show a)];
    } [@@deriving show]

    let id (m : t) : string = m.id
    let channel_id (m : t) : string = m.channel_id
    let channel (m : t) : Channel.t = Channel.create m.channel_id
    let content (m : t) : string = m.content
    let author (m : t) : User.t = m.author

    let of_yojson (json : Yojson.Safe.t) : (t, string) result =
        let open Yojson.Safe.Util in
        try
            let author =
                match User.of_yojson (json |> member "author") with
                | Ok a -> a
                | Error msg -> raise (Failure msg)
            in
            Ok
                { id = json |> member "id" |> to_string;
                  channel_id = json |> member "channel_id" |> to_string;
                  content = json |> member "content" |> to_string;
                  author }
        with
        | Type_error (msg, _) -> Error msg
        | Undefined (msg, _) -> Error msg
        | Failure msg -> Error msg

    let reply (rest : Rest.t) (m : t) (content : string) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages" in
        let body =
            `Assoc
                [ ("content", `String content);
                  ("message_reference", `Assoc [ ("message_id", `String m.id) ]) ]
            |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let reply_file (rest : Rest.t) (m : t) (attachment : Attachment.t) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages" in
        let body =
            `Assoc
                [ ("message_reference", `Assoc [ ("message_id", `String m.id) ]) ]
            |> Yojson.Safe.to_string
        in
        let files =
            [ (Attachment.name attachment, Attachment.content attachment) ]
        in
        let code, resp = Rest.request rest ~body ~files Rest.Post path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "POST %s: HTTP %d: %s" path code resp)

    let edit (rest : Rest.t) (m : t) (content : string) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages/" ^ m.id in
        let body =
            `Assoc [ ("content", `String content) ] |> Yojson.Safe.to_string
        in
        let code, resp = Rest.request rest ~body Rest.Patch path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "PATCH %s: HTTP %d: %s" path code resp)

    let delete (rest : Rest.t) (m : t) : unit =
        let path = "/channels/" ^ m.channel_id ^ "/messages/" ^ m.id in
        let code, resp = Rest.request rest Rest.Delete path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "DELETE %s: HTTP %d: %s" path code resp)

    let list (rest : Rest.t) ~channel_id ?before ?after ?limit () : t list =
        let base = "/channels/" ^ channel_id ^ "/messages" in
        let params =
            (match before with Some v -> [ ("before", v) ] | None -> [])
            @ (match after with Some v -> [ ("after", v) ] | None -> [])
            @ (match limit with
               | Some v -> [ ("limit", string_of_int v) ]
               | None -> [])
        in
        let path =
            match params with
            | [] -> base
            | _ ->
                List.fold_left
                    (fun uri (k, v) -> Uri.add_query_param' uri (k, v))
                    (Uri.of_string base) params
                |> Uri.to_string
        in
        let code, resp = Rest.request rest Rest.Get path in
        if code < 200 || code >= 300 then
            failwith (Printf.sprintf "GET %s: HTTP %d: %s" path code resp);
        Yojson.Safe.from_string resp |> Yojson.Safe.Util.to_list
        |> List.map (fun json ->
               match of_yojson json with
               | Ok m -> m
               | Error msg -> failwith (path ^ ": " ^ msg))

end : Message)
