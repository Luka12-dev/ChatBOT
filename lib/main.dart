import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

/// Minimal / Elegant Dark + Light theme and ThemeManager.
/// Safe to paste into lib/theme_manager.dart

class AppThemes {
  AppThemes._();

  static const Color _brandBlue = Color(0xFF2196F3);

  // Shared base text theme (same fields & shape for both light + dark)
  static const TextTheme _baseTextTheme = TextTheme(
    bodyLarge: TextStyle(color: Colors.black87, fontSize: 15),
    bodyMedium: TextStyle(color: Colors.black54, fontSize: 13),
    titleLarge: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
    labelLarge: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
  );

  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2196F3),
      onPrimary: Colors.white,
      background: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: _baseTextTheme, 
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(_brandBlue),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        textStyle: MaterialStateProperty.all(const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        elevation: MaterialStateProperty.all(0.0),
      ),
    ),
  );

  // DARK THEME
  static const Color _darkPrimary = Color(0xFF1C1C1C); 
  static const Color _darkSurface = Color(0xFF121212); 
  static const Color _darkAccent = Color(0xFF888888); 
  static const Color _darkOnSurface = Colors.white70; 
  static const Color _darkButton = Color(0xFF1F1F1F); 
  static const Color _darkMessage = Color(0xFF121212); // isti kao _darkSurface za sve poruke

  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: Colors.white,
      background: _darkPrimary,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
    ),
    scaffoldBackgroundColor: _darkPrimary,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: _darkOnSurface, fontSize: 15),
      bodyMedium: TextStyle(color: Colors.white60, fontSize: 13),
      titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      labelLarge: TextStyle(color: _darkAccent, fontSize: 14, fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(_darkButton),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        textStyle: MaterialStateProperty.all(TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        elevation: MaterialStateProperty.all(0.0),
      ),
    ),

    cardTheme: ThemeData().cardTheme.copyWith(
      color: _darkSurface, 
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.white54),
      labelStyle: TextStyle(color: _darkOnSurface),
    ),
  );

  /// CHAT MESSAGE WIDGET
  Widget outgoingMessage(String messageText) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppThemes._darkMessage, // OVDE je totalno crna
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          messageText,
          style: const TextStyle(color: Colors.white), // svetli tekst
        ),
      ),
    );
  }

  Widget incomingMessage(String messageText) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: AppThemes._darkMessage, // isti crni ton
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          messageText,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// ThemeManager: simple ChangeNotifier that holds current ThemeData and dark flag.
class ThemeManager extends ChangeNotifier {
  bool _isDark;
  ThemeManager({required bool initialDark}) : _isDark = initialDark;

  bool get isDark => _isDark;

  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode_v2', value);
    notifyListeners();
  }
}

class AuthManager extends ChangeNotifier {
  final _secure = const FlutterSecureStorage();
  static const _key = 'hf_access_token';
  String? _token;
  String get token => _token ?? '';
  bool get hasToken => _token != null && _token!.isNotEmpty;

  AuthManager() {
    _load();
  }

  Future<void> _load() async {
    try {
      _token = await _secure.read(key: _key);
    } catch (_) {
      _token = null;
    }

    // Fallback: ako secure storage nema token, pokušaj SharedPreferences
    if (_token == null || _token!.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final spToken =
            prefs.getString('token_v2') ?? prefs.getString('token') ?? '';
        if (spToken.isNotEmpty) _token = spToken;
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<void> setToken(String t, {bool saveJsonBackup = false}) async {
    final trimmed = t.trim();
    _token = trimmed;

    try {
      await _secure.write(key: _key, value: _token);
    } catch (_) {}

    // Sačuvaj kopiju u SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token_v2', _token ?? '');
    } catch (_) {}

    if (saveJsonBackup) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final f = File('${dir.path}/token.json');
        await f.writeAsString(jsonEncode({'hf_token': _token}));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> clearToken() async {
    _token = null;
    try {
      await _secure.delete(key: _key);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token_v2');
      await prefs.remove('token');
    } catch (_) {}
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/token.json');
      if (await f.exists()) await f.delete();
    } catch (_) {}
    notifyListeners();
  }

  Future<Map<String, dynamic>> validateToken() async {
    if (!hasToken) {
      return {'ok': 'false', 'msg': 'No token provided'};
    }

    // Basic format check
    if (!_token!.startsWith('hf_')) {
      return {
        'ok': 'false',
        'msg': 'Invalid token format. Token must start with "hf_"'
      };
    }

    try {
      final d = Dio();
      d.options.connectTimeout = const Duration(seconds: 10);
      d.options.receiveTimeout = const Duration(seconds: 10);

      final resp = await d.get(
        'https://huggingface.co/api/whoami',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => true, // Accept all status codes
        ),
      );

      if (kDebugMode) {
        print('HF API Response: ${resp.statusCode}');
        print('Response data: ${resp.data}');
      }

      // Success cases
      if (resp.statusCode == 200) {
        if (resp.data is Map<String, dynamic>) {
          final data = resp.data as Map<String, dynamic>;
          final username = data['name']?.toString() ??
              data['fullname']?.toString() ??
              data['id']?.toString() ??
              'user';
          return {'ok': 'true', 'msg': username};
        } else {
          return {
            'ok': 'false',
            'msg': 'Unexpected response format from HuggingFace'
          };
        }
      }

      // Error cases with detailed explanations
      if (resp.statusCode == 401) {
        return {
          'ok': 'false',
          'msg': 'Token is INVALID or EXPIRED.\n\n'
              '⚠️ Common causes:\n'
              '• Token was deleted on HuggingFace\n'
              '• Token has expired\n'
              '• Wrong token copied\n\n'
              '✓ Solution: Generate NEW token with "Read" permission'
        };
      }

      if (resp.statusCode == 403) {
        return {
          'ok': 'false',
          'msg': 'Token has NO PERMISSION.\n\n'
              '⚠️ Your token lacks "Read" scope!\n\n'
              '✓ Solution:\n'
              '1. Go to HuggingFace tokens page\n'
              '2. Create NEW token\n'
              '3. Select type: "Read" ✓\n'
              '4. Generate and copy'
        };
      }

      if (resp.statusCode == 429) {
        return {
          'ok': 'false',
          'msg': 'Too many requests. Wait a moment and try again.'
        };
      }

      if ((resp.statusCode ?? 0) >= 500) {
        return {
          'ok': false,
          'msg':
              'HuggingFace server error (${resp.statusCode}). Try again later.'
        };
      }

      // Generic error
      return {
        'ok': 'false',
        'msg':
            'HTTP ${resp.statusCode}: ${resp.statusMessage ?? "Unknown error"}'
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException: ${e.type}');
        print('Error: ${e.message}');
      }

      // Connection errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return {
          'ok': 'false',
          'msg': 'Connection timeout. Check your internet connection.'
        };
      }

