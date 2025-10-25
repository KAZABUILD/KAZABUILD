/// This file contains reusable custom button widgets for the application.
///
/// It aims to centralize button styles and behaviors to ensure a consistent
/// look and feel across different parts of the app.
library;

import 'package:flutter/material.dart';

/// A custom-styled button, typically used for primary call-to-action prompts
/// like "Start Build" or "Take Quiz" on the homepage.
class CustomStartButton extends StatelessWidget {
  /// The text to display on the button.
  final String label;

  /// The callback function that is executed when the button is pressed.
  /// If null, the button will be visually disabled.
  final VoidCallback? onPressed;

  /// Creates a custom-styled call-to-action button.
  const CustomStartButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      // Uses the default elevated button style from the app's theme for consistency.
      style: theme.elevatedButtonTheme.style,
      // If no onPressed callback is provided, the button will be disabled.
      onPressed: onPressed,
      child: Text(
        label,
        
        // Applies a bold style to the button's text.
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
