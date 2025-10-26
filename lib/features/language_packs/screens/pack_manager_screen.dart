// lib/features/packs/pack_manager_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../services/pack_downloader.dart';

/// 📦 Language Pack Manager Screen
///
/// Displays available language packs and handles download/installation
class PackManagerScreen extends StatefulWidget {
  const PackManagerScreen({super.key});

  @override
  State<PackManagerScreen> createState() => _PackManagerScreenState();
}

class _PackManagerScreenState extends State<PackManagerScreen> {
  final PackDownloader _downloader = PackDownloader();

  // Track installation status
  Map<String, bool> _installedPacks = {};

  // Track download progress
  Map<String, DownloadProgress> _downloadProgress = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledPacks();
    _listenToDownloadProgress();
  }

  /// Load list of installed packs
  Future<void> _loadInstalledPacks() async {
    setState(() => _isLoading = true);

    try {
      final installed = await StorageUtils.getInstalledPacks();

      setState(() {
        _installedPacks = {
          for (var packId in AppConstants.availablePacks.keys)
            packId: installed.contains(packId)
        };
        _isLoading = false;
      });

      Logger.info('PACKS', 'Loaded ${installed.length} installed packs');
    } catch (e) {
      Logger.error('PACKS', 'Failed to load installed packs', e);
      setState(() => _isLoading = false);
    }
  }

  /// Listen to download progress stream
  void _listenToDownloadProgress() {
    _downloader.progressStream.listen((progress) {
      setState(() {
        _downloadProgress[progress.packId] = progress;

        // Update installation status when complete
        if (progress.status == DownloadStatus.completed) {
          _installedPacks[progress.packId] = true;
          // Remove from progress after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _downloadProgress.remove(progress.packId);
              });
            }
          });
        }
      });
    });
  }

  /// Download a language pack
  Future<void> _downloadPack(String packId, LanguagePackInfo packInfo) async {
    // Check if already downloading
    if (_downloader.isDownloading(packId)) {
      _showSnackBar('Pack is already downloading', isError: false);
      return;
    }

    // Check storage space
    final hasSpace = await StorageUtils.hasEnoughSpace(packInfo.sizeInBytes);
    if (!hasSpace) {
      _showSnackBar('Not enough storage space', isError: true);
      return;
    }

    // Show confirmation dialog
    final confirm = await _showDownloadConfirmation(packInfo);
    if (confirm != true) return;

    // Start download
    Logger.info('PACKS', 'Starting download: $packId');

    final result = await _downloader.downloadPack(packId);

    if (result.success) {
      _showSnackBar('${packInfo.name} installed successfully!', isError: false);
      await _loadInstalledPacks(); // Refresh list
    } else {
      _showSnackBar(result.error ?? 'Download failed', isError: true);
    }
  }

  /// Delete a language pack
  Future<void> _deletePack(String packId, LanguagePackInfo packInfo) async {
    final confirm = await _showDeleteConfirmation(packInfo);
    if (confirm != true) return;

    try {
      final success = await StorageUtils.deleteLanguagePack(packId);

      if (success) {
        setState(() {
          _installedPacks[packId] = false;
        });
        _showSnackBar('${packInfo.name} deleted', isError: false);
        Logger.success('PACKS', 'Deleted pack: $packId');
      } else {
        _showSnackBar('Failed to delete pack', isError: true);
      }
    } catch (e) {
      Logger.error('PACKS', 'Delete failed', e);
      _showSnackBar('Error deleting pack', isError: true);
    }
  }

  /// Show download confirmation dialog
  Future<bool?> _showDownloadConfirmation(LanguagePackInfo packInfo) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        title: const Text('Download Language Pack?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(packInfo.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Size: ${packInfo.formattedSize}'),
            const SizedBox(height: 8),
            Text(
              'This will download ${packInfo.formattedSize} of data. Continue?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmation(LanguagePackInfo packInfo) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        title: const Text('Delete Language Pack?'),
        content: Text(
          'Delete ${packInfo.name}? This will free up ${packInfo.formattedSize}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Show snackbar message
  void _showSnackBar(String message, {required bool isError}) {
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.gradientBackground,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadInstalledPacks,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: AppConstants.availablePacks.length,
            itemBuilder: (context, index) {
              final entry = AppConstants.availablePacks.entries.elementAt(index);
              final packId = entry.key;
              final packInfo = entry.value;
              final isInstalled = _installedPacks[packId] ?? false;
              final progress = _downloadProgress[packId];

              return _buildPackCard(
                packId: packId,
                packInfo: packInfo,
                isInstalled: isInstalled,
                progress: progress,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPackCard({
    required String packId,
    required LanguagePackInfo packInfo,
    required bool isInstalled,
    DownloadProgress? progress,
  }) {
    final isDownloading = progress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isInstalled
              ? AppColors.success
              : AppColors.electricPurple.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isInstalled ? AppColors.success : AppColors.electricPurple)
                .withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Language icons
                _buildLanguageIcon(packInfo.sourceLanguage),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 8),
                _buildLanguageIcon(packInfo.targetLanguage),
                const Spacer(),
                // Status badge
                _buildStatusBadge(isInstalled),
              ],
            ),

            const SizedBox(height: 12),

            // Pack name
            Text(
              packInfo.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 4),

            // Pack size
            Text(
              packInfo.formattedSize,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            // Progress bar if downloading
            if (isDownloading) ...[
              const SizedBox(height: 16),
              _buildProgressSection(progress!),
            ],

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(packId, packInfo, isInstalled, isDownloading),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageIcon(String languageCode) {
    final color = AppColors.getLanguageColor(languageCode);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          languageCode.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isInstalled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isInstalled
            ? AppColors.success.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInstalled ? AppColors.success : AppColors.textTertiary,
        ),
      ),
      child: Text(
        isInstalled ? 'INSTALLED' : 'NOT INSTALLED',
        style: TextStyle(
          color: isInstalled ? AppColors.success : AppColors.textTertiary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressSection(DownloadProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress percentage and speed
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              progress.statusText,
              style: TextStyle(
                color: AppColors.electricPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (progress.bytesPerSecond != null)
              Text(
                FormatUtils.formatSpeed(progress.bytesPerSecond!),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.progress,
            backgroundColor: AppColors.shimmerBase,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.electricPurple,
            ),
            minHeight: 8,
          ),
        ),

        const SizedBox(height: 4),

        // Downloaded / Total
        Text(
          '${FormatUtils.formatBytes(progress.downloadedBytes)} / ${FormatUtils.formatBytes(progress.totalBytes)}',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      String packId,
      LanguagePackInfo packInfo,
      bool isInstalled,
      bool isDownloading,
      ) {
    if (isDownloading) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.electricPurple.withOpacity(0.3),
            disabledBackgroundColor: AppColors.electricPurple.withOpacity(0.3),
          ),
          child: const Text('Downloading...'),
        ),
      );
    }

    if (isInstalled) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Installed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success.withOpacity(0.2),
                foregroundColor: AppColors.success,
                disabledBackgroundColor: AppColors.success.withOpacity(0.2),
                disabledForegroundColor: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _deletePack(packId, packInfo),
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.1),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _downloadPack(packId, packInfo),
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      ),
    );
  }

  @override
  void dispose() {
    _downloader.dispose();
    super.dispose();
  }
}