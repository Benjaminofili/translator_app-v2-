import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'package:country_flags/country_flags.dart';

/// Extracts clean display name for chips (e.g., "English" from "English (English)")
String shortName(String fullLabel) {
  switch (fullLabel.split('(').first.trim().toLowerCase()) {
    case 'english': return 'Eng';
    case 'spanish': return 'Esp';
    case 'french': return 'Fr';
    case 'chinese': return 'Zh';
    default: return fullLabel.split('(').first.trim();
  }
}

/// In-memory persistence stub for recents/favorites (replace with SharedPreferences later)
class _LanguagePrefs {
  static final List<String> recents = <String>[];
  static final Set<String> favorites = <String>{};

  static void addRecent(String code) {
    recents.remove(code);
    recents.insert(0, code);
    if (recents.length > 8) recents.removeLast();
  }

  static void toggleFavorite(String code) {
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
  }
}

/// Premium Language Selector with bottom sheet, search, flags, and animated swap
class LanguageSelectorWidget extends StatefulWidget {
  final String sourceLanguage;
  final String targetLanguage;
  final Map<String, String> availableLanguages; // e.g., {'en': 'English (English)'}
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
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  double _swapTurns = 0.0; // 0.0 or 0.5
  bool _swapPressed = false;

  void _handleSwapTap() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _swapPressed = true;
      _swapTurns = _swapTurns == 0.0 ? 0.5 : 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 140));
    setState(() => _swapPressed = false);

    widget.onSwap();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.getCardDecoration(glowColor: AppColors.aquaAccent),
      child: Row(
        children: [
          Expanded(
            child: _LanguageChip(
              code: widget.sourceLanguage,
              label: widget.availableLanguages[widget.sourceLanguage] ?? widget.sourceLanguage,
              onTap: () => _showLanguageBottomSheet(
                context,
                isSource: true,
                onChanged: widget.onSourceChanged,
              ),
            ),
          ),
          const SizedBox(width: 16),
          AnimatedScale(
            scale: _swapPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedRotation(
              turns: _swapTurns,
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _handleSwapTap,
                child: Ink(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppColors.gradientPrimary),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.swap_horiz, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _LanguageChip(
              code: widget.targetLanguage,
              label: widget.availableLanguages[widget.targetLanguage] ?? widget.targetLanguage,
              onTap: () => _showLanguageBottomSheet(
                context,
                isSource: false,
                onChanged: widget.onTargetChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageBottomSheet(
      BuildContext context, {
        required bool isSource,
        required ValueChanged<String> onChanged,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.midnightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        String query = '';
        String? selected = isSource ? widget.sourceLanguage : widget.targetLanguage;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final entries = widget.availableLanguages.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value));

            final filtered = query.isEmpty
                ? entries
                : entries.where((e) => e.value.toLowerCase().contains(query.toLowerCase())).toList();

            final recentCodes = _LanguagePrefs.recents.where(widget.availableLanguages.containsKey).toList();
            final favoriteCodes = _LanguagePrefs.favorites.where(widget.availableLanguages.containsKey).toList();

            void select(String code) {
              Navigator.pop(context);
              onChanged(code);
              _LanguagePrefs.addRecent(code);
              HapticFeedback.lightImpact();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom, // keyboard-aware
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      "Select ${isSource ? "Source" : "Target"} Language",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),

                    // Search bar
                    TextField(
                      onChanged: (val) => setSheetState(() => query = val),
                      style: const TextStyle(color: Colors.white),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Search languages...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () => setSheetState(() => query = ''),
                        )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: ListView(
                        children: [
                          // Favorites
                          if (favoriteCodes.isNotEmpty) ...[
                            const _SectionTitle("Favorites"),
                            for (final code in favoriteCodes)
                              _LanguageTile(
                                code: code,
                                label: widget.availableLanguages[code]!,
                                selected: selected == code,
                                isFavorite: true,
                                onTap: () => select(code),
                                onToggleFavorite: () {
                                  setSheetState(() => _LanguagePrefs.toggleFavorite(code));
                                },
                              ),
                            const Divider(),
                          ],

                          // Recents
                          if (recentCodes.isNotEmpty) ...[
                            const _SectionTitle("Recently used"),
                            for (final code in recentCodes)
                              _LanguageTile(
                                code: code,
                                label: widget.availableLanguages[code]!,
                                selected: selected == code,
                                onTap: () => select(code),
                                onToggleFavorite: () {
                                  setSheetState(() => _LanguagePrefs.toggleFavorite(code));
                                },
                              ),
                            const Divider(),
                          ],

                          // All languages
                          const _SectionTitle("All languages"),
                          if (filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.search_off, color: Colors.white54),
                                  SizedBox(width: 8),
                                  Text("No matches found", style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            )
                          else
                            for (final e in filtered)
                              _LanguageTile(
                                code: e.key,
                                label: e.value,
                                selected: selected == e.key,
                                onTap: () => select(e.key),
                                onToggleFavorite: () {
                                  setSheetState(() => _LanguagePrefs.toggleFavorite(e.key));
                                },
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Chip with flag + label + dropdown icon, with ripple feedback
class _LanguageChip extends StatelessWidget {
  final String code;
  final String label;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.code,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            CountryFlag.fromLanguageCode(code, theme:const ImageTheme( height: 20, width: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shortName(label),
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// List tile with flag, label, selected indicator, and favorite toggle
class _LanguageTile extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _LanguageTile({
    required this.code,
    required this.label,
    required this.onTap,
    required this.onToggleFavorite,
    this.selected = false,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selected)
          const Icon(Icons.check_circle, color: Colors.white70, size: 20),
        IconButton(
          icon: Icon(
            isFavorite || _LanguagePrefs.favorites.contains(code)
                ? Icons.star
                : Icons.star_border,
            color: Colors.white70,
            size: 20,
          ),
          onPressed: onToggleFavorite,
          tooltip: 'Favorite',
        ),
      ],
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CountryFlag.fromLanguageCode(code, theme: const ImageTheme(height: 24, width: 32),),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white70,
        ),
      ),
    );
  }
}