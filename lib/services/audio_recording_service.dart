import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/logger_utils.dart';

/// 🎤 Audio Recording Service
/// 
/// Handles microphone recording with permission management
class AudioRecordingService {
  // Singleton pattern
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final Uuid _uuid = const Uuid();
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  // ═══════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Get current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      // Check if recorder is available
      final hasPermission = await checkPermission();
      
      if (!hasPermission) {
        Logger.warning('AUDIO', 'Microphone permission not granted');
        return false;
      }

      Logger.success('AUDIO', 'Audio service initialized');
      return true;
    } catch (e, stackTrace) {
      Logger.error('AUDIO', 'Initialization failed', e, stackTrace);
      return false;
    }
  }

  /// Check microphone permission
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      Logger.error('AUDIO', 'Permission check failed', e);
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        Logger.success('AUDIO', 'Microphone permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        Logger.warning('AUDIO', 'Microphone permission permanently denied');
        // Open app settings
        await openAppSettings();
        return false;
      } else {
        Logger.warning('AUDIO', 'Microphone permission denied');
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error('AUDIO', 'Permission request failed', e, stackTrace);
      return false;
    }
  }

  /// Start recording
  Future<RecordingResult> startRecording() async {
    if (_isRecording) {
      return RecordingResult.error('Already recording');
    }

    try {
      // Check permission first
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          return RecordingResult.error('Microphone permission required');
        }
      }

      // Generate unique file path
      final directory = await getTemporaryDirectory();
      final fileName = 'recording_${_uuid.v4()}.m4a';
      final filePath = '${directory.path}/$fileName';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC for better compatibility
          bitRate: 128000, // 128 kbps
          sampleRate: 44100, // CD quality
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;

      Logger.success('AUDIO', 'Recording started: $fileName');
      return RecordingResult.started(filePath);

    } catch (e, stackTrace) {
      Logger.error('AUDIO', 'Start recording failed', e, stackTrace);
      _isRecording = false;
      _currentRecordingPath = null;
      return RecordingResult.error('Failed to start recording: $e');
    }
  }

  /// Stop recording
  Future<RecordingResult> stopRecording() async {
    if (!_isRecording) {
      return RecordingResult.error('Not recording');
    }

    try {
      final path = await _recorder.stop();
      
      _isRecording = false;
      final recordedPath = _currentRecordingPath;
      _currentRecordingPath = null;

      if (path != null && recordedPath != null) {
        // Verify file exists and has content
        final file = File(recordedPath);
        if (await file.exists()) {
          final size = await file.length();
          
          if (size > 1000) { // At least 1KB
            Logger.success('AUDIO', 'Recording stopped: ${size} bytes');
            return RecordingResult.completed(recordedPath, size);
          } else {
            Logger.warning('AUDIO', 'Recording too short: $size bytes');
            await file.delete();
            return RecordingResult.error('Recording too short');
          }
        }
      }

      Logger.error('AUDIO', 'Recording file not found');
      return RecordingResult.error('Recording file not created');

    } catch (e, stackTrace) {
      Logger.error('AUDIO', 'Stop recording failed', e, stackTrace);
      _isRecording = false;
      _currentRecordingPath = null;
      return RecordingResult.error('Failed to stop recording: $e');
    }
  }

  /// Cancel recording (stop and delete file)
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          Logger.info('AUDIO', 'Recording cancelled and deleted');
        }
      }

      _isRecording = false;
      _currentRecordingPath = null;

    } catch (e) {
      Logger.error('AUDIO', 'Cancel recording failed', e);
    }
  }

  /// Check if device has microphone
  Future<bool> hasMicrophone() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  /// Get audio level (0.0 to 1.0) while recording
  Future<double> getAmplitude() async {
    if (!_isRecording) return 0.0;

    try {
      final amplitude = await _recorder.getAmplitude();
      // Convert decibels to 0-1 range
      final db = amplitude.current;
      if (db < -60) return 0.0;
      if (db > -10) return 1.0;
      return (db + 60) / 50; // Map -60dB to 0.0, -10dB to 1.0
    } catch (e) {
      return 0.0;
    }
  }

  /// Cleanup old recordings
  Future<int> cleanupOldRecordings() async {
    int deletedCount = 0;
    
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('recording_')) {
          // Delete recordings older than 1 hour
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          
          if (age.inHours > 1) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      if (deletedCount > 0) {
        Logger.info('AUDIO', 'Cleaned up $deletedCount old recordings');
      }
    } catch (e) {
      Logger.error('AUDIO', 'Cleanup failed', e);
    }

    return deletedCount;
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      await _recorder.dispose();
      Logger.info('AUDIO', 'Service disposed');
    } catch (e) {
      Logger.error('AUDIO', 'Dispose failed', e);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

/// Recording result
class RecordingResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final String? error;

  RecordingResult._({
    required this.success,
    this.filePath,
    this.fileSize,
    this.error,
  });

  factory RecordingResult.started(String filePath) {
    return RecordingResult._(
      success: true,
      filePath: filePath,
    );
  }

  factory RecordingResult.completed(String filePath, int fileSize) {
    return RecordingResult._(
      success: true,
      filePath: filePath,
      fileSize: fileSize,
    );
  }

  factory RecordingResult.error(String error) {
    return RecordingResult._(
      success: false,
      error: error,
    );
  }
}
