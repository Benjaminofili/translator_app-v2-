import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/audio_recording_service.dart';
import '../widget/voice_visualization_widget.dart';

/// 🎤 Translator Screen - MVP
///
/// Core translation interface with voice recording
class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  final AudioRecordingService _audioService = AudioRecordingService();

  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';

  bool _isRecording = false;
  bool _isProcessing = false;

  String _recordedText = '';
  String _translatedText = '';
  String? _errorMessage;

  double _currentVolume = 0.0;
  Timer? _volumeTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Available languages (simplified for MVP)
  final Map<String, String> _languages = {
    'en': '🇬🇧 English',
    'es': '🇪🇸 Spanish',
    'fr': '🇫🇷 French',
    'zh': '🇨🇳 Chinese',
  };

  @override
  void initState() {
    super.initState();

    // Initialize audio service
    _initializeAudioService();

    // Pulse animation for recording button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAudioService() async {
    final initialized = await _audioService.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Microphone permission required'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {}, // Will open settings
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _volumeTimer?.cancel(); // <-- Cancel volume timer
    _audioService.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      // Also swap texts if available
      if (_recordedText.isNotEmpty && _translatedText.isNotEmpty) {
        final tempText = _recordedText;
        _recordedText = _translatedText;
        _translatedText = tempText;
      }
    });
  }

  void _updateVolume() async {
    if (!_isRecording || !mounted) return;
    try {
      final amplitude = await _audioService.getAmplitude();
      setState(() {
        _currentVolume = amplitude;
      });
    } catch (e) {
      // Handle error fetching amplitude if necessary
      debugPrint("Error fetching amplitude: $e");
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _errorMessage = null;
      _recordedText = '';
      _translatedText = '';
    });

    _pulseController.repeat(reverse: true);

    // --- ADD VOLUME TIMER ---
    _volumeTimer?.cancel(); // Cancel any existing timer
    _volumeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateVolume());
    // --- END ADD VOLUME TIMER ---

    final result = await _audioService.startRecording();

    if (!result.success) {
      setState(() {
        _isRecording = false;
        _errorMessage = result.error ?? 'Failed to start recording';
      });
      _pulseController.stop();
      _pulseController.reset();

      _volumeTimer?.cancel(); // <-- Stop timer on error
      setState(() => _currentVolume = 0.0); // Reset volume

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    debugPrint('🎤 Recording started: ${result.filePath}');
  }

  Future<void> _stopRecording() async {
    _volumeTimer?.cancel();
    _volumeTimer = null;
    setState(() => _currentVolume = 0.0);
    setState(() {
      _isRecording = false;
    });

    _pulseController.stop();
    _pulseController.reset();

    final result = await _audioService.stopRecording();

    if (!result.success) {
      setState(() {
        _errorMessage = result.error ?? 'Failed to stop recording';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    debugPrint('🎤 Recording stopped: ${result.filePath}, ${result.fileSize} bytes');

    // Process translation
    await _processTranslation(result.filePath!);
  }

  Future<void> _processTranslation(String audioFilePath) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement actual translation service
      // For MVP, simulate translation
      debugPrint('📄 Processing audio file: $audioFilePath');

      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _recordedText = 'Hello, how are you?'; // Simulated STT
        _translatedText = '¡Hola, cómo estás!'; // Simulated translation
        _isProcessing = false;
      });

      debugPrint('✅ Translation complete');

    } catch (e) {
      setState(() {
        _errorMessage = 'Translation failed: $e';
        _isProcessing = false;
      });
      debugPrint('❌ Translation error: $e');
    }
  }

  void _clearResults() {
    setState(() {
      _recordedText = '';
      _translatedText = '';
      _errorMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.getGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildLanguageSelector(context),
              Expanded(child: _buildTranslationArea(context)),
              _buildRecordingButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
          ),
          Text(
            'Voice Translator',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            children: [
              IconButton(
                onPressed: _clearResults,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Navigate to history
                  debugPrint('📜 History tapped');
                },
                icon: const Icon(Icons.history),
                tooltip: 'History',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Source Language
          Expanded(
            child: _buildLanguageDropdown(
              value: _sourceLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sourceLanguage = value);
                }
              },
            ),
          ),

          const SizedBox(width: 16),

          // Swap Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _swapLanguages,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              tooltip: 'Swap languages',
            ),
          ),

          const SizedBox(width: 16),

          // Target Language
          Expanded(
            child: _buildLanguageDropdown(
              value: _targetLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _targetLanguage = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A2E),
          style: Theme.of(context).textTheme.titleMedium,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: _languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTranslationArea(BuildContext context) {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.electricPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Processing...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = null);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recordedText.isEmpty && _translatedText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_none,
              size: 80,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Hold the button to speak',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Release to translate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Original Text
          if (_recordedText.isNotEmpty) ...[
            _buildResultCard(
              context,
              title: 'Original',
              text: _recordedText,
              language: _languages[_sourceLanguage] ?? _sourceLanguage,
              icon: Icons.mic,
            ),
            const SizedBox(height: 16),
          ],

          // Translated Text
          if (_translatedText.isNotEmpty) ...[
            _buildResultCard(
              context,
              title: 'Translation',
              text: _translatedText,
              language: _languages[_targetLanguage] ?? _targetLanguage,
              icon: Icons.translate,
              isPrimary: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard(
      BuildContext context, {
        required String title,
        required String text,
        required String language,
        required IconData icon,
        bool isPrimary = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                language,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Play audio
                  debugPrint('🔊 Play audio');
                },
                icon: const Icon(Icons.volume_up, size: 20),
                tooltip: 'Play',
              ),
              IconButton(
                onPressed: () {
                  // TODO: Share
                  debugPrint('📤 Share: $text');
                },
                icon: const Icon(Icons.share, size: 20),
                tooltip: 'Share',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton(BuildContext context) {
    const double buttonSize = 140;
    const double visualizationSize = buttonSize * 2.5; // Still needed for the Positioned widget

    // This SizedBox now only reserves space for the button in the main Column layout
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Allow the visualization to paint outside the SizedBox
        children: [
          // 1. Position the visualization container centered relative to the SizedBox
          // The Positioned widget itself doesn't affect the parent SizedBox's layout size.
          Positioned(
            // Calculate offsets to center the larger visualization area
            // relative to the smaller SizedBox container.
            left: (buttonSize - visualizationSize) / 2,
            top: (buttonSize - visualizationSize) / 2,
            width: visualizationSize, // The visualization needs its own defined size
            height: visualizationSize,
            child: VoiceVisualizationWidget(
              isRecording: _isRecording,
              volume: _currentVolume,
              languageCode: _sourceLanguage,
            ),
          ),

          // 2. Recording Button (drawn on top, fits within SizedBox)
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // This Container defines the actual button's appearance and size
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: buttonSize, // Use defined size
                    height: buttonSize, // Use defined size
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isRecording
                            ? [ Colors.red.shade400, Colors.red.shade700 ]
                            : [ AppColors.electricPurple, AppColors.deepElectricPurple ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : AppColors.electricPurple).withOpacity(0.5),
                          blurRadius: _isRecording ? 30 : 20,
                          spreadRadius: _isRecording ? 5 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      size: buttonSize * 0.43, // Keep relative icon size
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}