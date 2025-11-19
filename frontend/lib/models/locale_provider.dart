/// This file defines the state management for the application's locale (language).
///
/// It uses Riverpod to allow users to switch between English, Polish, and Turkish.
/// The selected locale is persisted to SharedPreferences and made available globally
/// so that the entire UI can react to language changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localization.dart';

/// A `StateNotifier` that manages the application's current [Locale].
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'app_locale';
  static const Locale _defaultLocale = Locale('en');

  /// Initializes the notifier with a locale from SharedPreferences or default.
  LocaleNotifier() : super(_defaultLocale) {
    // Load locale asynchronously, but don't block initialization
    _loadLocale();
  }

  /// Loads the saved locale from SharedPreferences.
  /// This is called asynchronously, so the initial state will be the default locale
  /// until the saved preference is loaded.
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        final locale = Locale(localeCode);
        // Verify that the locale is supported
        if (AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
          state = locale;
        }
      }
    } catch (e) {
      // If loading fails, use default locale
      debugPrint('Error loading locale: $e');
    }
  }

  /// Sets the locale to a specific language code.
  /// This persists the choice to SharedPreferences and updates the state.
  Future<void> setLocale(String languageCode) async {
    final locale = Locale(languageCode);
    // Verify that the locale is supported
    if (!AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      debugPrint('Unsupported locale: $languageCode');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      state = locale;
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Sets the locale directly from a Locale object.
  Future<void> setLocaleFromLocale(Locale locale) async {
    await setLocale(locale.languageCode);
  }
}

/// A global provider that exposes the [LocaleNotifier] and its state ([Locale]).
///
/// Widgets can `watch` this provider to rebuild when the locale changes, or
/// `read` it to access the notifier's methods like `setLocale`.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

