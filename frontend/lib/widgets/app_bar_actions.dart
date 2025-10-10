import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        currentTheme == ThemeMode.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
}

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({super.key});
  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguageCode = 'uk';

  final Map<String, Map<String, String>> _languages = {
    'uk': {'flag': 'assets/uk_flag.png', 'name': 'English'},
    'tr': {'flag': 'assets/tr_flag.png', 'name': 'Türkçe'},
    'pl': {'flag': 'assets/pl_flag.png', 'name': 'Polski'},
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String newLangCode) {
        setState(() {
          _selectedLanguageCode = newLangCode;
        });
        log('${_languages[newLangCode]!['name']} choose.');
      },
      itemBuilder: (BuildContext context) {
        return _languages.keys
            .where((langCode) => langCode != _selectedLanguageCode)
            .map((langCode) {
              return PopupMenuItem<String>(
                value: langCode,
                child: Row(
                  children: [
                    Image.asset(
                      _languages[langCode]!['flag']!,
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.flag, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(_languages[langCode]!['name']!),
                  ],
                ),
              );
            })
            .toList();
      },
      child: Image.asset(
        _languages[_selectedLanguageCode]!['flag']!,
        width: 24,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) =>
            Icon(Icons.language, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
