import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

/// 🎬 Animation Utilities
/// 
/// Helper functions and curves for smooth, liquid animations
class AnimationUtils {
  AnimationUtils._();

  // ═══════════════════════════════════════════════════════════════
  // CUSTOM CURVES
  // ═══════════════════════════════════════════════════════════════
  
  /// Liquid flow curve - smooth, water-like motion
  static const Curve liquidFlow = Curves.easeInOutCubicEmphasized;
  
  /// Spring curve - iOS-style bounce
  static const Curve spring = Curves.elasticOut;
  
  /// Gentle entrance
  static const Curve gentleIn = Curves.easeOutCubic;
  
  /// Gentle exit
  static const Curve gentleOut = Curves.easeInCubic;
  
  /// Smooth transition
  static const Curve smooth = Curves.easeInOutCubic;
  
  // ═══════════════════════════════════════════════════════════════
  // DURATION HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Micro animation duration (button press)
  static Duration get microDuration => 
      Duration(milliseconds: AppConstants.microDuration);
  
  /// Small animation duration (card flip)
  static Duration get smallDuration => 
      Duration(milliseconds: AppConstants.smallDuration);
  
  /// Medium animation duration (page transition)
  static Duration get mediumDuration => 
      Duration(milliseconds: AppConstants.mediumDuration);
  
  /// Large animation duration (voice visualization)
  static Duration get largeDuration => 
      Duration(milliseconds: AppConstants.largeDuration);
  
  /// Liquid morph duration (text transformation)
  static Duration get liquidMorphDuration => 
      Duration(milliseconds: AppConstants.liquidMorphDuration);
  
  // ═══════════════════════════════════════════════════════════════
  // TWEEN HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Create a fade-in tween
  static Tween<double> fadeIn() => Tween<double>(begin: 0.0, end: 1.0);
  
  /// Create a fade-out tween
  static Tween<double> fadeOut() => Tween<double>(begin: 1.0, end: 0.0);
  
  /// Create a scale-up tween
  static Tween<double> scaleUp({double from = 0.0, double to = 1.0}) => 
      Tween<double>(begin: from, end: to);
  
  /// Create a scale-down tween
  static Tween<double> scaleDown({double from = 1.0, double to = 0.0}) => 
      Tween<double>(begin: from, end: to);
  
  /// Create a slide-in tween (from bottom)
  static Tween<Offset> slideInFromBottom() => 
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero);
  
  /// Create a slide-in tween (from top)
  static Tween<Offset> slideInFromTop() => 
      Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero);
  
  /// Create a slide-in tween (from left)
  static Tween<Offset> slideInFromLeft() => 
      Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero);
  
  /// Create a slide-in tween (from right)
  static Tween<Offset> slideInFromRight() => 
      Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);
  
  // ═══════════════════════════════════════════════════════════════
  // ANIMATION SEQUENCES
  // ═══════════════════════════════════════════════════════════════
  
  /// Create staggered animation intervals for multiple items
  /// Example: For 5 items with 100ms delay each
  static List<Interval> createStaggeredIntervals(
    int itemCount, {
    int delayMs = 100,
    Curve curve = Curves.easeOut,
  }) {
    final intervals = <Interval>[];
    final totalDelay = delayMs * itemCount;
    
    for (int i = 0; i < itemCount; i++) {
      final start = (delayMs * i) / totalDelay;
      final end = ((delayMs * i) + delayMs) / totalDelay;
      intervals.add(Interval(start, end, curve: curve));
    }
    
    return intervals;
  }
  
  /// Create cascading fade-in sequence
  static List<TweenSequenceItem<double>> createFadeCascade({
    int steps = 3,
    double pauseBetweenSteps = 0.1,
  }) {
    final items = <TweenSequenceItem<double>>[];
    
    for (int i = 0; i < steps; i++) {
      // Fade in
      items.add(TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1.0,
      ));
      
      // Pause (except for last step)
      if (i < steps - 1) {
        items.add(TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: pauseBetweenSteps,
        ));
      }
    }
    
    return items;
  }
  
  // ═══════════════════════════════════════════════════════════════
  // RIPPLE ANIMATION HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Calculate ripple radius based on progress and volume
  static double calculateRippleRadius(
    double progress,
    double volume, {
    double minRadius = AppConstants.minRippleRadius,
    double maxRadius = AppConstants.maxRippleRadius,
  }) {
    // Volume affects max radius (0.0 to 1.0)
    final volumeMultiplier = 0.5 + (volume * 0.5); // 0.5 to 1.0
    final adjustedMaxRadius = maxRadius * volumeMultiplier;
    
    // Linear interpolation from min to max based on progress
    return minRadius + (adjustedMaxRadius - minRadius) * progress;
  }
  
  /// Calculate ripple opacity (fades out as it expands)
  static double calculateRippleOpacity(double progress) {
    return 1.0 - progress; // Fades from 1.0 to 0.0
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PAGE TRANSITION BUILDERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Liquid slide transition (slides with fade)
  static Widget buildLiquidSlideTransition({
    required Animation<double> animation,
    required Widget child,
    bool slideFromRight = true,
  }) {
    final slideTween = slideFromRight 
        ? slideInFromRight() 
        : slideInFromLeft();
    
    return SlideTransition(
      position: slideTween.animate(
        CurvedAnimation(parent: animation, curve: liquidFlow),
      ),
      child: FadeTransition(
        opacity: fadeIn().animate(
          CurvedAnimation(parent: animation, curve: gentleIn),
        ),
        child: child,
      ),
    );
  }
  
  /// Fade scale transition (scales up with fade)
  static Widget buildFadeScaleTransition({
    required Animation<double> animation,
    required Widget child,
    double initialScale = 0.8,
  }) {
    return ScaleTransition(
      scale: scaleUp(from: initialScale).animate(
        CurvedAnimation(parent: animation, curve: gentleIn),
      ),
      child: FadeTransition(
        opacity: fadeIn().animate(
          CurvedAnimation(parent: animation, curve: gentleIn),
        ),
        child: child,
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════
  // SHIMMER ANIMATION
  // ═══════════════════════════════════════════════════════════════
  
  /// Calculate shimmer position for loading animation
  static double calculateShimmerPosition(double progress) {
    // Move from -1.0 to 2.0 for a smooth sweep across
    return -1.0 + (progress * 3.0);
  }
  
  /// Create shimmer gradient transform
  static AlignmentGeometry getShimmerAlignment(double progress) {
    final position = calculateShimmerPosition(progress);
    return Alignment(position, 0.0);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PROGRESS ANIMATION HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Animate progress bar with smooth easing
  static CurvedAnimation createProgressAnimation(
    AnimationController controller,
  ) {
    return CurvedAnimation(
      parent: controller,
      curve: smooth,
    );
  }
  
  /// Calculate download journey checkpoint position
  /// checkpoints: 0 (start) to 5 (complete)
  static double calculateJourneyProgress(
    int checkpoint,
    double withinCheckpointProgress,
  ) {
    final baseProgress = checkpoint / 5.0;
    final checkpointSize = 1.0 / 5.0;
    return baseProgress + (withinCheckpointProgress * checkpointSize);
  }
}
