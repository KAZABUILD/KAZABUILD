/// This file defines the state management for the application's theme.
///
/// It uses Riverpod to allow users to switch between light, dark, and system
/// default themes. The selected theme is made available globally so that the
/// entire UI can react to changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A `StateNotifier` that manages the application's current [ThemeMode].
class ThemeNotifier extends StateNotifier<ThemeMode> {
  /// Initializes the notifier with a default theme. Here, it's set to dark mode.
  // TODO: Load the user's saved theme preference from local storage (e.g., SharedPreferences)
  // instead of hardcoding the default to `ThemeMode.dark`.
  ThemeNotifier() : super(ThemeMode.dark);

  /// Toggles the theme between light and dark mode.
  /// This is a simple convenience method for a direct switch.
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Sets the theme to a specific [ThemeMode].
  /// This is used by the settings page to allow selection of light, dark, or system theme.
  void setTheme(ThemeMode themeMode) {
    state = themeMode;
  }
}

/// A global provider that exposes the [ThemeNotifier] and its state ([ThemeMode]).
///
/// Widgets can `watch` this provider to rebuild when the theme changes, or
/// `read` it to access the notifier's methods like `toggleTheme` and `setTheme`.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
