// lib/features/translator/widget/voice_ripple_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'ripple_model.dart'; // Import the Ripple class

class VoiceRipplePainter extends CustomPainter {
  final List<Ripple> ripples;

  VoiceRipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final ripple in ripples) {
      final paint = Paint()
        ..color = ripple.color.withOpacity(ripple.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ripple.strokeWidth;

      canvas.drawCircle(center, ripple.currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VoiceRipplePainter oldDelegate) {
    // Repaint if the list of ripples changes (reference or content)
    return !listEquals(oldDelegate.ripples, ripples);
    // Optimization: If Ripple becomes immutable and List is always new on change,
    //               `oldDelegate.ripples != ripples` might suffice.
  }
}

// Helper function to compare lists (requires flutter foundation)
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}