      if (e.type == DioExceptionType.connectionError) {
        return {
          'ok': 'false',
          'msg': 'No internet connection. Please check your network.'
        };
      }

      // HTTP errors
      final status = e.response?.statusCode ?? 0;
      if (status == 401) {
        return {
          'ok': 'false',
          'msg': 'Token is INVALID.\n\n'
              '✓ Generate new token with "Read" permission'
        };
      }
      if (status == 403) {
        return {
          'ok': 'false',
          'msg': 'Token has NO PERMISSION.\n\n'
              '✓ Create new token with "Read" type'
        };
      }

      return {
        'ok': 'false',
        'msg': 'Network error: ${e.message ?? "Unknown error"}'
      };
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error: $e');
      }
      return {'ok': 'false', 'msg': 'Unexpected error: ${e.toString()}'};
    }
  }
}

class LocalModelMeta {
  final String name;
  final double sizeGb;
  final List<String> languages;
  final String hfRepo;
  final String hfFile;
  bool isDownloaded;
  String? localPath;

  LocalModelMeta({
    required this.name,
    required this.sizeGb,
    required this.languages,
    required this.hfRepo,
    required this.hfFile,
    this.isDownloaded = false,
    this.localPath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'sizeGb': sizeGb,
        'languages': languages,
        'hfRepo': hfRepo,
        'hfFile': hfFile,
        'isDownloaded': isDownloaded,
        'localPath': localPath,
      };

  factory LocalModelMeta.fromJson(Map<String, dynamic> j) => LocalModelMeta(
        name: j['name'],
        sizeGb: (j['sizeGb'] + 0.0),
        languages: List<String>.from(j['languages']),
        hfRepo: j['hfRepo'],
        hfFile: j['hfFile'],
        isDownloaded: j['isDownloaded'] ?? false,
        localPath: j['localPath'],
      );
}

class ModelManager extends ChangeNotifier {
  final List<LocalModelMeta> models = [];
  LocalModelMeta? activeModel;
  static const _prefsKey = 'local_models_v1';

  ModelManager() {
    _initDefaultModels();
  }

  Future<void> initialize() async {
    await _loadState();
  }


  void _initDefaultModels() {
    final base = [
      // ===== TINY MODELS (0.1-1 GB) - Za slabe telefone =====
      [
        'TinyLlama-1.1B-Chat-Q4',
        0.6,
        ['en'],
        'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
        'tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf'
      ],
      [
        'TinyLlama-1.1B-Chat-Q2',
        0.4,
        ['en'],
        'TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF',
        'tinyllama-1.1b-chat-v1.0.Q2_K.gguf'
      ],
      [
        'Deepseek-Coder-1.3B-Q4',
        0.8,
        ['en'],
        'TheBloke/deepseek-coder-1.3b-instruct-GGUF',
        'deepseek-coder-1.3b-instruct.Q4_K_M.gguf'
      ],
      [
        'Phi-2-Q4',
        1.6,
        ['en'],
        'TheBloke/phi-2-GGUF',
        'phi-2.Q4_K_M.gguf'
      ],
      [
        'StableLM-Zephyr-3B-Q4',
        1.9,
        ['en'],
        'TheBloke/stablelm-zephyr-3b-GGUF',
        'stablelm-zephyr-3b.Q4_K_M.gguf'
      ],

      // ===== SMALL MODELS (2-4 GB) - Dobri za većinu telefona =====
      [
        'Mistral-7B-Q2',
        2.8,
        ['en'],
        'TheBloke/Mistral-7B-Instruct-v0.2-GGUF',
        'mistral-7b-instruct-v0.2.Q2_K.gguf'
      ],
      [
        'Llama-2-7B-Q2',
        2.7,
        ['en'],
        'TheBloke/Llama-2-7B-Chat-GGUF',
        'llama-2-7b-chat.Q2_K.gguf'
      ],
      [
        'CodeLlama-7B-Q2',
        2.9,
        ['en'],
        'TheBloke/CodeLlama-7B-Instruct-GGUF',
        'codellama-7b-instruct.Q2_K.gguf'
      ],
      [
        'Gemma-2B-Q4',
        1.6,
        ['en'],
        'lmstudio-community/gemma-2b-it-GGUF',
        'gemma-2b-it-Q4_K_M.gguf'
      ],
      [
        'Qwen-1.8B-Q4',
        1.1,
        ['en', 'zh'],
        'Qwen/Qwen1.5-1.8B-Chat-GGUF',
        'qwen1_5-1_8b-chat-q4_k_m.gguf'
      ],
      [
        'Llama-3.2-1B-Q4',
        0.8,
        ['en'],
        'bartowski/Llama-3.2-1B-Instruct-GGUF',
        'Llama-3.2-1B-Instruct-Q4_K_M.gguf'
      ],
      [
        'Llama-3.2-3B-Q4',
        2.0,
        ['en'],
        'bartowski/Llama-3.2-3B-Instruct-GGUF',
        'Llama-3.2-3B-Instruct-Q4_K_M.gguf'
      ],

      // ===== MEDIUM MODELS (4-8 GB) - Potrebno više RAM-a =====
      [
        'Mistral-7B-Q4',
        4.1,
        ['en'],
        'TheBloke/Mistral-7B-Instruct-v0.2-GGUF',
        'mistral-7b-instruct-v0.2.Q4_K_M.gguf'
      ],
      [
        'Llama-2-7B-Q4',
        3.8,
        ['en'],
        'TheBloke/Llama-2-7B-Chat-GGUF',
        'llama-2-7b-chat.Q4_K_M.gguf'
      ],
      [
        'Vicuna-7B-Q4',
        3.8,
        ['en'],
        'TheBloke/vicuna-7B-v1.5-GGUF',
        'vicuna-7b-v1.5.Q4_K_M.gguf'
      ],
      [
        'Zephyr-7B-Q4',
        4.1,
        ['en'],
        'TheBloke/zephyr-7B-beta-GGUF',
        'zephyr-7b-beta.Q4_K_M.gguf'
      ],
      [
        'OpenChat-3.5-Q4',
        4.1,
        ['en'],
        'TheBloke/openchat-3.5-1210-GGUF',
        'openchat-3.5-1210.Q4_K_M.gguf'
      ],
      [
        'Deepseek-Coder-6.7B-Q4',
        3.9,
        ['en'],
        'TheBloke/deepseek-coder-6.7b-instruct-GGUF',
        'deepseek-coder-6.7b-instruct.Q4_K_M.gguf'
      ],
      [
        'Mistral-7B-Q5',
        4.8,
        ['en'],
        'TheBloke/Mistral-7B-Instruct-v0.2-GGUF',
        'mistral-7b-instruct-v0.2.Q5_K_M.gguf'
      ],
      [
        'Llama-3-8B-Q4',
        4.9,
        ['en'],
        'bartowski/Meta-Llama-3-8B-Instruct-GGUF',
        'Meta-Llama-3-8B-Instruct-Q4_K_M.gguf'
      ],
      [
        'Gemma-7B-Q4',
        4.4,
        ['en'],
        'lmstudio-community/gemma-7b-it-GGUF',
        'gemma-7b-it-Q4_K_M.gguf'
      ],
      [
        'Qwen-7B-Q4',
        4.4,
        ['en', 'zh'],
        'Qwen/Qwen1.5-7B-Chat-GGUF',
        'qwen1_5-7b-chat-q4_k_m.gguf'
      ],

      // ===== LARGE MODELS (8-16 GB) - Samo za moćne telefone =====
      [
        'Mixtral-8x7B-Q2',
        7.5,
        ['en', 'fr', 'de', 'es', 'it'],
        'TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF',
        'mixtral-8x7b-instruct-v0.1.Q2_K.gguf'
      ],
      [
        'Llama-2-13B-Q2',
        5.1,
        ['en'],
        'TheBloke/Llama-2-13B-chat-GGUF',
        'llama-2-13b-chat.Q2_K.gguf'
      ],
      [
        'Vicuna-13B-Q2',
        5.2,
        ['en'],
        'TheBloke/vicuna-13B-v1.5-GGUF',
        'vicuna-13b-v1.5.Q2_K.gguf'
      ],
      [
        'Llama-2-13B-Q4',
        7.4,
        ['en'],
        'TheBloke/Llama-2-13B-chat-GGUF',
        'llama-2-13b-chat.Q4_K_M.gguf'
      ],
      [
        'CodeLlama-13B-Q4',
        7.3,
        ['en'],
        'TheBloke/CodeLlama-13B-Instruct-GGUF',
        'codellama-13b-instruct.Q4_K_M.gguf'
      ],
      [
        'Qwen-14B-Q4',
        8.5,
        ['en', 'zh'],
        'Qwen/Qwen1.5-14B-Chat-GGUF',
        'qwen1_5-14b-chat-q4_k_m.gguf'
      ],

      // ===== VERY LARGE MODELS (16+ GB) - Samo za high-end telefone =====
      [
        'Mixtral-8x7B-Q4',
        26.0,
        ['en', 'fr', 'de', 'es', 'it'],
        'TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF',
        'mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf'
      ],
      [
        'Llama-2-70B-Q2',
        19.0,
        ['en'],
        'TheBloke/Llama-2-70B-Chat-GGUF',
        'llama-2-70b-chat.Q2_K.gguf'
      ],
    ];

    for (var e in base) {
      models.add(LocalModelMeta(
        name: e[0] as String,
        sizeGb: e[1] as double,
        languages: List<String>.from(e[2] as List),
        hfRepo: e[3] as String,
        hfFile: e[4] as String,
      ));
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKey);
    if (s != null) {
      try {
        final data = jsonDecode(s) as List;
        if (data.isNotEmpty) {
          models.clear();
          models.addAll(data.map((e) => LocalModelMeta.fromJson(e)).toList());
        } else {
          // saved list empty -> keep default list from _initDefaultModels()
          if (kDebugMode)
            print('Saved models list is empty, keeping defaults.');
        }
      } catch (e) {
        if (kDebugMode) print('Failed to parse saved models: $e');
        // keep defaults
      }
    }
    // active model logic unchanged but guard for empty models:
    final active = prefs.getString('active_model_v2');
    if (models.isNotEmpty) {
      if (active != null) {
        activeModel = models.firstWhere((m) => m.name == active,
            orElse: () => models.first);
      } else {
        activeModel = models.firstWhere((m) => m.isDownloaded,
            orElse: () => models.first);
      }
    } else {
      activeModel = null;
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(models.map((m) => m.toJson()).toList()));
    if (activeModel != null) {
      await prefs.setString('active_model_v2', activeModel!.name);
    }
  }

