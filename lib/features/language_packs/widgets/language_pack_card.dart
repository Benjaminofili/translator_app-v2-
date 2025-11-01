import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/pack_downloader.dart';
import 'download_progress_indicator.dart';

/// 🎴 Language Pack Card - Minimal, Google-style
///
/// Clean card with clear hierarchy and single accent color
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isInstalled ? null : onDownload,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Language pair + status
              Row(
                children: [
                  // Language pair (text only, no decorative icons)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language names
                        Text(
                          packInfo.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),

                        // Size + status in one line
                        Row(
                          children: [
                            Text(
                              packInfo.formattedSize,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                            // Status indicator (compact)
                            if (isInstalled || isDownloading || isPaused) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.textTertiary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              _buildCompactStatus(context),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status icon (minimal)
                  if (isInstalled && !isDownloading && !isPaused)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),

              // Download progress (if active)
              if ((isDownloading || isPaused) && downloadProgress != null) ...[
                const SizedBox(height: 16),
                DownloadProgressIndicator(progress: downloadProgress!),
              ],

              // Action buttons (only show if not in default state)
              if (isInstalled || isDownloading || isPaused) ...[
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Compact status text (minimal)
  Widget _buildCompactStatus(BuildContext context) {
    String statusText;
    Color statusColor;

    if (isDownloading) {
      statusText = 'Downloading';
      statusColor = AppColors.textSecondary;
    } else if (isPaused) {
      statusText = 'Paused';
      statusColor = AppColors.warning;
    } else if (isInstalled) {
      statusText = 'Downloaded';
      statusColor = AppColors.success;
    } else {
      return const SizedBox.shrink();
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: statusColor,
      ),
    );
  }

  /// Action buttons with clear hierarchy
  Widget _buildActionButtons(BuildContext context) {
    // Downloading state: Pause + Cancel (secondary actions)
    if (isDownloading) {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onPauseDownload,
              icon: const Icon(Icons.pause, size: 18),
              label: const Text('Pause'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton.icon(
              onPressed: onCancelDownload,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      );
    }

    // Paused state: Resume (primary) + Cancel (secondary)
    if (isPaused) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: onResumeDownload,
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Resume'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextButton(
              onPressed: onCancelDownload,
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      );
    }

    // Installed state: Remove (destructive, but not primary)
    if (isInstalled) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onUninstall,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Remove'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textTertiary,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}