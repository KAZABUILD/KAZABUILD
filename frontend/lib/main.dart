/// This file is the main entry point for the KazaBuild Flutter application.
///
/// It initializes the app, sets up the root widget (`MyApp`), and configures
/// global state management using Riverpod by wrapping the entire app in a
/// `ProviderScope`. It also defines the top-level `MaterialApp` and connects
/// it to the theme provider to enable dynamic theme switching.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/router.dart';
import 'core/theme/app_theme.dart';
import 'widgets/theme_provider.dart';

/// The main function that runs when the application starts.
void main() {
  // runApp() inflates the given widget and attaches it to the screen.
  // ProviderScope is the widget that stores the state of all Riverpod providers.
  // All Flutter applications using Riverpod must have a ProviderScope at the
  // root of their widget tree.
  runApp(const ProviderScope(child: MyApp()));
}

/// The root widget of the application.
///
/// It's a `ConsumerWidget` which allows it to listen to Riverpod providers.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the `themeProvider` for changes. When the theme mode changes
    // (e.g., from light to dark), this widget will rebuild to apply the new theme.
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // MaterialApp is the root of the app's UI, providing routing, theming,
    // and other core functionalities.
    return MaterialApp.router(
      title: 'Kaza Build',

      // Defines the theme to use when the app is in light mode.
      theme: AppTheme.lightTheme,
      // Defines the theme to use when the app is in dark mode.
      darkTheme: AppTheme.darkTheme,

      // The `themeMode` is controlled by the `themeProvider`, allowing for
      // dynamic switching between light, dark, or system default themes.
      themeMode: themeMode,

      // Hides the "debug" banner in the top-right corner of the app.
      debugShowCheckedModeBanner: false,
      // The router configuration from our router provider.
      routerConfig: router,
    );
  }
}
