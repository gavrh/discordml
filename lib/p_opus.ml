module type Opus = sig
  type encoder = nativeint
  type decoder = nativeint

  val available : unit -> bool
  val load_error : unit -> string
  val encoder_create : unit -> encoder
  val encoder_destroy : encoder -> unit
  val encode : encoder -> int array -> string
  val decoder_create : unit -> decoder
  val decoder_destroy : decoder -> unit
  val decode : decoder -> string -> int array
end

include (
  struct
    type encoder = nativeint
    type decoder = nativeint

    external available : unit -> bool = "caml_p_opus_available"
    external load_error : unit -> string = "caml_p_opus_load_error"
    external encoder_create : unit -> encoder = "caml_p_opus_encoder_create"
    external encoder_destroy : encoder -> unit = "caml_p_opus_encoder_destroy"
    external encode : encoder -> int array -> string = "caml_p_opus_encode"
    external decoder_create : unit -> decoder = "caml_p_opus_decoder_create"
    external decoder_destroy : decoder -> unit = "caml_p_opus_decoder_destroy"
    external decode : decoder -> string -> int array = "caml_p_opus_decode"
  end :
    Opus)
