// import 'package:flutter/material.dart';
// import 'package:prototype_ai_core/services/model_service.dart';
// import 'package:prototype_ai_core/services/stt_audio_service.dart';
// import 'package:prototype_ai_core/services/tts_service.dart';
// import 'package:prototype_ai_core/services/tts_audio_playback.dart';
//
// /// Demo screen showing STT + TTS pipeline
// /// (Translation step is placeholder for now)
// class CombinedSTTTTSDemoScreen extends StatefulWidget {
//   const CombinedSTTTTSDemoScreen({super.key});
//
//   @override
//   State<CombinedSTTTTSDemoScreen> createState() =>
//       _CombinedSTTTTSDemoScreenState();
// }
//
// class _CombinedSTTTTSDemoScreenState extends State<CombinedSTTTTSDemoScreen> {
//   final ModelService _modelService = ModelService();
//   late STTAudioService _sttService;
//   final TTSService _ttsService = TTSService();
//   final TTSAudioPlaybackService _playbackService = TTSAudioPlaybackService();
//
//   bool _isInitializing = true;
//   bool _isReady = false;
//   bool _isListening = false;
//   bool _isSpeaking = false;
//
//   String _statusMessage = 'Initializing...';
//   String _sourceLanguage = 'en'; // STT language
//   String _targetLanguage = 'es'; // TTS language
//   String _recognizedText = '';
//   String _translatedText = ''; // Placeholder: same as recognized for now
//
//   @override
//   void initState() {
//     super.initState();
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     setState(() {
//       _isInitializing = true;
//       _statusMessage = 'Loading models...';
//     });
//
//     try {
//       // Initialize model service
//       await _modelService.initialize();
//
//       // Load language pack
//       final packLoaded = await _modelService.loadLanguagePack('en-es');
//       if (!packLoaded) {
//         setState(() {
//           _statusMessage = '❌ Failed to load language pack';
//           _isInitializing = false;
//           _isReady = false;
//         });
//         return;
//       }
//
//       // Initialize STT service
//       _sttService = STTAudioService(_modelService.getSherpaService());
//
//       // Initialize TTS for target language
//       final packPath = _modelService.getPackPath('en-es');
//       if (packPath == null) {
//         setState(() {
//           _statusMessage = '❌ Pack path not found';
//           _isInitializing = false;
//           _isReady = false;
//         });
//         return;
//       }
//
//       final ttsReady = await _ttsService.initialize(packPath, _targetLanguage);
//       if (!ttsReady) {
//         setState(() {
//           _statusMessage = '❌ Failed to initialize TTS';
//           _isInitializing = false;
//           _isReady = false;
//         });
//         return;
//       }
//
//       setState(() {
//         _isReady = true;
//         _isInitializing = false;
//         _statusMessage = '✅ Ready! Tap microphone to speak.';
//       });
//     } catch (e) {
//       setState(() {
//         _statusMessage = '❌ Error: $e';
//         _isInitializing = false;
//         _isReady = false;
//       });
//     }
//   }
//
//   Future<void> _toggleListening() async {
//     if (_isListening) {
//       await _stopListening();
//     } else {
//       await _startListening();
//     }
//   }
//
//   Future<void> _startListening() async {
//     if (!_isReady || _isSpeaking) return;
//
//     setState(() {
//       _isListening = true;
//       _statusMessage = '🎤 Listening... Speak now!';
//       _recognizedText = '';
//       _translatedText = '';
//     });
//
//     _sttService.startListening(
//       onPartialResult: (text) {
//         setState(() {
//           _recognizedText = text;
//           _statusMessage = '🎤 Listening: "$text"';
//         });
//       },
//       onFinalResult: (text) async {
//         setState(() {
//           _recognizedText = text;
//           _isListening = false;
//         });
//
//         if (text.trim().isNotEmpty) {
//           await _processRecognizedText(text);
//         } else {
//           setState(() {
//             _statusMessage = '❌ No speech detected';
//           });
//         }
//       },
//       onError: (error) {
//         setState(() {
//           _isListening = false;
//           _statusMessage = '❌ Error: $error';
//         });
//       },
//     );
//   }
//
//   Future<void> _stopListening() async {
//     await _sttService.stopListening();
//     setState(() {
//       _isListening = false;
//       _statusMessage = '⏹️ Stopped listening';
//     });
//   }
//
//   Future<void> _processRecognizedText(String text) async {
//     setState(() {
//       _statusMessage = '🔄 Processing...';
//     });
//
//     // Step 1: Translation (PLACEHOLDER - just echo for now)
//     // TODO: Integrate CTranslate2 here
//     await Future.delayed(const Duration(milliseconds: 500)); // Simulate processing
//     final translatedText = text; // Placeholder: no actual translation yet
//
//     setState(() {
//       _translatedText = translatedText;
//       _statusMessage = '🔊 Speaking translation...';
//       _isSpeaking = true;
//     });
//
//     // Step 2: Synthesize speech
//     final audio = await _ttsService.synthesize(translatedText);
//     if (audio == null) {
//       setState(() {
//         _statusMessage = '❌ Failed to synthesize speech';
//         _isSpeaking = false;
//       });
//       return;
//     }
//
//     // Step 3: Play audio
//     final played = await _playbackService.playAudio(
//       audio.samples,
//       audio.sampleRate,
//     );
//
//     if (!played) {
//       setState(() {
//         _statusMessage = '❌ Failed to play audio';
//         _isSpeaking = false;
//       });
//       return;
//     }
//
//     // Wait for playback to complete
//     while (_playbackService.isPlaying) {
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//
//     setState(() {
//       _statusMessage = '✅ Done! Tap mic to try again.';
//       _isSpeaking = false;
//     });
//   }
//
//   Future<void> _switchLanguages() async {
//     if (_isListening || _isSpeaking) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Please wait for current operation to finish')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isInitializing = true;
//       _statusMessage = 'Switching languages...';
//     });
//
//     // Swap languages
//     final tempLang = _sourceLanguage;
//     _sourceLanguage = _targetLanguage;
//     _targetLanguage = tempLang;
//
//     // Reload TTS for new target language
//     final packPath = _modelService.getPackPath('en-es');
//     if (packPath != null) {
//       await _ttsService.initialize(packPath, _targetLanguage);
//     }
//
//     // Reload STT for new source language
//     await _modelService.loadLanguagePack('en-es');
//     _sttService = STTAudioService(_modelService.getSherpaService());
//
//     setState(() {
//       _isInitializing = false;
//       _isReady = true;
//       _statusMessage =
//           '✅ Switched! Speak $_sourceLanguage, hear $_targetLanguage';
//       _recognizedText = '';
//       _translatedText = '';
//     });
//   }
//
//   @override
//   void dispose() {
//     _sttService.dispose();
//     _ttsService.dispose();
//     _playbackService.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('🎙️ Voice Translator Demo'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Status
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: _isReady
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(
//                   color: _isReady ? Colors.green : Colors.orange,
//                 ),
//               ),
//               child: Text(
//                 _statusMessage,
//                 style: TextStyle(
//                   color: _isReady ? Colors.green[700] : Colors.orange[700],
//                   fontWeight: FontWeight.bold,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//
//             const SizedBox(height: 24),
//
//             // Language direction
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildLanguageChip(_sourceLanguage, true),
//                 const SizedBox(width: 16),
//                 const Icon(Icons.arrow_forward, size: 32),
//                 const SizedBox(width: 16),
//                 _buildLanguageChip(_targetLanguage, false),
//                 const SizedBox(width: 16),
//                 IconButton(
//                   icon: const Icon(Icons.swap_horiz),
//                   onPressed: _switchLanguages,
//                   tooltip: 'Switch languages',
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 32),
//
//             // Recognized text
//             _buildTextBox(
//               title: '🎤 You said ($_sourceLanguage):',
//               text: _recognizedText,
//               isEmpty: _recognizedText.isEmpty,
//               emptyMessage: 'Waiting for speech...',
//             ),
//
//             const SizedBox(height: 16),
//
//             // Translation indicator
//             if (_recognizedText.isNotEmpty)
//               const Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.translate, color: Colors.grey),
//                   SizedBox(width: 8),
//                   Text(
//                     '(Translation placeholder - just echoes for now)',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//
//             const SizedBox(height: 16),
//
//             // Translated text
//             _buildTextBox(
//               title: '🔊 Translation ($_targetLanguage):',
//               text: _translatedText,
//               isEmpty: _translatedText.isEmpty,
//               emptyMessage: 'Translation will appear here...',
//             ),
//
//             const Spacer(),
//
//             // Microphone button
//             Center(
//               child: GestureDetector(
//                 onTap: _isReady && !_isInitializing && !_isSpeaking
//                     ? _toggleListening
//                     : null,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _isListening ? Colors.red : Colors.deepPurple,
//                     boxShadow: _isListening
//                         ? [
//                             BoxShadow(
//                               color: Colors.red.withOpacity(0.5),
//                               blurRadius: 20,
//                               spreadRadius: 5,
//                             )
//                           ]
//                         : [],
//                   ),
//                   child: Icon(
//                     _isListening ? Icons.mic : Icons.mic_none,
//                     size: 50,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 16),
//
//             // Status indicators
//             if (_isInitializing || _isSpeaking || _isListening)
//               const Center(child: CircularProgressIndicator()),
//
//             const SizedBox(height: 8),
//
//             // Instruction
//             Text(
//               _isListening
//                   ? 'Listening... Tap to stop'
//                   : 'Tap microphone to speak',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLanguageChip(String lang, bool isSource) {
//     final flag = lang == 'en' ? '🇺🇸' : '🇪🇸';
//     final name = lang == 'en' ? 'English' : 'Spanish';
//     final label = isSource ? 'Speak' : 'Hear';
//
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 12,
//             color: Colors.grey[600],
//           ),
//         ),
//         const SizedBox(height: 4),
//         Chip(
//           avatar: Text(flag, style: const TextStyle(fontSize: 20)),
//           label: Text(name),
//           backgroundColor: isSource ? Colors.blue[50] : Colors.green[50],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextBox({
//     required String title,
//     required String text,
//     required bool isEmpty,
//     required String emptyMessage,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Text(
//             isEmpty ? emptyMessage : text,
//             style: TextStyle(
//               fontSize: 16,
//               color: isEmpty ? Colors.grey[500] : Colors.black87,
//               fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
