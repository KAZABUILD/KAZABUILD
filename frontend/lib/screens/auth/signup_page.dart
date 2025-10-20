/// This file defines the UI for the user registration (Sign Up) screen.
///
/// It includes a comprehensive form for new users to enter their details
/// such as username, email, password, and other optional information.
/// It also provides links to the login page and the privacy policy.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/privacy_policy_dialog.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

/// The main widget for the sign-up page.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

/// The state for the [SignUpPage].
class _SignUpPageState extends State<SignUpPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A key to manage the form state, used for validation.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the birth date text field to manage its value.
  final _birthDateController = TextEditingController();

  /// The currently selected gender from the dropdown.
  String? _selectedGender;

  /// The currently selected country from the dropdown.
  String? _selectedCountry;

  /// A list of options for the gender selection dropdown.
  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  /// Displays a date picker dialog and updates the birth date text field.
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

    // Regular expression for email validation.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: false),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        // The main navigation bar, configured not to show profile details on this page.
        children: [
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
                          // The main sign-up form.
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Page title and subtitle.
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
                                // Social sign-up buttons.
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
                                // Form fields for user details.
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
                                CustomTextField(
                                  label: 'Address',
                                  icon: Icons.home_outlined,
                                ),
                                const SizedBox(height: 24),
                                // The primary button to create the account.
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
                                // Text with a link to the privacy policy.
                                const _TermsAndPolicyText(),
                                const SizedBox(height: 16),
                                // Link to navigate to the login page.
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

/// A text widget that displays the terms of service and privacy policy agreement.
///
/// It includes a tappable link that opens the [PrivacyPolicyDialog].
class _TermsAndPolicyText extends StatelessWidget {
  const _TermsAndPolicyText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final smallTextStyle = theme.textTheme.bodySmall?.copyWith(
      // A lighter color for the non-link part of the text.
      color: Colors.grey.shade500,
    );
    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      // Underline to indicate it's a tappable link.
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
            // A gesture recognizer to handle the tap event on the link.
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
