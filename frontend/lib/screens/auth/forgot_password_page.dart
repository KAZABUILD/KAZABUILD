/// This file defines the UI for the "Forgot Password" screen.
///
/// It provides a simple form where users can enter their email address
/// to receive a password reset link. This page is typically accessed from
/// the login screen.
///
/// It utilizes reusable authentication widgets like `CustomTextField` and
/// `PrimaryButton` to maintain a consistent UI across authentication flows.
library;

import 'package:flutter/material.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';

/// A stateless widget that renders the "Forgot Password" page.
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The Scaffold provides the basic visual structure for the page.
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // AppBar for navigation back to the previous screen.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // A back button to return to the previous screen (usually the login page).
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          // Pops the current route off the navigator stack.
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Stretches children horizontally.
              children: [
                // Page title.
                Text(
                  'Reset Password',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Instructional text guiding the user on how to proceed.
                Text(
                  'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                // Custom text field for email input.
                // This widget provides consistent styling and functionality for input fields.
                const CustomTextField(
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType:
                      TextInputType.emailAddress, // Suggests email keyboard.
                ),
                const SizedBox(height: 24),
                // Button to submit the password reset request.
                // TODO: Implement the onPressed logic to call the authentication service.
                const PrimaryButton(text: 'Send Reset Link', icon: null),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