  void markDownloaded(String name, String localPath) {
    final idx = models.indexWhere((m) => m.name == name);
    if (idx >= 0) {
      models[idx].isDownloaded = true;
      models[idx].localPath = localPath;
      _saveState();
      notifyListeners();
    }
  }

  void setActiveModel(String name) {
    activeModel =
        models.firstWhere((m) => m.name == name, orElse: () => models.first);
    _saveState();
    notifyListeners();
  }
}

class RamDetector extends ChangeNotifier {
  static const platform = MethodChannel('local_ai_chatbot/ram');
  double totalRamGb = 4.0;
  bool loading = false;

  String get totalRamGbString => '${totalRamGb.toStringAsFixed(2)} GB';

  Future<void> init() async {
    loading = true;
    notifyListeners();
    try {
      final res = await platform.invokeMethod<dynamic>('getTotalRam');
      if (res != null) {
        if (res is int) {
          totalRamGb = res / (1024 * 1024 * 1024);
        } else if (res is double) {
          totalRamGb = res;
        } else if (res is String) {
          final v = double.tryParse(res);
          if (v != null) totalRamGb = v;
        }
      } else {
        final di = DeviceInfoPlugin();
        final info = await di.androidInfo;
        final map = info.data;
        if (map.containsKey('totalPhysicalMemory')) {
          final v = map['totalPhysicalMemory'];
          if (v is int) totalRamGb = v / (1024 * 1024 * 1024);
        } else {
          totalRamGb = 4.0;
        }
      }
    } catch (_) {
      totalRamGb = 4.0;
    }
    loading = false;
    notifyListeners();
  }

  String recommendationForModel(LocalModelMeta model) {
    final device = totalRamGb;
    if (device >= model.sizeGb + 1.5) return 'Recommended';
    if (device >= model.sizeGb) return 'Middle zone';
    return 'Not recommended';
  }
}

class DownloadService {
  final Dio _dio = Dio();
  final AuthManager auth;
  
  DownloadService({required this.auth}) {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => true,
      headers: {
        'User-Agent': 'FlutterApp/1.0',
      },
    );

