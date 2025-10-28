// lib/features/translator/widgets/language_selector_widget.dart
import 'package:flutter/material.dart';

/// 🌐 Language Selector Widget
/// 
/// Displays source and target language dropdowns with swap button
class LanguageSelectorWidget extends StatelessWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Map<String, String> availableLanguages;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onSwap;

  const LanguageSelectorWidget({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.availableLanguages,
    required this.onSourceChanged,
    required this.onTargetChanged,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Source Language
          Expanded(
            child: _buildLanguageDropdown(
              context: context,
              value: sourceLanguage,
              onChanged: onSourceChanged,
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
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz, color: Colors.white),
              tooltip: 'Swap languages',
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Target Language
          Expanded(
            child: _buildLanguageDropdown(
              context: context,
              value: targetLanguage,
              onChanged: onTargetChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required BuildContext context,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A2E),
          style: Theme.of(context).textTheme.titleMedium,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          items: availableLanguages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}