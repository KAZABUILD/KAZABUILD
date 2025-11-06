/// This file contains a collection of reusable widgets specifically designed
/// for the authentication screens (e.g., Login, Sign Up, Forgot Password).
///
/// These widgets help maintain a consistent look and feel across all auth-related
/// pages and reduce code duplication. The collection includes:
/// - [Header]: The app logo and title.
/// - [PrimaryButton]: A standard call-to-action button.
/// - [SocialButton]: Buttons for third-party authentication (Google, etc.).
/// - [OrDivider]: A visual separator with text.
/// - [CustomTextField]: A styled text input field with validation and other features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A widget that displays the application's logo and name, used as a header
/// on authentication screens.
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // The main application icon.
        Icon(Icons.build_circle, color: theme.colorScheme.primary, size: 48),
        const SizedBox(height: 16),
        Text(
          'KAZABUILD',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        // A subtitle or slogan for the application.
        Text('PC Building Platform', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  /// The text to display on the button.
  final String text;

  /// An optional icon to display to the left of the text.
  final IconData? icon;

  /// The callback function that is executed when the button is pressed.
  final VoidCallback? onPressed;

  /// Creates a primary call-to-action button with a consistent style.
  const PrimaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // If an icon is provided, display it with some spacing.
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(text),
        ],
      ),
    );
  }
}

/// A button designed for social media sign-in options (e.g., Google, GitHub).
class SocialButton extends StatelessWidget {
  /// The text to display on the button (e.g., "Continue with Google").
  final String text;

  /// The asset path for the social media icon (can be SVG or other image formats).
  final String iconPath;

  /// The callback function that is executed when the button is pressed.
  final VoidCallback? onPressed;

  /// Creates a styled button for social media authentication.
  const SocialButton(
      {super.key, required this.text, required this.iconPath, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Conditionally render an SVG or a standard Image based on the file extension.
          if (iconPath.endsWith('.svg'))
            SvgPicture.asset(iconPath, height: 20, width: 20)
          else
            Image.asset(
              iconPath,
              height: 20,
              width: 20,
              errorBuilder: (c, e, s) {
                // Display a fallback error icon if the image fails to load.
                return const Icon(Icons.error, size: 20);
              },
            ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

/// A visual separator widget that consists of a horizontal line with text in the middle.
/// Commonly used to separate email login from social login options.
class OrDivider extends StatelessWidget {
  /// The text to display in the middle of the divider. Defaults to 'or continue with'.
  final String text;

  const OrDivider({super.key, this.text = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(text),
          ),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }
}

/// A simple decorative widget that draws a colored circle.
/// Can be used in the background of screens for visual effect.
class BackgroundCircle extends StatelessWidget {
  /// The color of the circle.
  final Color color;

  /// The diameter of the circle.
  final double radius;

  /// Creates a circular decoration.
  const BackgroundCircle({
    super.key,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// A customized `TextFormField` tailored for authentication forms.
///
/// It includes a label, a prefix icon, and optional password visibility toggle,
/// validation, and other standard `TextFormField` properties.
class CustomTextField extends StatefulWidget {
  /// The text that describes the input field.
  final String label;

  /// The icon to display at the beginning of the input field.
  final IconData icon;

  /// If true, the text field will be styled for password entry with an obscuring character
  /// and a visibility toggle icon.
  final bool isPassword;

  /// A controller for an editable text field.
  final TextEditingController? controller;

  /// An optional method that validates an input. Returns an error string to display if the input is invalid, or null otherwise.
  final String? Function(String?)? validator;

  /// The type of keyboard to use for editing the text.
  final TextInputType? keyboardType;

  /// Used to enable/disable this form field auto validation and update its error text.
  final AutovalidateMode? autovalidateMode;

  /// Whether the text can be changed.
  final bool readOnly;

  /// A callback that is triggered when the user taps on the text field.
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.autovalidateMode,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  /// Manages the visibility state of the password text.
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color?.withOpacity(0.5);
    
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(
          widget.icon,
          color: iconColor,
        ),
        // If it's a password field, show an icon button to toggle text visibility.
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
      ),
    );
  }
}
