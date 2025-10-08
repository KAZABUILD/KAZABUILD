import 'package:flutter/material.dart';

class LanguageSelector extends StatefulWidget {
  final String defaultLanguage;
  const LanguageSelector({super.key, this.defaultLanguage = 'en'});

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String selectedLanguage;
  bool _hovering = false;

  final languages = {'en': '🇬🇧', 'pl': '🇵🇱', 'tr': '🇹🇷'};

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.defaultLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Text(
            languages[selectedLanguage]!,
            style: const TextStyle(fontSize: 24),
          ),

          if (_hovering)
            Positioned(
              top: 26,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black54,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: languages.entries.map((entry) {
                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedLanguage = entry.key);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
