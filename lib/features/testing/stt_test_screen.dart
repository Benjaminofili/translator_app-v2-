import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/stt_audio_service.dart';
import '../../services/model_service.dart';
import '../../services/model_debug_helper.dart';

/// 🧪 STT Test Screen
///
/// Simple screen to test speech recognition
class STTTestScreen extends StatefulWidget {
  const STTTestScreen({super.key});

  @override
  State<STTTestScreen> createState() => _STTTestScreenState();
}

class _STTTestScreenState extends State<STTTestScreen> {
  final STTAudioService _sttService = STTAudioService();
  final ModelService _modelService = ModelService();

  bool _isListening = false;
  bool _isLoading = false;
  String _transcript = '';
  String _error = '';
  String _selectedLanguage = 'en';

  final List<String> _availableLanguages = ['en', 'es', 'fr', 'zh'];

  @override
  void initState() {
    super.initState();
    _initializeService();

    // Listen to transcript stream
    _sttService.transcriptStream.listen((transcript) {
      setState(() {
        _transcript = transcript;
      });
    });
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Initialize model service
      final initialized = await _modelService.initialize();
      if (!initialized) {
        throw Exception('Failed to initialize model service');
      }

      // Load a pack (assuming 'en-es' is installed)
      // You can change this based on your available packs
      final loadResult = await _modelService.loadPack('en-es');
      if (!loadResult.success) {
        throw Exception('Failed to load language pack: ${loadResult.error}');
      }

      setState(() {
        _isLoading = false;
        _error = '';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // Stop listening
      final finalTranscript = await _sttService.stopListening();
      setState(() {
        _isListening = false;
        if (finalTranscript != null) {
          _transcript = finalTranscript;
        }
      });
    } else {
      // Start listening
      setState(() {
        _transcript = '';
        _error = '';
      });

      final success = await _sttService.startListening(_selectedLanguage);

      if (success) {
        setState(() {
          _isListening = true;
        });
      } else {
        setState(() {
          _error = 'Failed to start listening. Check microphone permissions.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STT Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeService,
            tooltip: 'Reinitialize',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: _availableLanguages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(_getLanguageName(lang)),
                      );
                    }).toList(),
                    onChanged: _isListening
                        ? null
                        : (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Microphone button
          Center(
            child: GestureDetector(
              onTap: _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? AppColors.accent : AppColors.surface,
                  border: Border.all(
                    color: _isListening
                        ? AppColors.accent
                        : AppColors.divider,
                    width: 2,
                  ),
                  boxShadow: _isListening
                      ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                      : null,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: _isListening
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status text
          Center(
            child: Text(
              _isListening ? 'Listening...' : 'Tap to speak',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isListening
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Transcript display
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transcribe,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transcript',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _transcript.isEmpty
                            ? Center(
                          child: Text(
                            'Your speech will appear here...',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        )
                            : Text(
                          _transcript,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error display
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Clear button
          if (_transcript.isNotEmpty && !_isListening)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _transcript = '';
                  _error = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    const names = {
      'en': 'English',
      'es': 'Spanish (Español)',
      'fr': 'French (Français)',
      'zh': 'Chinese (中文)',
    };
    return names[code] ?? code;
  }

  @override
  void dispose() {
    if (_isListening) {
      _sttService.stopListening();
    }
    super.dispose();
  }
}