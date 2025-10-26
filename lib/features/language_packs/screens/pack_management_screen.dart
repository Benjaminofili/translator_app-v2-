import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../services/pack_downloader.dart';
import '../widgets/language_pack_card.dart';

/// 📦 Language Pack Management Screen
class PackManagementScreen extends StatefulWidget {
  const PackManagementScreen({super.key});

  @override
  State<PackManagementScreen> createState() => _PackManagementScreenState();
}

class _PackManagementScreenState extends State<PackManagementScreen> {
  final PackDownloader _downloader = PackDownloader();
  final Map<String, bool> _installedPacks = {};
  final Map<String, DownloadProgress?> _downloadProgress = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledPacks();
    _listenToDownloads();
  }

  Future<void> _loadInstalledPacks() async {
    setState(() => _isLoading = true);

    try {
      final installed = await StorageUtils.getInstalledPacks();

      setState(() {
        _installedPacks.clear();
        for (final packId in AppConstants.availablePacks.keys) {
          _installedPacks[packId] = installed.contains(packId);
        }
        _isLoading = false;
      });

      Logger.info('PACKS', 'Loaded ${installed.length} installed packs');
    } catch (e) {
      Logger.error('PACKS', 'Failed to load packs', e);
      setState(() => _isLoading = false);
    }
  }

  void _listenToDownloads() {
    _downloader.progressStream.listen((progress) {
      if (!mounted) return;

      setState(() {
        _downloadProgress[progress.packId] = progress;

        if (progress.status == DownloadStatus.completed) {
          _installedPacks[progress.packId] = true;
          _showMessage('${progress.packId.toUpperCase()} installed successfully!');
        } else if (progress.status == DownloadStatus.failed) {
          _showMessage('Download failed: ${progress.packId}', isError: true);
        } else if (progress.status == DownloadStatus.cancelled) {
          _downloadProgress[progress.packId] = null;
        }
      });
    });
  }

  Future<void> _downloadPack(String packId) async {
    Logger.info('PACKS', 'Starting download: $packId');

    final packInfo = AppConstants.availablePacks[packId]!;
    final hasSpace = await StorageUtils.hasEnoughSpace(packInfo.sizeInBytes);

    if (!hasSpace) {
      _showMessage(
        'Insufficient storage space (need ${packInfo.formattedSize})',
        isError: true,
      );
      return;
    }

    final result = await _downloader.downloadPack(packId);

    if (!result.success) {
      _showMessage(result.error ?? 'Download failed', isError: true);
    }
  }

  Future<void> _uninstallPack(String packId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Uninstall Pack',
      message: 'Remove ${packId.toUpperCase()} from your device?',
    );

    if (confirmed != true) return;

    Logger.info('PACKS', 'Uninstalling: $packId');

    final success = await StorageUtils.deleteLanguagePack(packId);

    if (success) {
      setState(() {
        _installedPacks[packId] = false;
      });
      _showMessage('${packId.toUpperCase()} uninstalled');
    } else {
      _showMessage('Failed to uninstall pack', isError: true);
    }
  }

  Future<void> _cancelDownload(String packId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Download',
      message: 'Stop downloading ${packId.toUpperCase()}?',
    );

    if (confirmed != true) return;

    final success = await _downloader.cancelDownload(packId);

    if (success) {
      setState(() {
        _downloadProgress[packId] = null;
      });
    }
  }

  Future<void> _pauseDownload(String packId) async {
    Logger.info('PACKS', 'Pausing: $packId');
    final success = await _downloader.pauseDownload(packId);

    if (!success) {
      _showMessage('Failed to pause download', isError: true);
    }
  }

  Future<void> _resumeDownload(String packId) async {
    Logger.info('PACKS', 'Resuming: $packId');
    final result = await _downloader.resumeDownload(packId);

    if (!result.success) {
      _showMessage(result.error ?? 'Resume failed', isError: true);
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Packs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstalledPacks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.getGradientBackground(),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPackList(),
      ),
    );
  }

  Widget _buildPackList() {
    return RefreshIndicator(
      onRefresh: _loadInstalledPacks,
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Language Packs',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Download packs to enable offline translation',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Pack cards
          ...AppConstants.availablePacks.entries.map((entry) {
            final packId = entry.key;
            final packInfo = entry.value;
            final isInstalled = _installedPacks[packId] ?? false;
            final progress = _downloadProgress[packId];

            // Check download status
            final isDownloading = progress != null &&
                progress.status == DownloadStatus.downloading;

            final isPaused = progress != null &&
                progress.status == DownloadStatus.paused;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
              child: LanguagePackCard(
                packId: packId,
                packInfo: packInfo,
                isInstalled: isInstalled,
                isDownloading: isDownloading,
                isPaused: isPaused,
                downloadProgress: progress,
                onDownload: () => _downloadPack(packId),
                onUninstall: () => _uninstallPack(packId),
                onCancelDownload: () => _cancelDownload(packId),
                onPauseDownload: () => _pauseDownload(packId),
                onResumeDownload: () => _resumeDownload(packId),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Storage info
          _buildStorageInfo(),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    return FutureBuilder<int>(
      future: StorageUtils.getTotalPacksSize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final sizeInMB = snapshot.data! / (1024 * 1024);
        final installedCount = _installedPacks.values.where((v) => v).length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                const Icon(
                  Icons.storage,
                  color: AppColors.aquaAccent,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage Used',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$installedCount packs • ${sizeInMB.toStringAsFixed(1)} MB',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}