import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../services/pack_downloader.dart';

/// 📊 Download Progress Indicator - Minimal, functional
///
/// Simple progress bar with essential info only
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
        // Progress bar (minimal, 4px height)
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            tween: Tween(begin: 0.0, end: progress.progress),
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppColors.progressTrack,
                valueColor: AlwaysStoppedAnimation(
                  _getProgressColor(progress.status),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Single line of essential info
        Row(
          children: [
            // Progress percentage
            Text(
              '${progress.progressPercent}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(width: 12),

            // Downloaded / Total
            Expanded(
              child: Text(
                '${FormatUtils.formatBytes(progress.downloadedBytes)} / ${FormatUtils.formatBytes(progress.totalBytes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            // Speed (only when actively downloading)
            if (progress.status == DownloadStatus.downloading &&
                progress.bytesPerSecond != null &&
                progress.bytesPerSecond! > 0)
              Text(
                FormatUtils.formatSpeed(progress.bytesPerSecond!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Get color based on download status
  Color _getProgressColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return AppColors.accent;
      case DownloadStatus.paused:
        return AppColors.warning;
      case DownloadStatus.extracting:
        return AppColors.accent;
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