    // Add interceptor for better error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('🌐 REQUEST: ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print('❌ ERROR: ${error.type} - ${error.message}');
          print('   Response: ${error.response?.statusCode}');
        }
        return handler.next(error);
      },
    ));
  }

  String hfResolveUrl(String repo, String file) {
    // Use HTTPS explicitly
    return 'https://huggingface.co/$repo/resolve/main/$file';
  }

  Future<void> downloadModel(
    LocalModelMeta model, {
    required void Function(double) onProgress,
    required void Function(String localPath) onCompleted,
    required void Function(String error) onError,
    CancelToken? cancelToken,
  }) async {
    try {
      final url = hfResolveUrl(model.hfRepo, model.hfFile);

      if (kDebugMode) {
        print('📥 Starting download: $url');
      }

      // Build headers
      final headers = <String, dynamic>{
        'User-Agent': 'FlutterApp/1.0',
        'Accept': '*/*',
      };
      
      if (auth.hasToken) {
        headers['Authorization'] = 'Bearer ${auth.token}';
        if (kDebugMode) print('🔑 Using auth token');
      }

      // HEAD preflight with better error handling
      try {
        if (kDebugMode) print('🔍 Checking file availability...');
        
        final headResp = await _dio.head(
          url,
          options: Options(
            headers: headers,
            validateStatus: (status) => true,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 15),
          ),
          cancelToken: cancelToken,
        );

        if (kDebugMode) {
          print('📋 HEAD Response: ${headResp.statusCode}');
          print('   Headers: ${headResp.headers}');
        }

        if (headResp.statusCode == 404) {
          onError('❌ 404 Not Found\n\nFile does not exist:\n${model.hfFile}\n\nCheck model name or file may be private.');
          return;
        }
        if (headResp.statusCode == 401) {
          onError('❌ 401 Unauthorized\n\nYou need a valid HuggingFace token.\n\n1. Get token from HuggingFace\n2. Paste in Settings\n3. Try again');
          return;
        }
        if (headResp.statusCode == 403) {
          onError('❌ 403 Forbidden\n\nYour token lacks permission or file is private.');
          return;
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ HEAD request failed (non-critical): $e');
        // Continue anyway - some servers don't support HEAD
      }

      final dir = await getApplicationDocumentsDirectory();

      // Fix filename handling
      String filename = model.hfFile;
      if (!filename.toLowerCase().endsWith('.gguf')) {
        filename = '${model.name}.gguf';
      }

      final dest = File('${dir.path}/$filename');

      if (kDebugMode) {
        print('💾 Download destination: ${dest.path}');
      }

      // Check for existing partial download
      int existing = 0;
      if (await dest.exists()) {
        existing = await dest.length();
        if (kDebugMode) print('📦 Found existing file: ${existing} bytes');
      }

      // Prepare request with resume support
      final requestHeaders = {
        ...headers,
        if (existing > 0) 'Range': 'bytes=$existing-',
      };

      final requestOptions = Options(
        responseType: ResponseType.stream,
        headers: requestHeaders,
        followRedirects: true,
        receiveTimeout: Duration.zero, // No timeout for streaming
        validateStatus: (status) => true,
      );

      if (kDebugMode) print('🚀 Starting download stream...');

      final response = await _dio.get<ResponseBody>(
        url,
        options: requestOptions,
        cancelToken: cancelToken,
      );

      // Handle HTTP errors
      final status = response.statusCode ?? 0;
      
      if (kDebugMode) {
        print('📡 Response status: $status');
        print('   Content-Type: ${response.headers.value('content-type')}');
        print('   Content-Length: ${response.headers.value('content-length')}');
      }

      if (status == 401) {
        onError('❌ 401 Unauthorized\n\nToken is missing or invalid.\n\nSolution:\n1. Go to Settings\n2. Add HuggingFace token\n3. Make sure token has "Read" permission');
        return;
      }
      if (status == 403) {
        onError('❌ 403 Forbidden\n\nYou don\'t have permission to download this file.\n\nCheck:\n• Token has "Read" permission\n• Model is not private\n• Token is valid');
        return;
      }
      if (status == 404) {
        onError('❌ 404 Not Found\n\nFile not found:\n$url\n\nPossible causes:\n• Wrong model name\n• File name changed\n• Model removed');
        return;
      }
      if (status != 200 && status != 206) {
        onError('❌ HTTP $status: ${response.statusMessage ?? "Unknown error"}\n\nURL: $url');
        return;
      }

      // Parse content length
      final totalHeader = response.headers.value('content-length') ?? '';
      int total = totalHeader.isNotEmpty ? int.tryParse(totalHeader) ?? 0 : 0;

      if (kDebugMode) {
        print('📊 Total size: ${total > 0 ? "${(total / (1024 * 1024)).toStringAsFixed(1)} MB" : "unknown"}');
        print('📊 Resume from: ${existing > 0 ? "${(existing / (1024 * 1024)).toStringAsFixed(1)} MB" : "0 MB"}');
      }

      // Open file for writing
      final raf = dest.openSync(mode: FileMode.append);
      int received = existing;
      int lastLogTime = DateTime.now().millisecondsSinceEpoch;

      try {
        // Stream download
        await for (final chunk in response.data!.stream) {
          // Check cancellation
          if (cancelToken != null && cancelToken.isCancelled) {
            raf.closeSync();
            onError('⏸️ Download cancelled by user');
            return;
          }

          // Write chunk
          raf.writeFromSync(chunk);
          received += chunk.length;

          // Calculate progress
          final effectiveTotal = (total > 0) ? (existing + total) : received;
          double prog = effectiveTotal > 0 ? received / effectiveTotal : 0.0;

          // Update progress callback
          try {
            onProgress(prog.clamp(0.0, 1.0));
          } catch (_) {}

          // Log progress periodically
          final now = DateTime.now().millisecondsSinceEpoch;
          if (kDebugMode && now - lastLogTime > 2000) {
            final mb = received / (1024 * 1024);
            print('📥 Downloaded: ${mb.toStringAsFixed(1)} MB (${(prog * 100).toStringAsFixed(1)}%)');
            lastLogTime = now;
          }
        }
      } finally {
        raf.closeSync();
      }

      // Verify download
      final finalSize = await dest.length();
      
      if (kDebugMode) {
        print('✅ Download complete!');
        print('   Path: ${dest.path}');
        print('   Size: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB');
      }

      // Check if file is complete
      if (total > 0 && finalSize < (existing + total) * 0.95) {
        onError('⚠️ Download incomplete\n\nExpected: ${((existing + total) / (1024 * 1024)).toStringAsFixed(1)} MB\nReceived: ${(finalSize / (1024 * 1024)).toStringAsFixed(1)} MB\n\nTry downloading again.');
        return;
      }

      onCompleted(dest.path);

    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ DioException: ${e.type}');
        print('   Message: ${e.message}');
        print('   Response: ${e.response?.statusCode}');
      }

      String errorMsg;

      if (CancelToken.isCancel(e)) {
        errorMsg = '⏸️ Download cancelled';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = '⏱️ Connection timeout\n\nYour internet is too slow or server is not responding.\n\nTry again later.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMsg = '⏱️ Send timeout\n\nFailed to send request.\n\nCheck your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = '⏱️ Receive timeout\n\nDownload is taking too long.\n\nTry again with better connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = '🌐 No Internet Connection\n\nCannot reach HuggingFace servers.\n\nCheck:\n• WiFi is connected\n• Mobile data is enabled\n• Not using VPN that blocks access\n• Firewall not blocking app';
      } else if (e.type == DioExceptionType.badResponse) {
        final status = e.response?.statusCode ?? 0;
        if (status == 401) {
          errorMsg = '❌ 401 Unauthorized\n\nAdd valid HuggingFace token in Settings';
        } else if (status == 403) {
          errorMsg = '❌ 403 Forbidden\n\nToken lacks permission';
        } else {
          errorMsg = '❌ HTTP $status: ${e.response?.statusMessage ?? "Unknown"}';
        }
      } else {
        errorMsg = '❌ Download failed\n\n${e.message ?? e.type.toString()}\n\nTry again or check internet connection.';
      }

      onError(errorMsg);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error: $e');
      }
      onError('❌ Unexpected error: ${e.toString()}');
    }
  }
}

