import 'package:flutter/foundation.dart';

/// 📝 Logger Utilities
///
/// Centralized logging system with different levels and pretty formatting
class Logger {
  Logger._();

  // Enable/disable logging based on build mode
  static bool _isEnabled = kDebugMode;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  // ═══════════════════════════════════════════════════════════════
  // LOG LEVELS
  // ═══════════════════════════════════════════════════════════════

  /// Debug info (detailed information)
  static void debug(String tag, String message) {
    if (!_isEnabled) return;
    _log('🔍 DEBUG', tag, message);
  }

  /// General info
  static void info(String tag, String message) {
    if (!_isEnabled) return;
    _log('ℹ️  INFO', tag, message);
  }

  /// Success messages
  static void success(String tag, String message) {
    if (!_isEnabled) return;
    _log('✅ SUCCESS', tag, message);
  }

  /// Warnings (potential issues)
  static void warning(String tag, String message) {
    if (!_isEnabled) return;
    _log('⚠️  WARNING', tag, message);
  }

  /// Errors (something went wrong)
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (!_isEnabled) return;
    _log('❌ ERROR', tag, message);
    if (error != null) {
      debugPrint('   └─ Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('   └─ Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FEATURE-SPECIFIC LOGGERS
  // ═══════════════════════════════════════════════════════════════

  /// Download-related logs
  static void download(String message) {
    info('DOWNLOAD', message);
  }

  /// Translation-related logs
  static void translation(String message) {
    info('TRANSLATION', message);
  }

  /// Audio-related logs
  static void audio(String message) {
    info('AUDIO', message);
  }

  /// Model loading logs
  static void model(String message) {
    info('MODEL', message);
  }

  /// Storage-related logs
  static void storage(String message) {
    info('STORAGE', message);
  }

  /// Performance timing logs
  static void performance(String operation, Duration duration) {
    info('PERFORMANCE', '$operation completed in ${duration.inMilliseconds}ms');
  }

  // ═══════════════════════════════════════════════════════════════
  // SPECIALIZED LOGGING
  // ═══════════════════════════════════════════════════════════════

  /// Log download progress
  static void downloadProgress(String packId, double progress, String speed) {
    if (!_isEnabled) return;
    final percentage = (progress * 100).toStringAsFixed(1);
    download('$packId: $percentage% ($speed)');
  }

  /// Log translation performance
  static void translationPerformance({
    required String source,
    required String target,
    required int sttMs,
    required int translationMs,
    required int ttsMs,
    required int totalMs,
  }) {
    if (!_isEnabled) return;
    performance('Translation $source→$target', Duration(milliseconds: totalMs));
    debug('TRANSLATION', '  STT: ${sttMs}ms | Translation: ${translationMs}ms | TTS: ${ttsMs}ms');
  }

  /// Log model initialization
  static void modelInit(String modelType, String language, Duration duration) {
    if (!_isEnabled) return;
    model('Initialized $modelType ($language) in ${duration.inMilliseconds}ms');
  }

  // ═══════════════════════════════════════════════════════════════
  // FORMATTING HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Internal log formatter
  static void _log(String level, String tag, String message) {
    final timestamp = DateTime.now().toString().substring(11, 19); // HH:MM:SS
    debugPrint('[$timestamp] $level [$tag] $message');
  }

  /// Log separator line
  static void separator([String? title]) {
    if (!_isEnabled) return;
    if (title != null) {
      debugPrint('═══════════════════════════════════════════════════════════════════');
      debugPrint('  $title');
      debugPrint('═══════════════════════════════════════════════════════════════════');
    } else {
      debugPrint('───────────────────────────────────────────────────────────────────');
    }
  }

  /// Log section header
  static void section(String title) {
    if (!_isEnabled) return;
    debugPrint('');
    debugPrint('▶ $title');
    debugPrint('');
  }
}

/// 📊 Performance Monitor
///
/// Helper class for timing operations
class PerformanceMonitor {
  final String _operation;
  final DateTime _startTime;

  PerformanceMonitor(this._operation) : _startTime = DateTime.now() {
    Logger.debug('PERF', '$_operation started');
  }

  /// Complete the operation and log duration
  void complete() {
    final duration = DateTime.now().difference(_startTime);
    Logger.performance(_operation, duration);
  }

  /// Complete with custom message
  void completeWith(String message) {
    final duration = DateTime.now().difference(_startTime);
    Logger.info('PERF', '$_operation: $message (${duration.inMilliseconds}ms)');
  }
}