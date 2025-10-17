import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/forgot_password_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
          CustomNavigationBar(showProfileArea: false, scaffoldKey: _scaffoldKey),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
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

                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Header(),
                                const SizedBox(height: 32),
                                _AuthToggleButtons(
                                  isSignIn: true,
                                  onSignUpTap: () {
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
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: true,
                                          onChanged: (v) {},
                                        ),
                                        const Text('Remember me'),
                                      ],
                                    ),
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

                                PrimaryButton(
                                  text: 'Sign In',
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      ref
                                          .read(authProvider.notifier)
                                          .signInForTest();

                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    }
                                  },
                                ),
                                const OrDivider(),
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

class _AuthToggleButtons extends StatelessWidget {
  final bool isSignIn;
  final VoidCallback onSignUpTap;

  const _AuthToggleButtons({required this.isSignIn, required this.onSignUpTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
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
