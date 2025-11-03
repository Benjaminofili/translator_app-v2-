import 'dart:io';
import 'dart:typed_data'; // Added for Float32List
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:path/path.dart' as path;
import '../core/utils/logger_utils.dart';
import '../core/utils/storage_utils.dart';
import '../core/constants/app_constants.dart';

/// 🎯 Sherpa-ONNX Service
///
/// Manages STT (Sherpa-ONNX) and TTS (Piper) models
/// Translation is handled separately via CTranslate2 native code
class SherpaService {
  static final SherpaService _instance = SherpaService._internal();
  factory SherpaService() => _instance;
  SherpaService._internal();

  // Model instances (per language)
  final Map<String, sherpa.OnlineRecognizer> _sttRecognizers = {};
  final Map<String, sherpa.OfflineTts> _ttsEngines = {};

  // Loaded packs
  final Map<String, _LoadedPack> _loadedPacks = {};
  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<bool> initialize() async {
    if (_isInitialized) {
      Logger.info('SHERPA', 'Already initialized');
      return true;
    }

    try {
      Logger.section('SHERPA-ONNX INITIALIZATION');

      // CRITICAL: Initialize sherpa-onnx library before any usage
      sherpa.initBindings();
      Logger.info('SHERPA', 'Sherpa-ONNX library initialized');

      _isInitialized = true;
      Logger.success('SHERPA', 'Service initialized');
      return true;

    } catch (e, stackTrace) {
      Logger.error('SHERPA', 'Initialization failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MODEL LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<bool> loadPack(String packId) async {
    try {
      if (_loadedPacks.containsKey(packId)) {
        Logger.info('SHERPA', 'Pack already loaded: $packId');
        return true;
      }

      Logger.info('SHERPA', 'Loading pack: $packId');

      final packPath = await StorageUtils.getPackPath(packId);
      final packInfo = AppConstants.availablePacks[packId];

      if (packInfo == null) {
        Logger.error('SHERPA', 'Pack info not found: $packId');
        return false;
      }

      // Load STT for source language
      final sttSuccess = await _loadSTTModel(
        packPath,
        packInfo.sourceLanguage,
      );

      if (!sttSuccess) {
        Logger.error('SHERPA', 'Failed to load STT model');
        return false;
      }

      // Load TTS for both languages
      final ttsSourceSuccess = await _loadTTSModel(
        packPath,
        packInfo.sourceLanguage,
      );

      final ttsTargetSuccess = await _loadTTSModel(
        packPath,
        packInfo.targetLanguage,
      );

      if (!ttsSourceSuccess || !ttsTargetSuccess) {
        Logger.error('SHERPA', 'Failed to load TTS models');
        return false;
      }

      _loadedPacks[packId] = _LoadedPack(
        packId: packId,
        sourceLanguage: packInfo.sourceLanguage,
        targetLanguage: packInfo.targetLanguage,
        loadedAt: DateTime.now(),
      );

      Logger.success('SHERPA', 'Pack loaded: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('SHERPA', 'Load pack failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STT MODEL LOADING (Sherpa-ONNX)
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _loadSTTModel(String packPath, String language) async {
    try {
      // Check if already loaded
      if (_sttRecognizers.containsKey(language)) {
        Logger.info('SHERPA', 'STT already loaded for: $language');
        return true;
      }

      Logger.info('SHERPA', 'Loading STT model for: $language');

      final sttPath = path.join(packPath, 'stt');

      // Check for model files
      final encoderPath = path.join(sttPath, 'encoder.onnx');
      final decoderPath = path.join(sttPath, 'decoder.onnx');
      final joinerPath = path.join(sttPath, 'joiner.onnx');
      final tokensPath = path.join(sttPath, 'tokens.txt');

      if (!await File(encoderPath).exists() ||
          !await File(decoderPath).exists() ||
          !await File(joinerPath).exists() ||
          !await File(tokensPath).exists()) {
        Logger.error('SHERPA', 'STT model files not found');
        return false;
      }

      // Configure online recognizer - FIXED: Uses 'model' and optionally 'feat'
      final config = sherpa.OnlineRecognizerConfig(
        model: sherpa.OnlineModelConfig(
          transducer: sherpa.OnlineTransducerModelConfig(
            encoder: encoderPath,
            decoder: decoderPath,
            joiner: joinerPath,
          ),
          tokens: tokensPath,
          numThreads: 2,
          debug: false,
        ),
        // Optional: feat parameter for custom feature config
        // feat: sherpa.FeatureConfig(
        //   sampleRate: 16000,
        //   featureDim: 80,
        // ),
      );

      _sttRecognizers[language] = sherpa.OnlineRecognizer(config);

      Logger.success('SHERPA', 'STT model loaded for: $language');
      return true;

    } catch (e, stackTrace) {
      Logger.error('SHERPA', 'STT load failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TTS MODEL LOADING (Piper)
  // ═══════════════════════════════════════════════════════════════

  Future<bool> _loadTTSModel(String packPath, String language) async {
    try {
      // Check if already loaded
      if (_ttsEngines.containsKey(language)) {
        Logger.info('SHERPA', 'TTS already loaded for: $language');
        return true;
      }

      Logger.info('SHERPA', 'Loading TTS model for: $language');

      final ttsPath = path.join(packPath, 'tts', language);

      // Find the .onnx file (e.g., en_US-lessac-medium.onnx)
      final ttsDir = Directory(ttsPath);
      if (!await ttsDir.exists()) {
        Logger.error('SHERPA', 'TTS directory not found: $ttsPath');
        return false;
      }

      String? modelPath;
      String? configPath;

      await for (final entity in ttsDir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.endsWith('.onnx') && !fileName.endsWith('.json')) {
            modelPath = entity.path;
            configPath = '${entity.path}.json';
          }
        }
      }

      if (modelPath == null || !await File(modelPath).exists()) {
        Logger.error('SHERPA', 'TTS model file not found');
        return false;
      }

      if (configPath == null || !await File(configPath).exists()) {
        Logger.error('SHERPA', 'TTS config file not found');
        return false;
      }

      // Configure Piper TTS
      final config = sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: modelPath,
            tokens: '', // Piper doesn't need separate tokens file
            dataDir: ttsPath,
          ),
          numThreads: 2,
          debug: false,
        ),
      );

      _ttsEngines[language] = sherpa.OfflineTts(config);

      Logger.success('SHERPA', 'TTS model loaded for: $language');
      return true;

    } catch (e, stackTrace) {
      Logger.error('SHERPA', 'TTS load failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UNLOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> unloadPack(String packId) async {
    try {
      final pack = _loadedPacks[packId];
      if (pack == null) return;

      // Remove recognizers
      _sttRecognizers.remove(pack.sourceLanguage);

      // Remove TTS engines
      _ttsEngines.remove(pack.sourceLanguage);
      _ttsEngines.remove(pack.targetLanguage);

      _loadedPacks.remove(packId);

      Logger.info('SHERPA', 'Pack unloaded: $packId');
    } catch (e) {
      Logger.error('SHERPA', 'Unload failed', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // STT OPERATIONS
  // ═══════════════════════════════════════════════════════════════

  sherpa.OnlineStream? createStream(String language) {
    final recognizer = _sttRecognizers[language];
    if (recognizer == null) {
      Logger.error('SHERPA', 'STT recognizer not loaded for: $language');
      return null;
    }

    try {
      return recognizer.createStream();
    } catch (e) {
      Logger.error('SHERPA', 'Create stream failed', e);
      return null;
    }
  }

  // FIXED: Convert List<double> to Float32List
  void acceptWaveform(
      String language,
      sherpa.OnlineStream stream,
      List<double> samples,
      int sampleRate,
      ) {
    try {
      stream.acceptWaveform(
        samples: Float32List.fromList(samples),
        sampleRate: sampleRate,
      );
    } catch (e) {
      Logger.error('SHERPA', 'Accept waveform failed', e);
    }
  }

  String getResult(String language, sherpa.OnlineStream stream) {
    try {
      final recognizer = _sttRecognizers[language];
      if (recognizer == null) return '';

      final isReady = recognizer.isReady(stream);
      if (!isReady) return '';

      recognizer.decode(stream);
      final result = recognizer.getResult(stream);

      return result.text;
    } catch (e) {
      Logger.error('SHERPA', 'Get result failed', e);
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TTS OPERATIONS (Piper)
  // ═══════════════════════════════════════════════════════════════

  Future<String?> synthesizeSpeech({
    required String text,
    required String language,
    double speed = 1.0,
  }) async {
    final tts = _ttsEngines[language];
    if (tts == null) {
      Logger.error('SHERPA', 'TTS engine not loaded for: $language');
      return null;
    }

    try {
      Logger.info('SHERPA', 'Synthesizing: "$text" ($language)');

      final audio = tts.generate(
        text: text,
        speed: speed,
        sid: 0,
      );

      if (audio.samples.isEmpty) {
        Logger.error('SHERPA', 'No audio samples generated');
        return null;
      }

      // Save to file
      final audioDir = await StorageUtils.getAudioDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(audioDir.path, 'tts_${language}_$timestamp.wav');

      await _writeWavFile(
        outputPath,
        audio.samples,
        audio.sampleRate,
      );

      Logger.success('SHERPA', 'Audio saved: $outputPath');
      return outputPath;

    } catch (e, stackTrace) {
      Logger.error('SHERPA', 'TTS failed', e, stackTrace);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WAV FILE WRITER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _writeWavFile(
      String outputPath,
      List<double> samples,
      int sampleRate,
      ) async {
    final file = File(outputPath);

    final pcmData = <int>[];
    for (final sample in samples) {
      final value = (sample * 32767).round().clamp(-32768, 32767);
      pcmData.add(value & 0xFF);
      pcmData.add((value >> 8) & 0xFF);
    }

    final dataSize = pcmData.length;
    final header = <int>[
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      (dataSize + 36) & 0xFF, ((dataSize + 36) >> 8) & 0xFF,
      ((dataSize + 36) >> 16) & 0xFF, ((dataSize + 36) >> 24) & 0xFF,
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // Format chunk size
      0x01, 0x00, // PCM
      0x01, 0x00, // Mono
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF,
      (sampleRate * 2) & 0xFF, ((sampleRate * 2) >> 8) & 0xFF,
      ((sampleRate * 2) >> 16) & 0xFF, ((sampleRate * 2) >> 24) & 0xFF,
      0x02, 0x00, // Block align
      0x10, 0x00, // Bits per sample
      0x64, 0x61, 0x74, 0x61, // "data"
      dataSize & 0xFF, (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];

    await file.writeAsBytes([...header, ...pcmData]);
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  bool isPackLoaded(String packId) => _loadedPacks.containsKey(packId);
  bool isSTTLoaded(String language) => _sttRecognizers.containsKey(language);
  bool isTTSLoaded(String language) => _ttsEngines.containsKey(language);

  List<String> getLoadedPacks() => _loadedPacks.keys.toList();

  void dispose() {
    for (final packId in _loadedPacks.keys.toList()) {
      unloadPack(packId);
    }
  }
}

class _LoadedPack {
  final String packId;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime loadedAt;

  _LoadedPack({
    required this.packId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.loadedAt,
  });
}