class NativeInference {
  DynamicLibrary? _lib;
  Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int)? _runPtr;
  void Function(Pointer<Void>)? _freePtr;
  bool ready = false;
  String? errorMessage;

  NativeInference() {
    _tryLoad();
  }

  void _tryLoad() {
    try {
      if (kDebugMode) print('🔍 Attempting to load native library...');

      String libName;
      if (Platform.isAndroid) {
        libName = 'liblocalai.so';
      } else if (Platform.isLinux) {
        libName = 'liblocalai.so';
      } else if (Platform.isMacOS) {
        libName = 'liblocalai.dylib';
      } else if (Platform.isWindows) {
        libName = 'localai.dll';
      } else {
        errorMessage = 'Unsupported platform: ${Platform.operatingSystem}';
        if (kDebugMode) print('❌ $errorMessage');
        ready = false;
        return;
      }

      if (kDebugMode) print('📚 Loading library: $libName');
      _lib = DynamicLibrary.open(libName);
      if (kDebugMode) print('✅ Library loaded successfully');

      // Pokušaj da učitaš run_inference funkciju
      try {
        final runFunc = _lib!.lookupFunction<
            Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
            Pointer<Utf8> Function(
                Pointer<Utf8>, Pointer<Utf8>, int)>('run_inference');
        _runPtr = runFunc;
        if (kDebugMode) print('✅ run_inference function loaded');
      } catch (e) {
        errorMessage = 'Function run_inference not found in library: $e';
        if (kDebugMode) print('❌ $errorMessage');
        ready = false;
        return;
      }

      // Pokušaj da učitaš free funkciju (optional)
      try {
        final freeFunc = _lib!.lookupFunction<Void Function(Pointer<Void>),
            void Function(Pointer<Void>)>('free_c_str');
        _freePtr = freeFunc;
        if (kDebugMode) print('✅ free_c_str function loaded');
      } catch (_) {
        try {
          final freeFunc2 = _lib!.lookupFunction<Void Function(Pointer<Void>),
              void Function(Pointer<Void>)>('free_c_char_ptr');
          _freePtr = freeFunc2;
          if (kDebugMode) print('✅ free_c_char_ptr function loaded');
        } catch (_) {
          // Nije kritično - koristićemo malloc.free kao fallback
          _freePtr = null;
          if (kDebugMode)
            print('⚠️ No free function found - using malloc.free as fallback');
        }
      }

      ready = true;
      errorMessage = null;
      if (kDebugMode) print('🎉 Native inference ready!');
    } catch (e) {
      errorMessage = 'Failed to load native library: $e';
      if (kDebugMode) {
        print('❌ $errorMessage');
        print('Stack trace: ${StackTrace.current}');
      }
      ready = false;
      _lib = null;
      _runPtr = null;
      _freePtr = null;
    }
  }

  String infer(String modelPath, String prompt, {int maxTokens = 256}) {
    if (!ready || _runPtr == null) {
      final msg = errorMessage ?? 'Native library not loaded';
      if (kDebugMode) {
        print('❌ Cannot run inference: $msg');
        print('   Model: $modelPath');
        print('   Prompt: $prompt');
      }
      return '❌ ERROR: Native library not available.\n\n'
          'Reason: $msg\n\n'
          '⚠️ The C++ inference library (llama.cpp) is not compiled or linked.\n\n'
          'To fix this:\n'
          '1. Check that liblocalai.so is in android/app/src/main/jniLibs/\n'
          '2. Ensure CMakeLists.txt is configured correctly\n'
          '3. Rebuild the app with: flutter clean && flutter build apk\n\n'
          'Model path: $modelPath\n'
          'Prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...';
    }

    if (kDebugMode) {
      print('🤖 Running inference...');
      print('   Model: $modelPath');
      print(
          '   Prompt: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}${prompt.length > 100 ? "..." : ""}');
      print('   Max tokens: $maxTokens');
    }

    // Proveri da li model file postoji
    final file = File(modelPath);
    if (!file.existsSync()) {
      final err = '❌ Model file not found at: $modelPath';
      if (kDebugMode) print(err);
      return err;
    }

    final fileSize = file.lengthSync();
    if (kDebugMode) {
      print(
          '✅ Model file exists: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB');
    }

    try {
      final pModel = modelPath.toNativeUtf8();
      final pPrompt = prompt.toNativeUtf8();

      if (kDebugMode) print('🔄 Calling native inference...');
      final resPtr = _runPtr!(pModel, pPrompt, maxTokens);

      final res = resPtr.toDartString();
      if (kDebugMode) {
        print('✅ Inference complete!');
        print('   Response length: ${res.length} chars');
        print(
            '   Response preview: ${res.substring(0, res.length > 100 ? 100 : res.length)}${res.length > 100 ? "..." : ""}');
      }

      // Free memory
      try {
        if (_freePtr != null) {
          _freePtr!(resPtr.cast<Void>());
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ Free failed (non-critical): $e');
      }

      malloc.free(pModel);
      malloc.free(pPrompt);

      return res;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Inference failed: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return '❌ Inference error: $e\n\n'
          'This usually means:\n'
          '• Model file is corrupted\n'
          '• Not enough RAM\n'
          '• Library version mismatch\n\n'
          'Try downloading the model again.';
    }
  }

  // Helper metoda za proveru statusa
  Map<String, dynamic> getStatus() {
    return {
      'ready': ready,
      'error': errorMessage,
      'platform': Platform.operatingSystem,
      'hasLibrary': _lib != null,
      'hasRunFunction': _runPtr != null,
      'hasFreeFunction': _freePtr != null,
    };
  }
}

class ChatStorage {
  static const _key = 'local_chats_v2';
  Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(chats));
  }

  Future<List<Map<String, dynamic>>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    if (s == null) return [];
    try {
      final l = jsonDecode(s) as List;
      return l.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dm = prefs.getBool('darkMode_v2') ?? true;

  final authManager = AuthManager();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) {
        final mm = ModelManager();
        mm.initialize(); // fire-and-forget: učitava saved state (async)
        return mm;
      }),
      ChangeNotifierProvider(create: (_) => RamDetector()),
      ChangeNotifierProvider(create: (_) => authManager),
      ChangeNotifierProvider(create: (_) {
        final s = SettingsManager();
        s.loadSettings(); // učitaj saved settings odmah
        return s;
      }),
      Provider(create: (ctx) => DownloadService(auth: ctx.read<AuthManager>())),
      Provider(create: (_) => NativeInference()),
      Provider(create: (_) => ChatStorage()),
    ],
    child: MyApp(initialDark: dm),
  ));
}

