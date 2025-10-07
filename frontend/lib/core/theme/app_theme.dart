import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class AppTheme {

  /// TODO fix colors
  /// Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.backgroundPrimary,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColorsDark.textWhite),
      bodyMedium: TextStyle(color: AppColorsDark.textNeon),
      labelLarge: TextStyle(color: AppColorsDark.textPurple),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsDark.buttonBlue,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsDark.buttonGreen,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsDark.buttonPurple,
      ),
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColorsDark.buttonBlue,
      secondary: AppColorsDark.buttonGreen,
      surface: AppColorsDark.backgroundSecondary,
      error: AppColorsDark.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
  );

  /// Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.backgroundPrimary,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: AppColorsLight.textBlack),
      bodyMedium: TextStyle(color: AppColorsLight.textNeon),
      labelLarge: TextStyle(color: AppColorsLight.textPurple),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsLight.buttonBlue,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColorsLight.buttonGreen,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorsLight.buttonGreen,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColorsLight.buttonBlue,
      secondary: AppColorsLight.buttonGreen,
      surface: AppColorsLight.backgroundSecondary,
      error: AppColorsLight.error,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
    ),
  );

}
