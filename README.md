# Local AI ChatBOT

A Flutter-based Android chatbot application that runs large language models locally on your device using llama.cpp. No internet required for inference (only for model downloads).

## Features

- **Offline Inference**: Run LLMs completely locally on your Android device
- **Multi-Model Support**: Download and switch between 30+ pre-configured models
- **HuggingFace Integration**: Direct model downloads with token authentication
- **Smart RAM Detection**: Automatic device capability assessment and model recommendations
- **Dark/Light Theme**: Beautiful Material Design UI with theme persistence
- **Chat History**: Local storage of conversation history
- **Progress Tracking**: Real-time download progress and cancellation support
- **Multi-Language Support**: English, Serbian (Cyrillic & Latin), German, Spanish
- **Background Inference**: Non-blocking AI responses using Dart isolates

## System Requirements

### Minimum
- Android 7.0 (API 24)
- 2GB RAM (for tiny models)
- 500MB storage (for smallest models)

### Recommended
- Android 11+ (API 30+)
- 6GB+ RAM (for 7B parameter models)
- 10GB+ storage (for multiple models)

### Supported Architectures
- ARM64 (arm64-v8a) - Primary, best supported
- ARMv7 (armeabi-v7a)
- x86_64
- x86

## Installation

### Prerequisites

1. **Flutter SDK** (3.0+)
   ```bash
   flutter --version
   ```

2. **Android NDK 25.1.8937393** (required for C++ compilation)
   ```bash
   # Via Android Studio SDK Manager, or:
   sdkmanager "ndk;25.1.8937393"
   ```

3. **CMake 3.22.1+** (for building native code)

### Build Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Luka12-dev/ChatBOT.git
   cd ChatBot
   ```

2. **Fetch llama.cpp dependency**
   ```bash
   # Clone llama.cpp as a git submodule (recommended)
   git submodule add https://github.com/ggerganov/llama.cpp.git android/app/third_party/llama.cpp
   git submodule update --init --recursive
   
   # OR manually clone it
   git clone --depth 1 https://github.com/ggerganov/llama.cpp.git android/app/third_party/llama.cpp
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Build the APK**
   ```bash
   # Debug build (faster compilation)
   flutter build apk --debug
   
   # Release build (optimized, recommended)
   flutter build apk --release
   ```

   The APK will be generated at: `build/app/outputs/flutter-apk/app-release.apk`

5. **Install on device**
   ```bash
   flutter install
   
   # Or manually:
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

## First Run

### 1. Get HuggingFace Token (Optional but Recommended)

For downloading private/gated models, you'll need a HuggingFace token:

1. Go to [HuggingFace Tokens Page](https://huggingface.co/settings/tokens)
2. Click **"New token"**
3. Name: `LocalChatBot`
4. Type: **Read** (⭐ IMPORTANT)
5. Click **"Generate"**
6. Copy the token (starts with `hf_`)

### 2. Add Token in App

1. Open the app
2. Tap the **Settings** icon (⚙️)
3. Scroll to "Hugging Face Token"
4. Click **"Paste from Clipboard"** or manually enter
5. Click **"Save & Validate"**

### 3. Download Your First Model

1. In Settings, scroll to "Models"
2. Choose a model based on your RAM:
   - **0.6-1.6 GB**: TinyLlama, Phi-2 (tiny models - all devices)
   - **2-4 GB**: Mistral-7B Q2, Llama-3.2 (small - recommended start)
   - **4-8 GB**: Mistral-7B Q4, Llama-3 (medium - needs 6GB+ RAM)
   - **8+ GB**: Mixtral, Llama-70B (large - high-end devices only)

3. Click **"Download"** and wait
4. Once complete, click **"Use"** to activate

### 4. Start Chatting

1. Type a message in the input field
2. Click **Send** (arrow icon)
3. Wait for the model to generate a response
4. Use special buttons for longer thinking:
   - **"Fast reply"**: Quick 64-token response
   - **"Think more (1 min)"**: Longer 256-token response with delay

## Model Recommendations

### For 2-3GB RAM Devices
- TinyLlama-1.1B-Chat-Q2 (0.4 GB)
- Llama-3.2-1B-Q4 (0.8 GB)
- Gemma-2B-Q4 (1.6 GB)

### For 4-6GB RAM Devices
- Mistral-7B-Q2 (2.8 GB) ⭐ Best balance
- Llama-2-7B-Q2 (2.7 GB)
- CodeLlama-7B-Q2 (2.9 GB)

### For 8GB+ RAM Devices
- Mistral-7B-Q4 (4.1 GB) ⭐ High quality
- Llama-3-8B-Q4 (4.9 GB)
- Gemma-7B-Q4 (4.4 GB)

### For Gaming/Flagship Phones
- Mixtral-8x7B-Q2 (7.5 GB)
- Llama-2-13B-Q4 (7.4 GB)

## Architecture Overview

### Components

```
lib/
├── main.dart              # App entry, providers, themes
├── ui/                    # Screens (HomeScreen, SettingsDrawer)
└── services/              # Business logic

android/app/src/main/
├── cpp/
│   └── llama_shim.cpp     # C++ wrapper for llama.cpp
├── jniLibs/               # Compiled .so libraries
└── AndroidManifest.xml