class MyApp extends StatefulWidget {
  final bool initialDark;
  const MyApp({Key? key, required this.initialDark}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialDark ? ThemeMode.dark : ThemeMode.light;
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode_v2', isDark);

    // Ovo menja samo ThemeMode, bez rebuild-ovanja MaterialApp direktno
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local ChatBOT',
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: _themeMode,
      locale: const Locale('en'),
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
        onLocale: (code) {},
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// HomeScreen & SettingsDrawer updated to include HF auth UI
class HomeScreen extends StatefulWidget {
  final void Function(bool) onToggleTheme;
  final bool isDark;
  final void Function(String) onLocale;
  const HomeScreen(
      {Key? key,
      required this.onToggleTheme,
      required this.isDark,
      required this.onLocale})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _thinking = false;
  final ChatStorage _storage = ChatStorage();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await _storage.loadChats();
    if (chats.isNotEmpty) setState(() => _messages.addAll(chats));
  }

  Future<void> _saveChats() async => await _storage.saveChats(_messages);

  // Replaced _send function - runs inference in a background isolate using compute()
  Future<void> _send(String text,
      {int extraSeconds = 0, bool fast = false}) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'from': 'user',
        'text': text,
        'ts': DateTime.now().toIso8601String()
      });
      _thinking = true;
    });
    await _saveChats();

    final mm = Provider.of<ModelManager>(context, listen: false);
    if (mm.activeModel == null) {
      _showSnack('No active model. Select model in settings.');
      setState(() => _thinking = false);
      return;
    }

    final native = Provider.of<NativeInference>(context, listen: false);
    String reply;

    if (native.ready && mm.activeModel?.localPath != null) {
      // Run inference in background isolate to prevent UI freeze
      try {
        reply = await compute(_runInferenceInBackground, {
          'modelPath': mm.activeModel!.localPath!,
          'prompt': text,
          'maxTokens': fast ? 64 : 256,
          'extraSeconds': extraSeconds,
        });
      } catch (e) {
        // If compute() fails for any reason, fallback to calling native on the main isolate
        reply = 'Background inference failed: $e';
      }
    } else {
      if (extraSeconds > 0)
        await Future.delayed(Duration(seconds: extraSeconds));
      await Future.delayed(Duration(milliseconds: fast ? 150 : 700));
      reply =
          'Stub local reply for: ${text.length > 120 ? text.substring(0, 120) + "..." : text}';
    }

    setState(() {
      _messages.add({
        'from': 'bot',
        'text': reply,
        'ts': DateTime.now().toIso8601String()
      });
      _thinking = false;
    });
    await _saveChats();
    _ctrl.clear();
  }

  void _showSnack(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  void _showDiagnostics() {
    final native = Provider.of<NativeInference>(context, listen: false);
    final mm = Provider.of<ModelManager>(context, listen: false);
    final status = native.getStatus();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔧 Diagnostics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Platform: ${status['platform']}'),
              const SizedBox(height: 8),
              Text(
                  'Library loaded: ${status['hasLibrary'] ? "✅ YES" : "❌ NO"}'),
              Text(
                  'Run function: ${status['hasRunFunction'] ? "✅ YES" : "❌ NO"}'),
              Text(
                  'Free function: ${status['hasFreeFunction'] ? "✅ YES" : "⚠️ NO (using fallback)"}'),
              const SizedBox(height: 8),
              Text(
                'Status: ${status['ready'] ? "✅ READY" : "❌ NOT READY"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status['ready'] ? Colors.green : Colors.red,
                ),
              ),
              if (status['error'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: ${status['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const Divider(),
              Text('Active model: ${mm.activeModel?.name ?? "none"}'),
              if (mm.activeModel?.localPath != null) ...[
                const SizedBox(height: 4),
                Text('Path: ${mm.activeModel!.localPath}'),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final file = File(mm.activeModel!.localPath!);
                    final exists = file.existsSync();
                    if (exists) {
                      final size = file.lengthSync() / (1024 * 1024);
                      return Text('File: ✅ ${size.toStringAsFixed(1)} MB');
                    }
                    return const Text('File: ❌ NOT FOUND',
                        style: TextStyle(color: Colors.red));
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mm = Provider.of<ModelManager>(context);
    final ram = Provider.of<RamDetector>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Local AI ChatBOT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: SettingsDrawer(
          onToggleTheme: widget.onToggleTheme,
          isDark: widget.isDark,
          onLocale: widget.onLocale),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                    child: Text('Active: ${mm.activeModel?.name ?? "none"}')),
                Text('RAM: ${ram.totalRamGbString}'),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                    child: const Text('Models')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (c, i) {
                final m = _messages[i];
                final user = m['from'] == 'user';
                return Align(
                  alignment:
                      user ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: user
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m['text'],
                        style: TextStyle(
                            color: user
                                ? Colors.white
                                : Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color)),
                  ),
                );
              },
            ),
          ),
          if (_thinking)
            const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator()),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                ElevatedButton(
                    onPressed: () => _send(_ctrl.text, extraSeconds: 60),
                    child: const Text('Think more (1 min)')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () => _send(_ctrl.text, extraSeconds: 180),
                    child: const Text('Think more (3 min)')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () => _send(_ctrl.text, extraSeconds: 300),
                    child: const Text('Think more (5 min)')),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: () => _send(_ctrl.text, fast: true),
                    child: const Text('Fast reply')),
              ],
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _ctrl,
                        decoration:
                            const InputDecoration(hintText: 'Type message'))),
                IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(_ctrl.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Top-level function for compute() - runs in background isolate
String _runInferenceInBackground(Map<String, dynamic> params) {
  final modelPath = params['modelPath'] as String;
  final prompt = params['prompt'] as String;
  final maxTokens = params['maxTokens'] as int;
  final extraSeconds = params['extraSeconds'] as int;

  if (extraSeconds > 0) {
    sleep(Duration(seconds: extraSeconds));
  }

  // Load library in this isolate
  final native = NativeInference();
  if (!native.ready) {
    return 'ERROR: Native library not available in background isolate';
  }

  return native.infer(modelPath, prompt, maxTokens: maxTokens);
}

class DarkModeSwitch extends StatefulWidget {
  final SettingsManager settings;
  final void Function(bool) onToggleTheme;

  const DarkModeSwitch(
      {Key? key, required this.settings, required this.onToggleTheme})
      : super(key: key);

  @override
  State<DarkModeSwitch> createState() => _DarkModeSwitchState();
}

class _DarkModeSwitchState extends State<DarkModeSwitch> {
  late bool _localDarkMode;

  @override
  void initState() {
    super.initState();
    _localDarkMode = widget.settings.isDarkMode;
  }

  void _onChanged(bool v) {
    // 1️⃣ Update local UI immediately
    setState(() => _localDarkMode = v);

    // 2️⃣ Schedule settings update safely after frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.settings.setDarkMode(v); // setDarkMode sa notifyListeners
    });

    // 3️⃣ Optional callback
    widget.onToggleTheme(v);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Dark mode'),
      value: _localDarkMode,
      onChanged: _onChanged,
    );
  }
}

