import 'package:flutter/material.dart';
import '../constants/app_color.dart';

class AppTheme {
  // -------------------
  // DARK THEME
  // -------------------
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColorsDark.backgroundPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColorsDark.buttonPurple,
      secondary: AppColorsDark.buttonGreen,
      background: AppColorsDark.backgroundPrimary,
      surface: AppColorsDark.backgroundSecondary,
      onPrimary: AppColorsDark.textWhite,
      onSecondary: AppColorsDark.textWhite,
      onBackground: AppColorsDark.textWhite,
      onSurface: AppColorsDark.textWhite,
      error: AppColorsDark.error,
      onError: AppColorsDark.textWhite,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AppColorsDark.textWhite,
      displayColor: AppColorsDark.textWhite,
    ),
    iconTheme: const IconThemeData(color: AppColorsDark.textWhite),
  );

  // -------------------
  // LIGHT THEME
  // -------------------
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColorsLight.backgroundPrimary,
    colorScheme: const ColorScheme.light(
      primary: AppColorsLight.buttonPurple,
      secondary: AppColorsLight.buttonGreen,
      background: AppColorsLight.backgroundPrimary,
      surface: AppColorsLight.backgroundTertiary,
      onPrimary: AppColorsLight.backgroundPrimary,
      onSecondary: AppColorsLight.backgroundPrimary,
      onBackground: AppColorsLight.textBlack,
      onSurface: AppColorsLight.textBlack,
      error: AppColorsLight.error,
      onError: AppColorsLight.backgroundPrimary,
    ),

    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AppColorsLight.textBlack,
      displayColor: AppColorsLight.textBlack,
    ),

    iconTheme: const IconThemeData(color: AppColorsLight.textBlack),
  );
}
