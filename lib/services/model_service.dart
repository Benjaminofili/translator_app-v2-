import 'dart:async';
import 'package:sherpa_onnx/src/online_stream.dart';
import 'package:prototype_ai_core/services/tts_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/storage_utils.dart';
import '../core/utils/logger_utils.dart';
import 'sherpa_service.dart';

/// 🤖 Model Service
///
/// Manages AI models (STT, Translation, TTS) via Sherpa-ONNX
/// Translation models exist but are not loaded/used in MVP
class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  final SherpaService _sherpa = SherpaService();

  // Loaded models tracking
  final Map<String, LoadedModel> _loadedModels = {};
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Initialize the model service
  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.info('MODEL', 'Already initialized');
      return true;
    }

    try {
      Logger.section('MODEL SERVICE INITIALIZATION');

      // Initialize Sherpa-ONNX
      final sherpaInitialized = await _sherpa.initialize();
      if (!sherpaInitialized) {
        Logger.error('MODEL', 'Sherpa-ONNX initialization failed');
        return false;
      }

      _isInitialized = true;
      Logger.success('MODEL', 'Service initialized');
      return true;

    } catch (e, stackTrace) {
      Logger.error('MODEL', 'Initialization failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MODEL LOADING
  // ═══════════════════════════════════════════════════════════════

  /// Load models for a language pack
  Future<LoadResult> loadPack(String packId) async {
    final monitor = PerformanceMonitor('Load pack $packId');

    try {
      // Verify pack is installed
      final isInstalled = await StorageUtils.isPackInstalled(packId);
      if (!isInstalled) {
        return LoadResult.error('Pack not installed: $packId');
      }

      // Check if already loaded
      if (_loadedModels.containsKey(packId)) {
        Logger.info('MODEL', 'Pack already loaded: $packId');
        return LoadResult.success(packId);
      }

      Logger.info('MODEL', 'Loading pack: $packId');

      final packPath = await StorageUtils.getPackPath(packId);
      final packInfo = AppConstants.availablePacks[packId];

      if (packInfo == null) {
        return LoadResult.error('Pack info not found: $packId');
      }

      // Load via Sherpa-ONNX (STT + TTS only, skip translation)
      final loadSuccess = await _sherpa.loadPack(packId);
      if (!loadSuccess) {
        return LoadResult.error('Failed to load pack via Sherpa-ONNX');
      }

      // Create loaded model entry
      _loadedModels[packId] = LoadedModel(
        packId: packId,
        packPath: packPath,
        sourceLanguage: packInfo.sourceLanguage,
        targetLanguage: packInfo.targetLanguage,
        loadedAt: DateTime.now(),
      );

      monitor.complete();
      Logger.success('MODEL', 'Pack loaded: $packId (STT + TTS ready)');
      return LoadResult.success(packId);

    } catch (e, stackTrace) {
      Logger.error('MODEL', 'Load failed: $packId', e, stackTrace);
      return LoadResult.error('Load error: $e');
    }
  }

  /// Unload a language pack from memory
  Future<bool> unloadPack(String packId) async {
    try {
      if (!_loadedModels.containsKey(packId)) {
        Logger.warning('MODEL', 'Pack not loaded: $packId');
        return false;
      }

      await _sherpa.unloadPack(packId);
      _loadedModels.remove(packId);

      Logger.success('MODEL', 'Pack unloaded: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('MODEL', 'Unload failed: $packId', e, stackTrace);
      return false;
    }
  }

  /// Unload all models
  Future<void> unloadAll() async {
    Logger.info('MODEL', 'Unloading all models');

    for (final packId in _loadedModels.keys.toList()) {
      await unloadPack(packId);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SPEECH-TO-TEXT (STT) - PRIMARY FOCUS
  // ═══════════════════════════════════════════════════════════════

  /// Create a recognition stream for a language
  OnlineStream? createRecognitionStream(String language) {
    final stream = _sherpa.createStream(language);
    if (stream == null) {
      Logger.error('STT', 'Failed to create stream for: $language');
    }
    return stream;
  }

  /// Feed audio samples to recognition stream
  void feedAudioSamples({
    required String language,
    required dynamic stream, // sherpa.OnlineStream
    required List<double> samples,
    int sampleRate = 16000,
  }) {
    _sherpa.acceptWaveform(language, stream, samples, sampleRate);
  }

  /// Get recognition result from stream
  String getRecognitionResult({
    required String language,
    required dynamic stream, // sherpa.OnlineStream
  }) {
    return _sherpa.getResult(language, stream);
  }

  // ═══════════════════════════════════════════════════════════════
  // TRANSLATION (NOT IMPLEMENTED - PLACEHOLDER)
  // ═══════════════════════════════════════════════════════════════

  /// Translate text - MVP returns placeholder
  Future<TranslationResult> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    Logger.info('TRANSLATION', 'Translation skipped in MVP');

    // Return placeholder
    return TranslationResult.success(
      original: text,
      translated: '[$targetLanguage] $text',
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TEXT-TO-SPEECH (TTS)
  // ═══════════════════════════════════════════════════════════════

  /// Synthesize speech from text
  Future<TTSResult> synthesizeSpeech({
    required String text,
    required String language,
    double speed = 1.0,
  }) async {
    final monitor = PerformanceMonitor('TTS $language');

    try {
      Logger.audio('Synthesizing: "$text" ($language)');

      // Find pack for language
      final packId = _findPackForLanguage(language);
      if (packId == null) {
        return TTSResult.error('No pack for language: $language');
      }

      // Ensure pack is loaded
      if (!_loadedModels.containsKey(packId)) {
        final loadResult = await loadPack(packId);
        if (!loadResult.success) {
          return TTSResult.error('Failed to load pack');
        }
      }

      // Synthesize via Sherpa-ONNX
      final audioPath = await _sherpa.synthesizeSpeech(
        text: text,
        language: language,
        speed: speed,
      );

      monitor.complete();

      if (audioPath != null) {
        Logger.success('TTS', 'Audio saved: $audioPath');
        return TTSResult.success(audioPath: audioPath);
      } else {
        return TTSResult.error('TTS generation failed');
      }

    } catch (e, stackTrace) {
      Logger.error('TTS', 'Synthesis failed', e, stackTrace);
      return TTSResult.error('TTS error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Find pack for a single language
  String? _findPackForLanguage(String language) {
    for (final entry in AppConstants.availablePacks.entries) {
      final info = entry.value;
      if (info.sourceLanguage == language || info.targetLanguage == language) {
        return entry.key;
      }
    }
    return null;
  }

  /// Check if a pack is loaded
  bool isPackLoaded(String packId) {
    return _loadedModels.containsKey(packId);
  }

  /// Get list of loaded packs
  List<String> getLoadedPacks() {
    return _loadedModels.keys.toList();
  }

  /// Get loaded model info
  LoadedModel? getLoadedModel(String packId) {
    return _loadedModels[packId];
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

class LoadedModel {
  final String packId;
  final String packPath;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime loadedAt;

  LoadedModel({
    required this.packId,
    required this.packPath,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.loadedAt,
  });

  Duration get timeSinceLoaded => DateTime.now().difference(loadedAt);
}

class LoadResult {
  final bool success;
  final String? packId;
  final String? error;

  LoadResult._({
    required this.success,
    this.packId,
    this.error,
  });

  factory LoadResult.success(String packId) {
    return LoadResult._(success: true, packId: packId);
  }

  factory LoadResult.error(String error) {
    return LoadResult._(success: false, error: error);
  }
}

class TranslationResult {
  final bool success;
  final String? original;
  final String? translated;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? error;

  TranslationResult._({
    required this.success,
    this.original,
    this.translated,
    this.sourceLanguage,
    this.targetLanguage,
    this.error,
  });

  factory TranslationResult.success({
    required String original,
    required String translated,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    return TranslationResult._(
      success: true,
      original: original,
      translated: translated,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
    );
  }

  factory TranslationResult.error(String error) {
    return TranslationResult._(success: false, error: error);
  }
}

class TTSResult {
  final bool success;
  final String? audioPath;
  final String? error;

  TTSResult._({
    required this.success,
    this.audioPath,
    this.error,
  });

  factory TTSResult.success({required String audioPath}) {
    return TTSResult._(success: true, audioPath: audioPath);
  }

  factory TTSResult.error(String error) {
    return TTSResult._(success: false, error: error);
  }
}