// lib/features/translator/widget/ripple_model.dart
import 'package:flutter/material.dart';

class Ripple {
  final double initialRadius;
  final double maxRadius;
  final double progress; // 0.0 to 1.0
  final Color color;
  final double opacity;
  final double strokeWidth;

  Ripple({
    required this.initialRadius,
    required this.maxRadius,
    required this.progress,
    required this.color,
    required this.opacity,
    this.strokeWidth = 2.0,
  });

  // Calculate current radius based on progress
  double get currentRadius => initialRadius + (maxRadius - initialRadius) * progress;
}