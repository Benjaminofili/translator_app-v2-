// lib/features/home/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_ai_core/features/translator/widget/translation_result_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/model_service.dart';
import '../../translator/widget/language_selector_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  final ModelService _modelService = ModelService();

  bool _isTranslating = false;
  bool _isFocused = false;
  String _sourceLanguage = 'en';
  String _targetLanguage = 'es';
  String _translatedText = '';

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Called on every keystroke to manage translation timing
  void _onTextChanged(String text) {
    // Cancel any existing timer
    _debounce?.cancel();

    if (text.isEmpty) {
      setState(() {
        _translatedText = '';
        _isTranslating = false;
      });
      return;
    }

    // Show loading indicator immediately
    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    // Start a new timer
    _debounce = Timer(_debounceDuration, () {
      _triggerTranslation(text);
    });
  }

  /// Triggers the actual (simulated) translation
  Future<void> _triggerTranslation(String text) async {
    // --- Simulate Translation ---
    // In a real app, you'd call:
    // final result = await _modelService.translate(
    //   text: text,
    //   sourceLanguage: _sourceLanguage,
    //   targetLanguage: _targetLanguage,
    // );

    await Future.delayed(const Duration(milliseconds: 750));

    // Check if text hasn't changed again while we were "translating"
    if (text != _textController.text) {
      return; // Stale request, user is typing again
    }

    setState(() {
      // if (result.success) {
      //   _translatedText = result.translated ?? '';
      // } else {
      //   _translatedText = 'Error: ${result.error}';
      // }

      // Simulated result:
      _translatedText = "This is the translated text for '$text'";
      _isTranslating = false;
    });
  }

  void _onSwapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;

      // Also swap text if there is a translation
      final tempText = _textController.text;
      _textController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableLanguages = AppConstants.languageNames;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppConstants.paddingMedium),

          // Language Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            decoration: AppTheme.getCardDecoration(),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: LanguageSelectorWidget(
                sourceLanguage: _sourceLanguage,
                targetLanguage: _targetLanguage,
                availableLanguages: availableLanguages,
                onSourceChanged: (code) => setState(() => _sourceLanguage = code),
                onTargetChanged: (code) => setState(() => _targetLanguage = code),
                onSwap: _onSwapLanguages,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Input Card - Minimal, clean design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Focus(
              onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: _isFocused ? AppColors.accent : AppColors.borderInactive,
                    width: _isFocused ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  cursorColor: AppColors.accent,
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: "Enter text to translate...",
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppConstants.paddingMedium),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _textController.clear();
                          _translatedText = '';
                          _isTranslating = false;
                          _debounce?.cancel();
                        });
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Result Card - Shows loading or translation
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMedium,
              0,
              AppConstants.paddingMedium,
              AppConstants.paddingMedium,
            ),
            child: _isTranslating
                ? Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Translating...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : _translatedText.isNotEmpty
                ? TranslationResultCard(
              title: 'Translation',
              text: _translatedText,
              language: availableLanguages[_targetLanguage] ?? _targetLanguage,
              icon: Icons.translate,
              isPrimary: true,
              onCopy: () {},
              onPlay: () {},
              onShare: () {},
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}