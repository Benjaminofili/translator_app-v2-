// // lib/core/transitions/liquid_page_transitions.dart
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
// import '../constants/app_colors.dart';
// import '../utils/animation_utils.dart';
//
// /// 🌊 Liquid Page Transitions
// ///
// /// Beautiful page transitions with liquid morphing effects
// class LiquidPageTransitions {
//   LiquidPageTransitions._();
//
//   // ═══════════════════════════════════════════════════════════════
//   // ROUTE BUILDERS
//   // ═══════════════════════════════════════════════════════════════
//
//   /// Create a liquid slide route
//   static Route<T> liquidSlideRoute<T>({
//     required Widget page,
//     RouteSettings? settings,
//     bool slideFromRight = true,
//   }) {
//     return PageRouteBuilder<T>(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return _LiquidSlideTransition(
//           animation: animation,
//           secondaryAnimation: secondaryAnimation,
//           slideFromRight: slideFromRight,
//           child: child,
//         );
//       },
//       transitionDuration: AnimationUtils.mediumDuration,
//       reverseTransitionDuration: AnimationUtils.mediumDuration,
//     );
//   }
//
//   /// Create a liquid morph route
//   static Route<T> liquidMorphRoute<T>({
//     required Widget page,
//     RouteSettings? settings,
//   }) {
//     return PageRouteBuilder<T>(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return _LiquidMorphTransition(
//           animation: animation,
//           secondaryAnimation: secondaryAnimation,
//           child: child,
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 800),
//       reverseTransitionDuration: const Duration(milliseconds: 800),
//     );
//   }
//
//   /// Create a particle burst route
//   static Route<T> particleBurstRoute<T>({
//     required Widget page,
//     RouteSettings? settings,
//   }) {
//     return PageRouteBuilder<T>(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return _ParticleBurstTransition(
//           animation: animation,
//           child: child,
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 1000),
//       reverseTransitionDuration: AnimationUtils.mediumDuration,
//     );
//   }
//
//   /// Create a ripple reveal route
//   static Route<T> rippleRevealRoute<T>({
//     required Widget page,
//     RouteSettings? settings,
//     Offset? center,
//   }) {
//     return PageRouteBuilder<T>(
//       settings: settings,
//       pageBuilder: (context, animation, secondaryAnimation) => page,
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         return _RippleRevealTransition(
//           animation: animation,
//           center: center,
//           child: child,
//         );
//       },
//       transitionDuration: const Duration(milliseconds: 700),
//       reverseTransitionDuration: AnimationUtils.mediumDuration,
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // LIQUID SLIDE TRANSITION (Enhanced)
// // ═══════════════════════════════════════════════════════════════
//
// class _LiquidSlideTransition extends StatelessWidget {
//   final Animation<double> animation;
//   final Animation<double> secondaryAnimation;
//   final bool slideFromRight;
//   final Widget child;
//
//   const _LiquidSlideTransition({
//     required this.animation,
//     required this.secondaryAnimation,
//     required this.slideFromRight,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     // Incoming page animation
//     final slideAnimation = Tween<Offset>(
//       begin: Offset(slideFromRight ? 1.0 : -1.0, 0.0),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: animation,
//       curve: AnimationUtils.liquidFlow,
//     ));
//
//     final fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: animation,
//       curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
//     ));
//
//     // Outgoing page animation (scale down slightly)
//     final scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.95,
//     ).animate(CurvedAnimation(
//       parent: secondaryAnimation,
//       curve: Curves.easeOut,
//     ));
//
//     return Stack(
//       children: [
//         // Outgoing page (scale down)
//         if (secondaryAnimation.value > 0)
//           ScaleTransition(
//             scale: scaleAnimation,
//             child: FadeTransition(
//               opacity: Tween<double>(begin: 1.0, end: 0.5).animate(secondaryAnimation),
//               child: Container(), // Placeholder for old page
//             ),
//           ),
//
//         // Liquid particle effect overlay
//         if (animation.value > 0 && animation.value < 1)
//           Positioned.fill(
//             child: IgnorePointer(
//               child: CustomPaint(
//                 painter: _LiquidParticlePainter(
//                   progress: animation.value,
//                   slideFromRight: slideFromRight,
//                 ),
//               ),
//             ),
//           ),
//
//         // Incoming page
//         SlideTransition(
//           position: slideAnimation,
//           child: FadeTransition(
//             opacity: fadeAnimation,
//             child: child,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // LIQUID MORPH TRANSITION
// // ═══════════════════════════════════════════════════════════════
//
// class _LiquidMorphTransition extends StatelessWidget {
//   final Animation<double> animation;
//   final Animation<double> secondaryAnimation;
//   final Widget child;
//
//   const _LiquidMorphTransition({
//     required this.animation,
//     required this.secondaryAnimation,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final morphAnimation = CurvedAnimation(
//       parent: animation,
//       curve: AnimationUtils.liquidFlow,
//     );
//
//     return Stack(
//       children: [
//         // Morphing liquid effect
//         Positioned.fill(
//           child: IgnorePointer(
//             child: AnimatedBuilder(
//               animation: morphAnimation,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _LiquidMorphPainter(
//                     progress: morphAnimation.value,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//
//         // Incoming page with scale and fade
//         ScaleTransition(
//           scale: Tween<double>(begin: 0.8, end: 1.0).animate(morphAnimation),
//           child: FadeTransition(
//             opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
//               CurvedAnimation(
//                 parent: animation,
//                 curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
//               ),
//             ),
//             child: child,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // PARTICLE BURST TRANSITION
// // ═══════════════════════════════════════════════════════════════
//
// class _ParticleBurstTransition extends StatelessWidget {
//   final Animation<double> animation;
//   final Widget child;
//
//   const _ParticleBurstTransition({
//     required this.animation,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final burstAnimation = CurvedAnimation(
//       parent: animation,
//       curve: Curves.easeOutCubic,
//     );
//
//     return Stack(
//       children: [
//         // Particle burst effect
//         Positioned.fill(
//           child: IgnorePointer(
//             child: AnimatedBuilder(
//               animation: burstAnimation,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _ParticleBurstPainter(
//                     progress: burstAnimation.value,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//
//         // Incoming page
//         FadeTransition(
//           opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
//             CurvedAnimation(
//               parent: animation,
//               curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
//             ),
//           ),
//           child: ScaleTransition(
//             scale: Tween<double>(begin: 0.9, end: 1.0).animate(burstAnimation),
//             child: child,
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // RIPPLE REVEAL TRANSITION
// // ═══════════════════════════════════════════════════════════════
//
// class _RippleRevealTransition extends StatelessWidget {
//   final Animation<double> animation;
//   final Offset? center;
//   final Widget child;
//
//   const _RippleRevealTransition({
//     required this.animation,
//     this.center,
//     required this.child,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final rippleAnimation = CurvedAnimation(
//       parent: animation,
//       curve: Curves.easeInOutCubic,
//     );
//
//     return AnimatedBuilder(
//       animation: rippleAnimation,
//       builder: (context, child) {
//         return ClipPath(
//           clipper: _CircularRevealClipper(
//             progress: rippleAnimation.value,
//             center: center,
//           ),
//           child: child,
//         );
//       },
//       child: child,
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // CUSTOM PAINTERS
// // ═══════════════════════════════════════════════════════════════
//
// /// Painter for liquid particle effect during slide
// class _LiquidParticlePainter extends CustomPainter {
//   final double progress;
//   final bool slideFromRight;
//
//   _LiquidParticlePainter({
//     required this.progress,
//     required this.slideFromRight,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (progress == 0 || progress == 1) return;
//
//     final paint = Paint()..style = PaintingStyle.fill;
//
//     // Create flowing particles at the edge
//     final particleCount = 20;
//     final random = math.Random(42); // Fixed seed for consistency
//
//     for (int i = 0; i < particleCount; i++) {
//       final t = i / particleCount;
//
//       // X position moves across screen
//       final baseX = slideFromRight
//           ? size.width * (1 - progress) + (size.width * 0.2 * t)
//           : size.width * progress - (size.width * 0.2 * t);
//
//       // Y position varies
//       final baseY = size.height * t;
//
//       // Add wave motion
//       final waveOffset = math.sin((progress * math.pi * 2) + (t * math.pi * 4)) * 30;
//
//       final x = baseX + waveOffset;
//       final y = baseY;
//
//       // Particle properties
//       final opacity = (1 - progress) * 0.6 * (1 - (t - 0.5).abs() * 2);
//       final radius = 3.0 + (random.nextDouble() * 4.0);
//
//       paint.color = AppColors.electricPurple.withValues(alpha: opacity);
//
//       canvas.drawCircle(Offset(x, y), radius, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(_LiquidParticlePainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
//
// /// Painter for liquid morph effect
// class _LiquidMorphPainter extends CustomPainter {
//   final double progress;
//
//   _LiquidMorphPainter({required this.progress});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (progress == 0 || progress == 1) return;
//
//     final paint = Paint()
//       ..style = PaintingStyle.fill
//       ..color = AppColors.electricPurple.withValues(alpha: (1 - progress) * 0.3);
//
//     // Create organic blob shapes
//     final path = Path();
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//
//     // Expand from center with organic motion
//     final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
//     final radius = maxRadius * progress;
//
//     final points = 8;
//     for (int i = 0; i <= points; i++) {
//       final angle = (i / points) * math.pi * 2;
//       final wave = math.sin(angle * 3 + progress * math.pi * 2) * 20;
//       final r = radius + wave;
//
//       final x = centerX + math.cos(angle) * r;
//       final y = centerY + math.sin(angle) * r;
//
//       if (i == 0) {
//         path.moveTo(x, y);
//       } else {
//         path.lineTo(x, y);
//       }
//     }
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(_LiquidMorphPainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
//
// /// Painter for particle burst effect
// class _ParticleBurstPainter extends CustomPainter {
//   final double progress;
//
//   _ParticleBurstPainter({required this.progress});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (progress == 0 || progress == 1) return;
//
//     final paint = Paint()..style = PaintingStyle.fill;
//
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
//
//     final particleCount = 50;
//     final random = math.Random(123);
//
//     for (int i = 0; i < particleCount; i++) {
//       final angle = (i / particleCount) * math.pi * 2 + (random.nextDouble() * 0.5);
//       final distance = progress * size.width * 0.8 * (0.5 + random.nextDouble() * 0.5);
//
//       final x = centerX + math.cos(angle) * distance;
//       final y = centerY + math.sin(angle) * distance;
//
//       final opacity = (1 - progress) * 0.8;
//       final radius = 2.0 + random.nextDouble() * 4.0;
//
//       // Color variety
//       final colorIndex = i % 3;
//       final color = colorIndex == 0
//           ? AppColors.electricPurple
//           : colorIndex == 1
//           ? AppColors.aquaAccent
//           : AppColors.deepElectricPurple;
//
//       paint.color = color.withValues(alpha: opacity);
//       canvas.drawCircle(Offset(x, y), radius * (1 - progress * 0.5), paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(_ParticleBurstPainter oldDelegate) {
//     return oldDelegate.progress != progress;
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // CUSTOM CLIPPERS
// // ═══════════════════════════════════════════════════════════════
//
// /// Circular reveal clipper
// class _CircularRevealClipper extends CustomClipper<Path> {
//   final double progress;
//   final Offset? center;
//
//   _CircularRevealClipper({
//     required this.progress,
//     this.center,
//   });
//
//   @override
//   Path getClip(Size size) {
//     final centerPoint = center ?? Offset(size.width / 2, size.height / 2);
//     final maxRadius = math.sqrt(
//       math.pow(size.width, 2) + math.pow(size.height, 2),
//     );
//     final radius = maxRadius * progress;
//
//     final path = Path();
//     path.addOval(Rect.fromCircle(center: centerPoint, radius: radius));
//     return path;
//   }
//
//   @override
//   bool shouldReclip(_CircularRevealClipper oldClipper) {
//     return oldClipper.progress != progress || oldClipper.center != center;
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // HELPER EXTENSION
// // ═══════════════════════════════════════════════════════════════
//
// extension LiquidNavigatorExtension on NavigatorState {
//   /// Navigate with liquid slide transition
//   Future<T?> pushLiquidSlide<T>(
//       Widget page, {
//         bool slideFromRight = true,
//       }) {
//     return push<T>(LiquidPageTransitions.liquidSlideRoute(
//       page: page,
//       slideFromRight: slideFromRight,
//     ));
//   }
//
//   /// Navigate with liquid morph transition
//   Future<T?> pushLiquidMorph<T>(Widget page) {
//     return push<T>(LiquidPageTransitions.liquidMorphRoute(page: page));
//   }
//
//   /// Navigate with particle burst transition
//   Future<T?> pushParticleBurst<T>(Widget page) {
//     return push<T>(LiquidPageTransitions.particleBurstRoute(page: page));
//   }
//
//   /// Navigate with ripple reveal transition
//   Future<T?> pushRippleReveal<T>(Widget page, {Offset? center}) {
//     return push<T>(LiquidPageTransitions.rippleRevealRoute(
//       page: page,
//       center: center,
//     ));
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════
// // CONVENIENCE EXTENSION FOR BUILDCONTEXT
// // ═══════════════════════════════════════════════════════════════
//
// extension LiquidContextExtension on BuildContext {
//   /// Navigate with liquid slide transition
//   Future<T?> pushLiquidSlide<T>(
//       Widget page, {
//         bool slideFromRight = true,
//       }) {
//     return Navigator.of(this).pushLiquidSlide(
//       page,
//       slideFromRight: slideFromRight,
//     );
//   }
//
//   /// Navigate with liquid morph transition
//   Future<T?> pushLiquidMorph<T>(Widget page) {
//     return Navigator.of(this).pushLiquidMorph(page);
//   }
//
//   /// Navigate with particle burst transition
//   Future<T?> pushParticleBurst<T>(Widget page) {
//     return Navigator.of(this).pushParticleBurst(page);
//   }
//
//   /// Navigate with ripple reveal transition
//   Future<T?> pushRippleReveal<T>(Widget page, {Offset? center}) {
//     return Navigator.of(this).pushRippleReveal(page, center: center);
//   }
// }