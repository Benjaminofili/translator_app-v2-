import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../services/pack_downloader.dart';
import '../widgets/language_pack_card.dart';

/// 📦 Language Pack Management Screen - Google-style minimal
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
          _showMessage('${_getPackDisplayName(progress.packId)} ready to use');
        } else if (progress.status == DownloadStatus.failed) {
          _showMessage('Download failed', isError: true);
        } else if (progress.status == DownloadStatus.cancelled) {
          _downloadProgress[progress.packId] = null;
        }
      });
    });
  }

  String _getPackDisplayName(String packId) {
    return AppConstants.availablePacks[packId]?.name ?? packId;
  }

  Future<void> _downloadPack(String packId) async {
    Logger.info('PACKS', 'Starting download: $packId');

    final packInfo = AppConstants.availablePacks[packId]!;
    final hasSpace = await StorageUtils.hasEnoughSpace(packInfo.sizeInBytes);

    if (!hasSpace) {
      _showMessage(
        'Need ${packInfo.formattedSize} free space',
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
    final packName = _getPackDisplayName(packId);

    final confirmed = await _showConfirmDialog(
      title: 'Remove language pack?',
      message: '$packName will be deleted from your device.',
      confirmText: 'Remove',
      isDestructive: true,
    );

    if (confirmed != true) return;

    Logger.info('PACKS', 'Uninstalling: $packId');

    final success = await StorageUtils.deleteLanguagePack(packId);

    if (success) {
      setState(() {
        _installedPacks[packId] = false;
      });
      _showMessage('$packName removed');
    } else {
      _showMessage('Failed to remove pack', isError: true);
    }
  }

  Future<void> _cancelDownload(String packId) async {
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
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.accent,
            ),
            child: Text(confirmText),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline languages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInstalledPacks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPackList(),
    );
  }

  Widget _buildPackList() {
    // Separate downloaded and available packs
    final downloadedPacks = <String>[];
    final availablePacks = <String>[];

    for (final packId in AppConstants.availablePacks.keys) {
      final isInstalled = _installedPacks[packId] ?? false;
      final progress = _downloadProgress[packId];
      final isActive = progress != null &&
          (progress.status == DownloadStatus.downloading ||
              progress.status == DownloadStatus.paused);

      if (isInstalled || isActive) {
        downloadedPacks.add(packId);
      } else {
        availablePacks.add(packId);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Downloaded section
        if (downloadedPacks.isNotEmpty) ...[
          _buildSectionHeader('Downloaded', downloadedPacks.length),
          const SizedBox(height: 12),
          ...downloadedPacks.map((packId) => _buildPackCard(packId)),
          const SizedBox(height: 24),
        ],

        // Available section
        if (availablePacks.isNotEmpty) ...[
          _buildSectionHeader('Available', availablePacks.length),
          const SizedBox(height: 12),
          ...availablePacks.map((packId) => _buildPackCard(packId)),
        ],

        // Storage info at bottom
        const SizedBox(height: 24),
        _buildStorageInfo(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(String packId) {
    final packInfo = AppConstants.availablePacks[packId]!;
    final isInstalled = _installedPacks[packId] ?? false;
    final progress = _downloadProgress[packId];

    final isDownloading = progress != null &&
        progress.status == DownloadStatus.downloading;

    final isPaused = progress != null &&
        progress.status == DownloadStatus.paused;

    return LanguagePackCard(
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
    );
  }

  Widget _buildStorageInfo() {
    return FutureBuilder<int>(
      future: StorageUtils.getTotalPacksSize(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final sizeInMB = snapshot.data! / (1024 * 1024);
        final installedCount = _installedPacks.values.where((v) => v).length;

        if (installedCount == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.storage_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                '$installedCount ${installedCount == 1 ? 'pack' : 'packs'} • ${sizeInMB.toStringAsFixed(0)} MB',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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