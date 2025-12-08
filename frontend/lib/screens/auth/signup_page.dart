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
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'package:frontend/screens/auth/privacy_policy_dialog.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:intl/intl.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/utils/validators.dart';

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
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final _birthDateController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetNumberController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _usernameFocusNode = FocusNode();
  final _displayNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _birthDateFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _countryFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _streetFocusNode = FocusNode();
  final _postalCodeFocusNode = FocusNode();
  final _streetNumberFocusNode = FocusNode();
  final _termsCheckboxFocusNode = FocusNode();
  final _createAccountButtonFocusNode = FocusNode();

  /// The currently selected gender from the dropdown.
  String? _selectedGender;

  /// Key for gender dropdown to programmatically open it
  final GlobalKey _genderDropdownKey = GlobalKey();

  /// The currently selected country from the dropdown. (Currently unused in the UI).
  //String? _selectedCountry;

  /// A list of options for the gender selection dropdown.
  static const List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];


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
      // After date selection, move to gender dropdown
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _genderFocusNode.requestFocus();
        }
      });
    } else {
      // If cancelled, unfocus
      _birthDateFocusNode.unfocus();
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  /// Cleans up the controller when the widget is removed from the widget tree.
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _birthDateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _streetNumberController.dispose();
    _usernameFocusNode.dispose();
    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _birthDateFocusNode.dispose();
    _genderFocusNode.dispose();
    _countryFocusNode.dispose();
    _cityFocusNode.dispose();
    _streetFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _streetNumberFocusNode.dispose();
    _termsCheckboxFocusNode.dispose();
    _createAccountButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
                        AppColorsDark.buttonPurple.withValues(alpha: 0.3),
                      ]
                    : [
                        AppColorsLight.backgroundPrimary,
                        AppColorsLight.backgroundSecondary.withValues(alpha: 0.5),
                        AppColorsLight.buttonPurple.withValues(alpha: 0.2),
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
                    AppColorsDark.buttonBlue.withValues(alpha: 0.1),
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
                    AppColorsDark.buttonPurple.withValues(alpha: 0.1),
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
                    ? _buildMobileLayout(context, theme, isDark)
                    : _buildDesktopLayout(context, theme, isDark),
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
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _buildSignUpCard(context, theme, isDark),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Visual/Illustration area
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
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
                            color: AppColorsDark.buttonBlue.withValues(alpha: 0.3),
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
                  'Join Our Community!',
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
                  'Create your account and start building amazing PCs.\nShare your builds, connect with enthusiasts, and get expert advice.',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.8)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Feature highlights
                _buildFeatureItem(
                  Icons.build_circle,
                  'Create Builds',
                  'Save and share your PC configurations',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.people,
                  'Join Community',
                  'Connect with PC building enthusiasts',
                  isDark,
                ),
                const SizedBox(height: 20),
                _buildFeatureItem(
                  Icons.star,
                  'Get Expert Advice',
                  'Learn from experienced builders',
                  isDark,
                ),
              ],
            ),
          ),
        ),
          // Right side - Sign up form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildSignUpCard(context, theme, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
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
            color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
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
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Column(
                children: [
                  Text(
                    'Create Account',
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
                    'Join KAZABUILD and start building',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Toggle buttons
              _SignUpAuthToggleButtons(
                isSignUp: true,
                onSignInTap: () {
                  context.go('/login');
                },
              ),
              const SizedBox(height: 28),

              // Social login button - Only Google
              SocialButton(
                text: 'Continue with Google',
                iconPath: 'google_icon.svg.webp',
                onPressed: _isLoading ? null : () {
                  // Google sign up logic can be added here
                },
              ),
              const SizedBox(height: 24),

              // Divider
              const OrDivider(),
              const SizedBox(height: 24),

              // Essential form fields - Two columns on desktop, single column on mobile
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    // Two columns layout for wider screens
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _usernameController,
                                label: 'Username',
                                icon: Icons.person_outline,
                                focusNode: _usernameFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: Validators.username,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                focusNode: _emailFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: Validators.email,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                focusNode: _passwordFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: Validators.password,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _displayNameController,
                                label: 'Display Name',
                                icon: Icons.badge_outlined,
                                focusNode: _displayNameFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: Validators.displayName,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                focusNode: _confirmPasswordFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _phoneNumberFocusNode.requestFocus(),
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(height: 56), // Spacer to align with password field
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Single column layout for mobile
                    return Column(
                      children: [
                        CustomTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                          focusNode: _usernameFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _displayNameFocusNode.requestFocus(),
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: Validators.username,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _displayNameController,
                          label: 'Display Name',
                          icon: Icons.badge_outlined,
                          focusNode: _displayNameFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: Validators.displayName,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: _emailFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          focusNode: _passwordFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          focusNode: _confirmPasswordFocusNode,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _phoneNumberFocusNode.requestFocus(),
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: (value) => Validators.confirmPassword(value, _passwordController.text),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneNumberController,
                label: 'Phone Number (Optional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                focusNode: _phoneNumberFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _birthDateFocusNode.requestFocus(),
                autovalidateMode: AutovalidateMode.disabled,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),

              // Birth Date field
              CustomTextField(
                label: 'Birth Date',
                icon: Icons.cake_outlined,
                controller: _birthDateController,
                focusNode: _birthDateFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  // Open date picker when Enter is pressed (keyboard navigation)
                  _selectDate(context);
                },
                readOnly: true,
                autovalidateMode: AutovalidateMode.disabled,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Gender dropdown - opens when focused via keyboard navigation
              Focus(
                focusNode: _genderFocusNode,
                onKeyEvent: (node, event) {
                  // When Enter or Space is pressed while focused, the dropdown will open
                  // DropdownButtonFormField automatically handles this
                  if (event is KeyDownEvent && 
                      (event.logicalKey == LogicalKeyboardKey.enter || 
                       event.logicalKey == LogicalKeyboardKey.space)) {
                    // The dropdown's onTap will be called automatically
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: DropdownButtonFormField<String>(
                  key: _genderDropdownKey,
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.transgender_outlined),
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: isDark
                      ? AppColorsDark.backgroundSecondary
                      : Colors.white,
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                  items: _genderOptions
                      .map(
                        (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                      )
                      .toList(),
                  onTap: () {
                    // Ensure focus is set when tapped
                    _genderFocusNode.requestFocus();
                  },
                  onChanged: (newValue) {
                    setState(() => _selectedGender = newValue);
                    // Move to country field after selection
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        _countryFocusNode.requestFocus();
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // Address section header
              Text(
                'Address (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              const SizedBox(height: 16),

              // Address fields
              CustomTextField(
                controller: _countryController,
                label: 'Country (Optional)',
                icon: Icons.public_outlined,
                focusNode: _countryFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _cityFocusNode.requestFocus(),
                autovalidateMode: AutovalidateMode.disabled,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cityController,
                label: 'City (Optional)',
                icon: Icons.location_city_outlined,
                focusNode: _cityFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _streetFocusNode.requestFocus(),
                autovalidateMode: AutovalidateMode.disabled,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _streetController,
                label: 'Street (Optional)',
                icon: Icons.home_outlined,
                focusNode: _streetFocusNode,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _postalCodeFocusNode.requestFocus(),
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
                      focusNode: _postalCodeFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _streetNumberFocusNode.requestFocus(),
                      autovalidateMode: AutovalidateMode.disabled,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _streetNumberController,
                      label: 'Street No.',
                      icon: Icons.signpost_outlined,
                      keyboardType: TextInputType.numberWithOptions(decimal: false),
                      focusNode: _streetNumberFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        // Move to checkbox and check it
                        setState(() {
                          _termsAccepted = true;
                        });
                        _termsCheckboxFocusNode.requestFocus();
                      },
                      autovalidateMode: AutovalidateMode.disabled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Terms and policy checkbox - Better positioned
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundTertiary.withValues(alpha: 0.3)
                      : AppColorsLight.backgroundTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Focus(
                          focusNode: _termsCheckboxFocusNode,
                          onFocusChange: (hasFocus) {
                            if (hasFocus && mounted) {
                              // Check the checkbox when focused
                              setState(() {
                                _termsAccepted = true;
                              });
                              // Move to Create Account button
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (mounted) {
                                  _createAccountButtonFocusNode.requestFocus();
                                }
                              });
                            }
                          },
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: (bool? value) {
                              setState(() {
                                _termsAccepted = value ?? false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const _TermsAndPolicyText(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Create Account button
              Focus(
                focusNode: _createAccountButtonFocusNode,
                onFocusChange: (hasFocus) {
                  if (hasFocus && mounted && _termsAccepted && !_isLoading) {
                    // Submit form when button receives focus
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) {
                        _createAccount();
                      }
                    });
                  }
                },
                child: _SignUpButton(
                  isLoading: _isLoading,
                  termsAccepted: _termsAccepted,
                  onPressed: _createAccount,
                ),
              ),
              const SizedBox(height: 20),

              // Link to login page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).go('/login'),
                    child: Text(
                      "Log in",
                      style: TextStyle(
                        color: AppColorsDark.buttonBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          content: Text(getUserFriendlyError(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
  }
}

// Separate widget classes outside of _SignUpPageState
/// A widget that displays "Sign In" and "Sign Up" toggle buttons for sign up page.
class _SignUpAuthToggleButtons extends StatelessWidget {
  final bool isSignUp;
  final VoidCallback onSignInTap;

  const _SignUpAuthToggleButtons({
    required this.isSignUp,
    required this.onSignInTap,
  });

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
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: !isSignUp
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
                onPressed: onSignInTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: !isSignUp ? Colors.white : (isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontWeight: !isSignUp ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: isSignUp
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
                  backgroundColor: Colors.transparent,
                  foregroundColor: isSignUp ? Colors.white : (isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: isSignUp ? FontWeight.bold : FontWeight.normal,
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

/// A dedicated widget for the Sign Up button.
class _SignUpButton extends StatelessWidget {
  final bool isLoading;
  final bool termsAccepted;
  final VoidCallback onPressed;

  const _SignUpButton({
    required this.isLoading,
    required this.termsAccepted,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
            color: AppColorsDark.buttonBlue.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: (isLoading || !termsAccepted) ? null : onPressed,
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
                    'Create Account',
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

/// A text widget that displays the terms of service and privacy policy agreement.
///
/// It includes a tappable link that opens the [PrivacyPolicyDialog].
class _TermsAndPolicyText extends StatelessWidget {
  const _TermsAndPolicyText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    /// Style for the non-interactive part of the text.
    final defaultStyle = TextStyle(
      fontSize: 13,
      color: isDark
          ? AppColorsDark.textWhite.withValues(alpha: 0.8)
          : AppColorsLight.textBlack.withValues(alpha: 0.7),
      height: 1.4,
    );

    /// Style for the tappable link, making it visually distinct.
    final linkStyle = defaultStyle.copyWith(
      color: AppColorsDark.buttonBlue,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColorsDark.buttonBlue,
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
      textAlign: TextAlign.left,
    );
  }
}