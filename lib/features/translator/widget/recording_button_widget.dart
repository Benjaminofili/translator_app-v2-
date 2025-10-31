import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// RecordingButtonWidget
/// - Tap to toggle; optional push-to-talk via long-press
/// - Multi-layer radial glow with pulse
/// - Lifecycle aware, accessible, and designer-tunable via properties
class RecordingButtonWidget extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final double size;

  // Designer-tunable overrides (optional)
  final double outerRadiusFactor;
  final double midRadiusFactor;
  final double innerRadiusFactor;

  final double outerPulseAmplitude; // fraction of d
  final double midPulseAmplitude;
  final double innerPulseAmplitude;

  final double outerBaseOpacity;
  final double midBaseOpacity;
  final double innerBaseOpacity;

  final double outerPulseBoost;
  final double midPulseBoost;
  final double innerPulseBoost;

  final double activeIntensityMultiplier;

  final bool enablePushToTalk;

  const RecordingButtonWidget({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    this.size = 70.0,
    // tuning defaults (match design intent)
    this.outerRadiusFactor = _GlowParams.outerRadiusFactor,
    this.midRadiusFactor = _GlowParams.midRadiusFactor,
    this.innerRadiusFactor = _GlowParams.innerRadiusFactor,
    this.outerPulseAmplitude = _GlowParams.outerPulseAmplitude,
    this.midPulseAmplitude = _GlowParams.midPulseAmplitude,
    this.innerPulseAmplitude = _GlowParams.innerPulseAmplitude,
    this.outerBaseOpacity = _GlowParams.outerBaseOpacity,
    this.midBaseOpacity = _GlowParams.midBaseOpacity,
    this.innerBaseOpacity = _GlowParams.innerBaseOpacity,
    this.outerPulseBoost = _GlowParams.outerPulseBoost,
    this.midPulseBoost = _GlowParams.midPulseBoost,
    this.innerPulseBoost = _GlowParams.innerPulseBoost,
    this.activeIntensityMultiplier = _GlowParams.activeIntensityMultiplier,
    this.enablePushToTalk = true,
  });

  @override
  State<RecordingButtonWidget> createState() => _RecordingButtonWidgetState();
}

/// Centralized glow constants (tweak here or override at widget level)
class _GlowParams {
  // Base radii as multiples of core diameter (d)
  static const double outerRadiusFactor = 2.0; // outer diameter = d * factor
  static const double midRadiusFactor = 1.4;
  static const double innerRadiusFactor = 1.0;

  // Pulse amplitude as fractions of core diameter (additive)
  static const double outerPulseAmplitude = 0.16; // 0..1 scaled by d
  static const double midPulseAmplitude = 0.12;
  static const double innerPulseAmplitude = 0.08;

  // Base opacities at idle
  static const double outerBaseOpacity = 0.08;
  static const double midBaseOpacity = 0.12;
  static const double innerBaseOpacity = 0.18;

  // Pulse boost factors used when active (added to base)
  static const double outerPulseBoost = 0.25;
  static const double midPulseBoost = 0.35;
  static const double innerPulseBoost = 0.45;

  // Intensity multiplier applied in active state
  static const double activeIntensityMultiplier = 1.2;
}