// ---------- SettingsManager ----------
class SettingsManager extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'en';
  String _token = '';

  // NEW keys (we prefer to write here)
  static const String _keyDarkModeNew = 'darkMode_v2';
  static const String _keyLanguageNew = 'language_v2';
  static const String _keyTokenNew = 'token_v2';

  // LEGACY keys (for migration / compatibility)
  static const String _keyDarkModeLegacy = 'darkMode';
  static const String _keyLanguageLegacy = 'language';
  static const String _keyTokenLegacy = 'token';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get token => _token;
  bool get hasToken => _token.isNotEmpty;

  void updateDarkMode(bool v) {
    _isDarkMode = v;
    notifyListeners();
  }

  Future<void> _persistDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkModeNew, v);
  }

  // Load settings with backward compatibility
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Dark mode
    if (prefs.containsKey(_keyDarkModeNew)) {
      _isDarkMode = prefs.getBool(_keyDarkModeNew) ?? false;
    } else {
      _isDarkMode = prefs.getBool(_keyDarkModeLegacy) ?? false;
    }

    // Language
    if (prefs.containsKey(_keyLanguageNew)) {
      _language = prefs.getString(_keyLanguageNew) ?? 'en';
    } else {
      _language = prefs.getString(_keyLanguageLegacy) ?? 'en';
    }

    // Token (optional - app also uses AuthManager)
    if (prefs.containsKey(_keyTokenNew)) {
      _token = prefs.getString(_keyTokenNew) ?? '';
    } else {
      _token = prefs.getString(_keyTokenLegacy) ?? '';
    }

    notifyListeners();
  }

  Future<void> setDarkMode(bool value, {bool saveToPrefs = true}) async {
    _isDarkMode = value;
    notifyListeners();
    if (saveToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkModeNew, value);
    }
  }

  Future<void> setLanguage(String lang, {bool saveToPrefs = true}) async {
    _language = lang;
    notifyListeners();
    if (saveToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguageNew, lang);
    }
  }

  /// Note: AuthManager is canonical for HF token. This setter only keeps a local copy/backups.
  Future<void> setToken(String value,
      {bool saveToPrefs = true, bool backupJson = false}) async {
    _token = value;
    notifyListeners();
    if (saveToPrefs) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTokenNew, value);
    }
    if (backupJson) await _backupToJsonFile();
  }

  Future<void> clearToken() async {
    _token = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTokenNew);
  }

  Future<void> resetAll() async {
    _isDarkMode = false;
    _language = 'en';
    _token = '';
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDarkModeNew);
    await prefs.remove(_keyLanguageNew);
    await prefs.remove(_keyTokenNew);
    // also clean legacy keys just in case
    await prefs.remove(_keyDarkModeLegacy);
    await prefs.remove(_keyLanguageLegacy);
    await prefs.remove(_keyTokenLegacy);
  }

  // Backup to JSON in app documents dir (user can restore)
  Future<void> _backupToJsonFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings_backup.json');
      final data = {
        'darkMode': _isDarkMode,
        'language': _language,
        'token': _token
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) print('Failed to backup settings to JSON: $e');
    }
  }

  Future<void> restoreFromJsonBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/settings_backup.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        _isDarkMode = data['darkMode'] ?? _isDarkMode;
        _language = data['language'] ?? _language;
        _token = data['token'] ?? _token;

        // persist migrated values to new keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyDarkModeNew, _isDarkMode);
        await prefs.setString(_keyLanguageNew, _language);
        await prefs.setString(_keyTokenNew, _token);

        notifyListeners();
      } else {
        if (kDebugMode) print('No settings_backup.json found');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to restore settings from JSON: $e');
    }
  }

  @override
  String toString() =>
      'SettingsManager(isDarkMode: $_isDarkMode, language: $_language, token:${_token.isNotEmpty})';
}

// ---------- SettingsDrawer ----------
class SettingsDrawer extends StatefulWidget {
  final void Function(bool) onToggleTheme;
  final bool isDark;
  final void Function(String) onLocale;

  const SettingsDrawer({
    Key? key,
    required this.onToggleTheme,
    required this.isDark,
    required this.onLocale,
  }) : super(key: key);

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  late bool _localDarkMode;
  String _lang = 'en';

  late final TextEditingController _tokenCtrl;
  late final FocusNode _tokenFocusNode;

  final Map<String, double> _progress = {};
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  void initState() {
    super.initState();

    // read current settings once and use local copy to avoid notifyListeners during build
    final settings = context.read<SettingsManager>();
    _localDarkMode = settings.isDarkMode;

    // init controllers
    _tokenCtrl = TextEditingController();
    _tokenFocusNode = FocusNode();

    // load auth token after widget mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final auth = context.read<AuthManager>();
        if (mounted && auth.token.isNotEmpty) {
          _tokenCtrl.text = auth.token;
          _tokenCtrl.selection = TextSelection.collapsed(offset: _tokenCtrl.text.length);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    for (final t in _cancelTokens.values) {
      try {
        if (!t.isCancelled) t.cancel('widget disposed');
      } catch (_) {}
    }
    _cancelTokens.clear();

    _tokenCtrl.dispose();
    _tokenFocusNode.dispose();
    super.dispose();
  }

  void _safeSetProgress(String name, double? value) {
    if (!mounted) return;
    setState(() {
      if (value == null) _progress.remove(name);
      else _progress[name] = value;
    });
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _tokenCtrl.text = text;
          _tokenCtrl.selection = TextSelection.collapsed(offset: _tokenCtrl.text.length);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token pasted (${text.length} chars)')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Paste failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    final auth = context.watch<AuthManager>();
    final mm = context.watch<ModelManager>();
    final ram = context.watch<RamDetector>();
    final ds = context.read<DownloadService>();

    // keep token field in sync when not focused
    final authToken = auth.token;
    if (!_tokenFocusNode.hasFocus && authToken != _tokenCtrl.text) {
      _tokenCtrl.text = authToken;
      _tokenCtrl.selection = TextSelection.collapsed(offset: _tokenCtrl.text.length);
    }

    final lang = settings.language;

    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // compact card section for toggles
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      // LOCAL switch to avoid notify during build
                      SwitchListTile(
                        title: const Text('Dark mode'),
                        value: _localDarkMode,
                        onChanged: (v) {
                          // update local immediately
                          setState(() => _localDarkMode = v);

                          // persist and update global state AFTER this frame to avoid notify-in-build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            // canonical place to set global settings (saves + notifies)
                            context.read<SettingsManager>().setDarkMode(v);
                          });

                          // optional callback to parent (if parent toggles App theme)
                          widget.onToggleTheme(v);
                        },
                      ),

