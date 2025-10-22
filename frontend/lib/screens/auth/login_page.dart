/// This file defines the user login interface for the KazaBuild application.
///
/// It presents a comprehensive login form where users can input their
/// credentials (username/email and password). The page also provides
/// convenient links for new users to sign up, for existing users to reset
/// their forgotten passwords, and integrates options for social media login
/// (Google, GitHub, Discord) to enhance user experience and flexibility.
///
/// The page leverages Riverpod for efficient state management, particularly
/// for handling authentication processes and interacting with the `authProvider`.
/// It reuses common authentication widgets defined in `auth_widgets.dart`
/// to ensure a consistent look and feel across all authentication flows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main widget for the login page.
/// It's a `ConsumerStatefulWidget` to interact with Riverpod providers for state management.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  /// A global key to manage the [Scaffold] state, primarily used for
  /// programmatically opening or closing the [Drawer] on mobile layouts.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A global key to manage the [Form] state, essential for triggering
  /// validation and saving form fields.
  final _formKey = GlobalKey<FormState>();

  /// Builds the UI for the login page.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: false),
      // Sets the background color of the Scaffold based on the current theme.
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          /// The main navigation bar for the application.
          /// Configured not to show the profile area on the login page,
          /// as the user is not yet authenticated.
          CustomNavigationBar(
            showProfileArea: false,
            scaffoldKey: _scaffoldKey,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                /// Wraps the content in a [SingleChildScrollView] to prevent overflow
                /// on devices with smaller screens or when the keyboard is active.
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

                          /// The main login form, wrapped in a [Form] widget to enable validation.
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                /// Displays the application's logo and title.
                                /// This is a reusable widget from `auth_widgets.dart`.
                                const Header(),
                                const SizedBox(height: 32),

                                /// A custom widget providing toggle buttons for "Sign In" and "Sign Up".
                                /// It visually indicates the active authentication mode and handles
                                /// navigation to the sign-up page.
                                _AuthToggleButtons(
                                  isSignIn: true,
                                  onSignUpTap: () {
                                    /// Navigates to the SignUpPage with a fade transition, replacing the current page.
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

                                /// Welcome message for returning users.
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),

                                /// Encouraging subtitle for the login page.
                                Text(
                                  'Continue building your dream PC',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),

                                /// Custom text field for entering the user's username or email.
                                /// Includes validation to ensure the field is not empty.
                                CustomTextField(
                                  label: 'Username or Email',
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'This field cannot be empty'
                                      : null,
                                ),
                                const SizedBox(height: 16),

                                /// Custom text field for entering the user's password.
                                /// It's configured as a password field with a visibility toggle and validation.
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
                                    /// A checkbox for the "Remember me" functionality.
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: true,
                                          onChanged: (v) {},
                                        ),
                                        const Text('Remember me'),
                                      ],
                                    ), // "Forgot password?" link.
                                    /// A [TextButton] to navigate to the [ForgotPasswordPage].
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

                                /// The primary button to initiate the sign-in process.
                                /// It triggers form validation and, upon success,
                                /// would typically call an authentication service.
                                PrimaryButton(
                                  text: 'Sign In',
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    /// Validates the form before proceeding.
                                    if (_formKey.currentState!.validate()) {
                                      /// TODO: Implement actual sign-in logic here.
                                      /// For now, it just reads the provider and navigates home.
                                      ref.read(authProvider.notifier);

                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    }
                                  },
                                ),

                                /// A visual separator with "OR" text, typically used between
                                /// credential-based login and social login options.
                                const OrDivider(),

                                /// Button for signing in with Google.
                                const SocialButton(
                                  text: 'Continue with Google',
                                  iconPath: 'google_icon.svg.webp',
                                ),
                                const SizedBox(height: 12),

                                /// Button for signing in with GitHub.
                                const SocialButton(
                                  text: 'Continue with GitHub',
                                  iconPath: 'github_icon.svg',
                                ),
                                const SizedBox(height: 12),

                                /// Button for signing in with Discord.
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
///
/// This widget is used to visually indicate the current authentication mode
/// (Sign In or Sign Up) and allows users to switch between them.
class _AuthToggleButtons extends StatelessWidget {
  /// A boolean flag indicating if the "Sign In" button is currently active.
  final bool isSignIn;

  /// A callback function executed when the "Sign Up" button is tapped.
  /// This typically navigates to the sign-up page.
  final VoidCallback onSignUpTap;

  const _AuthToggleButtons({required this.isSignIn, required this.onSignUpTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Defines the visual style for the currently selected (active) button.
    final selectedStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    /// Defines the visual style for the unselected (inactive) button.
    final unselectedStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    /// A container that holds the two toggle buttons, providing a consistent
    /// background and rounded corners.
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          /// The "Sign In" button. Its style changes based on the `isSignIn` flag.
          /// It has an empty `onPressed` as it's the current page.
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: isSignIn ? selectedStyle : unselectedStyle,
              child: const Text('Sign In'),
            ),
          ),

          /// The "Sign Up" button. Its style changes based on the `isSignIn` flag.
          /// Tapping it triggers the `onSignUpTap` callback.
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
