module type Ws = sig
    type t

    val gateway_version : string

    val encoding : string

    val gateway : string

    val connect : sw:Eio.Switch.t -> net:'a Eio.Net.t -> t

    val send_text : t -> string -> unit
    val send_binary : t -> string -> unit
    val recv : t -> string option
    val close : t -> unit
    val is_closed : t -> bool
end

include (struct

    let op_continuation = 0x0
    let op_text = 0x1
    let op_binary = 0x2
    let op_close = 0x8
    let op_ping = 0x9
    let op_pong = 0xA

    let ws_guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

    let b64_alphabet =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    let base64_encode (s : string) : string =
        let n = String.length s in
        let b = Buffer.create (((n + 2) / 3) * 4) in
        let code i = Char.code s.[i] in
        let i = ref 0 in
        while !i + 2 < n do
            let x = code !i and y = code (!i + 1) and z = code (!i + 2) in
            Buffer.add_char b b64_alphabet.[x lsr 2];
            Buffer.add_char b b64_alphabet.[((x land 0x3) lsl 4) lor (y lsr 4)];
            Buffer.add_char b b64_alphabet.[((y land 0xf) lsl 2) lor (z lsr 6)];
            Buffer.add_char b b64_alphabet.[z land 0x3f];
            i := !i + 3
        done;
        (match n - !i with
         | 1 ->
             let x = code !i in
             Buffer.add_char b b64_alphabet.[x lsr 2];
             Buffer.add_char b b64_alphabet.[(x land 0x3) lsl 4];
             Buffer.add_string b "=="
         | 2 ->
             let x = code !i and y = code (!i + 1) in
             Buffer.add_char b b64_alphabet.[x lsr 2];
             Buffer.add_char b b64_alphabet.[((x land 0x3) lsl 4) lor (y lsr 4)];
             Buffer.add_char b b64_alphabet.[(y land 0xf) lsl 2];
             Buffer.add_char b '='
         | _ -> ());
        Buffer.contents b

    type uri = {
        secure : bool;
        host : string;
        port : int;
        path : string;
    }

    let parse_uri (s : string) : uri =
        let secure, rest =
            if String.length s >= 6 && String.sub s 0 6 = "wss://" then
                (true, String.sub s 6 (String.length s - 6))
            else if String.length s >= 5 && String.sub s 0 5 = "ws://" then
                (false, String.sub s 5 (String.length s - 5))
            else
                failwith ("websocket: unsupported scheme in " ^ s)
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
            | None -> (authority, if secure then 443 else 80)
        in
        { secure; host; port; path }

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
            | Error (`Msg m) -> failwith ("websocket: ca-certs: " ^ m)
        in
        match Tls.Config.client ~authenticator () with
        | Ok c -> c
        | Error (`Msg m) -> failwith ("websocket: tls config: " ^ m)

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

    type t = {
        flow : Tls_eio.t;
        reader : Eio.Buf_read.t;
        mutable closed : bool;
    }

    let send_frame (t : t) (opcode : int) (payload : string) : unit =
        let len = String.length payload in
        let b = Buffer.create (14 + len) in
        Buffer.add_char b (Char.chr (0x80 lor opcode));
        if len < 126 then
            Buffer.add_char b (Char.chr (0x80 lor len))
        else if len < 65536 then begin
            Buffer.add_char b (Char.chr (0x80 lor 126));
            Buffer.add_char b (Char.chr ((len lsr 8) land 0xff));
            Buffer.add_char b (Char.chr (len land 0xff))
        end
        else begin
            Buffer.add_char b (Char.chr (0x80 lor 127));
            for i = 7 downto 0 do
                Buffer.add_char b (Char.chr ((len lsr (8 * i)) land 0xff))
            done
        end;
        let mask = Mirage_crypto_rng.generate 4 in
        Buffer.add_string b mask;
        let masked = Bytes.create len in
        for i = 0 to len - 1 do
            Bytes.set masked i
                (Char.chr (Char.code payload.[i] lxor Char.code mask.[i mod 4]))
        done;
        Buffer.add_bytes b masked;
        Eio.Flow.copy_string (Buffer.contents b) t.flow

    let read_frame (t : t) : bool * int * string =
        let hdr = Eio.Buf_read.take 2 t.reader in
        let b0 = Char.code hdr.[0] and b1 = Char.code hdr.[1] in
        let fin = b0 land 0x80 <> 0 in
        if b0 land 0x70 <> 0 then failwith "websocket: RSV bits set";
        let opcode = b0 land 0x0f in
        let masked = b1 land 0x80 <> 0 in
        let len0 = b1 land 0x7f in
        let len =
            if len0 < 126 then len0
            else if len0 = 126 then
                let s = Eio.Buf_read.take 2 t.reader in
                (Char.code s.[0] lsl 8) lor Char.code s.[1]
            else
                let s = Eio.Buf_read.take 8 t.reader in
                let v = ref 0 in
                for i = 0 to 7 do
                    v := (!v lsl 8) lor Char.code s.[i]
                done;
                !v
        in
        let mask = if masked then Some (Eio.Buf_read.take 4 t.reader) else None in
        let payload = if len = 0 then "" else Eio.Buf_read.take len t.reader in
        let payload =
            match mask with
            | None -> payload
            | Some m ->
                String.init len (fun i ->
                    Char.chr (Char.code payload.[i] lxor Char.code m.[i mod 4]))
        in
        (fin, opcode, payload)

    let rec recv (t : t) : string option =
        if t.closed then None
        else
            match read_frame t with
            | exception End_of_file ->
                t.closed <- true;
                None
            | fin, opcode, payload ->
                (match opcode with
                 | op when op = op_close ->
                     (try send_frame t op_close "" with _ -> ());
                     t.closed <- true;
                     None
                 | op when op = op_ping ->
                     send_frame t op_pong payload;
                     recv t
                 | op when op = op_pong -> recv t
                 | _ ->
                     let buf = Buffer.create 256 in
                     Buffer.add_string buf payload;
                     let rec more () =
                         if fin then Some (Buffer.contents buf)
                         else
                             match read_frame t with
                             | fin', op', p' ->
                                 (match op' with
                                  | op when op = op_close ->
                                      (try send_frame t op_close "" with _ -> ());
                                      t.closed <- true;
                                      None
                                  | op when op = op_ping ->
                                      send_frame t op_pong p';
                                      more ()
                                  | op when op = op_pong -> more ()
                                  | _ ->
                                      Buffer.add_string buf p';
                                      more' fin')
                             | exception End_of_file ->
                                 t.closed <- true;
                                 None
                     and more' fin' =
                         if fin' then Some (Buffer.contents buf) else more ()
                     in
                     more ())

    let send_text (t : t) (s : string) : unit = send_frame t op_text s

    let send_binary (t : t) (s : string) : unit = send_frame t op_binary s

    let close (t : t) : unit =
        if not t.closed then begin
            (try send_frame t op_close "" with _ -> ());
            t.closed <- true
        end

    let is_closed (t : t) : bool = t.closed

    let connect_url ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) (url : string) : t =
        ensure_rng ();
        let u = parse_uri url in
        let config = tls_config () in
        let addr =
            match
                Eio.Net.getaddrinfo_stream net u.host
                    ~service:(string_of_int u.port)
            with
            | addr :: _ -> addr
            | [] -> failwith ("websocket: could not resolve " ^ u.host)
        in
        let raw = Eio.Net.connect ~sw net addr in
        let flow =
            Tls_eio.client_of_flow config
                ~host:(Domain_name.host_exn (Domain_name.of_string_exn u.host))
                raw
        in
        let key = base64_encode (Mirage_crypto_rng.generate 16) in
        let host_header =
            if u.port = (if u.secure then 443 else 80) then u.host
            else Printf.sprintf "%s:%d" u.host u.port
        in
        let request =
            Printf.sprintf
                "GET %s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\n\
                 Connection: Upgrade\r\nSec-WebSocket-Key: %s\r\n\
                 Sec-WebSocket-Version: 13\r\n\r\n"
                u.path host_header key
        in
        Eio.Flow.copy_string request flow;
        let reader = Eio.Buf_read.of_flow ~max_size:10_000_000 flow in
        let status = Eio.Buf_read.line reader in
        let headers = read_headers reader in
        if not (String.length status >= 12
                && String.sub status 9 3 = "101")
        then
            failwith ("websocket: handshake failed: " ^ status);
        let expected =
            base64_encode
                (Digestif.SHA1.(
                     to_raw_string (digest_string (key ^ ws_guid))))
        in
        (match List.assoc_opt "sec-websocket-accept" headers with
         | Some got when got = expected -> ()
         | Some got ->
             failwith
                 (Printf.sprintf
                    "websocket: bad Sec-WebSocket-Accept (expected %s, got %s)"
                    expected got)
         | None -> failwith "websocket: missing Sec-WebSocket-Accept");
        { flow; reader; closed = false }

    let gateway_version : string = "10"
    let encoding : string = "json"

    let gateway : string =
        "wss://gateway.discord.gg/?v=" ^ gateway_version ^ "&encoding=" ^ encoding

    let connect ~(sw : Eio.Switch.t) ~(net : 'a Eio.Net.t) : t =
        connect_url ~sw ~net gateway

end : Ws)
