import 'package:flutter/material.dart';

/// 🌊 Liquid AI Color Palette
/// 
/// Theme: Translation as flowing water - adaptive, universal, transformative
/// Design System: Dark-first with vibrant accents and language-specific tints
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // CORE LIQUID COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Deep Ocean - Primary background
  static const Color deepOcean = Color(0xFF0D0D1F);
  
  /// Midnight Blue - Surface color (cards, containers)
  static const Color midnightBlue = Color(0xFF1A1A2E);
  
  /// Electric Purple - Primary action color
  static const Color electricPurple = Color(0xFF6C5CE7);
  
  /// Deep Electric Purple - Darker variant for gradients
  static const Color deepElectricPurple = Color(0xFF4834D4);
  
  /// Aqua Accent - Active states, highlights
  static const Color aquaAccent = Color(0xFF00D9FF);
  
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
  // SEMANTIC COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Success states (downloads complete, translation success)
  static const Color success = Color(0xFF00D9A3);
  
  /// Error states (network errors, translation failures)
  static const Color error = Color(0xFFFF6B6B);
  
  /// Warning states (low storage, slow connection)
  static const Color warning = Color(0xFFFECA57);
  
  /// Info states (tips, onboarding)
  static const Color info = Color(0xFF48DBFB);
  
  // ═══════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Primary text - High emphasis
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Secondary text - Medium emphasis
  static const Color textSecondary = Color(0xFFB8B8C8);
  
  /// Tertiary text - Low emphasis (hints, placeholders)
  static const Color textTertiary = Color(0xFF6C6C7E);
  
  /// Disabled text
  static const Color textDisabled = Color(0xFF3E3E4E);
  
  // ═══════════════════════════════════════════════════════════════
  // SURFACE & OVERLAY COLORS
  // ═══════════════════════════════════════════════════════════════
  
  /// Card surface - Elevated containers
  static const Color surfaceCard = Color(0xFF252540);
  
  /// Modal overlay - Semi-transparent backdrop
  static const Color overlay = Color(0x80000000);
  
  /// Shimmer/loading effect base
  static const Color shimmerBase = Color(0xFF1A1A2E);
  
  /// Shimmer/loading effect highlight
  static const Color shimmerHighlight = Color(0xFF2D2D4A);
  
  // ═══════════════════════════════════════════════════════════════
  // GRADIENTS (as color lists for easy use)
  // ═══════════════════════════════════════════════════════════════
  
  /// Primary gradient - Electric Purple flow
  static const List<Color> gradientPrimary = [
    electricPurple,
    deepElectricPurple,
  ];
  
  /// Aqua gradient - Active state flow
  static const List<Color> gradientAqua = [
    aquaAccent,
    Color(0xFF00B8D4),
  ];
  
  /// Background gradient - Subtle depth
  static const List<Color> gradientBackground = [
    deepOcean,
    Color(0xFF16162A),
  ];
  
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
        return electricPurple; // Fallback to primary color
    }
  }
  
  /// Get language color with opacity
  static Color getLanguageColorWithOpacity(String languageCode, double opacity) {
    return getLanguageColor(languageCode).withOpacity(opacity);
  }
  
  /// Create a gradient for a specific language
  static List<Color> getLanguageGradient(String languageCode) {
    final baseColor = getLanguageColor(languageCode);
    return [
      baseColor,
      baseColor.withOpacity(0.6),
    ];
  }
  
  /// Liquid shimmer colors for loading states
  static List<Color> get shimmerColors => [
    shimmerBase,
    shimmerHighlight,
    shimmerBase,
  ];
}
