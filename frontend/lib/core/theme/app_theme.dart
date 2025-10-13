import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class AppTheme {
  // -------------------
  // DARK THEME
  // -------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.buttonBlue,
      secondary: AppColorsLight.buttonGreen,
      background: AppColorsLight.backgroundPrimary,
      surface: AppColorsLight
          .backgroundTertiary, // Kartlar, appbarlar vb. için biraz farklı bir ton
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: AppColorsLight.textBlack,
      onSurface: AppColorsLight.textBlack,
      error: AppColorsLight.error,
      errorContainer: Color.fromARGB(255, 255, 215, 215),
      primaryContainer: AppColorsLight.backgroundSecondary,
      onPrimaryContainer: AppColorsLight.textBlack,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColorsLight.textBlack),
      displayMedium: TextStyle(color: AppColorsLight.textBlack),
      displaySmall: TextStyle(color: AppColorsLight.textBlack),
      headlineLarge: TextStyle(color: AppColorsLight.textBlack),
      headlineMedium: TextStyle(color: AppColorsLight.textBlack),
      headlineSmall: TextStyle(color: AppColorsLight.textBlack),
      titleLarge: TextStyle(color: AppColorsLight.textBlack),
      titleMedium: TextStyle(color: AppColorsLight.textBlack),
      titleSmall: TextStyle(color: AppColorsLight.textBlack),
      bodyLarge: TextStyle(color: AppColorsLight.textBlack),
      bodyMedium: TextStyle(color: AppColorsLight.textBlack),
      bodySmall: TextStyle(color: AppColorsLight.textBlack),
      labelLarge: TextStyle(color: AppColorsLight.textBlack),
      labelMedium: TextStyle(color: AppColorsLight.textBlack),
      labelSmall: TextStyle(color: AppColorsLight.textBlack),
    ),
    scaffoldBackgroundColor: AppColorsLight.backgroundPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsLight.backgroundTertiary,
      foregroundColor: AppColorsLight.textBlack,
    ),
    iconTheme: const IconThemeData(color: AppColorsLight.textBlack),
    dividerTheme: DividerThemeData(color: Colors.grey.shade300),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsLight.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // --- KARANLIK TEMA ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.buttonBlue,
      secondary: AppColorsDark.buttonGreen,
      background: AppColorsDark.backgroundPrimary,
      surface: AppColorsDark.backgroundSecondary, // Kartlar, appbarlar vb.
      onPrimary: AppColorsDark.textWhite,
      onSecondary: AppColorsDark.textWhite,
      onBackground: AppColorsDark.textWhite,
      onSurface: AppColorsDark.textWhite,
      error: AppColorsDark.error,
      errorContainer: Color.fromARGB(255, 122, 12, 4),
      primaryContainer: AppColorsDark.buttonPurple,
      onPrimaryContainer: AppColorsDark.textWhite,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColorsDark.textWhite),
      displayMedium: TextStyle(color: AppColorsDark.textWhite),
      displaySmall: TextStyle(color: AppColorsDark.textWhite),
      headlineLarge: TextStyle(color: AppColorsDark.textWhite),
      headlineMedium: TextStyle(color: AppColorsDark.textWhite),
      headlineSmall: TextStyle(color: AppColorsDark.textWhite),
      titleLarge: TextStyle(color: AppColorsDark.textWhite),
      titleMedium: TextStyle(color: AppColorsDark.textWhite),
      titleSmall: TextStyle(color: AppColorsDark.textWhite),
      bodyLarge: TextStyle(color: AppColorsDark.textWhite),
      bodyMedium: TextStyle(color: AppColorsDark.textWhite),
      bodySmall: TextStyle(color: AppColorsDark.textWhite),
      labelLarge: TextStyle(color: AppColorsDark.textWhite),
      labelMedium: TextStyle(color: AppColorsDark.textWhite),
      labelSmall: TextStyle(color: AppColorsDark.textWhite),
    ),
    scaffoldBackgroundColor: AppColorsDark.backgroundPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColorsDark.backgroundSecondary,
      foregroundColor: AppColorsDark.textWhite,
    ),
    iconTheme: const IconThemeData(color: AppColorsDark.textWhite),
    dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.2)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorsDark.backgroundTertiary.withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
