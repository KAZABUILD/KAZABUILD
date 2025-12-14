/// This file defines reusable action widgets commonly used in the app's `AppBar`.
///
/// It includes:
/// - [ThemeToggleButton]: An icon button to switch between light and dark themes.
/// - [LanguageSelector]: A dropdown menu to change the application's language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/theme_provider.dart';
import 'package:frontend/models/locale_provider.dart';

/// A `ConsumerWidget` that displays an icon button to toggle the app's theme.
///
/// It watches the [themeProvider] to determine the current theme and displays
/// either a light mode or dark mode icon accordingly.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Watch the [themeProvider] to get the current [ThemeMode] and rebuild when it changes.
    final currentTheme = ref.watch(themeProvider);
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        currentTheme ==
                ThemeMode
                    .dark // Dynamically change the icon based on the current theme.
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () {
        /// Call the notifier's method to toggle the theme, which updates the state.
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
}

/// A `ConsumerWidget` that provides a dropdown menu for language selection.
///
/// It displays the flag of the currently selected language and shows a list
/// of other available languages in a popup menu. It integrates with the
/// `localeProvider` to actually change the app's locale when a language is selected.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  /// A map containing the data for each supported language, including the
  /// asset path for its flag and its display name.
  static const Map<String, Map<String, String>> _languages = {
    'en': {'flag': 'assets/flags/uk_flag.png', 'name': 'English'},
    'tr': {'flag': 'assets/flags/tr_flag.png', 'name': 'Türkçe'},
    'pl': {'flag': 'assets/flags/pl_flag.png', 'name': 'Polski'},
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the locale provider to get the current language code
    final currentLocale = ref.watch(localeProvider);
    final selectedLanguageCode = currentLocale.languageCode;

    return PopupMenuButton<String>(
      onSelected: (String newLangCode) {
        // Update the locale using the provider, which will persist the choice
        // and trigger a rebuild of the entire app with the new language
        ref.read(localeProvider.notifier).setLocale(newLangCode);
      },
      itemBuilder: (BuildContext context) {
        /// Build the list of menu items, excluding the currently selected language.
        return _languages.keys
            .where((langCode) => langCode != selectedLanguageCode)
            .map((langCode) {
              return PopupMenuItem<String>(
                value: langCode,
                child: Row(
                  children: [
                    /// Display the flag image for the language, with a fallback icon.
                    Image.asset(
                      _languages[langCode]!['flag']!,
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.flag, size: 16), // Fallback icon
                    ),
                    const SizedBox(width: 8),
                    Text(_languages[langCode]!['name']!),
                  ],
                ),
              );
            })
            .toList();
      },

      /// The child of the [PopupMenuButton] is the widget that is always visible on the AppBar.
      /// It displays the flag of the currently selected language.
      child: Image.asset(
        _languages[selectedLanguageCode]!['flag']!,
        width: 24,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) =>
            Icon(Icons.language, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
