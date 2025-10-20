/// This file defines the UI for the user login screen.
///
/// It includes a form for users to enter their credentials, links to sign up
/// or reset their password, and options for social media login.
/// It uses Riverpod for state management to handle the authentication process.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the login page.
/// It's a `ConsumerStatefulWidget` to interact with Riverpod providers.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A key to manage the form state, used for validation.
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: false),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          // The main navigation bar, configured not to show profile details on this page.
          CustomNavigationBar(
            showProfileArea: false,
            scaffoldKey: _scaffoldKey,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ensures the content is scrollable on smaller screens.
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),

                          // The main login form.
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // App logo and title.
                                const Header(),
                                const SizedBox(height: 32),
                                // Toggle buttons for switching between Sign In and Sign Up.
                                _AuthToggleButtons(
                                  isSignIn: true,
                                  onSignUpTap: () {
                                    // Navigates to the SignUpPage with a fade transition.
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            const SignUpPage(),
                                        transitionsBuilder: (_, a, __, c) =>
                                            FadeTransition(
                                              opacity: a,
                                              child: c,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Continue building your dream PC',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                                // Text fields for username/email and password.
                                CustomTextField(
                                  label: 'Username or Email',
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'This field cannot be empty'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'This field cannot be empty'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // "Remember me" checkbox.
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: true,
                                          onChanged: (v) {},
                                        ),
                                        const Text('Remember me'),
                                      ],
                                    ),
                                    // "Forgot password?" link.
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      child: const Text('Forgot password?'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // The primary sign-in button.
                                PrimaryButton(
                                  text: 'Sign In',
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    // Validate the form before proceeding.
                                    if (_formKey.currentState!.validate()) {
                                      // TODO: Implement actual sign-in logic here.
                                      // For now, it just reads the provider and navigates home.
                                      ref.read(authProvider.notifier);

                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    }
                                  },
                                ),
                                // Divider with "OR" text.
                                const OrDivider(),
                                // Social login buttons.
                                const SocialButton(
                                  text: 'Continue with Google',
                                  iconPath: 'google_icon.svg.webp',
                                ),
                                const SizedBox(height: 12),
                                const SocialButton(
                                  text: 'Continue with GitHub',
                                  iconPath: 'github_icon.svg',
                                ),
                                const SizedBox(height: 12),
                                const SocialButton(
                                  text: 'Continue with Discord',
                                  iconPath: 'discord_icon.svg',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays "Sign In" and "Sign Up" toggle buttons.
/// The currently active button is styled differently.
class _AuthToggleButtons extends StatelessWidget {
  final bool isSignIn;
  final VoidCallback onSignUpTap;

  const _AuthToggleButtons({required this.isSignIn, required this.onSignUpTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Style for the selected (active) button.
    final selectedStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    // Style for the unselected button.
    final unselectedStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: isSignIn ? selectedStyle : unselectedStyle,
              child: const Text('Sign In'),
            ),
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: onSignUpTap,
              style: !isSignIn ? selectedStyle : unselectedStyle,
              child: const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
