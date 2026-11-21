#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

typedef void *DAVESessionHandle;
typedef void *DAVECommitResultHandle;
typedef void *DAVEWelcomeResultHandle;
typedef void *DAVEKeyRatchetHandle;
typedef void *DAVEEncryptorHandle;
typedef void *DAVEDecryptorHandle;

typedef enum {
    DAVE_CODEC_UNKNOWN = 0,
    DAVE_CODEC_OPUS = 1,
    DAVE_CODEC_VP8 = 2,
    DAVE_CODEC_VP9 = 3,
    DAVE_CODEC_H264 = 4,
    DAVE_CODEC_H265 = 5,
    DAVE_CODEC_AV1 = 6
} DAVECodec;

typedef enum {
    DAVE_MEDIA_TYPE_AUDIO = 0,
    DAVE_MEDIA_TYPE_VIDEO = 1
} DAVEMediaType;

typedef void (*DAVEMLSFailureCallback)(const char *source, const char *reason,
                                       void *userData);

#define DAVE_FN(name, ret, args)                                               \
    typedef ret(*name##_fn) args;                                              \
    static name##_fn p_##name = NULL;

DAVE_FN(daveMaxSupportedProtocolVersion, uint16_t, (void))
DAVE_FN(daveFree, void, (void *))
DAVE_FN(daveSessionCreate, DAVESessionHandle,
        (void *, const char *, DAVEMLSFailureCallback, void *))
DAVE_FN(daveSessionDestroy, void, (DAVESessionHandle))
DAVE_FN(daveSessionInit, void,
        (DAVESessionHandle, uint16_t, uint64_t, const char *))
DAVE_FN(daveSessionReset, void, (DAVESessionHandle))
DAVE_FN(daveSessionSetProtocolVersion, void, (DAVESessionHandle, uint16_t))
DAVE_FN(daveSessionGetProtocolVersion, uint16_t, (DAVESessionHandle))
DAVE_FN(daveSessionSetExternalSender, void,
        (DAVESessionHandle, const uint8_t *, size_t))
DAVE_FN(daveSessionAddRecognizedUser, void, (DAVESessionHandle, const char *))
DAVE_FN(daveSessionRemoveRecognizedUser, void,
        (DAVESessionHandle, const char *))
DAVE_FN(daveSessionProcessProposals, void,
        (DAVESessionHandle, const uint8_t *, size_t, uint8_t **, size_t *))
DAVE_FN(daveSessionProcessCommit, DAVECommitResultHandle,
        (DAVESessionHandle, const uint8_t *, size_t))
DAVE_FN(daveSessionProcessWelcome, DAVEWelcomeResultHandle,
        (DAVESessionHandle, const uint8_t *, size_t))
DAVE_FN(daveSessionGetMarshalledKeyPackage, void,
        (DAVESessionHandle, uint8_t **, size_t *))
DAVE_FN(daveSessionGetKeyRatchet, DAVEKeyRatchetHandle,
        (DAVESessionHandle, const char *))
DAVE_FN(daveKeyRatchetDestroy, void, (DAVEKeyRatchetHandle))
DAVE_FN(daveCommitResultIsFailed, bool, (DAVECommitResultHandle))
DAVE_FN(daveCommitResultIsIgnored, bool, (DAVECommitResultHandle))
DAVE_FN(daveCommitResultGetRosterMemberIds, void,
        (DAVECommitResultHandle, uint64_t **, size_t *))
DAVE_FN(daveCommitResultDestroy, void, (DAVECommitResultHandle))
DAVE_FN(daveWelcomeResultGetRosterMemberIds, void,
        (DAVEWelcomeResultHandle, uint64_t **, size_t *))
DAVE_FN(daveWelcomeResultDestroy, void, (DAVEWelcomeResultHandle))
DAVE_FN(daveEncryptorCreate, DAVEEncryptorHandle, (void))
DAVE_FN(daveEncryptorDestroy, void, (DAVEEncryptorHandle))
DAVE_FN(daveEncryptorSetKeyRatchet, void,
        (DAVEEncryptorHandle, DAVEKeyRatchetHandle))
DAVE_FN(daveEncryptorSetPassthroughMode, void, (DAVEEncryptorHandle, bool))
DAVE_FN(daveEncryptorAssignSsrcToCodec, void,
        (DAVEEncryptorHandle, uint32_t, DAVECodec))
DAVE_FN(daveEncryptorGetProtocolVersion, uint16_t, (DAVEEncryptorHandle))
DAVE_FN(daveEncryptorGetMaxCiphertextByteSize, size_t,
        (DAVEEncryptorHandle, DAVEMediaType, size_t))
DAVE_FN(daveEncryptorHasKeyRatchet, bool, (DAVEEncryptorHandle))
DAVE_FN(daveEncryptorIsPassthroughMode, bool, (DAVEEncryptorHandle))
DAVE_FN(daveEncryptorEncrypt, int,
        (DAVEEncryptorHandle, DAVEMediaType, uint32_t, const uint8_t *, size_t,
         uint8_t *, size_t, size_t *))
DAVE_FN(daveDecryptorCreate, DAVEDecryptorHandle, (void))
DAVE_FN(daveDecryptorDestroy, void, (DAVEDecryptorHandle))
DAVE_FN(daveDecryptorTransitionToKeyRatchet, void,
        (DAVEDecryptorHandle, DAVEKeyRatchetHandle))
DAVE_FN(daveDecryptorTransitionToPassthroughMode, void,
        (DAVEDecryptorHandle, bool))
DAVE_FN(daveDecryptorDecrypt, int,
        (DAVEDecryptorHandle, DAVEMediaType, const uint8_t *, size_t, uint8_t *,
         size_t, size_t *))
DAVE_FN(daveDecryptorGetMaxPlaintextByteSize, size_t,
        (DAVEDecryptorHandle, DAVEMediaType, size_t))

static void *dave_lib = NULL;
static int dave_load_attempted = 0;
static int dave_loaded = 0;
static char dave_load_error[512] = "libdave is not loaded";

static void *dave_sym(const char *name) {
#ifdef _WIN32
    return (void *)GetProcAddress((HMODULE)dave_lib, name);
#else
    return dlsym(dave_lib, name);
#endif
}

static void *dave_open(const char *path) {
#ifdef _WIN32
    return (void *)LoadLibraryA(path);
#else
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
}

static int dave_missing_symbol(const char *name) {
    snprintf(dave_load_error, sizeof(dave_load_error),
             "libdave is missing symbol %s", name);
    return 0;
}

#define DAVE_LOAD(name)                                                        \
    do {                                                                       \
        p_##name = (name##_fn)dave_sym(#name);                                 \
        if (p_##name == NULL)                                                  \
            return dave_missing_symbol(#name);                                 \
    } while (0)

static int dave_load(void) {
    if (dave_load_attempted)
        return dave_loaded;
    dave_load_attempted = 1;

    const char *env = getenv("DISCORDML_LIBDAVE");
    if (env != NULL && env[0] != '\0')
        dave_lib = dave_open(env);
    if (dave_lib == NULL) {
#ifdef _WIN32
        dave_lib = dave_open("libdave.dll");
        if (dave_lib == NULL)
            dave_lib = dave_open("dave.dll");
#elif defined(__APPLE__)
        dave_lib = dave_open("libdave.dylib");
#else
        dave_lib = dave_open("libdave.so");
        if (dave_lib == NULL)
            dave_lib = dave_open("libdave.so.1");
#endif
    }
    if (dave_lib == NULL) {
        snprintf(dave_load_error, sizeof(dave_load_error),
                 "libdave not found (set DISCORDML_LIBDAVE to its path)");
        return 0;
    }

    DAVE_LOAD(daveMaxSupportedProtocolVersion);
    DAVE_LOAD(daveFree);
    DAVE_LOAD(daveSessionCreate);
    DAVE_LOAD(daveSessionDestroy);
    DAVE_LOAD(daveSessionInit);
    DAVE_LOAD(daveSessionReset);
    DAVE_LOAD(daveSessionSetProtocolVersion);
    DAVE_LOAD(daveSessionGetProtocolVersion);
    DAVE_LOAD(daveSessionSetExternalSender);
    DAVE_LOAD(daveSessionAddRecognizedUser);
    DAVE_LOAD(daveSessionRemoveRecognizedUser);
    DAVE_LOAD(daveSessionProcessProposals);
    DAVE_LOAD(daveSessionProcessCommit);
    DAVE_LOAD(daveSessionProcessWelcome);
    DAVE_LOAD(daveSessionGetMarshalledKeyPackage);
    DAVE_LOAD(daveSessionGetKeyRatchet);
    DAVE_LOAD(daveKeyRatchetDestroy);
    DAVE_LOAD(daveCommitResultIsFailed);
    DAVE_LOAD(daveCommitResultIsIgnored);
    DAVE_LOAD(daveCommitResultGetRosterMemberIds);
    DAVE_LOAD(daveCommitResultDestroy);
    DAVE_LOAD(daveWelcomeResultGetRosterMemberIds);
    DAVE_LOAD(daveWelcomeResultDestroy);
    DAVE_LOAD(daveEncryptorCreate);
    DAVE_LOAD(daveEncryptorDestroy);
    DAVE_LOAD(daveEncryptorSetKeyRatchet);
    DAVE_LOAD(daveEncryptorSetPassthroughMode);
    DAVE_LOAD(daveEncryptorAssignSsrcToCodec);
    DAVE_LOAD(daveEncryptorGetProtocolVersion);
    DAVE_LOAD(daveEncryptorGetMaxCiphertextByteSize);
    DAVE_LOAD(daveEncryptorHasKeyRatchet);
    DAVE_LOAD(daveEncryptorIsPassthroughMode);
    DAVE_LOAD(daveEncryptorEncrypt);
    DAVE_LOAD(daveDecryptorCreate);
    DAVE_LOAD(daveDecryptorDestroy);
    DAVE_LOAD(daveDecryptorTransitionToKeyRatchet);
    DAVE_LOAD(daveDecryptorTransitionToPassthroughMode);
    DAVE_LOAD(daveDecryptorDecrypt);
    DAVE_LOAD(daveDecryptorGetMaxPlaintextByteSize);

    dave_loaded = 1;
    return 1;
}

static void dave_require(void) {
    if (!dave_load())
        caml_failwith(dave_load_error);
}

static DAVESessionHandle session_val(value v) {
    return (DAVESessionHandle)(intptr_t)Nativeint_val(v);
}

static value session_handle(DAVESessionHandle h) {
    return caml_copy_nativeint((intptr_t)h);
}

static void mls_failure(const char *source, const char *reason, void *user) {
    (void)user;
    fprintf(stderr, "libdave MLS failure (%s): %s\n", source, reason);
}

static value copy_bytes(const uint8_t *data, size_t len) {
    if (data == NULL || len == 0)
        return caml_alloc_string(0);
    return caml_alloc_initialized_string(len, (const char *)data);
}

value caml_p_dave_available(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(dave_load()));
}

value caml_p_dave_load_error(value unit) {
    CAMLparam1(unit);
    if (dave_load())
        CAMLreturn(caml_alloc_string(0));
    CAMLreturn(caml_copy_string(dave_load_error));
}

value caml_p_dave_max_protocol_version(value unit) {
    CAMLparam1(unit);
    dave_require();
    CAMLreturn(Val_int(p_daveMaxSupportedProtocolVersion()));
}

value caml_p_dave_session_create(value auth_session_id) {
    CAMLparam1(auth_session_id);
    dave_require();
    const char *auth = String_val(auth_session_id);
    DAVESessionHandle h = p_daveSessionCreate(NULL, auth, mls_failure, NULL);
    if (h == NULL)
        caml_failwith("libdave: failed to create session");
    CAMLreturn(session_handle(h));
}

value caml_p_dave_session_destroy(value session) {
    CAMLparam1(session);
    dave_require();
    if (Nativeint_val(session) != 0)
        p_daveSessionDestroy(session_val(session));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_init(value session, value version, value group_id,
                               value user_id) {
    CAMLparam4(session, version, group_id, user_id);
    dave_require();
    uint64_t group = strtoull(String_val(group_id), NULL, 10);
    p_daveSessionInit(session_val(session), (uint16_t)Int_val(version), group,
                      String_val(user_id));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_reset(value session) {
    CAMLparam1(session);
    dave_require();
    p_daveSessionReset(session_val(session));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_set_protocol_version(value session, value version) {
    CAMLparam2(session, version);
    dave_require();
    p_daveSessionSetProtocolVersion(session_val(session),
                                    (uint16_t)Int_val(version));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_get_protocol_version(value session) {
    CAMLparam1(session);
    dave_require();
    CAMLreturn(Val_int(p_daveSessionGetProtocolVersion(session_val(session))));
}

value caml_p_dave_session_set_external_sender(value session, value data) {
    CAMLparam2(session, data);
    dave_require();
    p_daveSessionSetExternalSender(session_val(session),
                                   (const uint8_t *)String_val(data),
                                   caml_string_length(data));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_add_recognized_user(value session, value user_id) {
    CAMLparam2(session, user_id);
    dave_require();
    p_daveSessionAddRecognizedUser(session_val(session), String_val(user_id));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_remove_recognized_user(value session, value user_id) {
    CAMLparam2(session, user_id);
    dave_require();
    p_daveSessionRemoveRecognizedUser(session_val(session),
                                      String_val(user_id));
    CAMLreturn(Val_unit);
}

value caml_p_dave_session_process_proposals(value session, value proposals) {
    CAMLparam2(session, proposals);
    CAMLlocal1(result);
    dave_require();
    uint8_t *out = NULL;
    size_t len = 0;
    p_daveSessionProcessProposals(session_val(session),
                                  (const uint8_t *)String_val(proposals),
                                  caml_string_length(proposals), &out, &len);
    result = copy_bytes(out, len);
    if (out != NULL)
        p_daveFree(out);
    CAMLreturn(result);
}

value caml_p_dave_session_process_commit(value session, value commit) {
    CAMLparam2(session, commit);
    dave_require();
    DAVECommitResultHandle h = p_daveSessionProcessCommit(
        session_val(session), (const uint8_t *)String_val(commit),
        caml_string_length(commit));
    CAMLreturn(session_handle(h));
}

value caml_p_dave_session_process_welcome(value session, value welcome) {
    CAMLparam2(session, welcome);
    dave_require();
    DAVEWelcomeResultHandle h = p_daveSessionProcessWelcome(
        session_val(session), (const uint8_t *)String_val(welcome),
        caml_string_length(welcome));
    CAMLreturn(session_handle(h));
}

value caml_p_dave_session_get_key_package(value session) {
    CAMLparam1(session);
    CAMLlocal1(result);
    dave_require();
    uint8_t *out = NULL;
    size_t len = 0;
    p_daveSessionGetMarshalledKeyPackage(session_val(session), &out, &len);
    result = copy_bytes(out, len);
    if (out != NULL)
        p_daveFree(out);
    CAMLreturn(result);
}

value caml_p_dave_session_get_key_ratchet(value session, value user_id) {
    CAMLparam2(session, user_id);
    dave_require();
    DAVEKeyRatchetHandle h =
        p_daveSessionGetKeyRatchet(session_val(session), String_val(user_id));
    CAMLreturn(session_handle(h));
}

value caml_p_dave_key_ratchet_destroy(value ratchet) {
    CAMLparam1(ratchet);
    dave_require();
    if (Nativeint_val(ratchet) != 0)
        p_daveKeyRatchetDestroy(
            (DAVEKeyRatchetHandle)(intptr_t)Nativeint_val(ratchet));
    CAMLreturn(Val_unit);
}

value caml_p_dave_commit_result_is_failed(value result) {
    CAMLparam1(result);
    dave_require();
    CAMLreturn(Val_bool(p_daveCommitResultIsFailed(
        (DAVECommitResultHandle)(intptr_t)Nativeint_val(result))));
}

value caml_p_dave_commit_result_is_ignored(value result) {
    CAMLparam1(result);
    dave_require();
    CAMLreturn(Val_bool(p_daveCommitResultIsIgnored(
        (DAVECommitResultHandle)(intptr_t)Nativeint_val(result))));
}

value caml_p_dave_commit_result_has_roster(value result) {
    CAMLparam1(result);
    dave_require();
    uint64_t *ids = NULL;
    size_t len = 0;
    p_daveCommitResultGetRosterMemberIds(
        (DAVECommitResultHandle)(intptr_t)Nativeint_val(result), &ids, &len);
    if (ids != NULL)
        p_daveFree(ids);
    CAMLreturn(Val_bool(ids != NULL && len > 0));
}

value caml_p_dave_commit_result_destroy(value result) {
    CAMLparam1(result);
    dave_require();
    if (Nativeint_val(result) != 0)
        p_daveCommitResultDestroy(
            (DAVECommitResultHandle)(intptr_t)Nativeint_val(result));
    CAMLreturn(Val_unit);
}

value caml_p_dave_welcome_result_has_roster(value result) {
    CAMLparam1(result);
    dave_require();
    if (Nativeint_val(result) == 0)
        CAMLreturn(Val_false);
    uint64_t *ids = NULL;
    size_t len = 0;
    p_daveWelcomeResultGetRosterMemberIds(
        (DAVEWelcomeResultHandle)(intptr_t)Nativeint_val(result), &ids, &len);
    if (ids != NULL)
        p_daveFree(ids);
    CAMLreturn(Val_bool(len > 0));
}

value caml_p_dave_welcome_result_destroy(value result) {
    CAMLparam1(result);
    dave_require();
    if (Nativeint_val(result) != 0)
        p_daveWelcomeResultDestroy(
            (DAVEWelcomeResultHandle)(intptr_t)Nativeint_val(result));
    CAMLreturn(Val_unit);
}

value caml_p_dave_encryptor_create(value unit) {
    CAMLparam1(unit);
    dave_require();
    DAVEEncryptorHandle h = p_daveEncryptorCreate();
    if (h == NULL)
        caml_failwith("libdave: failed to create encryptor");
    CAMLreturn(session_handle(h));
}

value caml_p_dave_encryptor_destroy(value encryptor) {
    CAMLparam1(encryptor);
    dave_require();
    if (Nativeint_val(encryptor) != 0)
        p_daveEncryptorDestroy(
            (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor));
    CAMLreturn(Val_unit);
}

value caml_p_dave_encryptor_set_key_ratchet(value encryptor, value ratchet) {
    CAMLparam2(encryptor, ratchet);
    dave_require();
    p_daveEncryptorSetKeyRatchet(
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor),
        (DAVEKeyRatchetHandle)(intptr_t)Nativeint_val(ratchet));
    CAMLreturn(Val_unit);
}

value caml_p_dave_encryptor_set_passthrough(value encryptor, value enabled) {
    CAMLparam2(encryptor, enabled);
    dave_require();
    p_daveEncryptorSetPassthroughMode(
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor),
        Bool_val(enabled));
    CAMLreturn(Val_unit);
}

value caml_p_dave_encryptor_assign_ssrc(value encryptor, value ssrc,
                                        value codec) {
    CAMLparam3(encryptor, ssrc, codec);
    dave_require();
    p_daveEncryptorAssignSsrcToCodec(
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor),
        (uint32_t)Int_val(ssrc), (DAVECodec)Int_val(codec));
    CAMLreturn(Val_unit);
}

value caml_p_dave_encryptor_has_key_ratchet(value encryptor) {
    CAMLparam1(encryptor);
    dave_require();
    CAMLreturn(Val_bool(p_daveEncryptorHasKeyRatchet(
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor))));
}

value caml_p_dave_encryptor_get_protocol_version(value encryptor) {
    CAMLparam1(encryptor);
    dave_require();
    CAMLreturn(Val_int(p_daveEncryptorGetProtocolVersion(
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor))));
}

value caml_p_dave_encryptor_encrypt(value encryptor, value ssrc, value frame) {
    CAMLparam3(encryptor, ssrc, frame);
    CAMLlocal2(pair, bytes);
    dave_require();
    DAVEEncryptorHandle h =
        (DAVEEncryptorHandle)(intptr_t)Nativeint_val(encryptor);
    size_t frame_len = caml_string_length(frame);
    size_t capacity = p_daveEncryptorGetMaxCiphertextByteSize(
        h, DAVE_MEDIA_TYPE_AUDIO, frame_len);
    if (capacity == 0)
        capacity = frame_len + 64;
    uint8_t *out = malloc(capacity);
    if (out == NULL)
        caml_failwith("libdave: out of memory");
    size_t written = 0;
    int code = p_daveEncryptorEncrypt(
        h, DAVE_MEDIA_TYPE_AUDIO, (uint32_t)Int_val(ssrc),
        (const uint8_t *)String_val(frame), frame_len, out, capacity, &written);
    bytes = copy_bytes(out, code == 0 ? written : 0);
    free(out);
    pair = caml_alloc_tuple(2);
    Store_field(pair, 0, Val_int(code));
    Store_field(pair, 1, bytes);
    CAMLreturn(pair);
}

value caml_p_dave_decryptor_create(value unit) {
    CAMLparam1(unit);
    dave_require();
    DAVEDecryptorHandle h = p_daveDecryptorCreate();
    if (h == NULL)
        caml_failwith("libdave: failed to create decryptor");
    CAMLreturn(session_handle(h));
}

value caml_p_dave_decryptor_destroy(value decryptor) {
    CAMLparam1(decryptor);
    dave_require();
    if (Nativeint_val(decryptor) != 0)
        p_daveDecryptorDestroy(
            (DAVEDecryptorHandle)(intptr_t)Nativeint_val(decryptor));
    CAMLreturn(Val_unit);
}

value caml_p_dave_decryptor_transition_to_key_ratchet(value decryptor,
                                                      value ratchet) {
    CAMLparam2(decryptor, ratchet);
    dave_require();
    p_daveDecryptorTransitionToKeyRatchet(
        (DAVEDecryptorHandle)(intptr_t)Nativeint_val(decryptor),
        (DAVEKeyRatchetHandle)(intptr_t)Nativeint_val(ratchet));
    CAMLreturn(Val_unit);
}

value caml_p_dave_decryptor_transition_to_passthrough(value decryptor,
                                                      value enabled) {
    CAMLparam2(decryptor, enabled);
    dave_require();
    p_daveDecryptorTransitionToPassthroughMode(
        (DAVEDecryptorHandle)(intptr_t)Nativeint_val(decryptor),
        Bool_val(enabled));
    CAMLreturn(Val_unit);
}

value caml_p_dave_decryptor_decrypt(value decryptor, value frame) {
    CAMLparam2(decryptor, frame);
    CAMLlocal2(pair, bytes);
    dave_require();
    DAVEDecryptorHandle h =
        (DAVEDecryptorHandle)(intptr_t)Nativeint_val(decryptor);
    size_t frame_len = caml_string_length(frame);
    size_t capacity = p_daveDecryptorGetMaxPlaintextByteSize(
        h, DAVE_MEDIA_TYPE_AUDIO, frame_len);
    if (capacity == 0)
        capacity = frame_len + 64;
    uint8_t *out = malloc(capacity);
    if (out == NULL)
        caml_failwith("libdave: out of memory");
    size_t written = 0;
    int code = p_daveDecryptorDecrypt(h, DAVE_MEDIA_TYPE_AUDIO,
                                      (const uint8_t *)String_val(frame),
                                      frame_len, out, capacity, &written);
    bytes = copy_bytes(out, code == 0 ? written : 0);
    free(out);
    pair = caml_alloc_tuple(2);
    Store_field(pair, 0, Val_int(code));
    Store_field(pair, 1, bytes);
    CAMLreturn(pair);
}
