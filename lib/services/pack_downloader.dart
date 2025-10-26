import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/storage_utils.dart';
import '../core/utils/logger_utils.dart';

/// 📦 Language Pack Downloader with Pause/Resume
class PackDownloader {
  static final PackDownloader _instance = PackDownloader._internal();
  factory PackDownloader() => _instance;
  PackDownloader._internal();

  final Map<String, DownloadProgress> _activeDownloads = {};
  final Map<String, bool> _pausedDownloads = {}; // Track paused state
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
        if (parts.length == 3) {
          final packId = key.replaceFirst('download_', '');
          final url = parts[0];
          final downloadedBytes = int.parse(parts[1]);
          final totalBytes = int.parse(parts[2]);
          _pausedDownloads[packId] = true;
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
      final zipPath = await _downloadFile(packId, packInfo.downloadUrl, packInfo.sizeInBytes);

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

      // Mark as paused
      _pausedDownloads[packId] = true;

      // Cancel the stream
      final subscription = _activeStreams[packId];
      if (subscription != null) {
        await subscription.cancel();
        _activeStreams.remove(packId);
      }

      // Update status to paused
      final currentProgress = _activeDownloads[packId];
      if (currentProgress != null) {
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

      // Remove pause flag FIRST
      _pausedDownloads.remove(packId);

      // Remove from active downloads to allow restart
      _activeDownloads.remove(packId);

      // Clear any existing streams
      _activeStreams.remove(packId);

      // Resume download from beginning (full implementation would use HTTP Range)
      return await downloadPack(packId);

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

      // Cleanup partial files
      try {
        final packInfo = AppConstants.availablePacks[packId];
        if (packInfo != null) {
          final zipPath = await StorageUtils.getDownloadPath(packInfo.fileName);
          await StorageUtils.deleteFile(zipPath);
        }
      } catch (e) {
        Logger.warning('DOWNLOAD', 'Cleanup failed: $e');
      }

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

  Future<String?> _downloadFile(String packId, String url, int totalBytes) async {
    try {
      final fileName = url.split('/').last;
      final savePath = await StorageUtils.getDownloadPath(fileName);

      Logger.download('Downloading from: $url');
      Logger.download('Saving to: $savePath');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        Logger.error('DOWNLOAD', 'HTTP ${response.statusCode}');
        client.close();
        return null;
      }

      final file = File(savePath);
      final sink = file.openWrite();
      int downloadedBytes = 0;
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
            final speed = elapsed > 0 ? (downloadedBytes / elapsed).toDouble() : 0.0;

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

  void _updateProgress(
      String packId,
      DownloadStatus status,
      double progress, {
        int? downloadedBytes,
        double? bytesPerSecond,
      }) {
    final progressData = DownloadProgress(
      packId: packId,
      status: status,
      progress: progress.clamp(0.0, 1.0),
      downloadedBytes: downloadedBytes ?? 0,
      totalBytes: AppConstants.availablePacks[packId]?.sizeInBytes ?? 0,
      bytesPerSecond: bytesPerSecond,
    );

    _activeDownloads[packId] = progressData;
    _progressController.add(progressData);
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