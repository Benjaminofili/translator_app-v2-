import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_ai_core/features/translator/screens/stt_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import 'package:prototype_ai_core/features/translator/screens/translation_screen.dart';
import '../../translator/widget/language_selector_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();
  bool _isTranslating = false;
  bool _isFocused = false;
  bool _buttonPressed = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTranslate() async {
    if (_textController.text.isEmpty) return;
    setState(() => _isTranslating = true);

    await Future.delayed(const Duration(milliseconds: AppConstants.mediumDuration));

    setState(() => _isTranslating = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TranslatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableLanguages = AppConstants.languageNames;

    return Scaffold(
      // use AppTheme.darkTheme scaffoldBackgroundColor via theme; explicit keeps parity with your design system
      backgroundColor: AppColors.deepOcean,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppColors.deepOcean,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppConstants.paddingMedium),

          // Language Selector card (uses AppTheme.getCardDecoration)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            decoration: AppTheme.getCardDecoration(glowColor: AppColors.aquaAccent),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: LanguageSelectorWidget(
                sourceLanguage: 'en',
                targetLanguage: 'es',
                availableLanguages: availableLanguages,
                onSourceChanged: (code) {},
                onTargetChanged: (code) {},
                onSwap: () {},
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Input Card using theme tokens
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Focus(
              onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: AppConstants.microDuration),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: _isFocused ? AppColors.electricPurple : AppColors.surfaceCard,
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                    BoxShadow(
                      color: AppColors.electricPurple.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [],
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  cursorColor: AppColors.electricPurple,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    // Use your InputDecorationTheme from AppTheme; override only where necessary
                    hintText: "Type text to translate...",
                    hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingMedium,
                      vertical: AppConstants.paddingMedium,
                    ),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() => _textController.clear());
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Gradient Translate Button using gradientPrimary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: AnimatedScale(
              scale: _buttonPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: AppConstants.microDuration),
              child: GestureDetector(
                onTapDown: (_) {
                  HapticFeedback.lightImpact();
                  setState(() => _buttonPressed = true);
                },
                onTapUp: (_) => setState(() => _buttonPressed = false),
                onTapCancel: () => setState(() => _buttonPressed = false),
                child: Opacity(
                  opacity: _textController.text.isEmpty ? 0.6 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.gradientPrimary),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricPurple.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _textController.text.isEmpty || _isTranslating ? null : _onTranslate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: _isTranslating
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text("Translate"),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Voice Translation Button (gradient circular, themed)
          Center(
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppConstants.micButtonSize / 2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SttScreen()),
                    );
                  },
                  child: Ink(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.gradientPrimary),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricPurple.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(AppConstants.paddingMedium),
                      child: Icon(Icons.mic, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                const Text(
                  "Voice Translation",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.paddingLarge),

          // Empty State / Recent Translations Placeholder (themed)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history_outlined, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    "No recent translations yet",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    "Your translation history will appear here",
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
