// lib/features/translator/widget/voice_visualization_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animation_utils.dart'; // For calculation helpers
import 'ripple_model.dart';
import 'voice_ripple_painter.dart';

class VoiceVisualizationWidget extends StatefulWidget {
  final bool isRecording;
  final double volume; // Input volume (0.0 to 1.0)
  final String languageCode; // For color coding

  const VoiceVisualizationWidget({
    super.key,
    required this.isRecording,
    this.volume = 0.5, // Default volume if not provided
    this.languageCode = 'en', // Default language
  });

  @override
  State<VoiceVisualizationWidget> createState() => _VoiceVisualizationWidgetState();
}

class _VoiceVisualizationWidgetState extends State<VoiceVisualizationWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ActiveRipple> _activeRipples = [];
  Timer? _spawnTimer;

  // Breathing animation state
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isBreathing = false;

  @override
  void initState() {
    super.initState();

    // Main animation controller (ticks continuously)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Doesn't really matter, it just ticks
    )..addListener(_updateRipples);

    // Breathing animation controller (for idle state)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slow breath cycle
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _controller.repeat(); // Start the main ticker
    _updateState();
  }

  @override
  void didUpdateWidget(covariant VoiceVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording) {
      _updateState();
    }
    // No need to explicitly check volume/language change,
    // _spawnRipple and _updateRipples will use the latest widget.volume/widget.languageCode
  }

  void _updateState() {
    _isBreathing = !widget.isRecording; // Update breathing flag
    if (widget.isRecording) {
      _breathingController.stop();
      _breathingController.reset();
      _startSpawningRipples();
    } else {
      _stopSpawningRipples();
      _startBreathing(); // Start breathing when not recording
    }
  }

  void _startBreathing() {
    if (_isBreathing && mounted) {
      _breathingController.repeat(reverse: true);
    }
  }


  void _startSpawningRipples() {
    // Spawn ripples periodically based on volume (faster spawn for louder sound)
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      // Adjust spawn rate: Faster for louder volume
      Duration(milliseconds: (400 - (widget.volume * 250)).clamp(150, 400).toInt()),
          (timer) {
        if (widget.isRecording && mounted && _activeRipples.length < AppConstants.voiceRippleCount) {
          _spawnRipple();
        }
      },
    );
  }

  void _stopSpawningRipples() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
  }

  void _spawnRipple() {
    final startTime = _controller.value; // Use controller's value as start time
    final color = AppColors.getLanguageColor(widget.languageCode);

    _activeRipples.add(_ActiveRipple(startTime: startTime, color: color));
    // Trigger a repaint
    setState(() {});
  }

  void _updateRipples() {
    final currentTime = _controller.value;
    final double lifespanSeconds = AppConstants.rippleLifespan;

    // List to store ripples for the painter
    List<Ripple> painterRipples = [];

    // Update existing ripples
    _activeRipples.removeWhere((activeRipple) {
      // Calculate progress (0.0 to 1.0) over the ripple's lifespan
      // Handle animation controller looping (value goes 0 -> 1 -> 0 ...)
      double elapsed = currentTime - activeRipple.startTime;
      if (elapsed < 0) {
        elapsed += 1.0; // Adjust for loop
      }

      final progress = (elapsed / (lifespanSeconds / _controller.duration!.inSeconds)).clamp(0.0, 1.0);


      if (progress >= 1.0) {
        return true; // Remove ripple if it completed its lifespan
      }

      // --- Checklist Items ---
      // 4. Calculate ripple radius based on progress
      // 6. Make ripples volume-reactive (adjusts maxRadius)
      final radius = AnimationUtils.calculateRippleRadius(
        progress,
        widget.volume, // Use current volume from widget
        minRadius: AppConstants.minRippleRadius,
        maxRadius: AppConstants.maxRippleRadius,
      );

      // 5. Calculate ripple opacity (fade out)
      final opacity = AnimationUtils.calculateRippleOpacity(progress);

      // --- Add ripple data for the painter ---
      painterRipples.add(Ripple(
        initialRadius: AppConstants.minRippleRadius,
        maxRadius: AppConstants.maxRippleRadius, // Painter uses this? Let's check... Ripple Model uses it.
        progress: progress,
        // 7. Add language-specific color coding
        color: activeRipple.color,
        opacity: opacity,
        strokeWidth: math.max(1.0, 3.0 * (1.0 - progress)), // Thinner as it expands
      ));

      return false; // Keep ripple
    });

    // Optimization: Only call setState if the list content might have changed
    // This basic check works if Ripple instances are recreated each time.
    // For deeper optimization, compare lists more thoroughly if needed.
    if (!listEquals(_lastPainterRipples, painterRipples)) {
      _lastPainterRipples = List.from(painterRipples); // Store for next comparison
      setState(() {
        // Update the list that the painter uses
      });
    }
  }

  // Store the last list passed to the painter for comparison
  List<Ripple> _lastPainterRipples = [];

  @override
  void dispose() {
    _controller.removeListener(_updateRipples);
    _controller.dispose();
    _breathingController.dispose();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 11. Add breathing animation for idle state
    Widget visualization = CustomPaint(
      painter: VoiceRipplePainter(ripples: _lastPainterRipples), // Use the stored list
      child: Container(), // Painter paints on this container's canvas
    );

    if (_isBreathing) {
      return AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _breathingAnimation.value,
            child: child,
          );
        },
        // Apply breathing animation *around* the mic icon (or placeholder)
        child: Icon(
          Icons.mic,
          color: AppColors.getLanguageColor(widget.languageCode).withOpacity(0.5),
          size: AppConstants.minRippleRadius * 0.8, // Slightly smaller than min ripple
        ),
      );
    } else {
      return visualization; // Show ripples when recording
    }

  }
}

// Internal helper class to track ripple start time
class _ActiveRipple {
  final double startTime; // Controller value when spawned (0.0 to 1.0)
  final Color color;

  _ActiveRipple({required this.startTime, required this.color});
}