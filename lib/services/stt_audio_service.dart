import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import '../core/utils/logger_utils.dart';
import 'model_service.dart';

/// 🎙️ STT Audio Service
/// 
/// Links audio recording with speech recognition
class STTAudioService {
  static final STTAudioService _instance = STTAudioService._internal();
  factory STTAudioService() => _instance;
  STTAudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final ModelService _modelService = ModelService();
  
  sherpa.OnlineStream? _recognitionStream;
  StreamSubscription? _audioSubscription;
  
  bool _isListening = false;
  String _currentLanguage = 'en';
  
  // Result stream for real-time transcription
  final StreamController<String> _transcriptController = 
      StreamController<String>.broadcast();
  Stream<String> get transcriptStream => _transcriptController.stream;

  // Final result
  String _finalTranscript = '';

  // ═══════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  /// Start listening and recognizing speech
  Future<bool> startListening(String language) async {
    if (_isListening) {
      Logger.warning('STT_AUDIO', 'Already listening');
      return false;
    }

    try {
      Logger.info('STT_AUDIO', 'Starting STT for: $language');
      _currentLanguage = language;
      _finalTranscript = '';

      // Check microphone permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        Logger.error('STT_AUDIO', 'No microphone permission');
        return false;
      }

      // Create recognition stream from model service
      final stream = _modelService.createRecognitionStream(language);
      if (stream == null) {
        Logger.error('STT_AUDIO', 'Failed to create recognition stream');
        return false;
      }
      
      _recognitionStream = stream as sherpa.OnlineStream;

      // Configure audio recording for Sherpa-ONNX
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,  // 16-bit PCM
        sampleRate: 16000,                // Required by Sherpa
        numChannels: 1,                   // Mono
        bitRate: 128000,
      );

      // Start recording stream
      final audioStream = await _recorder.startStream(config);
      
      _audioSubscription = audioStream.listen(
        _onAudioData,
        onError: (error) {
          Logger.error('STT_AUDIO', 'Audio stream error', error);
        },
        onDone: () {
          Logger.info('STT_AUDIO', 'Audio stream ended');
        },
      );

      _isListening = true;
      Logger.success('STT_AUDIO', 'Listening started');
      return true;

    } catch (e, stackTrace) {
      Logger.error('STT_AUDIO', 'Start listening failed', e, stackTrace);
      return false;
    }
  }

  /// Stop listening and get final result
  Future<String?> stopListening() async {
    if (!_isListening) {
      return null;
    }

    try {
      Logger.info('STT_AUDIO', 'Stopping listening');

      // Stop recording
      await _recorder.stop();
      await _audioSubscription?.cancel();
      _audioSubscription = null;

      // Get final result
      if (_recognitionStream != null) {
        _finalTranscript = _modelService.getRecognitionResult(
          language: _currentLanguage,
          stream: _recognitionStream!,
        );
        _recognitionStream = null;
      }

      _isListening = false;
      
      Logger.success('STT_AUDIO', 'Listening stopped');
      if (_finalTranscript.isNotEmpty) {
        Logger.info('STT_AUDIO', 'Final transcript: $_finalTranscript');
        _transcriptController.add(_finalTranscript); // Send final result
      }
      
      return _finalTranscript.isNotEmpty ? _finalTranscript : null;

    } catch (e, stackTrace) {
      Logger.error('STT_AUDIO', 'Stop listening failed', e, stackTrace);
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUDIO PROCESSING
  // ═══════════════════════════════════════════════════════════════

  /// Process incoming audio data
  void _onAudioData(Uint8List audioData) {
    if (_recognitionStream == null || !_isListening) return;

    try {
      // Convert PCM16 bytes to Float32 samples
      final samples = _convertPCM16ToFloat32(audioData);
      
      // Feed to model service
      _modelService.feedAudioSamples(
        language: _currentLanguage,
        stream: _recognitionStream!,
        samples: samples,
        sampleRate: 16000,
      );
      
      // Get intermediate results for live transcription
      final partialResult = _modelService.getRecognitionResult(
        language: _currentLanguage,
        stream: _recognitionStream!,
      );
      
      if (partialResult.isNotEmpty && partialResult != _finalTranscript) {
        _finalTranscript = partialResult;
        _transcriptController.add(partialResult);
        Logger.info('STT_AUDIO', 'Partial: $partialResult');
      }

    } catch (e) {
      Logger.error('STT_AUDIO', 'Audio processing error', e);
    }
  }

  /// Convert PCM16 bytes to Float32 samples
  /// Sherpa-ONNX expects samples in range [-1.0, 1.0]
  List<double> _convertPCM16ToFloat32(Uint8List pcmData) {
    final samples = <double>[];
    
    // PCM16 is 2 bytes per sample (little-endian)
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      final low = pcmData[i];
      final high = pcmData[i + 1];
      
      // Combine bytes to form 16-bit signed integer
      int value = (high << 8) | low;
      
      // Handle sign (two's complement)
      if (value >= 0x8000) {
        value = value - 0x10000;
      }
      
      // Normalize to [-1.0, 1.0]
      final normalized = value / 32768.0;
      samples.add(normalized);
    }
    
    return samples;
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isListening => _isListening;
  String get currentLanguage => _currentLanguage;
  String get lastTranscript => _finalTranscript;

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════

  void dispose() {
    if (_isListening) {
      stopListening();
    }
    _transcriptController.close();
  }
}
