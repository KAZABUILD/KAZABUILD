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
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/privacy_policy_dialog.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

/// The main widget for the sign-up page.
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

/// The state for the [SignUpPage].
class _SignUpPageState extends ConsumerState<SignUpPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A key to manage the form state, used for validation.
  final _formKey = GlobalKey<FormState>();

  // Controllers for all text input fields.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final _birthDateController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetNumberController = TextEditingController();

  /// The currently selected gender from the dropdown.
  String? _selectedGender;

  /// The currently selected country from the dropdown. (Currently unused in the UI).
  //String? _selectedCountry;

  /// A list of options for the gender selection dropdown.
  static const List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  /// Regular expression for validating email address format - moved outside build method
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Tracks the loading state of the sign-up process.
  bool _isLoading = false;

  /// Tracks whether the user has accepted the terms and policy.
  bool _termsAccepted = false;

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
    if (picked != null && mounted) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  /// Cleans up the controller when the widget is removed from the widget tree.
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _streetNumberController.dispose();
    super.dispose();
  }

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
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
                                  onPressed: null,
                                ),
                                const SizedBox(height: 16),

                                /// Form fields for collecting user details.
                                CustomTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter a username';
                                    if (value.length < 8) return 'Username must be at least 8 characters long';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _displayNameController,
                                  label: 'Display Name',
                                  icon: Icons.badge_outlined,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter a display name';
                                    if (value.length < 8) return 'Display Name must be at least 8 characters long';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _emailController,
                                  label: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: (value) {
                                    // Provides validation for the email format.
                                    if (value == null || value.isEmpty)
                                      return 'Please enter your email address';
                                    if (!_emailRegex.hasMatch(value))
                                      return 'Please enter a valid email address';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  autovalidateMode: AutovalidateMode.disabled,
                                  validator: (value) =>
                                      (value != null && value.length < 8)
                                      ? 'Password must be at least 8 characters'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _phoneNumberController,
                                  label: 'Phone Number (Optional)',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  autovalidateMode: AutovalidateMode.disabled,
                                ),
                                const SizedBox(height: 16),

                                /// A read-only text field that opens a date picker on tap.
                                CustomTextField(
                                  label: 'Birth Date',
                                  icon: Icons.cake_outlined,
                                  controller: _birthDateController,
                                  readOnly: true,
                                  autovalidateMode: AutovalidateMode.disabled,
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
                                // --- Detaylı Adres Alanları ---
                                CustomTextField(
                                  controller: _countryController,
                                  label: 'Country (Optional)',
                                  icon: Icons.public_outlined,
                                  autovalidateMode: AutovalidateMode.disabled,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _cityController,
                                  label: 'City (Optional)',
                                  icon: Icons.location_city_outlined,
                                  autovalidateMode: AutovalidateMode.disabled,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _streetController,
                                  label: 'Street (Optional)',
                                  icon: Icons.home_outlined,
                                  autovalidateMode: AutovalidateMode.disabled,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _postalCodeController,
                                        label: 'Postal Code',
                                        icon: Icons.local_post_office_outlined,
                                        keyboardType: TextInputType.text,
                                        autovalidateMode: AutovalidateMode.disabled,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _streetNumberController,
                                        label: 'Street No.',
                                        icon: Icons.signpost_outlined,
                                        keyboardType:
                                            TextInputType.numberWithOptions(
                                                decimal: false),
                                        autovalidateMode: AutovalidateMode.disabled,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                /// A row containing the checkbox and the tappable text for terms and policy.
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: _termsAccepted,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _termsAccepted = value ?? false;
                                        });
                                      },
                                    ),
                                    const Expanded(
                                      child: _TermsAndPolicyText(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                /// The primary button to submit the form and create the account.
                                PrimaryButton(
                                  text: _isLoading ? 'Creating Account...' : 'Create Account',
                                  onPressed: _isLoading || !_termsAccepted
                                      ? null
                                      : _createAccount,
                                ),
                                const SizedBox(height: 24),

                                /// The `_TermsAndPolicyText` is now inside the Row with the Checkbox.
                                /// This space is adjusted.
                                // const _TermsAndPolicyText(),
                                // const SizedBox(height: 16),

                                /// A link to navigate to the login page for existing users.
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account?"),
                                    TextButton(
                                      onPressed: () => GoRouter.of(context).go('/login'),
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
        ],
      ),
    );
  }

  /// Handles the account creation process.
 void _createAccount() async {
  
  FocusScope.of(context).unfocus();

  // Show a snackbar if terms are not accepted.
  if (!_termsAccepted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You must accept the terms and privacy policy to continue.'),
      ),
    );
    return;
  }
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    
    final Map<String, dynamic> addressData = {
      'country': _countryController.text,
      'city': _cityController.text,
      'street': _streetController.text,
      'postalCode': _postalCodeController.text,
      // Backend expects string for streetNumber and apartmentNumber
      'streetNumber': _streetNumberController.text.isNotEmpty ? _streetNumberController.text : null,
      'apartmentNumber': null, // This field is not in the UI, send null.
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    
    final Map<String, dynamic> payload = {
      'login': _usernameController.text,
      'displayName': _displayNameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phoneNumber': _phoneNumberController.text.isNotEmpty ? _phoneNumberController.text : null,
      'description': '',
      'gender': _selectedGender ?? 'Unknown',
      'imageUrl': 'wwwroot/defaultuser.png', // Changed to camelCase to match Swagger example
      'birth': _birthDateController.text.isNotEmpty
          ? DateTime.parse(_birthDateController.text).toIso8601String()
          : DateTime(2000, 1, 1).toIso8601String(),
      'registeredAt': DateTime.now().toIso8601String(),
      'profileAccessibility': 'PUBLIC',
      'theme': 'DARK',
      'language': 'ENGLISH',
      'receiveEmailNotifications': true,
      'enableDoubleFactorAuthentication': false,
      'redirectUrl': '/login',
      'location': '',
      'address': addressData.isNotEmpty ? addressData : null, // Send null if address is empty
    };

   
    final successMessage =
        await ref.read(authProvider.notifier).signUp(payload);

    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );
      GoRouter.of(context).go('/login');
    }
  } catch (error) {
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
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