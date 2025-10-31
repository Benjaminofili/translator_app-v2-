import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
      body: Container(
        decoration: AppTheme.getGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),

              // Language selector
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

              // Waveform
              SizedBox(
                height: 150,
                child: TweenedWaveform(isListening: _isRecording),
              ),

              // Recording button
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: RecordingButtonWidget(
                  isRecording: _isRecording,
                  onStartRecording: _startRecording,
                  onStopRecording: _stopRecording,
                ),
              ),
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
          ),
          Text('Voice Translator',
              style: Theme.of(context).textTheme.headlineSmall),
          Row(
            children: [
              IconButton(
                onPressed: _clearResults,
                icon: const Icon(Icons.clear_all),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Navigate to history
                },
                icon: const Icon(Icons.history),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationArea(BuildContext context) {
    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_recordedText.isEmpty && _translatedText.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.mic_none, size: 80, color: Colors.white30),
            SizedBox(height: 16),
            Text('Hold the button to speak',
                style: TextStyle(color: Colors.white70)),
            Text('Release to translate',
                style: TextStyle(color: Colors.white54)),
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
          const SizedBox(height: 16),
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