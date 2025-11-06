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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';

/// A widget that renders the "Forgot Password" page.
/// It's a `ConsumerStatefulWidget` to manage local state (loading) and interact with Riverpod.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
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
            child: Form(
              key: _formKey,
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
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email address',
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress, // Suggests email keyboard.
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Button to submit the password reset request.
                  PrimaryButton(
                    text: _isLoading ? 'Sending Link...' : 'Send Reset Link',
                    icon: null,
                    onPressed: _isLoading ? null : _sendResetLink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the logic for sending the password reset link.
  void _sendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final successMessage = await ref
          .read(authProvider.notifier)
          .requestPasswordReset(_emailController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
