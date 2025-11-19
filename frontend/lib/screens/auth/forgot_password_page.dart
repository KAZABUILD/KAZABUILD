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
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/utils/error_utils.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Stack(
        children: [
          // Animated gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColorsDark.backgroundPrimary,
                        AppColorsDark.backgroundSecondary,
                        AppColorsDark.buttonPurple.withValues(alpha: 0.3),
                      ]
                    : [
                        AppColorsLight.backgroundPrimary,
                        AppColorsLight.backgroundSecondary.withValues(alpha: 0.5),
                        AppColorsLight.buttonPurple.withValues(alpha: 0.2),
                      ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColorsDark.buttonBlue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColorsDark.buttonPurple.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Top bar with back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(context, theme, isDark, emailRegex)
                    : _buildDesktopLayout(context, theme, isDark, emailRegex),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RegExp emailRegex,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _buildResetPasswordCard(context, theme, isDark, emailRegex),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RegExp emailRegex,
  ) {
    return Row(
      children: [
        // Left side - Visual/Illustration area
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and branding
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColorsDark.buttonBlue.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo/kaza.png',
                        width: 56,
                        height: 56,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColorsDark.buttonBlue,
                                  AppColorsDark.buttonPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.computer,
                              color: Colors.white,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'KAZABUILD',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No worries! Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.8)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Feature highlights
                _buildFeatureItem(
                  Icons.lock_reset,
                  'Secure Reset',
                  'We\'ll send you a secure link to reset your password',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.email,
                  'Email Verification',
                  'Check your inbox for the password reset link',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.security,
                  'Safe & Secure',
                  'Your account security is our top priority',
                  isDark,
                ),
              ],
            ),
          ),
        ),
        // Right side - Reset password form
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _buildResetPasswordCard(context, theme, isDark, emailRegex),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColorsDark.buttonBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResetPasswordCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    RegExp emailRegex,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColorsDark.buttonBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 48,
                      color: AppColorsDark.buttonBlue,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to receive a reset link',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Email field
              CustomTextField(
                controller: _emailController,
                label: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.disabled,
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

              // Send Reset Link button
              _ResetPasswordButton(
                isLoading: _isLoading,
                onPressed: _sendResetLink,
              ),
              const SizedBox(height: 20),

              // Back to login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      "Back to Login",
                      style: TextStyle(
                        color: AppColorsDark.buttonBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
          content: Text(getUserFriendlyError(e)),
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

/// A dedicated widget for the Reset Password button.
class _ResetPasswordButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ResetPasswordButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsDark.buttonBlue,
            AppColorsDark.buttonPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColorsDark.buttonBlue.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}
