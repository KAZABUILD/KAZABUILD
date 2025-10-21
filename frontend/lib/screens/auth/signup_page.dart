/// This file defines the UI for the user registration (Sign Up) screen.
///
/// It includes a comprehensive form for new users to enter their details
/// such as username, email, and password. It also features fields for optional
/// information like birth date and gender.
///
/// The page integrates social sign-up options, a link to the login page for
/// existing users, and a mandatory agreement to the terms and privacy policy,
/// which is displayed via a dialog. It is fully responsive and uses reusable
/// widgets from `auth_widgets.dart` for a consistent UI.

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

  /// Controller for the birth date text field to programmatically set its value.
  final _birthDateController = TextEditingController();

  /// The currently selected gender from the dropdown.
  String? _selectedGender;

  /// The currently selected country from the dropdown. (Currently unused in the UI).
  String? _selectedCountry;

  /// A list of options for the gender selection dropdown.
  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  /// Displays a date picker dialog and updates the birth date text field.
  /// This is triggered when the user taps the 'Birth Date' text field.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    // If a date is selected, format it and set it as the text field's value.
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  /// Cleans up the controller when the widget is removed from the widget tree.
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// A regular expression for validating email address format.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

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
                /// Ensures the content is scrollable to prevent overflow on smaller screens.
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

                          /// The main sign-up form, which handles input and validation.
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

                                /// Social sign-up buttons for quick registration.
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

                                /// Form fields for collecting user details.
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
                                    // Provides real-time validation for the email format.
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

                                /// A read-only text field that opens a date picker on tap.
                                CustomTextField(
                                  label: 'Birth Date',
                                  icon: Icons.cake_outlined,
                                  controller: _birthDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(context),
                                ),
                                const SizedBox(height: 16),

                                /// A dropdown menu for gender selection.
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

                                /// The primary button to submit the form and create the account.
                                PrimaryButton(
                                  text: 'Create Account',
                                  onPressed: () {
                                    // Validates all form fields before proceeding.
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

                                /// A text widget with a tappable link to the privacy policy.
                                const _TermsAndPolicyText(),
                                const SizedBox(height: 16),

                                /// A link to navigate to the login page for existing users.
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

    /// Style for the non-interactive part of the text.
    final defaultStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.grey.shade500,
    );

    /// Style for the tappable link, making it visually distinct.
    final linkStyle = defaultStyle?.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    /// Uses [Text.rich] to combine different text styles in a single widget.
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: defaultStyle,
        children: <TextSpan>[
          TextSpan(
            text: 'Terms and Privacy Policy',
            style: linkStyle,

            /// A gesture recognizer to handle the tap event on the link, which opens the dialog.
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
