#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>
#include "llama.h"

#define LOG_TAG "EdithNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace {
llama_model* g_model = nullptr;
llama_context* g_ctx = nullptr;
llama_sampler* g_sampler = nullptr;
bool g_backend_initialized = false;

constexpr int kContextSize = 2048;
constexpr int kMaxGenTokens = 256;

void freeEngine() {
    if (g_sampler) { llama_sampler_free(g_sampler); g_sampler = nullptr; }
    if (g_ctx) { llama_free(g_ctx); g_ctx = nullptr; }
    if (g_model) { llama_model_free(g_model); g_model = nullptr; }
}
} // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_nlocho_edith_MainActivity_initLlamaEngine(JNIEnv* env, jobject /* this */, jstring modelPath) {
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    LOGI("Loading model from: %s", path);

    if (!g_backend_initialized) {
        llama_backend_init();
        g_backend_initialized = true;
    }

    // Clean up any previous engine before reinitializing.
    freeEngine();

    llama_model_params modelParams = llama_model_default_params();
    modelParams.n_gpu_layers = 0; // CPU-only on Android

    g_model = llama_model_load_from_file(path, modelParams);
    env->ReleaseStringUTFChars(modelPath, path);

    if (!g_model) {
        LOGE("Failed to load model");
        return JNI_FALSE;
    }

    llama_context_params ctxParams = llama_context_default_params();
    ctxParams.n_ctx = kContextSize;
    ctxParams.n_threads = 4;
    ctxParams.n_threads_batch = 4;

    g_ctx = llama_init_from_model(g_model, ctxParams);
    if (!g_ctx) {
        LOGE("Failed to create context");
        freeEngine();
        return JNI_FALSE;
    }

    llama_sampler_chain_params samplerParams = llama_sampler_chain_default_params();
    g_sampler = llama_sampler_chain_init(samplerParams);
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_k(40));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_top_p(0.9f, 1));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_temp(0.7f));
    llama_sampler_chain_add(g_sampler, llama_sampler_init_dist(LLAMA_DEFAULT_SEED));

    LOGI("Engine initialized successfully");
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_nlocho_edith_MainActivity_runLlamaInference(JNIEnv* env, jobject /* this */, jstring promptJ) {
    if (!g_model || !g_ctx || !g_sampler) {
        return env->NewStringUTF("[error] Engine not initialized");
    }

    const char* promptChars = env->GetStringUTFChars(promptJ, nullptr);
    std::string prompt(promptChars);
    env->ReleaseStringUTFChars(promptJ, promptChars);

    const llama_vocab* vocab = llama_model_get_vocab(g_model);

    // Tokenize the prompt.
    int nPromptTokens = -llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(),
                                         nullptr, 0, true, true);
    std::vector<llama_token> promptTokens(nPromptTokens);
    if (llama_tokenize(vocab, prompt.c_str(), (int32_t)prompt.size(),
                        promptTokens.data(), nPromptTokens, true, true) < 0) {
        return env->NewStringUTF("[error] Tokenization failed");
    }

    // Reset KV cache for a fresh generation each call (simple, stateless turns).
    llama_memory_clear(llama_get_memory(g_ctx), true);

    llama_batch batch = llama_batch_get_one(promptTokens.data(), (int32_t)promptTokens.size());
    if (llama_decode(g_ctx, batch) != 0) {
        return env->NewStringUTF("[error] Initial decode failed");
    }

    std::string result;
    llama_token newToken;
    int generated = 0;
    int nCurrent = (int)promptTokens.size();

    char pieceBuf[256];

    while (generated < kMaxGenTokens) {
        newToken = llama_sampler_sample(g_sampler, g_ctx, -1);
        llama_sampler_accept(g_sampler, newToken);

        if (llama_vocab_is_eog(vocab, newToken)) {
            break;
        }

        int n = llama_token_to_piece(vocab, newToken, pieceBuf, sizeof(pieceBuf), 0, true);
        if (n > 0) {
            result.append(pieceBuf, n);
        }

        llama_batch nextBatch = llama_batch_get_one(&newToken, 1);
        if (llama_decode(g_ctx, nextBatch) != 0) {
            LOGE("Decode failed mid-generation");
            break;
        }

        generated++;
        nCurrent++;
    }

    return env->NewStringUTF(result.c_str());
}
