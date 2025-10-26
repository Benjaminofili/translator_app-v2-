/// 🌍 App-wide Constants
///
/// Central place for all constant values used across the app
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ═══════════════════════════════════════════════════════════════
  // APP INFORMATION
  // ═══════════════════════════════════════════════════════════════

  static const String appName = 'Voice Translator';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Offline real-time voice translation';

  // ═══════════════════════════════════════════════════════════════
  // GITHUB RELEASE & PACK URLS
  // ═══════════════════════════════════════════════════════════════

  static const String githubRepo = 'Benjaminofili/translator_app_packs';
  static const String releaseVersion = 'v1.1.0';
  static const String baseDownloadUrl =
      'https://github.com/$githubRepo/releases/download/$releaseVersion/';

  /// Catalog JSON URL for discovering available packs
  static const String catalogUrl = '${baseDownloadUrl}catalog.json';

  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE PACK INFORMATION
  // ═══════════════════════════════════════════════════════════════

  /// Available language packs with their sizes
  static const Map<String, LanguagePackInfo> availablePacks = {
    'en-es': LanguagePackInfo(
      id: 'en-es',
      name: 'English ↔ Spanish',
      sourceLanguage: 'en',
      targetLanguage: 'es',
      sizeInMB: 444,
      fileName: 'en-es-v1.1.0.zip',
    ),
    'en-fr': LanguagePackInfo(
      id: 'en-fr',
      name: 'English ↔ French',
      sourceLanguage: 'en',
      targetLanguage: 'fr',
      sizeInMB: 433,
      fileName: 'en-fr-v1.1.0.zip',
    ),
    'en-zh': LanguagePackInfo(
      id: 'en-zh',
      name: 'English ↔ Chinese',
      sourceLanguage: 'en',
      targetLanguage: 'zh',
      sizeInMB: 444,
      fileName: 'en-zh-v1.1.0.zip',
    ),
    'fr-es': LanguagePackInfo(
      id: 'fr-es',
      name: 'French ↔ Spanish',
      sourceLanguage: 'fr',
      targetLanguage: 'es',
      sizeInMB: 513,
      fileName: 'fr-es-v1.1.0.zip',
    ),
  };

  /// Language display names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'zh': 'Chinese',
  };

  /// Language native names (for better UX)
  static const Map<String, String> languageNativeNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'zh': '中文',
  };

  // ═══════════════════════════════════════════════════════════════
  // ANIMATION DURATIONS (in milliseconds)
  // ═══════════════════════════════════════════════════════════════

  /// Micro interactions (button press)
  static const int microDuration = 200;

  /// Small animations (card flip)
  static const int smallDuration = 400;

  /// Medium animations (page transition)
  static const int mediumDuration = 600;

  /// Large animations (voice visualization)
  static const int largeDuration = 1000;

  /// Liquid morphing translation duration
  static const int liquidMorphDuration = 1400;

  // ═══════════════════════════════════════════════════════════════
  // ANIMATION PHYSICS
  // ═══════════════════════════════════════════════════════════════

  /// Spring damping (iOS-style feel)
  static const double springDamping = 0.7;

  /// Spring stiffness
  static const double springStiffness = 120.0;

  /// Spring mass
  static const double springMass = 1.0;

  // ═══════════════════════════════════════════════════════════════
  // VOICE VISUALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Number of concurrent ripple rings
  static const int voiceRippleCount = 5;

  /// Ripple lifespan in seconds
  static const double rippleLifespan = 1.6;

  /// Minimum ripple radius
  static const double minRippleRadius = 60.0;

  /// Maximum ripple radius
  static const double maxRippleRadius = 200.0;

  // ═══════════════════════════════════════════════════════════════
  // AUDIO SETTINGS
  // ═══════════════════════════════════════════════════════════════

  /// Default audio playback speed
  static const double defaultPlaybackSpeed = 1.0;

  /// Minimum playback speed
  static const double minPlaybackSpeed = 0.5;

  /// Maximum playback speed
  static const double maxPlaybackSpeed = 2.0;

  /// Default audio volume
  static const double defaultVolume = 0.8;

  // ═══════════════════════════════════════════════════════════════
  // FILE & STORAGE
  // ═══════════════════════════════════════════════════════════════

  /// Directory name for storing models
  static const String modelsDirectory = 'translator_models';

  /// Directory name for storing audio files
  static const String audioDirectory = 'translated_audio';

  /// Maximum conversation history to keep
  static const int maxConversationHistory = 100;

  /// Auto-delete audio files older than (days)
  static const int audioRetentionDays = 7;

  // ═══════════════════════════════════════════════════════════════
  // NETWORK & DOWNLOAD
  // ═══════════════════════════════════════════════════════════════

  /// Download timeout in seconds
  static const int downloadTimeoutSeconds = 300; // 5 minutes

  /// Connection timeout in seconds
  static const int connectionTimeoutSeconds = 30;

  /// Retry attempts for failed downloads
  static const int maxRetryAttempts = 3;

  /// Chunk size for download progress updates (bytes)
  static const int downloadChunkSize = 8192; // 8 KB

  // ═══════════════════════════════════════════════════════════════
  // UI DIMENSIONS
  // ═══════════════════════════════════════════════════════════════

  /// Standard padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  /// Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  /// Mic button size
  static const double micButtonSize = 80.0;

  /// Language card height
  static const double languageCardHeight = 120.0;

  // ═══════════════════════════════════════════════════════════════
  // PERFORMANCE THRESHOLDS
  // ═══════════════════════════════════════════════════════════════

  /// Translation time warning threshold (ms)
  static const int slowTranslationThreshold = 1000;

  /// Low storage warning threshold (MB)
  static const double lowStorageThreshold = 500.0;

  /// Minimum required storage for pack download (MB)
  static const double minStorageForDownload = 1000.0;
}

// ═══════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════

/// Information about a language pack
class LanguagePackInfo {
  final String id;
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final double sizeInMB;
  final String fileName;

  const LanguagePackInfo({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sizeInMB,
    required this.fileName,
  });

  /// Get download URL for this pack
  String get downloadUrl => '${AppConstants.baseDownloadUrl}$fileName';

  /// Get size in bytes
  int get sizeInBytes => (sizeInMB * 1024 * 1024).round();

  /// Get formatted size string
  String get formattedSize => '${sizeInMB.toStringAsFixed(1)} MB';

  /// Get both language codes as a list
  List<String> get languageCodes => [sourceLanguage, targetLanguage];

  /// Check if this pack contains a specific language
  bool containsLanguage(String languageCode) {
    return sourceLanguage == languageCode || targetLanguage == languageCode;
  }
}