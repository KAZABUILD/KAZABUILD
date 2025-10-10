import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/privacy_policy_dialog.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emailController = TextEditingController();
    // Enhanced email regex for better validation
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          const CustomNavigationBar(showProfileArea: false),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Save your builds and interact with the community!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 32),
                              const SocialButton(
                                text: 'Continue with Google',
                                iconPath: 'google_icon.svg',
                              ),
                              const SizedBox(height: 12),
                              const SocialButton(
                                text: 'Continue with Apple',
                                iconPath: 'apple_icon.png',
                              ),
                              const OrDivider(text: 'OR CONTINUE WITH EMAIL'),

                              const CustomTextField(
                                label: 'Username',
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Email address',
                                icon: Icons.email_outlined,
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email address';
                                  } else if (value.length < 5) {
                                    return 'Email address is too short';
                                  } else if (!value.contains('@')) {
                                    return 'Email must contain @ symbol';
                                  } else if (value.startsWith('@') || value.endsWith('@')) {
                                    return 'Invalid email format';
                                  } else if (value.split('@').length != 2) {
                                    return 'Email can only contain one @ symbol';
                                  } else if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const CustomTextField(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                              const SizedBox(height: 24),
                              const PrimaryButton(
                                text: 'Create Account',
                                icon: null,
                              ),
                              const SizedBox(height: 24),
                              const _TermsAndPolicyText(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?"),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              const LoginPage(),
                                          transitionsBuilder: (_, a, __, c) =>
                                              FadeTransition(
                                                opacity: a,
                                                child: c,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text("Log in"),
                                  ),
                                ],
                              ),
                            ],
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

class _TermsAndPolicyText extends StatelessWidget {
  const _TermsAndPolicyText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smallTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade500,
    );
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: smallTextStyle,
        children: <TextSpan>[
          TextSpan(
            text: 'Terms and Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const PrivacyPolicyDialog();
                  },
                );
              },
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
