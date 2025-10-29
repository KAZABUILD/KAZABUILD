/// This file defines the user login interface for the KazaBuild application.
///
/// It presents a comprehensive login form where users can input their
/// credentials (username/email and password). The page also provides
/// convenient links for new users to sign up, for existing users to reset
/// their forgotten passwords, and integrates options for social media login
/// (Google, GitHub, Discord) to enhance user experience and flexibility.
///
/// The page leverages Riverpod for efficient state management, particularly
/// for listening to authentication state changes and interacting with the `authProvider`.
/// for handling authentication processes and interacting with the `authProvider`.
/// It reuses common authentication widgets defined in `auth_widgets.dart`
/// to ensure a consistent look and feel across all authentication flows.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/screens/home/homepage.dart';
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

  // Controllers to capture user input for email and password.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to free up resources when the widget is removed.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Builds the UI for the login page.
  @override
  Widget build(BuildContext context) {
    // Listen to the authProvider for state changes (e.g., errors, success).
    // This is used for side effects like showing SnackBars or navigating.
    ref.listen<AsyncValue<AppUser?>>(authProvider, _handleAuthStateChange);

    final authState = ref.watch(authProvider);
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
                                    // Use go_router for consistent navigation.
                                    context.go('/signup');
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
                                  controller: _emailController,
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
                                  controller: _passwordController,
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
                                _SignInButton(
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  isLoading: authState.isLoading,
                                ),

                                /// A visual separator with "OR" text, typically used between
                                /// credential-based login and social login options.
                                const OrDivider(),

                                /// Button for signing in with Google.
                                SocialButton(
                                  text: 'Continue with Google',
                                  iconPath: 'google_icon.svg.webp',
                                  onPressed: () {
                                    //ref.read(authProvider.notifier).signInWithGoogle();
                                  },
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

  /// A listener function to handle changes in the authentication state.
  void _handleAuthStateChange(AsyncValue<AppUser?>? previous, AsyncValue<AppUser?> next) {
    if (next is AsyncError) {
      // If an error occurs, show a SnackBar with the error message.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Reset the state to allow for another login attempt.
      ref.read(authProvider.notifier).state = const AsyncValue.data(null);
    } 
    // Success navigation is now handled automatically by GoRouter's redirect logic
    // when the auth state changes. No need for manual navigation here.
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

/// A dedicated widget for the Sign In button to encapsulate its logic.
/// It handles form validation and interacts with the [authProvider].
class _SignInButton extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;

  const _SignInButton({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryButton(
      // Show a loading indicator text and disable the button during sign-in.
      text: isLoading ? 'Signing In...' : 'Sign In',
      icon: isLoading ? null : Icons.arrow_forward,
      onPressed: isLoading
          ? null
          : () {
              // Hide the keyboard.
              FocusScope.of(context).unfocus();

              // Validate the form before proceeding.
              if (formKey.currentState!.validate()) {
                // Call the signIn method from the auth provider with user credentials.
                ref.read(authProvider.notifier).signIn(
                      emailController.text,
                      passwordController.text,
                    );
              }
            },
    );
  }
}
