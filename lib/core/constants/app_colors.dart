import 'package:flutter/material.dart';

/// 🌊 Refined Liquid AI Color Palette
///
/// Philosophy: Minimal chrome, maximum clarity
/// Accent color reserved for PRIMARY ACTIONS ONLY
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // CORE SURFACES (Reduced to 2 levels for clarity)
  // ═══════════════════════════════════════════════════════════════

  /// Primary background - Most of the app lives here
  static const Color background = Color(0xFF0D0D1F);

  /// Elevated surface - Cards, inputs, raised elements
  /// Lighter than background for subtle depth without heavy shadows
  static const Color surface = Color(0xFF1A1A2E);

  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE-SPECIFIC COLORS (subtle overlays)
  // ═══════════════════════════════════════════════════════════════

  /// English - Cool Blue
  static const Color englishBlue = Color(0xFF4A90E2);

  /// Spanish - Warm Coral
  static const Color spanishCoral = Color(0xFFFF6B6B);

  /// French - Elegant Purple
  static const Color frenchPurple = Color(0xFFA29BFE);

  /// Chinese - Golden Yellow
  static const Color chineseGold = Color(0xFFFEA47F);


  // ═══════════════════════════════════════════════════════════════
  // ACCENT COLORS (Use sparingly - PRIMARY ACTIONS ONLY)
  // ═══════════════════════════════════════════════════════════════

  /// Primary accent - ONLY for main CTA (translate button, download button)
  static const Color accent = Color(0xFF6C5CE7);

  /// Active states - Selected language chips, progress indicators
  static const Color accentLight = Color(0xFF8B7FE8);

  /// Disabled accent - When action is unavailable
  static const Color accentDisabled = Color(0xFF3E3A5C);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC COLORS (Minimal, functional only)
  // ═══════════════════════════════════════════════════════════════

  /// Success - Download complete, translation successful
  static const Color success = Color(0xFF00D9A3);

  /// Error - Network failure, invalid input
  static const Color error = Color(0xFFFF6B6B);

  /// Warning - Low storage, slow connection
  static const Color warning = Color(0xFFFECA57);

  /// Info - Neutral system messages
  static const Color info = Color(0xFF48DBFB);

  // ═══════════════════════════════════════════════════════════════
  // TEXT HIERARCHY (Clear, functional)
  // ═══════════════════════════════════════════════════════════════

  /// Primary text - Translated content, main actions
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - Labels, supporting info
  static const Color textSecondary = Color(0xFFB8B8C8);

  /// Tertiary text - Hints, metadata, timestamps
  static const Color textTertiary = Color(0xFF6C6C7E);

  /// Disabled text
  static const Color textDisabled = Color(0xFF3E3E4E);

  // ═══════════════════════════════════════════════════════════════
  // BORDERS & DIVIDERS (Subtle separation)
  // ═══════════════════════════════════════════════════════════════

  /// Subtle divider - Date separators in history
  static const Color divider = Color(0xFF252540);

  /// Input border - Inactive state
  static const Color borderInactive = Color(0xFF2D2D4A);

  /// Input border - Focus state (uses accent)
  static Color get borderFocus => accent;

  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE-SPECIFIC TINTS (Very subtle, for chips only)
  // ═══════════════════════════════════════════════════════════════

  /// Use at 10-15% opacity as background tint for language chips
  static const Map<String, Color> languageTints = {
    'en': Color(0xFF4A90E2), // Cool blue
    'es': Color(0xFFFF6B6B), // Coral
    'fr': Color(0xFFA29BFE), // Purple
    'zh': Color(0xFFFEA47F), // Gold
  };

  // ═══════════════════════════════════════════════════════════════
  // LOADING STATES (Minimal, functional)
  // ═══════════════════════════════════════════════════════════════

  /// Skeleton loader base
  static const Color skeletonBase = Color(0xFF1A1A2E);

  /// Skeleton loader highlight
  static const Color skeletonHighlight = Color(0xFF252540);

  /// Progress track - Background of progress bars
  static const Color progressTrack = Color(0xFF252540);

  /// Progress indicator - Uses accent color
  static Color get progressIndicator => accent;

  // ═══════════════════════════════════════════════════════════════
  // OVERLAYS & SCRIMS
  // ═══════════════════════════════════════════════════════════════

  /// Modal backdrop
  static const Color scrim = Color(0xCC000000); // 80% opacity

  /// Hover state overlay (for web/desktop)
  static const Color hoverOverlay = Color(0x0AFFFFFF); // 4% white

  /// Press state overlay
  static const Color pressOverlay = Color(0x14FFFFFF); // 8% white

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════
  /// Get language-specific color by language code
  static Color getLanguageColor(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return englishBlue;
      case 'es':
        return spanishCoral;
      case 'fr':
        return frenchPurple;
      case 'zh':
        return chineseGold;
      default:
        return accent; // Fallback to primary color
    }
  }

  /// Get language chip background color
  /// Uses subtle tint at 12% opacity over surface
  static Color getLanguageChipColor(String languageCode, {bool isSelected = false}) {
    if (isSelected) {
      // Selected state: accent at 20% opacity
      return accent.withOpacity(0.2);
    }

    // Default state: language tint at 12% opacity over surface
    final tint = languageTints[languageCode.toLowerCase()] ?? accent;
    return Color.alphaBlend(tint.withOpacity(0.12), surface);
  }

  /// Get language chip border color
  static Color getLanguageChipBorder(String languageCode, {bool isSelected = false}) {
    if (isSelected) {
      return accent;
    }

    final tint = languageTints[languageCode.toLowerCase()] ?? accent;
    return tint.withOpacity(0.3);
  }

  /// Get download state color
  static Color getDownloadStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'downloaded':
      case 'complete':
        return success;
      case 'downloading':
      case 'in_progress':
        return accent;
      case 'failed':
      case 'error':
        return error;
      case 'paused':
        return warning;
      default:
        return textSecondary;
    }
  }

  /// Shimmer gradient for loading states
  static List<Color> get shimmerGradient => [
    skeletonBase,
    skeletonHighlight,
    skeletonBase,
  ];
}