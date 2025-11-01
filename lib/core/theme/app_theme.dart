import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// 🎨 Refined App Theme
///
/// Philosophy: Minimal chrome, maximum efficiency
/// Accent color reserved for PRIMARY ACTIONS ONLY
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ═══════════════════════════════════════════════════════════
      // COLOR SCHEME - Minimal, functional
      // ═══════════════════════════════════════════════════════════
      colorScheme: ColorScheme.dark(
        // Primary accent - ONLY for main CTAs
        primary: AppColors.accent,
        secondary: AppColors.accentLight,

        // Surfaces - Only 2 levels
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.background,

        // Semantic colors
        error: AppColors.error,

        // On-colors (text on surfaces)
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // ═══════════════════════════════════════════════════════════
      // APP BAR - Minimal, borderless
      // ═══════════════════════════════════════════════════════════
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0, // No shadow on scroll
        centerTitle: false, // Left-aligned like Google
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500, // Medium weight, not bold
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // CARDS - Minimal elevation, no glow
      // ═══════════════════════════════════════════════════════════
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // Flat design
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        margin: EdgeInsets.zero, // Control margins explicitly per use
      ),

      // ═══════════════════════════════════════════════════════════
      // BUTTONS - Accent ONLY for primary actions
      // ═══════════════════════════════════════════════════════════

      // Primary action button (Translate, Download)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0, // Flat
          shadowColor: Colors.transparent,
          disabledBackgroundColor: AppColors.accentDisabled,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Secondary/tertiary actions (Clear, Edit, etc.)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          disabledForegroundColor: AppColors.textDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Icon buttons (mic, swap, play, copy)
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          // No background color - icons float on surface
        ),
      ),

      // FAB - Only if needed (Google rarely uses FABs)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4, // Slight elevation for FAB only
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // INPUT FIELDS - Clean, minimal borders
      // ═══════════════════════════════════════════════════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,

        // Default border - subtle
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.borderInactive,
            width: 1,
          ),
        ),

        // Enabled border - same as default
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.borderInactive,
            width: 1,
          ),
        ),

        // Focused border - accent color
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.accent,
            width: 2,
          ),
        ),

        // Error border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),

        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // PROGRESS INDICATORS - Accent color only
      // ═══════════════════════════════════════════════════════════
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),

      // ═══════════════════════════════════════════════════════════
      // CHIPS - Low visual weight
      // ═══════════════════════════════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accent.withOpacity(0.2),
        disabledColor: AppColors.surface.withOpacity(0.5),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.borderInactive,
            width: 1,
          ),
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // DIVIDERS - Subtle
      // ═══════════════════════════════════════════════════════════
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ═══════════════════════════════════════════════════════════
      // ICONS - Primary text color by default
      // ═══════════════════════════════════════════════════════════
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // ═══════════════════════════════════════════════════════════
      // TEXT THEME - Clear hierarchy
      // ═══════════════════════════════════════════════════════════
      textTheme: const TextTheme(
        // Large titles (screen headers)
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400, // Regular weight
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),

        // Section headers
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),

        // Card titles, list titles
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0,
        ),

        // List item titles
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.15,
        ),

        // Small labels
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),

        // Body text - translated content
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
          height: 1.5, // Good line height for readability
        ),

        // Secondary body text
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.25,
          height: 1.43,
        ),

        // Tertiary text (timestamps, hints)
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
          letterSpacing: 0.4,
          height: 1.33,
        ),

        // Button text
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),

        // Chip text, small buttons
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS - Removed heavy decorations
  // ═══════════════════════════════════════════════════════════════

  /// Simple card decoration (no glow)
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      border: Border.all(
        color: AppColors.divider,
        width: 1,
      ),
    );
  }

  /// Language chip decoration
  static BoxDecoration getLanguageChipDecoration(
      String languageCode, {
        bool isSelected = false,
      }) {
    return BoxDecoration(
      color: AppColors.getLanguageChipColor(languageCode, isSelected: isSelected),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: AppColors.getLanguageChipBorder(languageCode, isSelected: isSelected),
        width: 1,
      ),
    );
  }

  /// Shimmer gradient (unchanged - needed for loading)
  static LinearGradient getShimmerGradient() {
    return LinearGradient(
      begin: const Alignment(-1.0, 0.0),
      end: const Alignment(1.0, 0.0),
      colors: AppColors.shimmerGradient,
      stops: const [0.0, 0.5, 1.0],
    );
  }
}