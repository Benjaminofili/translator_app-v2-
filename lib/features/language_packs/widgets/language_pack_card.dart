import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../services/pack_downloader.dart';
import 'download_progress_indicator.dart';

/// 🎴 Language Pack Card
///
/// Beautiful card showing pack info with download/uninstall actions
class LanguagePackCard extends StatelessWidget {
  final String packId;
  final LanguagePackInfo packInfo;
  final bool isInstalled;
  final bool isDownloading;
  final bool isPaused;
  final DownloadProgress? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onUninstall;
  final VoidCallback onCancelDownload;
  final VoidCallback onPauseDownload;
  final VoidCallback onResumeDownload;

  const LanguagePackCard({
    super.key,
    required this.packId,
    required this.packInfo,
    required this.isInstalled,
    required this.isDownloading,
    required this.isPaused,
    this.downloadProgress,
    required this.onDownload,
    required this.onUninstall,
    required this.onCancelDownload,
    required this.onPauseDownload,
    required this.onResumeDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isInstalled ? 6 : 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          gradient: isInstalled
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceCard,
              AppColors.getLanguageColor(packInfo.sourceLanguage)
                  .withValues(alpha: 0.1),
            ],
          )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Language flags
                  _buildLanguageIcons(),

                  const SizedBox(width: 16),

                  // Pack info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          packInfo.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          packInfo.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  _buildStatusBadge(context),
                ],
              ),

              // Download progress (if downloading or paused)
              if ((isDownloading || isPaused) && downloadProgress != null) ...[
                const SizedBox(height: 16),
                DownloadProgressIndicator(progress: downloadProgress!),
              ],

              // Action buttons
              const SizedBox(height: 16),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Language flag icons
  Widget _buildLanguageIcons() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.getLanguageColor(packInfo.sourceLanguage).withValues(alpha: 0.3),
            AppColors.getLanguageColor(packInfo.targetLanguage).withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Center(
        child: Text(
          FormatUtils.formatLanguagePair(
            packInfo.sourceLanguage,
            packInfo.targetLanguage,
            bidirectional: true,
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Status badge (installed/downloading/paused)
  Widget _buildStatusBadge(BuildContext context) {
    if (isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.aquaAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.aquaAccent),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              downloadProgress?.statusText ?? 'Loading',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.aquaAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (isPaused) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle,
              size: 14,
              color: AppColors.warning,
            ),
            const SizedBox(width: 4),
            Text(
              'Paused',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (isInstalled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              'Installed',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Action buttons (download/uninstall/pause/resume/cancel)
  /// Action buttons (download/uninstall/pause/resume/cancel)
  Widget _buildActionButtons(BuildContext context) {
    if (isDownloading) {
      return Row(
        children: [
          // Pause button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPauseDownload,
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Pause'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warning,
                side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancelDownload,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ],
      );
    }

    if (isPaused) {
      return Row(
        children: [
          // Resume button (larger)
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              onPressed: onResumeDownload,
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Cancel button (smaller)
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: onCancelDownload,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      );
    }

    if (isInstalled) {
      return OutlinedButton.icon(
        onPressed: onUninstall,
        icon: const Icon(Icons.delete_outline),
        label: const Text('Uninstall'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download),
      label: Text('Download (${packInfo.formattedSize})'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}