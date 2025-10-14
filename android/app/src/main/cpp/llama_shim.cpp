#include <string>
#include <cstring>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <sstream>
#include <android/log.h>

#define LOG_TAG "LocalAI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static inline char* malloc_copy_cstr(const std::string& s) {
    char* out = (char*)std::malloc(s.size() + 1);
    if (out) std::memcpy(out, s.c_str(), s.size() + 1);
    return out;
}

static inline bool file_exists(const char* path) {
    if (!path) return false;
    std::ifstream f(path);
    return f.good();
}

#ifdef USE_LLAMA_CPP
#include "llama.h"

// Global cache
static llama_model* g_model = nullptr;
static llama_context* g_ctx = nullptr;
static const llama_vocab* g_vocab = nullptr;
static std::string g_model_path;

static void free_model() {
    if (g_ctx) {
        llama_free(g_ctx);
        g_ctx = nullptr;
    }
    if (g_model) {
        llama_model_free(g_model);
        g_model = nullptr;
    }
    g_vocab = nullptr;
    g_model_path.clear();
}

static bool load_model(const char* path) {
    LOGI("Loading model from: %s", path);
    
    if (!path || !file_exists(path)) {
        LOGE("Model file does not exist: %s", path ? path : "(null)");
        return false;
    }

    if (g_model && g_model_path == path) {
        LOGI("Model already loaded");
        return true;
    }

    free_model();
    
    LOGI("Initializing llama backend...");
    llama_backend_init();
    
    LOGI("Setting up model params...");
    llama_model_params model_params = llama_model_default_params();
    model_params.n_gpu_layers = 0; // CPU only
    
    LOGI("Loading model file...");
    g_model = llama_model_load_from_file(path, model_params);
    if (!g_model) {
        LOGE("Failed to load model from file");
        return false;
    }
    
    LOGI("Getting vocab...");
    g_vocab = llama_model_get_vocab(g_model);
    if (!g_vocab) {
        LOGE("Failed to get vocab from model");
        llama_model_free(g_model);
        g_model = nullptr;
        return false;
    }
    
    LOGI("Setting up context params...");
    llama_context_params ctx_params = llama_context_default_params();
    ctx_params.n_ctx = 512;      // Reduced from 2048
    ctx_params.n_batch = 128;    // Reduced from 512
    ctx_params.n_threads = 2;    // Reduced from 4
    
    LOGI("Creating context...");
    g_ctx = llama_init_from_model(g_model, ctx_params);
    if (!g_ctx) {
        LOGE("Failed to create context");
        llama_model_free(g_model);
        g_model = nullptr;
        g_vocab = nullptr;
        return false;
    }
    
    g_model_path = path;
    LOGI("Model loaded successfully!");
    return true;
}