class _RecordingButtonWidgetState extends State<RecordingButtonWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;
  DateTime? _lastTapTime;
  bool _wasRecordingWhenPaused = false;

  static const Duration _pulseDuration = Duration(milliseconds: 1200);
  static const Duration _tapDebounce = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(vsync: this, duration: _pulseDuration);
    _pulse = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    // Reflect initial recording state
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RecordingButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop pulse when recording state changes
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startPulse();
        HapticFeedback.mediumImpact();
        _announce('Recording started');
      } else {
        _stopPulse();
        HapticFeedback.lightImpact();
        _announce('Recording stopped');
      }
    }
  }

  void _announce(String text) {
    try {
      SemanticsService.announce(text, TextDirection.ltr);
    } catch (_) {}
  }

  void _startPulse() {
    if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasRecordingWhenPaused = widget.isRecording;
      _pulseController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (widget.isRecording && _wasRecordingWhenPaused) {
        _pulseController.repeat(reverse: true);
      }
      _wasRecordingWhenPaused = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < _tapDebounce) return;
    _lastTapTime = now;

    if (widget.isRecording) {
      widget.onStopRecording();
    } else {
      widget.onStartRecording();
    }
  }

  void _onLongPressStart(_) {
    if (!widget.enablePushToTalk) return;
    widget.onStartRecording();
  }

  void _onLongPressEnd(_) {
    if (!widget.enablePushToTalk) return;
    widget.onStopRecording();
  }

  @override
  Widget build(BuildContext context) {
    final double d = widget.size;

    // Defensive guard: don't render if size is invalid
    if (d <= 0) return const SizedBox.shrink();

    final double iconSize = d * 0.5; // 50% of diameter
    const Color coreColor = Color(0xFF6B5FFF);
    const Color coreColorActive = Color(0xFF8B6CFF);

    // Compute container size from outer radius factor and pulse amplitude (worst-case)
    final double maxOuter = d * widget.outerRadiusFactor + (1.0 * d * widget.outerPulseAmplitude);
    final double containerSize = (maxOuter).clamp(d, d * 3.5);

    return Semantics(
      button: true,
      label: widget.isRecording ? 'Stop recording' : 'Start recording',
      hint: widget.enablePushToTalk ? 'Tap to toggle, long press for push to talk' : 'Tap to toggle recording',
      value: widget.isRecording ? 'Recording' : 'Idle',
      child: GestureDetector(
        onTap: _onTap,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: containerSize,
          height: containerSize,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final double p = widget.isRecording ? _pulse.value : 0.0;

                // Radii base + pulse (base radii are >= core so idle glow visible)
                final double outerRadius = d * widget.outerRadiusFactor + (p * d * widget.outerPulseAmplitude);
                final double midRadius = d * widget.midRadiusFactor + (p * d * widget.midPulseAmplitude);
                final double innerRadius = d * widget.innerRadiusFactor + (p * d * widget.innerPulseAmplitude);

                // Idle vs active base/pulse opacity logic (clear, explicit)
                final bool isActive = widget.isRecording;
                final double pulseBoost = p; // 0..1

                final double outerOpacity = isActive
                    ? (widget.outerBaseOpacity + pulseBoost * widget.outerPulseBoost) * widget.activeIntensityMultiplier
                    : widget.outerBaseOpacity;

                final double midOpacity = isActive
                    ? (widget.midBaseOpacity + pulseBoost * widget.midPulseBoost) * widget.activeIntensityMultiplier
                    : widget.midBaseOpacity;

                final double innerOpacity = isActive
                    ? (widget.innerBaseOpacity + pulseBoost * widget.innerPulseBoost) * widget.activeIntensityMultiplier
                    : widget.innerBaseOpacity;

                // Clamp opacities defensively
                final double outerOpacityClamped = outerOpacity.clamp(0.0, 1.0);
                final double midOpacityClamped = midOpacity.clamp(0.0, 1.0);
                final double innerOpacityClamped = innerOpacity.clamp(0.0, 1.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer diffuse glow
                    Container(
                      width: outerRadius,
                      height: outerRadius,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            coreColorActive.withOpacity(outerOpacityClamped),
                            coreColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),

                    // Mid glow
                    Container(
                      width: midRadius,
                      height: midRadius,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            coreColorActive.withOpacity(midOpacityClamped),
                            coreColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),

                    // Inner glow (tight)
                    Container(
                      width: innerRadius,
                      height: innerRadius,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            coreColorActive.withOpacity(innerOpacityClamped),
                            coreColor.withOpacity(0.0),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),

                    // Core button (radial shading, slight top bias)
                    Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.9,
                          colors: widget.isRecording
                              ? [coreColorActive, coreColorActive.withOpacity(0.95)]
                              : [coreColor, coreColor.withOpacity(0.9)],
                          stops: const [0.0, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.isRecording ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}