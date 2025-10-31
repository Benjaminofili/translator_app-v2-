import 'package:flutter/material.dart';
import '../utils/animation_utils.dart';

/// 🌊 Transition Manager
/// Central place to define page transitions across the app
class TransitionManager {
  TransitionManager._();

  /// Default liquid slide (from right)
  static Route liquidSlide(Widget page, {bool fromRight = true}) {
    return PageRouteBuilder(
      transitionDuration: AnimationUtils.mediumDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return AnimationUtils.buildLiquidSlideTransition(
          animation: animation,
          child: child,
          slideFromRight: fromRight,
        );
      },
    );
  }

  /// Fade + scale (good for modals, onboarding)
  static Route fadeScale(Widget page, {double initialScale = 0.9}) {
    return PageRouteBuilder(
      transitionDuration: AnimationUtils.mediumDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return AnimationUtils.buildFadeScaleTransition(
          animation: animation,
          child: child,
          initialScale: initialScale,
        );
      },
    );
  }

  /// Simple fade (clean, minimal)
  static Route fade(Widget page) {
    return PageRouteBuilder(
      transitionDuration: AnimationUtils.smallDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: AnimationUtils.fadeIn().animate(animation),
          child: child,
        );
      },
    );
  }

  /// Slide from bottom (like a sheet)
  static Route slideFromBottom(Widget page) {
    return PageRouteBuilder(
      transitionDuration: AnimationUtils.mediumDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: AnimationUtils.slideInFromBottom().animate(animation),
          child: child,
        );
      },
    );
  }
}