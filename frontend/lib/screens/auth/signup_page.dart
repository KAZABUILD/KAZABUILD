import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/data/countries.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/privacy_policy_dialog.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _birthDateController = TextEditingController();

  String? _selectedGender;
  String? _selectedCountry;
  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign Up',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
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
                                  iconPath: 'google_icon.svg.webp',
                                ),
                                const SizedBox(height: 12),
                                const SocialButton(
                                  text: 'Continue with Apple',
                                  iconPath: 'apple_icon.svg',
                                ),
                                const OrDivider(text: 'OR CONTINUE WITH EMAIL'),
                                CustomTextField(
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? 'Please enter a username'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return 'Please enter your email address';
                                    if (!emailRegex.hasMatch(value))
                                      return 'Please enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  validator: (value) =>
                                      (value != null && value.length < 6)
                                      ? 'Password must be at least 6 characters'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Birth Date',
                                  icon: Icons.cake_outlined,
                                  controller: _birthDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    prefixIcon: Icon(
                                      Icons.transgender_outlined,
                                    ),
                                  ),
                                  items: _genderOptions
                                      .map(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (newValue) => setState(
                                    () => _selectedGender = newValue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedCountry,
                                  decoration: const InputDecoration(
                                    labelText: 'Country',
                                    prefixIcon: Icon(Icons.flag_outlined),
                                  ),
                                  isExpanded: true,
                                  items: countries
                                      .map(
                                        (String value) =>
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (newValue) => setState(
                                    () => _selectedCountry = newValue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Address',
                                  icon: Icons.home_outlined,
                                ),
                                const SizedBox(height: 24),
                                PrimaryButton(
                                  text: 'Create Account',
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Creating account...'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                const _TermsAndPolicyText(),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account?"),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pushReplacement(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (_, __, ___) =>
                                                  const LoginPage(),
                                              transitionsBuilder:
                                                  (_, a, __, c) =>
                                                      FadeTransition(
                                                        opacity: a,
                                                        child: c,
                                                      ),
                                            ),
                                          ),
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
