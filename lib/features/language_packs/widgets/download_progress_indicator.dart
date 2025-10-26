import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../services/pack_downloader.dart';

/// 📊 Download Progress Indicator
/// 
/// Beautiful animated progress bar with stats
class DownloadProgressIndicator extends StatelessWidget {
  final DownloadProgress progress;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            tween: Tween(begin: 0.0, end: progress.progress),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.shimmerBase,
                valueColor: AlwaysStoppedAnimation(
                  _getProgressColor(progress.status),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Progress percentage
            Text(
              '${progress.progressPercent}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _getProgressColor(progress.status),
                fontWeight: FontWeight.w600,
              ),
            ),

            // Download speed and ETA
            if (progress.status == DownloadStatus.downloading &&
                progress.bytesPerSecond != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    FormatUtils.formatSpeed(progress.bytesPerSecond!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  if (progress.estimatedTimeRemaining != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      FormatUtils.formatTimeRemaining(
                        progress.estimatedTimeRemaining!,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Downloaded size
        Text(
          '${FormatUtils.formatBytes(progress.downloadedBytes)} / ${FormatUtils.formatBytes(progress.totalBytes)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Get color based on download status
  Color _getProgressColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.aquaAccent;
      case DownloadStatus.paused:
        return AppColors.warning;
      case DownloadStatus.extracting:
        return AppColors.electricPurple;
      case DownloadStatus.verifying:
        return AppColors.success;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.error;
      case DownloadStatus.cancelled:
        return AppColors.textTertiary;
    }
  }
}