static std::string generate_text(const char* prompt, int max_tokens) {
    if (!g_model || !g_ctx || !g_vocab) {
        return "ERROR: Model not loaded";
    }
    
    LOGI("Starting text generation...");
    LOGI("Input: %.50s", prompt);
    
    try {
        // Tokenize
        std::vector<llama_token> tokens;
        tokens.resize(512);
        
        LOGI("Tokenizing...");
        int n_tokens = llama_tokenize(
            g_vocab,
            prompt,
            strlen(prompt),
            tokens.data(),
            tokens.size(),
            true,
            false
        );
        
        if (n_tokens < 0) {
            LOGE("Tokenization failed: %d", n_tokens);
            return "ERROR: Tokenization failed";
        }
        
        tokens.resize(n_tokens);
        LOGI("Tokenized into %d tokens", n_tokens);
        
        // Evaluate prompt
        LOGI("Preparing batch...");
        llama_batch batch = llama_batch_get_one(tokens.data(), n_tokens);
        
        LOGI("Decoding prompt...");
        if (llama_decode(g_ctx, batch) != 0) {
            LOGE("Failed to decode prompt");
            return "ERROR: Failed to decode prompt";
        }
        
        LOGI("Prompt decoded successfully");
        
        // Generate tokens
        std::string result;
        result.reserve(max_tokens * 4);
        
        int n_vocab = llama_vocab_n_tokens(g_vocab);
        LOGI("Vocab size: %d", n_vocab);
        
        // Limit max tokens to prevent crashes
        int safe_max_tokens = (max_tokens > 50) ? 50 : max_tokens;
        LOGI("Generating %d tokens...", safe_max_tokens);
        
        for (int i = 0; i < safe_max_tokens; i++) {
            // Get logits - with safety check
            float* logits = llama_get_logits_ith(g_ctx, -1);
            if (!logits) {
                LOGE("Failed to get logits at token %d", i);
                break;
            }
            
            // Simple greedy sampling
            llama_token new_token = 0;
            float max_logit = -1e10f;
            
            for (int j = 0; j < n_vocab; j++) {
                if (logits[j] > max_logit) {
                    max_logit = logits[j];
                    new_token = j;
                }
            }
            
            LOGI("Token %d: id=%d, logit=%.3f", i, new_token, max_logit);
            
            // Check for EOS
            if (llama_vocab_is_eog(g_vocab, new_token)) {
                LOGI("EOS reached at token %d", i);
                break;
            }
            
            // Convert token to text
            char buf[256];
            int n = llama_token_to_piece(g_vocab, new_token, buf, sizeof(buf), 0, false);
            if (n > 0 && n < 256) {
                result.append(buf, n);
                LOGI("Generated text so far: %s", result.c_str());
            }
            
            // Decode next token
            llama_batch next_batch = llama_batch_get_one(&new_token, 1);
            if (llama_decode(g_ctx, next_batch) != 0) {
                LOGE("Failed to decode at token %d", i);
                break;
            }
        }
        
        LOGI("Generation complete: %d chars", (int)result.size());
        
        if (result.empty()) {
            return "ERROR: Generated empty response";
        }
        
        return result;
        
    } catch (...) {
        LOGE("Exception during generation");
        return "ERROR: Exception during generation";
    }
}

#endif // USE_LLAMA_CPP

extern "C" {

char* run_inference(const char* modelPath, const char* prompt, int maxTokens) {
    LOGI("=== run_inference called ===");
    LOGI("Model: %s", modelPath ? modelPath : "(null)");
    LOGI("Prompt: %s", prompt ? prompt : "(null)");
    LOGI("Max tokens: %d", maxTokens);
    
    if (!prompt) {
        return malloc_copy_cstr("ERROR: Prompt is null");
    }
    
    if (!modelPath || !file_exists(modelPath)) {
        std::string err = "ERROR: Model file not found at: ";
        err += modelPath ? modelPath : "(null)";
        LOGE("%s", err.c_str());
        return malloc_copy_cstr(err);
    }

#ifdef USE_LLAMA_CPP
    LOGI("Starting model load...");
    if (!load_model(modelPath)) {
        LOGE("Model load failed");
        return malloc_copy_cstr("ERROR: Failed to load model. Check logs for details.");
    }
    
    LOGI("Model loaded, starting generation...");
    std::string result = generate_text(prompt, maxTokens);
    LOGI("Generation finished: %s", result.c_str());
    return malloc_copy_cstr(result);
#else
    LOGI("Running in MOCK mode");
    std::ostringstream oss;
    oss << "MOCK RESPONSE:\n\n";
    oss << "Your question: " << prompt << "\n\n";
    oss << "The llama.cpp library is not properly linked.\n";
    oss << "Model file: " << modelPath << "\n";
    
    return malloc_copy_cstr(oss.str());
#endif
}

void free_c_str(void* ptr) {
    if (ptr) free(ptr);
}

void free_c_char_ptr(void* ptr) {
    if (ptr) free(ptr);
}

const char* test_native() {
    return "ok";
}

const char* get_library_version() {
    return "localai-v6-safe";
}

} // extern "C"