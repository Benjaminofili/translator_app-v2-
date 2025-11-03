import 'dart:io';
import 'package:path/path.dart' as path;
import '../core/utils/logger_utils.dart';
import '../core/utils/storage_utils.dart';

/// 🔍 Model Debug Helper
/// 
/// Utility to check if models are properly loaded
class ModelDebugHelper {
  ModelDebugHelper._();

  /// Check if a pack's STT models are available
  static Future<Map<String, dynamic>> checkSTTModels(String packId) async {
    final result = <String, dynamic>{
      'packExists': false,
      'sttDirExists': false,
      'files': <String, bool>{},
      'errors': <String>[],
    };

    try {
      final packPath = await StorageUtils.getPackPath(packId);
      final packDir = Directory(packPath);

      result['packPath'] = packPath;
      result['packExists'] = await packDir.exists();

      if (!result['packExists']) {
        result['errors'].add('Pack directory not found');
        return result;
      }

      // Check STT directory
      final sttPath = path.join(packPath, 'stt');
      final sttDir = Directory(sttPath);
      result['sttPath'] = sttPath;
      result['sttDirExists'] = await sttDir.exists();

      if (!result['sttDirExists']) {
        result['errors'].add('STT directory not found');
        return result;
      }

      // Check required files
      final requiredFiles = [
        'encoder.onnx',
        'decoder.onnx',
        'joiner.onnx',
        'tokens.txt',
      ];

      for (final fileName in requiredFiles) {
        final filePath = path.join(sttPath, fileName);
        final file = File(filePath);
        final exists = await file.exists();

        result['files'][fileName] = exists;

        if (!exists) {
          result['errors'].add('Missing: $fileName');
        } else {
          final size = await file.length();
          result['files']['${fileName}_size'] = size;

          if (size < 1000) {
            result['errors'].add('$fileName is too small (${size} bytes)');
          }
        }
      }

    } catch (e, stackTrace) {
      result['errors'].add('Exception: $e');
      Logger.error('DEBUG', 'Check STT models failed', e, stackTrace);
    }

    return result;
  }

  /// Check if a pack's TTS models are available
  static Future<Map<String, dynamic>> checkTTSModels(
      String packId,
      String language,
      ) async {
    final result = <String, dynamic>{
      'ttsDirExists': false,
      'hasModel': false,
      'hasConfig': false,
      'errors': <String>[],
    };

    try {
      final packPath = await StorageUtils.getPackPath(packId);
      final ttsPath = path.join(packPath, 'tts', language);
      final ttsDir = Directory(ttsPath);

      result['ttsPath'] = ttsPath;
      result['ttsDirExists'] = await ttsDir.exists();

      if (!result['ttsDirExists']) {
        result['errors'].add('TTS directory not found for $language');
        return result;
      }

      // Find .onnx and .json files
      String? modelFile;
      String? configFile;

      await for (final entity in ttsDir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);
          if (fileName.endsWith('.onnx') && !fileName.endsWith('.json')) {
            modelFile = fileName;
            result['modelFile'] = fileName;
            result['modelSize'] = await entity.length();
            result['hasModel'] = true;
          } else if (fileName.endsWith('.onnx.json')) {
            configFile = fileName;
            result['configFile'] = fileName;
            result['configSize'] = await entity.length();
            result['hasConfig'] = true;
          }
        }
      }

      if (!result['hasModel']) {
        result['errors'].add('No .onnx model file found');
      }
      if (!result['hasConfig']) {
        result['errors'].add('No .onnx.json config file found');
      }

    } catch (e, stackTrace) {
      result['errors'].add('Exception: $e');
      Logger.error('DEBUG', 'Check TTS models failed', e, stackTrace);
    }

    return result;
  }

  /// Print detailed debug info for a pack
  static Future<void> printDebugInfo(String packId) async {
    Logger.separator('DEBUG INFO: $packId');

    // Check STT
    Logger.info('DEBUG', 'Checking STT models...');
    final sttInfo = await checkSTTModels(packId);
    Logger.info('DEBUG', 'Pack exists: ${sttInfo['packExists']}');
    Logger.info('DEBUG', 'Pack path: ${sttInfo['packPath']}');
    Logger.info('DEBUG', 'STT dir exists: ${sttInfo['sttDirExists']}');

    if (sttInfo['files'] is Map) {
      final files = sttInfo['files'] as Map<String, dynamic>;
      for (final entry in files.entries) {
        if (!entry.key.endsWith('_size')) {
          Logger.info('DEBUG', '  ${entry.key}: ${entry.value}');
        }
      }
    }

    if (sttInfo['errors'] is List && (sttInfo['errors'] as List).isNotEmpty) {
      Logger.error('DEBUG', 'STT Errors:');
      for (final error in sttInfo['errors']) {
        Logger.error('DEBUG', '  - $error');
      }
    } else {
      Logger.success('DEBUG', 'STT models OK ✅');
    }

    // Check TTS for both languages (assuming en-es)
    for (final lang in ['en', 'es']) {
      Logger.info('DEBUG', '\nChecking TTS models for: $lang');
      final ttsInfo = await checkTTSModels(packId, lang);
      Logger.info('DEBUG', 'TTS dir exists: ${ttsInfo['ttsDirExists']}');
      Logger.info('DEBUG', 'Has model: ${ttsInfo['hasModel']}');
      Logger.info('DEBUG', 'Has config: ${ttsInfo['hasConfig']}');

      if (ttsInfo['errors'] is List && (ttsInfo['errors'] as List).isNotEmpty) {
        Logger.error('DEBUG', 'TTS Errors:');
        for (final error in ttsInfo['errors']) {
          Logger.error('DEBUG', '  - $error');
        }
      } else {
        Logger.success('DEBUG', 'TTS models OK ✅');
      }
    }

    Logger.separator();
  }

  /// Quick health check
  static Future<bool> isPackHealthy(String packId) async {
    final sttInfo = await checkSTTModels(packId);
    final sttHealthy = sttInfo['packExists'] == true &&
        sttInfo['sttDirExists'] == true &&
        (sttInfo['errors'] as List).isEmpty;

    if (!sttHealthy) {
      return false;
    }

    // Check at least one TTS language
    final ttsInfo = await checkTTSModels(packId, 'en');
    final ttsHealthy = ttsInfo['ttsDirExists'] == true &&
        ttsInfo['hasModel'] == true &&
        ttsInfo['hasConfig'] == true;

    return ttsHealthy;
  }
}