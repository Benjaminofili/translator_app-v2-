import 'dart:math' as math;

/// 📊 Formatting Utilities
///
/// Helper functions for formatting numbers, time, file sizes, etc.
class FormatUtils {
  FormatUtils._();

  // ═══════════════════════════════════════════════════════════════
  // FILE SIZE FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format bytes to human-readable size (e.g., "1.5 GB", "234 MB")
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);

    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Convert MB to bytes
  static int mbToBytes(double mb) {
    return (mb * 1024 * 1024).round();
  }

  /// Convert bytes to MB
  static double bytesToMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format milliseconds to readable time (e.g., "1.5s", "234ms")
  static String formatDuration(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    }

    final seconds = milliseconds / 1000;
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    }

    final minutes = seconds / 60;
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(1)}m';
    }

    final hours = minutes / 60;
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Format duration from Duration object
  static String formatDurationObject(Duration duration) {
    return formatDuration(duration.inMilliseconds);
  }

  /// Format time remaining (e.g., "2m 30s", "45s")
  static String formatTimeRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Format estimated time of completion
  static String formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.isNegative) return 'Complete';
    if (difference.inSeconds < 60) return 'Less than a minute';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes';

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  // ═══════════════════════════════════════════════════════════════
  // DOWNLOAD SPEED FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format download speed (e.g., "1.5 MB/s", "234 KB/s")
  static String formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }

    final kbps = bytesPerSecond / 1024;
    if (kbps < 1024) {
      return '${kbps.toStringAsFixed(1)} KB/s';
    }

    final mbps = kbps / 1024;
    return '${mbps.toStringAsFixed(2)} MB/s';
  }

  // ═══════════════════════════════════════════════════════════════
  // PERCENTAGE FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format percentage (e.g., "45.5%", "100%")
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Format progress (0.0 to 1.0) as percentage
  static String formatProgress(double progress) {
    final percentage = (progress * 100).clamp(0, 100);
    return '${percentage.toStringAsFixed(0)}%';
  }

  // ═══════════════════════════════════════════════════════════════
  // NUMBER FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format number with thousands separator (e.g., "1,234,567")
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  /// Format decimal number with fixed decimals
  static String formatDecimal(double number, {int decimals = 2}) {
    return number.toStringAsFixed(decimals);
  }

  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE PACK FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format language pair (e.g., "EN → ES", "FR ↔ ES")
  static String formatLanguagePair(String source, String target, {bool bidirectional = true}) {
    final arrow = bidirectional ? '↔' : '→';
    return '${source.toUpperCase()} $arrow ${target.toUpperCase()}';
  }

  /// Format language name with flag emoji (if available)
  static String formatLanguageWithFlag(String languageCode, String languageName) {
    final flags = {
      'en': '🇬🇧',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'zh': '🇨🇳',
    };

    final flag = flags[languageCode.toLowerCase()] ?? '🌍';
    return '$flag $languageName';
  }

  // ═══════════════════════════════════════════════════════════════
  // DATE & TIME FORMATTING
  // ═══════════════════════════════════════════════════════════════

  /// Format date to readable string (e.g., "Oct 25, 2024")
  static String formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Format time to readable string (e.g., "2:30 PM")
  static String formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  /// Format date and time (e.g., "Oct 25, 2024 at 2:30 PM")
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} at ${formatTime(dateTime)}';
  }

  /// Format relative time (e.g., "2 minutes ago", "Just now")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 10) return 'Just now';
    if (difference.inSeconds < 60) return '${difference.inSeconds} seconds ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes} minutes ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';

    return '${(difference.inDays / 365).floor()} years ago';
  }

  // ═══════════════════════════════════════════════════════════════
  // VALIDATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Check if storage space is sufficient
  static bool hasEnoughStorage(int availableBytes, int requiredBytes) {
    return availableBytes >= requiredBytes;
  }

  /// Format storage warning message
  static String formatStorageWarning(int availableBytes, int requiredBytes) {
    final available = formatBytes(availableBytes);
    final required = formatBytes(requiredBytes);
    return 'Insufficient storage: $available available, $required required';
  }
}