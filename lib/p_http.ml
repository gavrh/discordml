module type Http = sig
    val get :
        sw:Eio.Switch.t ->
        net:'a Eio.Net.t ->
        headers:(string * string) list ->
        string ->
        int * string
end

include (struct

    type uri = {
        host : string;
        port : int;
        path : string;
    }

    let parse_uri (s : string) : uri =
        let rest =
            if String.length s >= 8 && String.sub s 0 8 = "https://" then
                String.sub s 8 (String.length s - 8)
            else
                failwith ("http: unsupported scheme in " ^ s)
        in
        let authority, path =
            match String.index_opt rest '/' with
            | Some i -> (String.sub rest 0 i, String.sub rest i (String.length rest - i))
            | None -> (rest, "/")
        in
        let host, port =
            match String.index_opt authority ':' with
            | Some i ->
                ( String.sub authority 0 i,
                  int_of_string
                      (String.sub authority (i + 1) (String.length authority - i - 1)) )
            | None -> (authority, 443)
        in
        { host; port; path }

    let rng_ready = ref false

    let ensure_rng () =
        if not !rng_ready then begin
            Mirage_crypto_rng_unix.use_default ();
            rng_ready := true
        end

    let tls_config () : Tls.Config.client =
        let authenticator =
            match Ca_certs.authenticator () with
            | Ok a -> a
            | Error (`Msg m) -> failwith ("http: ca-certs: " ^ m)
        in
        match Tls.Config.client ~authenticator () with
        | Ok c -> c
        | Error (`Msg m) -> failwith ("http: tls config: " ^ m)

    let read_headers (r : Eio.Buf_read.t) : (string * string) list =
        let rec loop acc =
            match Eio.Buf_read.line r with
            | "" -> List.rev acc
            | line ->
                (match String.index_opt line ':' with
                 | Some i ->
                     let k =
                         String.sub line 0 i |> String.trim |> String.lowercase_ascii
                     in
                     let v =
                         String.sub line (i + 1) (String.length line - i - 1)
                         |> String.trim
                     in
                     loop ((k, v) :: acc)
                 | None -> loop acc)
        in
        loop []

    let read_chunked (r : Eio.Buf_read.t) : string =
        let b = Buffer.create 256 in
        let rec loop () =
            let size_line = Eio.Buf_read.line r in
            let size_str =
                match String.index_opt size_line ';' with
                | Some i -> String.sub size_line 0 i
                | None -> size_line
            in
            let size = int_of_string ("0x" ^ String.trim size_str) in
            if size = 0 then begin
                let rec skip () =
                    match Eio.Buf_read.line r with
                    | "" -> ()
                    | _ -> skip ()
                in
                skip ();
                Buffer.contents b
            end
            else begin
                Buffer.add_string b (Eio.Buf_read.take size r);
                ignore (Eio.Buf_read.take 2 r);
                loop ()
            end
        in
        loop ()

    let read_body (r : Eio.Buf_read.t) (headers : (string * string) list) : string =
        match List.assoc_opt "transfer-encoding" headers with
        | Some v when String.lowercase_ascii v = "chunked" -> read_chunked r
        | _ ->
            (match List.assoc_opt "content-length" headers with
             | Some n -> Eio.Buf_read.take (int_of_string (String.trim n)) r
             | None -> Eio.Buf_read.take_all r)

    let get ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t)
            ~(headers : (string * string) list) (url : string) : int * string =
        ensure_rng ();
        let u = parse_uri url in
        let config = tls_config () in
        let addr =
            match
                Eio.Net.getaddrinfo_stream net u.host
                    ~service:(string_of_int u.port)
            with
            | addr :: _ -> addr
            | [] -> failwith ("http: could not resolve " ^ u.host)
        in
        let raw = Eio.Net.connect ~sw net addr in
        let flow =
            Tls_eio.client_of_flow config
                ~host:(Domain_name.host_exn (Domain_name.of_string_exn u.host))
                raw
        in
        let header_lines =
            headers
            |> List.map (fun (k, v) -> Printf.sprintf "%s: %s\r\n" k v)
            |> String.concat ""
        in
        let request =
            Printf.sprintf
                "GET %s HTTP/1.1\r\nHost: %s\r\n%sConnection: close\r\n\r\n"
                u.path u.host header_lines
        in
        Eio.Flow.copy_string request flow;
        let r = Eio.Buf_read.of_flow ~max_size:10_000_000 flow in
        let status_line = Eio.Buf_read.line r in
        if String.length status_line < 12 then
            failwith ("http: bad status line: " ^ status_line);
        let code = int_of_string (String.sub status_line 9 3) in
        let headers = read_headers r in
        (code, read_body r headers)

end : Http)
