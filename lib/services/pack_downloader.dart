import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:prototype_ai_core/core/utils/format_utils.dart';
import 'package:prototype_ai_core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/storage_utils.dart';
import '../core/utils/logger_utils.dart';
import 'background_service.dart';

/// 📦 Language Pack Downloader with Pause/Resume
class PackDownloader {
  static final PackDownloader _instance = PackDownloader._internal();
  factory PackDownloader() => _instance;
  PackDownloader._internal();

  final NotificationService _notificationService = NotificationService();
  final BackgroundDownloadService _backgroundService = BackgroundDownloadService();
  final Map<String, DownloadProgress> _activeDownloads = {};
  final Map<String, bool> _pausedDownloads = {}; // Track paused state
  final Map<String, String> _partialDownloads = {};
  final Map<String, StreamSubscription?> _activeStreams = {};
  final StreamController<DownloadProgress> _progressController =
  StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final pausedKeys = prefs.getKeys().where((key) => key.startsWith('download_'));

    for (var key in pausedKeys) {
      final data = prefs.getString(key);
      if (data != null) {
        final parts = data.split('|');
        if (parts.length == 4) { // Changed from 3 to 4 (added filePath)
          final packId = key.replaceFirst('download_', '');
          final url = parts[0];
          final downloadedBytes = int.parse(parts[1]);
          final totalBytes = int.parse(parts[2]);
          final filePath = parts[3];

          _pausedDownloads[packId] = true;
          _partialDownloads[packId] = filePath; // Store partial file path

          _activeDownloads[packId] = DownloadProgress(
            packId: packId,
            status: DownloadStatus.paused,
            progress: downloadedBytes / totalBytes,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
          );

          Logger.info('DOWNLOAD', 'Restored paused download: $packId ($downloadedBytes/$totalBytes bytes)');
        }
      }
    }
  }
  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  Future<DownloadResult> downloadPack(String packId) async {
    final monitor = PerformanceMonitor('Download pack $packId');

    try {
      if (_activeDownloads.containsKey(packId)) {
        return DownloadResult.error('Pack is already being downloaded');
      }

      final packInfo = AppConstants.availablePacks[packId];
      if (packInfo == null) {
        return DownloadResult.error('Pack not found: $packId');
      }

      final hasSpace = await StorageUtils.hasEnoughSpace(packInfo.sizeInBytes);
      if (!hasSpace) {
        return DownloadResult.error('Insufficient storage space');
      }

      final isInstalled = await StorageUtils.isPackInstalled(packId);
      if (isInstalled) {
        return DownloadResult.error('Pack is already installed');
      }

      // 🆕 Register background task
      await _backgroundService.startBackgroundDownload(packId);
      Logger.download('Starting download: $packId (${packInfo.formattedSize})');

      _activeDownloads[packId] = DownloadProgress(
        packId: packId,
        status: DownloadStatus.downloading,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: packInfo.sizeInBytes,
      );

      _progressController.add(_activeDownloads[packId]!);

      // Download
      final zipPath = await _downloadFileWithResume(packId, packInfo.downloadUrl, packInfo.sizeInBytes);

      if (zipPath == null) {
        _updateProgress(packId, DownloadStatus.failed, 0.0);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Download failed');
      }

      // Extract
      _updateProgress(packId, DownloadStatus.extracting, 0.9);
      final extractSuccess = await _extractPack(packId, zipPath);

      if (!extractSuccess) {
        _updateProgress(packId, DownloadStatus.failed, 0.9);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Extraction failed');
      }

      // Verify
      _updateProgress(packId, DownloadStatus.verifying, 0.95);
      final isValid = await StorageUtils.verifyPackIntegrity(packId);

      if (!isValid) {
        _updateProgress(packId, DownloadStatus.failed, 0.95);
        await StorageUtils.deleteLanguagePack(packId);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Pack verification failed');
      }

      await _cleanupTempFile(zipPath);

      _updateProgress(packId, DownloadStatus.completed, 1.0);

      Future.delayed(const Duration(milliseconds: 500), () {
        _activeDownloads.remove(packId);
      });

      monitor.complete();
      Logger.success('DOWNLOAD', 'Pack installed successfully: $packId');

      return DownloadResult.success(packId);

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Download failed: $packId', e, stackTrace);
      _updateProgress(packId, DownloadStatus.failed, 0.0);
      _activeDownloads.remove(packId);
      return DownloadResult.error('Download error: $e');
    }
  }

  /// Pause an active download
  Future<bool> pauseDownload(String packId) async {
    if (!_activeDownloads.containsKey(packId)) {
      Logger.warning('DOWNLOAD', 'No active download to pause: $packId');
      return false;
    }

    try {
      Logger.info('DOWNLOAD', 'Pausing download: $packId');

      // Cancel the stream first
      final subscription = _activeStreams[packId];
      if (subscription != null) {
        await subscription.cancel();
        _activeStreams.remove(packId);
      }

      // Save pause state to SharedPreferences
      final currentProgress = _activeDownloads[packId];
      if (currentProgress != null) {
        final packInfo = AppConstants.availablePacks[packId];
        if (packInfo != null) {
          final prefs = await SharedPreferences.getInstance();
          final filePath = _partialDownloads[packId] ??
              await StorageUtils.getDownloadPath(packInfo.fileName);

          // Save: url|downloadedBytes|totalBytes|filePath
          await prefs.setString(
            'download_$packId',
            '${packInfo.downloadUrl}|${currentProgress.downloadedBytes}|${currentProgress.totalBytes}|$filePath',
          );

          Logger.info('DOWNLOAD', 'Saved pause state: ${currentProgress.downloadedBytes} bytes');
        }

        // Mark as paused
        _pausedDownloads[packId] = true;

        // Update status to paused
        _updateProgress(
          packId,
          DownloadStatus.paused,
          currentProgress.progress,
          downloadedBytes: currentProgress.downloadedBytes,
        );
      }

      Logger.success('DOWNLOAD', 'Download paused: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Pause failed', e, stackTrace);
      return false;
    }
  }

  /// Resume a paused download
  Future<DownloadResult> resumeDownload(String packId) async {
    if (!_pausedDownloads.containsKey(packId)) {
      return DownloadResult.error('Download is not paused');
    }

    try {
      Logger.info('DOWNLOAD', 'Resuming download: $packId');
      await _backgroundService.resumeBackgroundDownload(packId);
      final packInfo = AppConstants.availablePacks[packId];
      if (packInfo == null) {
        return DownloadResult.error('Pack not found: $packId');
      }

      // Get saved progress
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('download_$packId');

      int resumeFrom = 0;
      String? existingFilePath;

      if (savedData != null) {
        final parts = savedData.split('|');
        if (parts.length >= 2) {
          resumeFrom = int.parse(parts[1]);
          if (parts.length >= 4) {
            existingFilePath = parts[3];
          }
        }
      }

      Logger.info('DOWNLOAD', 'Resuming from byte: $resumeFrom');

      // Remove pause flag
      _pausedDownloads.remove(packId);

      // Update status to downloading
      _updateProgress(
        packId,
        DownloadStatus.downloading,
        resumeFrom / packInfo.sizeInBytes,
        downloadedBytes: resumeFrom,
      );

      // Resume download with HTTP Range
      final zipPath = await _downloadFileWithResume(
        packId,
        packInfo.downloadUrl,
        packInfo.sizeInBytes,
        resumeFrom: resumeFrom,
        existingFilePath: existingFilePath,
      );

      if (zipPath == null) {
        _updateProgress(packId, DownloadStatus.failed, 0.0);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Download failed');
      }

      // Clear saved pause state
      await prefs.remove('download_$packId');
      _partialDownloads.remove(packId);

      // Extract
      _updateProgress(packId, DownloadStatus.extracting, 0.9);
      final extractSuccess = await _extractPack(packId, zipPath);

      if (!extractSuccess) {
        _updateProgress(packId, DownloadStatus.failed, 0.9);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Extraction failed');
      }

      // Verify
      _updateProgress(packId, DownloadStatus.verifying, 0.95);
      final isValid = await StorageUtils.verifyPackIntegrity(packId);

      if (!isValid) {
        _updateProgress(packId, DownloadStatus.failed, 0.95);
        await StorageUtils.deleteLanguagePack(packId);
        _activeDownloads.remove(packId);
        return DownloadResult.error('Pack verification failed');
      }

      await _cleanupTempFile(zipPath);
      _updateProgress(packId, DownloadStatus.completed, 1.0);

      Future.delayed(const Duration(milliseconds: 500), () {
        _activeDownloads.remove(packId);
      });

      Logger.success('DOWNLOAD', 'Pack installed successfully: $packId');
      return DownloadResult.success(packId);

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Resume failed', e, stackTrace);
      return DownloadResult.error('Resume error: $e');
    }
  }

  /// Cancel an active download
  Future<bool> cancelDownload(String packId) async {
    if (!_activeDownloads.containsKey(packId)) {
      Logger.warning('DOWNLOAD', 'No active download to cancel: $packId');
      return false;
    }

    try {
      Logger.info('DOWNLOAD', 'Cancelling download: $packId');

      // Cancel stream
      final subscription = _activeStreams[packId];
      if (subscription != null) {
        await subscription.cancel();
        _activeStreams.remove(packId);
      }

      // Update status
      _updateProgress(packId, DownloadStatus.cancelled, 0.0);

      // Remove tracking
      _activeDownloads.remove(packId);
      _pausedDownloads.remove(packId);

      // Clear saved state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('download_$packId');

      // Cleanup partial files
      try {
        final partialPath = _partialDownloads[packId];
        if (partialPath != null) {
          await StorageUtils.deleteFile(partialPath);
          _partialDownloads.remove(packId);
        }
      } catch (e) {
        Logger.warning('DOWNLOAD', 'Cleanup failed: $e');
      }
      // 🆕 Cancel background task
      await _backgroundService.cancelBackgroundDownload(packId);
      Logger.success('DOWNLOAD', 'Download cancelled: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Cancel failed', e, stackTrace);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIVATE DOWNLOAD METHODS
  // ═══════════════════════════════════════════════════════════════

  Future<String?> _downloadFileWithResume(
      String packId,
      String url,
      int totalBytes, {
        int resumeFrom = 0,
        String? existingFilePath,
      }) async {
    try {
      final fileName = url.split('/').last;
      final savePath = existingFilePath ?? await StorageUtils.getDownloadPath(fileName);

      // Store partial file path
      _partialDownloads[packId] = savePath;

      Logger.download('Downloading from: $url');
      Logger.download('Saving to: $savePath');
      if (resumeFrom > 0) {
        Logger.info('DOWNLOAD', 'Resuming from byte: $resumeFrom');
      }

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));

      // Add Range header for resume
      if (resumeFrom > 0) {
        request.headers['Range'] = 'bytes=$resumeFrom-';
        Logger.info('DOWNLOAD', 'Using HTTP Range: bytes=$resumeFrom-');
      }

      final response = await client.send(request);

      // Check status codes
      if (response.statusCode != 200 && response.statusCode != 206) {
        Logger.error('DOWNLOAD', 'HTTP ${response.statusCode}');
        client.close();
        return null;
      }

      // Verify server supports ranges if resuming
      if (resumeFrom > 0 && response.statusCode != 206) {
        Logger.warning('DOWNLOAD', 'Server does not support Range requests, restarting from beginning');
        resumeFrom = 0;
      }

      final file = File(savePath);
      final sink = file.openWrite(mode: resumeFrom > 0 ? FileMode.append : FileMode.write);

      int downloadedBytes = resumeFrom;
      final startTime = DateTime.now();
      int lastUpdateTime = DateTime.now().millisecondsSinceEpoch;

      final completer = Completer<String?>();

      _activeStreams[packId] = response.stream.listen(
            (chunk) {
          // Check if paused or cancelled
          if (_pausedDownloads.containsKey(packId) ||
              !_activeDownloads.containsKey(packId)) {
            sink.close();
            client.close();
            completer.complete(null);
            return;
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;

          // Throttle progress updates (every 500ms)
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - lastUpdateTime >= 500) {
            final progress = downloadedBytes / totalBytes;
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            final speed = elapsed > 0 ? ((downloadedBytes - resumeFrom) / elapsed).toDouble() : 0.0;

            _updateProgress(
              packId,
              DownloadStatus.downloading,
              progress * 0.9,
              downloadedBytes: downloadedBytes,
              bytesPerSecond: speed,
            );

            lastUpdateTime = now;
          }
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          client.close();
          _activeStreams.remove(packId);
          Logger.success('DOWNLOAD', 'File downloaded: $savePath');
          completer.complete(savePath);
        },
        onError: (error, stackTrace) async {
          await sink.close();
          client.close();
          _activeStreams.remove(packId);
          Logger.error('DOWNLOAD', 'Stream error', error, stackTrace);
          completer.completeError(error);
        },
        cancelOnError: true,
      );

      return await completer.future;

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Download error', e, stackTrace);
      return null;
    }
  }

  Future<bool> _extractPack(String packId, String zipPath) async {
    try {
      Logger.info('DOWNLOAD', 'Extracting pack: $packId');

      final packDir = await StorageUtils.getPackDirectory(packId);
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (!_activeDownloads.containsKey(packId)) {
          Logger.info('DOWNLOAD', 'Extraction cancelled: $packId');
          return false;
        }

        final filename = file.name;
        final filePath = '${packDir.path}/$filename';

        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }

      Logger.success('DOWNLOAD', 'Extraction complete: $packId');
      return true;

    } catch (e, stackTrace) {
      Logger.error('DOWNLOAD', 'Extraction failed', e, stackTrace);
      return false;
    }
  }

  Future<void> _cleanupTempFile(String filePath) async {
    try {
      await StorageUtils.deleteFile(filePath);
      Logger.info('DOWNLOAD', 'Cleaned up temp file');
    } catch (e) {
      Logger.warning('DOWNLOAD', 'Failed to cleanup temp file: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS TRACKING
  // ═══════════════════════════════════════════════════════════════

// Replace your existing _updateProgress method with this:
  void _updateProgress(
      String packId,
      DownloadStatus status,
      double progress, {
        int? downloadedBytes,
        double? bytesPerSecond,
      }) {
    final totalBytes = AppConstants.availablePacks[packId]?.sizeInBytes ?? 0;

    final progressData = DownloadProgress(
      packId: packId,
      status: status,
      progress: progress.clamp(0.0, 1.0),
      downloadedBytes: downloadedBytes ?? 0,
      totalBytes: totalBytes,
      bytesPerSecond: bytesPerSecond,
    );

    _activeDownloads[packId] = progressData;
    _progressController.add(progressData);

    // 🔔 Add notification updates
    if (status == DownloadStatus.downloading) {
      _notificationService.showDownloadProgress(
        packId: packId,
        packName: AppConstants.availablePacks[packId]?.name ?? packId,
        progress: (progress * 100).round(),
        downloadedBytes: downloadedBytes ?? 0,
        totalBytes: totalBytes,
        speed: bytesPerSecond != null
            ? FormatUtils.formatSpeed(bytesPerSecond)
            : null,
      );
    } else if (status == DownloadStatus.completed) {
      // Show completion notification
      _notificationService.showDownloadCompleted(
        packId: packId,
        packName: AppConstants.availablePacks[packId]?.name ?? packId,
      );
    } else if (status == DownloadStatus.failed) {
      // Cancel notification on failure
      _notificationService.cancelDownloadNotification();
    } else if (status == DownloadStatus.paused) {
      // Show paused notification
      _notificationService.showDownloadPaused(
        packId: packId,
        packName: AppConstants.availablePacks[packId]?.name ?? packId,
        progress: (progress * 100).round(),
      );
    }
  }

  DownloadProgress? getProgress(String packId) {
    return _activeDownloads[packId];
  }

  bool isDownloading(String packId) {
    return _activeDownloads.containsKey(packId) &&
        !_pausedDownloads.containsKey(packId);
  }

  bool isPaused(String packId) {
    return _pausedDownloads.containsKey(packId);
  }

  void dispose() {
    _progressController.close();
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

enum DownloadStatus {
  downloading,
  paused,
  extracting,
  verifying,
  completed,
  failed,
  cancelled,
}

class DownloadProgress {
  final String packId;
  final DownloadStatus status;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final double? bytesPerSecond;

  DownloadProgress({
    required this.packId,
    required this.status,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    this.bytesPerSecond,
  });

  int get progressPercent => (progress * 100).round();

  Duration? get estimatedTimeRemaining {
    if (bytesPerSecond == null || bytesPerSecond! <= 0) return null;
    final remainingBytes = totalBytes - downloadedBytes;
    final seconds = remainingBytes / bytesPerSecond!;
    return Duration(seconds: seconds.round());
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.extracting:
        return 'Extracting...';
      case DownloadStatus.verifying:
        return 'Verifying...';
      case DownloadStatus.completed:
        return 'Complete';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class DownloadResult {
  final bool success;
  final String? packId;
  final String? error;

  DownloadResult._({required this.success, this.packId, this.error});

  factory DownloadResult.success(String packId) =>
      DownloadResult._(success: true, packId: packId);

  factory DownloadResult.error(String error) =>
      DownloadResult._(success: false, error: error);
}