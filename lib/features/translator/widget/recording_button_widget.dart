import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Recording Button - Minimal glow, single accent color
class RecordingButtonWidget extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final double size;
  final bool enablePushToTalk;

  const RecordingButtonWidget({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    this.size = 70.0,
    this.enablePushToTalk = true,
  });

  @override
  State<RecordingButtonWidget> createState() => _RecordingButtonWidgetState();
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

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RecordingButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

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

    if (d <= 0) return const SizedBox.shrink();

    final double iconSize = d * 0.5;

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
          width: d * 2.5,
          height: d * 2.5,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final double p = widget.isRecording ? _pulse.value : 0.0;

                // Minimal glow - only visible when active
                final double glowRadius = d * (1.0 + (0.15 * p));
                final double glowOpacity = widget.isRecording ? (0.15 + 0.10 * p) : 0.05;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Single subtle glow layer
                    if (widget.isRecording)
                      Container(
                        width: glowRadius,
                        height: glowRadius,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withOpacity(glowOpacity),
                              AppColors.accent.withOpacity(0.0),
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),

                    // Core button
                    Container(
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isRecording
                            ? AppColors.accent
                            : AppColors.surface,
                        border: widget.isRecording
                            ? null
                            : Border.all(
                          color: AppColors.divider,
                          width: 2,
                        ),
                        boxShadow: widget.isRecording
                            ? [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          widget.isRecording ? Icons.mic : Icons.mic_none,
                          color: widget.isRecording
                              ? Colors.white
                              : AppColors.textPrimary,
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