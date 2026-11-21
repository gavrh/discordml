module type Dave = sig
  type session = nativeint
  type commit_result = nativeint
  type welcome_result = nativeint
  type key_ratchet = nativeint
  type encryptor = nativeint
  type decryptor = nativeint

  val available : unit -> bool
  val load_error : unit -> string
  val max_protocol_version : unit -> int
  val session_create : string -> session
  val session_destroy : session -> unit

  val session_init :
    session -> version:int -> group_id:string -> user_id:string -> unit

  val session_reset : session -> unit
  val session_set_protocol_version : session -> int -> unit
  val session_get_protocol_version : session -> int
  val session_set_external_sender : session -> string -> unit
  val session_add_recognized_user : session -> string -> unit
  val session_remove_recognized_user : session -> string -> unit
  val session_process_proposals : session -> string -> string
  val session_process_commit : session -> string -> commit_result
  val session_process_welcome : session -> string -> welcome_result
  val session_get_key_package : session -> string
  val session_get_key_ratchet : session -> string -> key_ratchet
  val key_ratchet_destroy : key_ratchet -> unit
  val commit_result_is_failed : commit_result -> bool
  val commit_result_is_ignored : commit_result -> bool
  val commit_result_has_roster : commit_result -> bool
  val commit_result_destroy : commit_result -> unit
  val welcome_result_has_roster : welcome_result -> bool
  val welcome_result_destroy : welcome_result -> unit
  val encryptor_create : unit -> encryptor
  val encryptor_destroy : encryptor -> unit
  val encryptor_set_key_ratchet : encryptor -> key_ratchet -> unit
  val encryptor_set_passthrough : encryptor -> bool -> unit
  val encryptor_assign_ssrc : encryptor -> ssrc:int -> codec:int -> unit
  val encryptor_has_key_ratchet : encryptor -> bool
  val encryptor_get_protocol_version : encryptor -> int
  val encryptor_encrypt : encryptor -> ssrc:int -> string -> int * string
  val decryptor_create : unit -> decryptor
  val decryptor_destroy : decryptor -> unit
  val decryptor_transition_to_key_ratchet : decryptor -> key_ratchet -> unit
  val decryptor_transition_to_passthrough : decryptor -> bool -> unit
  val decryptor_decrypt : decryptor -> string -> int * string
end

include (
  struct
    type session = nativeint
    type commit_result = nativeint
    type welcome_result = nativeint
    type key_ratchet = nativeint
    type encryptor = nativeint
    type decryptor = nativeint

    external available : unit -> bool = "caml_p_dave_available"
    external load_error : unit -> string = "caml_p_dave_load_error"

    external max_protocol_version : unit -> int
      = "caml_p_dave_max_protocol_version"

    external session_create : string -> session = "caml_p_dave_session_create"
    external session_destroy : session -> unit = "caml_p_dave_session_destroy"

    external session_init :
      session -> version:int -> group_id:string -> user_id:string -> unit
      = "caml_p_dave_session_init"

    external session_reset : session -> unit = "caml_p_dave_session_reset"

    external session_set_protocol_version : session -> int -> unit
      = "caml_p_dave_session_set_protocol_version"

    external session_get_protocol_version : session -> int
      = "caml_p_dave_session_get_protocol_version"

    external session_set_external_sender : session -> string -> unit
      = "caml_p_dave_session_set_external_sender"

    external session_add_recognized_user : session -> string -> unit
      = "caml_p_dave_session_add_recognized_user"

    external session_remove_recognized_user : session -> string -> unit
      = "caml_p_dave_session_remove_recognized_user"

    external session_process_proposals : session -> string -> string
      = "caml_p_dave_session_process_proposals"

    external session_process_commit : session -> string -> commit_result
      = "caml_p_dave_session_process_commit"

    external session_process_welcome : session -> string -> welcome_result
      = "caml_p_dave_session_process_welcome"

    external session_get_key_package : session -> string
      = "caml_p_dave_session_get_key_package"

    external session_get_key_ratchet : session -> string -> key_ratchet
      = "caml_p_dave_session_get_key_ratchet"

    external key_ratchet_destroy : key_ratchet -> unit
      = "caml_p_dave_key_ratchet_destroy"

    external commit_result_is_failed : commit_result -> bool
      = "caml_p_dave_commit_result_is_failed"

    external commit_result_is_ignored : commit_result -> bool
      = "caml_p_dave_commit_result_is_ignored"

    external commit_result_has_roster : commit_result -> bool
      = "caml_p_dave_commit_result_has_roster"

    external commit_result_destroy : commit_result -> unit
      = "caml_p_dave_commit_result_destroy"

    external welcome_result_has_roster : welcome_result -> bool
      = "caml_p_dave_welcome_result_has_roster"

    external welcome_result_destroy : welcome_result -> unit
      = "caml_p_dave_welcome_result_destroy"

    external encryptor_create : unit -> encryptor
      = "caml_p_dave_encryptor_create"

    external encryptor_destroy : encryptor -> unit
      = "caml_p_dave_encryptor_destroy"

    external encryptor_set_key_ratchet : encryptor -> key_ratchet -> unit
      = "caml_p_dave_encryptor_set_key_ratchet"

    external encryptor_set_passthrough : encryptor -> bool -> unit
      = "caml_p_dave_encryptor_set_passthrough"

    external encryptor_assign_ssrc : encryptor -> ssrc:int -> codec:int -> unit
      = "caml_p_dave_encryptor_assign_ssrc"

    external encryptor_has_key_ratchet : encryptor -> bool
      = "caml_p_dave_encryptor_has_key_ratchet"

    external encryptor_get_protocol_version : encryptor -> int
      = "caml_p_dave_encryptor_get_protocol_version"

    external encryptor_encrypt : encryptor -> ssrc:int -> string -> int * string
      = "caml_p_dave_encryptor_encrypt"

    external decryptor_create : unit -> decryptor
      = "caml_p_dave_decryptor_create"

    external decryptor_destroy : decryptor -> unit
      = "caml_p_dave_decryptor_destroy"

    external decryptor_transition_to_key_ratchet :
      decryptor -> key_ratchet -> unit
      = "caml_p_dave_decryptor_transition_to_key_ratchet"

    external decryptor_transition_to_passthrough : decryptor -> bool -> unit
      = "caml_p_dave_decryptor_transition_to_passthrough"

    external decryptor_decrypt : decryptor -> string -> int * string
      = "caml_p_dave_decryptor_decrypt"
  end :
    Dave)
