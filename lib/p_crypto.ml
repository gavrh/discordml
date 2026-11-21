module type Crypto = sig
  type mode = Aes256_gcm_rtpsize | Xchacha20_poly1305_rtpsize

  val mode_of_string : string -> mode option
  val string_of_mode : mode -> string

  val encrypt :
    mode -> key:string -> counter:int -> header:string -> string -> string

  val decrypt : mode -> key:string -> header:string -> string -> string option
end

include (
  struct
    type mode = Aes256_gcm_rtpsize | Xchacha20_poly1305_rtpsize

    let mode_of_string = function
      | "aead_aes256_gcm_rtpsize" -> Some Aes256_gcm_rtpsize
      | "aead_xchacha20_poly1305_rtpsize" -> Some Xchacha20_poly1305_rtpsize
      | _ -> None

    let string_of_mode = function
      | Aes256_gcm_rtpsize -> "aead_aes256_gcm_rtpsize"
      | Xchacha20_poly1305_rtpsize -> "aead_xchacha20_poly1305_rtpsize"

    let mask = 0xffffffff
    let add a b = (a + b) land mask
    let xor a b = a lxor b land mask
    let rotl x n = (x lsl n) lor (x lsr (32 - n)) land mask

    let quarter_round a b c d =
      let a = add a b in
      let d = rotl (xor d a) 16 in
      let c = add c d in
      let b = rotl (xor b c) 12 in
      let a = add a b in
      let d = rotl (xor d a) 8 in
      let c = add c d in
      let b = rotl (xor b c) 7 in
      (a, b, c, d)

    let word_le (s : string) (i : int) : int =
      Char.code s.[i]
      lor (Char.code s.[i + 1] lsl 8)
      lor (Char.code s.[i + 2] lsl 16)
      lor (Char.code s.[i + 3] lsl 24)

    let set_word_le (b : Bytes.t) (i : int) (v : int) : unit =
      Bytes.set b i (Char.chr (v land 0xff));
      Bytes.set b (i + 1) (Char.chr ((v lsr 8) land 0xff));
      Bytes.set b (i + 2) (Char.chr ((v lsr 16) land 0xff));
      Bytes.set b (i + 3) (Char.chr ((v lsr 24) land 0xff))

    let hchacha20 ~(key : string) ~(nonce : string) : string =
      if String.length key <> 32 then
        invalid_arg "P_crypto.hchacha20: key must be 32 bytes";
      if String.length nonce <> 16 then
        invalid_arg "P_crypto.hchacha20: nonce must be 16 bytes";
      let state = Array.make 16 0 in
      state.(0) <- 0x61707865;
      state.(1) <- 0x3320646e;
      state.(2) <- 0x79622d32;
      state.(3) <- 0x6b206574;
      for i = 0 to 7 do
        state.(4 + i) <- word_le key (i * 4)
      done;
      for i = 0 to 3 do
        state.(12 + i) <- word_le nonce (i * 4)
      done;
      for _ = 1 to 10 do
        let a, b, c, d =
          quarter_round state.(0) state.(4) state.(8) state.(12)
        in
        state.(0) <- a;
        state.(4) <- b;
        state.(8) <- c;
        state.(12) <- d;
        let a, b, c, d =
          quarter_round state.(1) state.(5) state.(9) state.(13)
        in
        state.(1) <- a;
        state.(5) <- b;
        state.(9) <- c;
        state.(13) <- d;
        let a, b, c, d =
          quarter_round state.(2) state.(6) state.(10) state.(14)
        in
        state.(2) <- a;
        state.(6) <- b;
        state.(10) <- c;
        state.(14) <- d;
        let a, b, c, d =
          quarter_round state.(3) state.(7) state.(11) state.(15)
        in
        state.(3) <- a;
        state.(7) <- b;
        state.(11) <- c;
        state.(15) <- d;
        let a, b, c, d =
          quarter_round state.(0) state.(5) state.(10) state.(15)
        in
        state.(0) <- a;
        state.(5) <- b;
        state.(10) <- c;
        state.(15) <- d;
        let a, b, c, d =
          quarter_round state.(1) state.(6) state.(11) state.(12)
        in
        state.(1) <- a;
        state.(6) <- b;
        state.(11) <- c;
        state.(12) <- d;
        let a, b, c, d =
          quarter_round state.(2) state.(7) state.(8) state.(13)
        in
        state.(2) <- a;
        state.(7) <- b;
        state.(8) <- c;
        state.(13) <- d;
        let a, b, c, d =
          quarter_round state.(3) state.(4) state.(9) state.(14)
        in
        state.(3) <- a;
        state.(4) <- b;
        state.(9) <- c;
        state.(14) <- d
      done;
      let out = Bytes.create 32 in
      for i = 0 to 3 do
        set_word_le out (i * 4) state.(i);
        set_word_le out (16 + (i * 4)) state.(12 + i)
      done;
      Bytes.unsafe_to_string out

    let set_be32 (b : Bytes.t) (i : int) (v : int) : unit =
      Bytes.set b i (Char.chr ((v lsr 24) land 0xff));
      Bytes.set b (i + 1) (Char.chr ((v lsr 16) land 0xff));
      Bytes.set b (i + 2) (Char.chr ((v lsr 8) land 0xff));
      Bytes.set b (i + 3) (Char.chr (v land 0xff))

    let get_be32 (s : string) (i : int) : int =
      (Char.code s.[i] lsl 24)
      lor (Char.code s.[i + 1] lsl 16)
      lor (Char.code s.[i + 2] lsl 8)
      lor Char.code s.[i + 3]

    let nonce mode counter =
      let b =
        Bytes.make (match mode with Aes256_gcm_rtpsize -> 12 | _ -> 24) '\000'
      in
      set_be32 b 0 counter;
      Bytes.unsafe_to_string b

    let encrypt_with_nonce mode ~key ~nonce ~header plaintext =
      match mode with
      | Aes256_gcm_rtpsize ->
          let key = Mirage_crypto.AES.GCM.of_secret key in
          Mirage_crypto.AES.GCM.authenticate_encrypt ~key ~nonce ~adata:header
            plaintext
      | Xchacha20_poly1305_rtpsize ->
          let subkey = hchacha20 ~key ~nonce:(String.sub nonce 0 16) in
          let nonce = String.make 4 '\000' ^ String.sub nonce 16 8 in
          Mirage_crypto.Chacha20.authenticate_encrypt
            ~key:(Mirage_crypto.Chacha20.of_secret subkey)
            ~nonce ~adata:header plaintext

    let decrypt_with_nonce mode ~key ~nonce ~header ciphertext =
      match mode with
      | Aes256_gcm_rtpsize ->
          let key = Mirage_crypto.AES.GCM.of_secret key in
          Mirage_crypto.AES.GCM.authenticate_decrypt ~key ~nonce ~adata:header
            ciphertext
      | Xchacha20_poly1305_rtpsize ->
          let subkey = hchacha20 ~key ~nonce:(String.sub nonce 0 16) in
          let nonce = String.make 4 '\000' ^ String.sub nonce 16 8 in
          Mirage_crypto.Chacha20.authenticate_decrypt
            ~key:(Mirage_crypto.Chacha20.of_secret subkey)
            ~nonce ~adata:header ciphertext

    let encrypt mode ~(key : string) ~(counter : int) ~(header : string)
        (plaintext : string) : string =
      let nonce = nonce mode counter in
      let ciphertext = encrypt_with_nonce mode ~key ~nonce ~header plaintext in
      let trailer = Bytes.create 4 in
      set_be32 trailer 0 counter;
      header ^ ciphertext ^ Bytes.unsafe_to_string trailer

    let decrypt mode ~(key : string) ~(header : string) (packet : string) :
        string option =
      let header_len = String.length header in
      if String.length packet < header_len + 4 then None
      else
        let ciphertext_len = String.length packet - header_len - 4 in
        let counter = get_be32 packet (String.length packet - 4) in
        let ciphertext = String.sub packet header_len ciphertext_len in
        decrypt_with_nonce mode ~key ~nonce:(nonce mode counter) ~header
          ciphertext
  end :
    Crypto)
