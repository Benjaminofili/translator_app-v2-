import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/audio_recording_service.dart';
import '../widget/language_selector_widget.dart';
import '../widget/translation_result_card.dart';
import '../widget/recording_button_widget.dart';
import '../widget/liquid_waveform_widget.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final AudioRecordingService _audioService = AudioRecordingService();

  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';
  bool _isRecording = false;
  bool _isProcessing = false;

  String _recordedText = '';
  String _translatedText = '';
  String? _errorMessage;

  final Map<String, String> _languages = {
    'en': 'English (English)',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'zh': 'Chinese (中文)',
    'ja': 'Japanese (日本語)',
  };

  @override
  void dispose() {
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
    });
  }

  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _errorMessage = null;
      _recordedText = '';
      _translatedText = '';
    });
    await _audioService.startRecording();
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    final result = await _audioService.stopRecording();

    if (!result.success) {
      setState(() => _errorMessage = result.error ?? 'Failed to stop recording');
      return;
    }

    await _processTranslation(result.filePath!);
  }

  Future<void> _processTranslation(String audioFilePath) async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2)); // simulate
    setState(() {
      _recordedText = 'Hello, how are you?';
      _translatedText = '¡Hola, cómo estás!';
      _isProcessing = false;
    });
  }

  void _clearResults() {
    setState(() {
      _recordedText = '';
      _translatedText = '';
      _errorMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Language selector at top
            LanguageSelectorWidget(
              sourceLanguage: _sourceLanguage,
              targetLanguage: _targetLanguage,
              availableLanguages: _languages,
              onSourceChanged: (val) => setState(() => _sourceLanguage = val),
              onTargetChanged: (val) => setState(() => _targetLanguage = val),
              onSwap: _swapLanguages,
            ),

            // Translation area
            Expanded(child: _buildTranslationArea(context)),

            // Waveform (minimal height)
            SizedBox(
              height: 120,
              child: TweenedWaveform(isListening: _isRecording),
            ),

            // Recording button
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 16),
              child: RecordingButtonWidget(
                isRecording: _isRecording,
                onStartRecording: _startRecording,
                onStopRecording: _stopRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationArea(BuildContext context) {
    if (_isProcessing) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _clearResults,
                child: const Text('Dismiss'),
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
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to speak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Release to translate',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recordedText.isNotEmpty)
          TranslationResultCard(
            title: 'Original',
            text: _recordedText,
            language: _languages[_sourceLanguage]!,
            icon: Icons.mic,
          ),
        if (_translatedText.isNotEmpty) ...[
          const SizedBox(height: 12),
          TranslationResultCard(
            title: 'Translation',
            text: _translatedText,
            language: _languages[_targetLanguage]!,
            icon: Icons.translate,
            isPrimary: true,
          ),
        ],
      ],
    );
  }
}