#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

typedef void OpusEncoder;
typedef void OpusDecoder;

#define OPUS_APPLICATION_VOIP 2048
#define OPUS_SET_BITRATE_REQUEST 4002
#define OPUS_FRAME_SIZE 5760

#define OPUS_FN(name, ret, args)                                               \
    typedef ret(*name##_fn) args;                                              \
    static name##_fn p_##name = NULL;

OPUS_FN(opus_encoder_create, OpusEncoder *, (int, int, int, int *))
OPUS_FN(opus_encoder_destroy, int, (OpusEncoder *))
OPUS_FN(opus_encoder_ctl, int, (OpusEncoder *, int, ...))
OPUS_FN(opus_encode, int,
        (OpusEncoder *, const int16_t *, int, unsigned char *, int))
OPUS_FN(opus_decoder_create, OpusDecoder *, (int, int, int *))
OPUS_FN(opus_decoder_destroy, int, (OpusDecoder *))
OPUS_FN(opus_decode, int,
        (OpusDecoder *, const unsigned char *, int, int16_t *, int, int))
OPUS_FN(opus_strerror, const char *, (int))

static void *opus_lib = NULL;
static int opus_load_attempted = 0;
static int opus_loaded = 0;
static char opus_load_error[512] = "libopus is not loaded";

static void *opus_sym(const char *name) {
#ifdef _WIN32
    return (void *)GetProcAddress((HMODULE)opus_lib, name);
#else
    return dlsym(opus_lib, name);
#endif
}

static void *opus_open(const char *path) {
#ifdef _WIN32
    return (void *)LoadLibraryA(path);
#else
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
}

static int opus_missing_symbol(const char *name) {
    snprintf(opus_load_error, sizeof(opus_load_error),
             "libopus is missing symbol %s", name);
    return 0;
}

#define OPUS_LOAD(name)                                                        \
    do {                                                                       \
        p_##name = (name##_fn)opus_sym(#name);                                 \
        if (p_##name == NULL)                                                  \
            return opus_missing_symbol(#name);                                 \
    } while (0)

static int opus_load(void) {
    if (opus_load_attempted)
        return opus_loaded;
    opus_load_attempted = 1;

    const char *env = getenv("DISCORDML_LIBOPUS");
    if (env != NULL && env[0] != '\0')
        opus_lib = opus_open(env);
    if (opus_lib == NULL) {
#ifdef _WIN32
        opus_lib = opus_open("opus.dll");
#elif defined(__APPLE__)
        opus_lib = opus_open("libopus.dylib");
        if (opus_lib == NULL)
            opus_lib = opus_open("libopus.0.dylib");
#else
        opus_lib = opus_open("libopus.so.0");
        if (opus_lib == NULL)
            opus_lib = opus_open("libopus.so");
#endif
    }
    if (opus_lib == NULL) {
        snprintf(opus_load_error, sizeof(opus_load_error),
                 "libopus not found (set DISCORDML_LIBOPUS to its path)");
        return 0;
    }

    OPUS_LOAD(opus_encoder_create);
    OPUS_LOAD(opus_encoder_destroy);
    OPUS_LOAD(opus_encoder_ctl);
    OPUS_LOAD(opus_encode);
    OPUS_LOAD(opus_decoder_create);
    OPUS_LOAD(opus_decoder_destroy);
    OPUS_LOAD(opus_decode);
    OPUS_LOAD(opus_strerror);

    opus_loaded = 1;
    return 1;
}

static void opus_require(void) {
    if (!opus_load())
        caml_failwith(opus_load_error);
}

static OpusEncoder *encoder_val(value v) {
    return (OpusEncoder *)(intptr_t)Nativeint_val(v);
}

static OpusDecoder *decoder_val(value v) {
    return (OpusDecoder *)(intptr_t)Nativeint_val(v);
}

value caml_p_opus_available(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(opus_load()));
}

value caml_p_opus_load_error(value unit) {
    CAMLparam1(unit);
    if (opus_load())
        CAMLreturn(caml_alloc_string(0));
    CAMLreturn(caml_copy_string(opus_load_error));
}

value caml_p_opus_encoder_create(value unit) {
    CAMLparam1(unit);
    opus_require();
    int error = 0;
    OpusEncoder *enc =
        p_opus_encoder_create(48000, 2, OPUS_APPLICATION_VOIP, &error);
    if (enc == NULL || error != 0)
        caml_failwith("libopus: failed to create encoder");
    (void)p_opus_encoder_ctl(enc, OPUS_SET_BITRATE_REQUEST, 64000);
    CAMLreturn(caml_copy_nativeint((intptr_t)enc));
}

value caml_p_opus_encoder_destroy(value encoder) {
    CAMLparam1(encoder);
    opus_require();
    if (Nativeint_val(encoder) != 0)
        p_opus_encoder_destroy(encoder_val(encoder));
    CAMLreturn(Val_unit);
}

value caml_p_opus_encode(value encoder, value pcm) {
    CAMLparam2(encoder, pcm);
    opus_require();
    mlsize_t len = Wosize_val(pcm);
    int frame_size = (int)(len / 2);
    if (frame_size <= 0 || len % 2 != 0)
        caml_invalid_argument("P_opus.encode: expected interleaved stereo PCM");
    int16_t *samples = malloc(len * sizeof(int16_t));
    if (samples == NULL)
        caml_failwith("libopus: out of memory");
    for (mlsize_t i = 0; i < len; i++)
        samples[i] = (int16_t)Long_val(Field(pcm, i));
    unsigned char out[4000];
    int written = p_opus_encode(encoder_val(encoder), samples, frame_size, out,
                                (int)sizeof(out));
    free(samples);
    if (written < 0)
        caml_failwith(p_opus_strerror(written));
    CAMLreturn(caml_alloc_initialized_string(written, (const char *)out));
}

value caml_p_opus_decoder_create(value unit) {
    CAMLparam1(unit);
    opus_require();
    int error = 0;
    OpusDecoder *dec = p_opus_decoder_create(48000, 2, &error);
    if (dec == NULL || error != 0)
        caml_failwith("libopus: failed to create decoder");
    CAMLreturn(caml_copy_nativeint((intptr_t)dec));
}

value caml_p_opus_decoder_destroy(value decoder) {
    CAMLparam1(decoder);
    opus_require();
    if (Nativeint_val(decoder) != 0)
        p_opus_decoder_destroy(decoder_val(decoder));
    CAMLreturn(Val_unit);
}

value caml_p_opus_decode(value decoder, value packet) {
    CAMLparam2(decoder, packet);
    CAMLlocal1(result);
    opus_require();
    int16_t samples[OPUS_FRAME_SIZE * 2];
    int frames = p_opus_decode(
        decoder_val(decoder), (const unsigned char *)String_val(packet),
        (int)caml_string_length(packet), samples, OPUS_FRAME_SIZE, 0);
    if (frames < 0)
        caml_failwith(p_opus_strerror(frames));
    int count = frames * 2;
    result = caml_alloc(count, 0);
    for (int i = 0; i < count; i++)
        Store_field(result, i, Val_long(samples[i]));
    CAMLreturn(result);
}
