import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:path/path.dart' as path;

/// Service for Text-to-Speech using Piper models via Sherpa-ONNX
///
/// This is a wrapper that works with Sherpa's OfflineTts API
class TTSService {
  sherpa.OfflineTts? _tts;
  String? _currentLanguage;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get currentLanguage => _currentLanguage;

  /// Initialize TTS for a specific language
  ///
  /// [packPath] - Path to the language pack (e.g., /path/to/en-es)
  /// [language] - Language code (e.g., 'en' or 'es')
  Future<bool> initialize(String packPath, String language) async {
    try {
      debugPrint('[TTS] Initializing for language: $language');

      // Clean up existing instance
      await dispose();

      // Construct paths to TTS model files
      final ttsDir = path.join(packPath, 'tts');
      final modelPath = path.join(ttsDir, '$language.onnx');
      final configPath = path.join(ttsDir, '$language.onnx.json');

      // Verify files exist
      final modelFile = File(modelPath);
      final configFile = File(configPath);

      if (!await modelFile.exists()) {
        debugPrint('[TTS] Error: Model file not found: $modelPath');
        return false;
      }

      if (!await configFile.exists()) {
        debugPrint('[TTS] Error: Config file not found: $configPath');
        return false;
      }

      debugPrint('[TTS] Model path: $modelPath');
      debugPrint('[TTS] Config path: $configPath');

      // Create TTS configuration for Piper models
      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: modelPath,
            lexicon: '', // Piper models don't need separate lexicon
            tokens: '',  // Tokens are embedded in the model
            dataDir: '', // Not needed for Piper
          ),
          numThreads: 2,
          debug: kDebugMode,
          provider: 'cpu',
        ),
        ruleFsts: '',     // Not needed for Piper
      );

      // Initialize the TTS engine
      _tts = sherpa.OfflineTts(config);

      _currentLanguage = language;
      _isInitialized = true;

      debugPrint('[TTS] ✅ Successfully initialized for $language');
      return true;

    } catch (e, stackTrace) {
      debugPrint('[TTS] Error during initialization: $e');
      debugPrint('[TTS] Stack trace: $stackTrace');
      _isInitialized = false;
      return false;
    }
  }

  /// Synthesize speech from text
  ///
  /// Returns GeneratedAudio with samples and sample rate
  sherpa.GeneratedAudio? synthesize(String text, {double speed = 1.0}) {
    if (!_isInitialized || _tts == null) {
      debugPrint('[TTS] Error: Not initialized');
      return null;
    }

    if (text.trim().isEmpty) {
      debugPrint('[TTS] Error: Empty text provided');
      return null;
    }

    try {
      debugPrint('[TTS] Synthesizing: "$text"');

      final startTime = DateTime.now();

      // Generate audio using Sherpa-ONNX
      final audio = _tts!.generate(
        text: text,
        sid: 0,      // Speaker ID (0 for single-speaker models)
        speed: speed, // Speech speed
      );

      final duration = DateTime.now().difference(startTime);

      if (audio.samples.isEmpty) {
        debugPrint('[TTS] Error: Generated audio is empty');
        return null;
      }

      debugPrint('[TTS] ✅ Generated ${audio.samples.length} samples '
          'in ${duration.inMilliseconds}ms');
      debugPrint('[TTS] Sample rate: ${audio.sampleRate} Hz');

      return audio;

    } catch (e, stackTrace) {
      debugPrint('[TTS] Error during synthesis: $e');
      debugPrint('[TTS] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get sample rate of the current TTS model
  int getSampleRate() {
    if (!_isInitialized || _tts == null) {
      return 22050; // Default Piper sample rate
    }
    return _tts!.sampleRate;
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_tts != null) {
      debugPrint('[TTS] Disposing TTS instance');
      // Note: Sherpa-ONNX doesn't require explicit cleanup in Dart
      _tts = null;
    }
    _isInitialized = false;
    _currentLanguage = null;
  }
}