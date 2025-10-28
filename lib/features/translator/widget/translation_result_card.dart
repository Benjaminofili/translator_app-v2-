// lib/features/translator/widgets/translation_result_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📝 Translation Result Card Widget
/// 
/// Displays original or translated text with action buttons
class TranslationResultCard extends StatelessWidget {
  final String title;
  final String text;
  final String language;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback? onCopy;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;

  const TranslationResultCard({
    super.key,
    required this.title,
    required this.text,
    required this.language,
    required this.icon,
    this.isPrimary = false,
    this.onCopy,
    this.onPlay,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          
          const SizedBox(height: 12),
          
          // Text Content
          Text(
            text,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action Buttons
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Copy Button
        if (onCopy != null)
          _ActionButton(
            icon: Icons.copy,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
              onCopy?.call();
            },
          ),
        
        // Play Button
        if (onPlay != null)
          _ActionButton(
            icon: Icons.volume_up,
            tooltip: 'Play',
            onPressed: onPlay!,
          ),
        
        // Share Button
        if (onShare != null)
          _ActionButton(
            icon: Icons.share,
            tooltip: 'Share',
            onPressed: onShare!,
          ),
      ],
    );
  }
}

/// Internal action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      color: Colors.white70,
      splashRadius: 24,
    );
  }
}