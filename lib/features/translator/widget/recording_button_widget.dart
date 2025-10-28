// lib/features/translator/widgets/recording_button_widget.dart
import 'package:flutter/material.dart';

/// 🎤 Recording Button Widget
/// 
/// Animated button for voice recording with pulse effect
class RecordingButtonWidget extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final double size;

  const RecordingButtonWidget({
    super.key,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    this.size = 140,
  });

  @override
  State<RecordingButtonWidget> createState() => _RecordingButtonWidgetState();
}

class _RecordingButtonWidgetState extends State<RecordingButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(RecordingButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Start/stop animation based on recording state
    if (widget.isRecording && !oldWidget.isRecording) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => widget.onStartRecording(),
      onLongPressEnd: (_) => widget.onStopRecording(),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isRecording
                      ? [
                          Colors.red.shade400,
                          Colors.red.shade700,
                        ]
                      : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary)
                        .withOpacity(0.5),
                    blurRadius: widget.isRecording ? 30 : 20,
                    spreadRadius: widget.isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: Icon(
                widget.isRecording ? Icons.mic : Icons.mic_none,
                size: widget.size * 0.43, // ~60px for default 140px size
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}