android/app/third_party/
└── llama.cpp/             # Git submodule (not in repo)
```

### Key Classes

- **`AuthManager`**: HuggingFace token management (secure storage)
- **`ModelManager`**: Local model metadata and state
- **`DownloadService`**: Model downloading with resume support
- **`NativeInference`**: FFI bindings to C++ inference
- **`SettingsManager`**: App preferences (theme, language, token)
- **`RamDetector`**: Device RAM detection for model recommendations

## Troubleshooting

### Build Issues

**Error: "CMake not found"**
```bash
# Install CMake via Android Studio SDK Manager
# Settings → SDK Manager → SDK Tools → CMake 3.22.1
```

**Error: "NDK not found"**
```bash
# Install NDK 25.1.8937393
sdkmanager "ndk;25.1.8937393"

# Or set in local.properties:
# ndk.dir=/path/to/ndk/25.1.8937393
```

**Error: "llama.cpp CMakeLists.txt not found"**
```bash
# Ensure llama.cpp is cloned:
git submodule update --init --recursive
# Or manually:
git clone https://github.com/ggerganov/llama.cpp.git android/app/third_party/llama.cpp
```

### Runtime Issues

**Error: "Native library not loaded"**
- Check that `.so` files exist: `android/app/src/main/jniLibs/`
- Run: `flutter clean && flutter build apk --release`
- Check logcat: `adb logcat | grep LocalAI`

**Model downloads fail with 401/403**
- Verify HuggingFace token has "Read" permission
- Token must start with `hf_`
- Generate a new token if unsure
- Check Settings > Save & Validate

**App freezes during inference**
- Inference runs in background isolate (Dart `compute()`)
- Large models may need 10-30 seconds
- Check device temperature (thermal throttling)
- Reduce `max_tokens` in Settings

**"Not enough memory" crashes**
- Choose smaller model (lower GB)
- Close other apps
- Check RAM with Settings diagnostics
- Reduce context size (edit `llama_shim.cpp` line ~80)

### Diagnostics

Enable debug logging:
```dart
// In main.dart, uncomment kDebugMode checks
flutter run -v
adb logcat | grep "LocalAI\|liblocalai"
```

## Development

### Project Structure

```
ChatBOT/
├── lib/                           # Dart/Flutter code
├── android/
│   ├── app/
│   │   ├── src/main/cpp/          # C++ inference wrapper
│   │   ├── src/main/jniLibs/      # Compiled native libraries
│   │   ├── build.gradle.kts       # Android build config
│   │   └── CMakeLists.txt         # CMake build config
│   └── gradle/                    # Gradle wrapper
├── pubspec.yaml                   # Flutter dependencies
└── README.md                       # This file
```

### Building for Different Architectures

By default, the app builds for all supported ABIs. To build for specific architectures:

```bash
# ARM64 only (most efficient)
flutter build apk --target-platform android-arm64

# All architectures
flutter build apk

# Split APKs by architecture (smaller downloads)
flutter build apk --split-per-abi
```

### Modifying Model Parameters

Edit `android/app/src/main/cpp/llama_shim.cpp`:
- Line ~80: `ctx_params.n_ctx = 512;` (context size)
- Line ~81: `ctx_params.n_batch = 128;` (batch size)
- Line ~82: `ctx_params.n_threads = 2;` (CPU threads)

Then rebuild: `flutter clean && flutter build apk --release`

## Performance Tips

1. **Use Quantized Models**: Q2/Q4 much faster than Q8
2. **Reduce Context**: 256 tokens faster than 512
3. **Smaller Models**: TinyLlama/Phi-2 run in seconds
4. **Close Background Apps**: Free up RAM
5. **Use Fast Reply**: 64 tokens (typical: 2-3 seconds)

## Dependencies

### Flutter Packages
- `flutter_ffi` - Native code bindings
- `provider` - State management
- `dio` - HTTP client for downloads
- `shared_preferences` - Local storage
- `flutter_secure_storage` - Secure token storage
- `device_info_plus` - Device capabilities
- `path_provider` - File system access
- `url_launcher` - Open browser links

### Native
- `llama.cpp` - LLM inference engine
- `Android NDK 25.1` - C++ compilation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards
- Follow Dart style guide (`dart format .`)
- Test on ARM64 first (primary architecture)
- Profile on low-end devices (2-3GB RAM)
- Document complex FFI interactions

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - The backbone inference engine
- [TheBloke](https://huggingface.co/TheBloke) - Quantized model conversions
- [Flutter](https://flutter.dev) - Cross-platform framework
- [HuggingFace](https://huggingface.co) - Model hosting and community

## Support

### Resources
- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [Flutter Documentation](https://flutter.dev/docs)
- [HuggingFace Models](https://huggingface.co/models)
- [Android NDK Guide](https://developer.android.com/ndk/guides)

### Report Issues
- Check [Existing Issues](https://github.com/Luka12-dev/ChatBOT/issues)
- Include logcat output and device info
- Mention model name and size

---

## Author
- Luka

**Happy chatting! 🚀**

*Note: This app requires no internet after model download. Your conversations stay on your device.*