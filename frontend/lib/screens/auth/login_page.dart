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
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/core/constants/app_color.dart';

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
  
  // Remember me checkbox state
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  /// Loads saved login information for auto-fill.
  Future<void> _loadSavedLoginInfo() async {
    try {
      final savedInfo = await ref.read(authProvider.notifier).getSavedLoginInfo();
      if (savedInfo != null && mounted) {
        setState(() {
          _emailController.text = savedInfo['email'] ?? '';
          _rememberMe = savedInfo['rememberMe'] ?? false;
        });
      }
    } catch (e) {
      // Ignore errors when loading saved login info
      print('Failed to load saved login info: $e');
    }
  }

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
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    // Listen to the authProvider for state changes (e.g., errors, success).
    // This is used for side effects like showing SnackBars or navigating.
    ref.listen<AsyncValue<AppUser?>>(authProvider, (previous, next) {
      if (next is AsyncError) {
        // If an error occurs, show a SnackBar with the error message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      // Success navigation is now handled automatically by GoRouter's redirect logic
      // when the auth state changes. No need for manual navigation here.
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: false),
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
                        AppColorsDark.buttonPurple.withOpacity(0.3),
                      ]
                    : [
                        AppColorsLight.backgroundPrimary,
                        AppColorsLight.backgroundSecondary.withOpacity(0.5),
                        AppColorsLight.buttonPurple.withOpacity(0.2),
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
                    AppColorsDark.buttonBlue.withOpacity(0.1),
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
                    AppColorsDark.buttonPurple.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              CustomNavigationBar(
                showProfileArea: false,
                scaffoldKey: _scaffoldKey,
              ),
              Expanded(
                child: isMobile
                    ? _buildMobileLayout(context, theme, authState, isDark)
                    : _buildDesktopLayout(context, theme, authState, isDark),
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
    AsyncValue<AppUser?> authState,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: _buildLoginCard(context, theme, authState, isDark),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    AsyncValue<AppUser?> authState,
    bool isDark,
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
                            color: AppColorsDark.buttonBlue.withOpacity(0.3),
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
                  'Welcome Back!',
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
                  'Build your dream PC with our comprehensive platform.\nJoin thousands of PC enthusiasts and share your builds.',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? AppColorsDark.textWhite.withOpacity(0.8)
                        : AppColorsLight.textBlack.withOpacity(0.7),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Feature highlights
                _buildFeatureItem(
                  Icons.speed,
                  'Lightning Fast',
                  'Quick access to all your builds',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.people,
                  'Community Driven',
                  'Connect with PC building enthusiasts',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.security,
                  'Secure & Private',
                  'Your data is safe with us',
                  isDark,
                ),
              ],
            ),
          ),
        ),
        // Right side - Login form
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(60),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _buildLoginCard(context, theme, authState, isDark),
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
            color: AppColorsDark.buttonBlue.withOpacity(0.2),
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
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(
    BuildContext context,
    ThemeData theme,
    AsyncValue<AppUser?> authState,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header section
            Column(
              children: [
                Text(
                  'Welcome Back',
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
                  'Sign in to continue your journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withOpacity(0.7)
                        : AppColorsLight.textBlack.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Toggle buttons
            _AuthToggleButtons(
              isSignIn: true,
              onSignUpTap: () {
                context.go('/signup');
              },
            ),
            const SizedBox(height: 28),

            // Form fields
            CustomTextField(
              controller: _emailController,
              label: 'Username or Email',
              icon: Icons.person_outline,
              autovalidateMode: AutovalidateMode.disabled,
              validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'This field cannot be empty'
                      : null,
            ),
            const SizedBox(height: 18),

            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
              autovalidateMode: AutovalidateMode.disabled,
              validator: (value) =>
                  (value == null || value.isEmpty)
                      ? 'This field cannot be empty'
                      : null,
            ),
            const SizedBox(height: 14),

            // Remember me and Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        checkboxTheme: CheckboxThemeData(
                          fillColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColorsDark.buttonBlue;
                            }
                            return null;
                          }),
                        ),
                      ),
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                    ),
                    Text(
                      'Remember me',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite.withOpacity(0.8)
                            : AppColorsLight.textBlack.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => GoRouter.of(context).go('/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColorsDark.buttonBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sign in button
            _SignInButton(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              isLoading: authState.isLoading,
              rememberMe: _rememberMe,
            ),
            const SizedBox(height: 20),

            // Divider
            const OrDivider(),
            const SizedBox(height: 20),

            // Social login button - Only Google
            SocialButton(
              text: 'Continue with Google',
              iconPath: 'google_icon.svg.webp',
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      await ref.read(authProvider.notifier).signInWithGoogleWeb();
                    },
            ),
            ],
          ),
        ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundTertiary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: isSignIn
                    ? LinearGradient(
                        colors: [
                          AppColorsDark.buttonBlue,
                          AppColorsDark.buttonPurple,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSignIn ? Colors.transparent : Colors.transparent,
                  foregroundColor: isSignIn ? Colors.white : (isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontWeight: isSignIn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: !isSignIn
                    ? LinearGradient(
                        colors: [
                          AppColorsDark.buttonBlue,
                          AppColorsDark.buttonPurple,
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: onSignUpTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: !isSignIn ? Colors.white : (isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: !isSignIn ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
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
  final bool rememberMe;

  const _SignInButton({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.rememberMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            color: AppColorsDark.buttonBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                // Hide the keyboard.
                FocusScope.of(context).unfocus();

                // Validate the form before proceeding.
                if (formKey.currentState!.validate()) {
                  // Call the signIn method from the auth provider with user credentials.
                  ref.read(authProvider.notifier).signIn(
                        emailController.text.trim(),
                        passwordController.text,
                        rememberMe: rememberMe,
                      );
                }
              },
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
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }
}
