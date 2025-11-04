import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:prototype_ai_core/services/model_service.dart';

/// Simple TTS Test Screen using existing ModelService
///
/// This uses your ModelService.synthesizeSpeech() method which
/// already returns a file path to the generated audio.
class SimpleTTSTestScreen extends StatefulWidget {
  const SimpleTTSTestScreen({super.key});

  @override
  State<SimpleTTSTestScreen> createState() => _SimpleTTSTestScreenState();
}

class _SimpleTTSTestScreenState extends State<SimpleTTSTestScreen> {
  final ModelService _modelService = ModelService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _textController = TextEditingController();

  bool _isInitializing = true;
  bool _isReady = false;
  bool _isSpeaking = false;
  String _statusMessage = 'Initializing...';
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initialize();

    // Listen for playback completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _statusMessage = '✅ Done!';
        });
      }
    });
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _statusMessage = 'Loading models...';
    });

    try {
      // Initialize ModelService
      final initialized = await _modelService.initialize();
      if (!initialized) {
        setState(() {
          _statusMessage = '❌ Failed to initialize';
          _isInitializing = false;
          _isReady = false;
        });
        return;
      }

      // Load en-es pack
      final loadResult = await _modelService.loadPack('en-es');
      if (!loadResult.success) {
        setState(() {
          _statusMessage = '❌ ${loadResult.error}';
          _isInitializing = false;
          _isReady = false;
        });
        return;
      }

      setState(() {
        _isReady = true;
        _isInitializing = false;
        _statusMessage = '✅ Ready! Enter text and tap Speak.';
      });

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isInitializing = false;
        _isReady = false;
      });
    }
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
      return;
    }

    if (!_isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TTS not ready. Please wait.')),
      );
      return;
    }

    setState(() {
      _isSpeaking = true;
      _statusMessage = '🔊 Generating speech...';
    });

    try {
      // Use YOUR existing ModelService method
      final result = await _modelService.synthesizeSpeech(
        text: text,
        language: _selectedLanguage,
        speed: 1.0,
      );

      if (!result.success || result.audioPath == null) {
        setState(() {
          _statusMessage = '❌ ${result.error ?? "Failed to generate audio"}';
          _isSpeaking = false;
        });
        return;
      }

      setState(() {
        _statusMessage = '🔊 Playing...';
      });

      // Play the generated audio file
      await _audioPlayer.play(DeviceFileSource(result.audioPath!));

      // State will be updated by onPlayerComplete listener

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isSpeaking = false;
      });
    }
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _isSpeaking = false;
      _statusMessage = '⏹️ Stopped';
    });
  }

  Future<void> _changeLanguage(String language) async {
    if (_isSpeaking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for speech to finish')),
      );
      return;
    }

    setState(() {
      _selectedLanguage = language;
      _statusMessage = '✅ Switched to $language';
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔊 TTS Test'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isReady
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isReady ? Colors.green : Colors.orange,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _isReady ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Language selector
            Row(
              children: [
                const Text('Language: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('🇺🇸 English'),
                  selected: _selectedLanguage == 'en',
                  onSelected: _isReady && !_isSpeaking && !_isInitializing
                      ? (_) => _changeLanguage('en')
                      : null,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('🇪🇸 Spanish'),
                  selected: _selectedLanguage == 'es',
                  onSelected: _isReady && !_isSpeaking && !_isInitializing
                      ? (_) => _changeLanguage('es')
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Text input
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: _selectedLanguage == 'en'
                    ? 'Enter English text to speak...'
                    : 'Introduce texto en español...',
                border: const OutlineInputBorder(),
              ),
              enabled: _isReady && !_isSpeaking,
            ),

            const SizedBox(height: 16),

            // Quick test phrases
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedLanguage == 'en') ...[
                  _buildQuickPhraseChip('Hello, how are you?'),
                  _buildQuickPhraseChip('This is a test.'),
                  _buildQuickPhraseChip('The weather is nice today.'),
                ] else ...[
                  _buildQuickPhraseChip('Hola, ¿cómo estás?'),
                  _buildQuickPhraseChip('Esta es una prueba.'),
                  _buildQuickPhraseChip('El clima es agradable hoy.'),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // Speak/Stop buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isReady && !_isSpeaking && !_isInitializing
                        ? _speak
                        : null,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Speak'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSpeaking ? _stop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Loading indicator
            if (_isInitializing || _isSpeaking)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPhraseChip(String phrase) {
    return ActionChip(
      label: Text(phrase),
      onPressed: _isReady && !_isSpeaking
          ? () {
        setState(() {
          _textController.text = phrase;
        });
      }
          : null,
    );
  }
}