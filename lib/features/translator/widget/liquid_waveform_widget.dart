import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Tweened Waveform - Minimal audio visualization
class TweenedWaveform extends StatefulWidget {
  final bool isListening;
  const TweenedWaveform({super.key, required this.isListening});

  @override
  State<TweenedWaveform> createState() => _TweenedWaveformState();
}

class _TweenedWaveformState extends State<TweenedWaveform>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _phaseController;
  late final AnimationController _stateController;
  late Animation<double> _centerYFactor;
  late Animation<double> _amplitudeScale;
  late bool _previousListeningState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _previousListeningState = widget.isListening;

    _phaseController = AnimationController(
      vsync: this,
      duration: _WaveParams.phaseDuration,
    )..repeat();

    _stateController = AnimationController(
      vsync: this,
      duration: _WaveParams.stateDuration,
    );

    _centerYFactor = AlwaysStoppedAnimation<double>(
      widget.isListening ? _WaveParams.activeCenterY : _WaveParams.idleCenterY,
    );
    _amplitudeScale = AlwaysStoppedAnimation<double>(
      widget.isListening ? 1.00 : 0.83,
    );
    _stateController.value = 1.0;
  }

  void _configureTweens({required bool fromListeningState}) {
    final double beginCenter = fromListeningState ? _WaveParams.activeCenterY : _WaveParams.idleCenterY;
    final double endCenter = fromListeningState ? _WaveParams.idleCenterY : _WaveParams.activeCenterY;
    final double beginAmp = fromListeningState ? 1.00 : 0.83;
    final double endAmp = fromListeningState ? 0.83 : 1.00;

    _centerYFactor = Tween<double>(begin: beginCenter, end: endCenter)
        .animate(CurvedAnimation(parent: _stateController, curve: Curves.easeInOut));

    _amplitudeScale = Tween<double>(begin: beginAmp, end: endAmp)
        .animate(CurvedAnimation(parent: _stateController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant TweenedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != _previousListeningState) {
      _configureTweens(fromListeningState: _previousListeningState);
      _stateController.forward(from: 0.0);
      _previousListeningState = widget.isListening;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _phaseController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _phaseController.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phaseController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_phaseController, _stateController]),
      builder: (_, __) {
        return CustomPaint(
          size: Size.infinite,
          painter: TweenedWaveformPainter(
            animationValue: _phaseController.value,
            centerYFactor: _centerYFactor.value,
            amplitudeScale: _amplitudeScale.value,
          ),
        );
      },
    );
  }
}

/// Visual parameters
class _WaveParams {
  static const double activeCenterY = 0.50;
  static const double idleCenterY = 0.65;

  static const double activeAmplitude1 = 70.0;
  static const double activeAmplitude2 = 60.0;
  static const double activeAmplitude3 = 35.0;

  static const double freq1 = 2.0;
  static const double freq2 = 2.3;
  static const double freq3 = 1.6;

  static const double stroke1 = 3.0;
  static const double stroke2 = 2.5;
  static const double stroke3 = 2.0;

  static const double outerGlowBlur = 3.0;
  static const double innerGlowBlur = 1.5;

  static const double glow1 = 0.45;
  static const double glow2 = 0.40;
  static const double glow3Active = 0.35;
  static const double glow3Idle = 0.40;

  static const double opacity1 = 0.90;
  static const double opacity2 = 0.80;
  static const double opacity3Active = 0.50;
  static const double opacity3Idle = 0.55;

  static const Duration stateDuration = Duration(milliseconds: 450);
  static const Duration phaseDuration = Duration(seconds: 2);
}

/// Painter using app accent color
class TweenedWaveformPainter extends CustomPainter {
  final double animationValue;
  final double centerYFactor;
  final double amplitudeScale;

  const TweenedWaveformPainter({
    required this.animationValue,
    required this.centerYFactor,
    required this.amplitudeScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height * centerYFactor;

    final double t = ((centerYFactor - _WaveParams.activeCenterY) /
        (_WaveParams.idleCenterY - _WaveParams.activeCenterY))
        .clamp(0.0, 1.0);
    final double breathSpeed = _lerp(0.3, 0.2, t);
    final double breathing = 0.9 + 0.2 * math.sin(animationValue * 2 * math.pi * breathSpeed);
    final double phaseShift = animationValue * 2 * math.pi;

    // Use app accent color gradient
    final shader = LinearGradient(
      colors: [
        AppColors.accent,
        AppColors.accentLight,
        AppColors.accent.withOpacity(0.8),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    void drawWave({
      required double amplitude,
      required double frequency,
      required double basePhase,
      required double strokeWidth,
      required double opacity,
      required double glowOpacity,
    }) {
      final path = Path()..moveTo(0, centerY);

      for (double x = 0; x <= width; x++) {
        final xNorm = x / width;
        final envelope = math.pow(math.sin(xNorm * math.pi), 1.5).toDouble();
        final y = centerY +
            (amplitude * amplitudeScale * breathing) *
                envelope *
                math.sin(frequency * xNorm * 2 * math.pi + phaseShift + basePhase);
        path.lineTo(x, y);
      }

      // Minimal glow (reduced from original)
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 1
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _WaveParams.outerGlowBlur)
          ..blendMode = BlendMode.plus
          ..color = Colors.white.withOpacity(glowOpacity * 0.6),
      );

      // Core stroke
      canvas.drawPath(
        path,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..blendMode = BlendMode.srcOver
          ..color = Colors.white.withOpacity(opacity),
      );
    }

    final bool nearActive = centerYFactor <= (_WaveParams.activeCenterY + 0.025);
    final double o3 = nearActive ? _WaveParams.opacity3Active : _WaveParams.opacity3Idle;
    final double g3 = nearActive ? _WaveParams.glow3Active : _WaveParams.glow3Idle;

    drawWave(
      amplitude: _WaveParams.activeAmplitude1,
      frequency: _WaveParams.freq1,
      basePhase: 0.0,
      strokeWidth: _WaveParams.stroke1,
      opacity: _WaveParams.opacity1,
      glowOpacity: _WaveParams.glow1,
    );

    drawWave(
      amplitude: _WaveParams.activeAmplitude2,
      frequency: _WaveParams.freq2,
      basePhase: math.pi / 3,
      strokeWidth: _WaveParams.stroke2,
      opacity: _WaveParams.opacity2,
      glowOpacity: _WaveParams.glow2,
    );

    drawWave(
      amplitude: _WaveParams.activeAmplitude3,
      frequency: _WaveParams.freq3,
      basePhase: 2 * math.pi / 3,
      strokeWidth: _WaveParams.stroke3,
      opacity: o3,
      glowOpacity: g3,
    );
  }

  @override
  bool shouldRepaint(covariant TweenedWaveformPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
          oldDelegate.centerYFactor != centerYFactor ||
          oldDelegate.amplitudeScale != amplitudeScale;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;