                      ListTile(
                        title: const Text('App language'),
                        subtitle: Text(lang),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (!mounted) return;
                            setState(() => _lang = v);
                            await settings.setLanguage(v);
                            widget.onLocale(v);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'en', child: Text('English')),
                            PopupMenuItem(value: 'sr', child: Text('Srpski latinica')),
                            PopupMenuItem(value: 'sr-Cyrl', child: Text('Српски ћирилица')),
                            PopupMenuItem(value: 'de', child: Text('Deutsch')),
                            PopupMenuItem(value: 'es', child: Text('Español')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(),
              const Text('Hugging Face Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: auth.hasToken ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auth.hasToken ? '✓ Token saved' : '⚠ No token - downloads may fail',
                  style: TextStyle(color: auth.hasToken ? Colors.green : Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('How to get a token:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                      '1. Click button below\n2. Login to HuggingFace\n3. Click "New token"\n4. Name: "MyApp"\n5. Type: "Read" ✓ IMPORTANT\n6. Click "Generate"\n7. Copy and paste here',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Get token from HuggingFace'),
                onPressed: () async {
                  const url = 'https://huggingface.co/settings/tokens';
                  final u = Uri.parse(url);
                  if (await canLaunchUrl(u)) {
                    await launchUrl(u, mode: LaunchMode.externalApplication);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open browser')));
                  }
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _tokenCtrl,
                focusNode: _tokenFocusNode,
                decoration: InputDecoration(
                  labelText: 'HuggingFace Token',
                  hintText: 'hf_...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: 'Paste from clipboard',
                    icon: const Icon(Icons.paste),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                maxLines: 1,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save & Validate'),
                    onPressed: () async {
                      final t = _tokenCtrl.text.trim();
                      if (t.isEmpty) {
                        if (mounted) {
                          showDialog(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('⚠️ No Token'),
                            content: const Text('Please paste your HuggingFace token first.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                          ));
                        }
                        return;
                      }
                      if (!t.startsWith('hf_')) {
                        if (mounted) {
                          showDialog(context: context, builder: (ctx) => AlertDialog(
                            title: const Text('❌ Invalid Format'),
                            content: const Text('HuggingFace tokens must start with "hf_"'),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                          ));
                        }
                        return;
                      }

                      if (mounted) {
                        showDialog(context: context, barrierDismissible: false, builder: (ctx) => const AlertDialog(
                          content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text('Validating token...')]),
                        ));
                      }

                      await auth.setToken(t, saveJsonBackup: true);
                      final res = await auth.validateToken();

                      if (!mounted) return;
                      Navigator.of(context).pop();

                      showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: Text(res['ok'] == 'true' ? '✅ Success!' : '❌ Validation Failed'),
                        content: SingleChildScrollView(child: Text(res['ok'] == 'true' ? 'Token is valid!\n\nUsername: ${res['msg']}' : res['msg'] ?? 'Unknown error')),
                        actions: [
                          if (res['ok'] == 'false') TextButton(onPressed: () { Navigator.pop(ctx); launchUrl(Uri.parse('https://huggingface.co/settings/tokens'), mode: LaunchMode.externalApplication); }, child: const Text('Get New Token')),
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                        ],
                      ));
                    },
                  ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear'),
                    onPressed: () async {
                      await auth.clearToken();
                      if (mounted) {
                        setState(() => _tokenCtrl.text = '');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token cleared')));
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const Text('Models', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(8)),
                child: mm.models.isEmpty ? const Center(child: Text('No models available')) :
                ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: mm.models.length,
                  itemBuilder: (ctx, idx) {
                    final model = mm.models[idx];
                    final prog = _progress[model.name] ?? 0.0;
                    final downloading = _progress.containsKey(model.name);

                    return ListTile(
                      title: Text(model.name),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${model.sizeGb.toStringAsFixed(1)} GB • ${model.languages.join(', ')}'),
                        Text('RAM: ${ram.recommendationForModel(model)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        if (downloading) Padding(padding: const EdgeInsets.only(top: 6.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          LinearProgressIndicator(value: prog > 0 && prog <= 1 ? prog : null, minHeight: 6),
                          const SizedBox(height: 2),
                          Text('${(prog * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 10)),
                        ])),
                      ]),
                      trailing: SizedBox(
                        width: 140, // cap trailing width to avoid consuming tile
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (model.isDownloaded)
                            Expanded(child: ElevatedButton(onPressed: () { mm.setActiveModel(model.name); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Active model: ${model.name}'))); }, child: const Text('Use')))
                          else if (downloading)
                            IconButton(icon: const Icon(Icons.cancel), onPressed: () {
                              final ct = _cancelTokens[model.name];
                              if (ct != null && !ct.isCancelled) ct.cancel('User canceled');
                              _safeSetProgress(model.name, null);
                              _cancelTokens.remove(model.name);
                            })
                          else
                            Expanded(child: ElevatedButton(onPressed: () async {
                              if (_progress.containsKey(model.name)) return;
                              if (!auth.hasToken && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠ No HuggingFace token - download may fail for private models'), duration: Duration(seconds: 3)));
                              final ct = CancelToken();
                              _cancelTokens[model.name] = ct;
                              _safeSetProgress(model.name, 0.001);
                              try {
                                await ds.downloadModel(model, cancelToken: ct, onProgress: (p) { if (!mounted) return; _safeSetProgress(model.name, p); }, onCompleted: (localPath) {
                                  if (!mounted) return;
                                  mm.markDownloaded(model.name, localPath);
                                  _safeSetProgress(model.name, null);
                                  _cancelTokens.remove(model.name);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✓ Downloaded ${model.name}')));
                                }, onError: (err) {
                                  if (!mounted) return;
                                  _safeSetProgress(model.name, null);
                                  _cancelTokens.remove(model.name);
                                  String errorMsg = err;
                                  if (err.contains('404')) errorMsg = '404 Not Found - File may not exist or is private. Check token.';
                                  if (err.contains('401')) errorMsg = '401 Unauthorized - Add valid HuggingFace token above.';
                                  if (err.contains('403')) errorMsg = '403 Forbidden - Token lacks permissions.';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✗ $errorMsg'), duration: const Duration(seconds: 5), backgroundColor: Colors.red));
                                });
                              } catch (e) {
                                if (!mounted) return;
                                _safeSetProgress(model.name, null);
                                _cancelTokens.remove(model.name);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✗ Download failed: $e'), backgroundColor: Colors.red));
                              }
                            }, child: const Text('Download'))),
                        ]),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(icon: const Icon(Icons.restore), label: const Text('Restore settings from backup'), onPressed: () async {
                await settings.restoreFromJsonBackup();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings restored (if backup existed)')));
              }),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}