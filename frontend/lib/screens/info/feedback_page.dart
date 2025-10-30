/// This file defines the UI for the user feedback page.
///
/// It provides a form for users to submit feedback, suggestions, or bug reports,
/// The page features staggered entrance animations for a more polished look.
library;

import 'package:flutter/material.dart';
import 'package:frontend/screens/home/homepage.dart';

/// The main stateful widget for the feedback page.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

/// The state for the [FeedbackPage], managing animations and form submission.
///
/// It uses a [SingleTickerProviderStateMixin] to provide a ticker for the
/// animation controller.
class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  /// A key to manage the form state, used for validation.
  final _formKey = GlobalKey<FormState>();

  /// The animation controller that drives all the animations on this page.
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    /// Initialize and start the animation controller to trigger the entrance animations.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    /// Dispose the controller when the widget is removed from the tree to free up resources.
    _controller.dispose();
    super.dispose();
  }

  /// A reusable helper widget that wraps its child in a staggered fade and slide animation.
  ///
  /// This simplifies the process of applying consistent entrance animations to widgets.
  Widget _buildAnimatedWidget({
    required Widget child,
    required Interval interval,
  }) {
    // The SlideTransition animates the widget's position from an offset to zero.
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: interval)),
      // The FadeTransition animates the widget's opacity from 0.0 to 1.0.
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: interval)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Regular expression for basic email format validation.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        backgroundColor: theme.colorScheme.surface,
      ),
      backgroundColor: theme.colorScheme.background,

      /// The main container with a subtle gradient background for visual appeal.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                // The main column that holds all form elements.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Page title, animated.
                    _buildAnimatedWidget(
                      interval: const Interval(0.0, 0.4, curve: Curves.easeOut),
                      child: Text(
                        'We Value Your Feedback',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Instructional text, animated.
                    _buildAnimatedWidget(
                      interval: const Interval(0.1, 0.5, curve: Curves.easeOut),
                      child: Text(
                        'Help us improve Kaza Build by sharing your thoughts or reporting a bug.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 40),

                    /// Form fields, each with a staggered animation for a sequential appearance.
                    _buildAnimatedWidget(
                      interval: const Interval(0.2, 0.6, curve: Curves.easeOut),
                      child: _buildTextFormField(
                        label: 'Name',
                        hint: 'Enter your name',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedWidget(
                      interval: const Interval(0.3, 0.7, curve: Curves.easeOut),
                      child: _buildTextFormField(
                        label: 'Email',
                        hint: 'Enter your registered email',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field cannot be empty.';
                          }
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email format.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedWidget(
                      interval: const Interval(0.4, 0.8, curve: Curves.easeOut),
                      child: _buildTextFormField(
                        label: 'Subject',
                        hint: 'What is this about?',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedWidget(
                      interval: const Interval(0.5, 0.9, curve: Curves.easeOut),
                      child: _buildTextFormField(
                        label: 'Message',
                        hint: 'Describe your feedback in detail...',
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildAnimatedWidget(
                      interval: const Interval(0.6, 1.0, curve: Curves.easeOut),
                      child: _SubmitButton(
                        onPressed: () {
                          /// Validate the form before proceeding.
                          if (_formKey.currentState!.validate()) {
                            // TODO: Implement a real API call to send the feedback data to a backend service.
                            ScaffoldMessenger.of(context).showSnackBar(
                              // Show a success message to the user.
                              const SnackBar(
                                content: Text(
                                  'Your message has been sent successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

                            /// After a short delay, navigate back to the homepage.
                            Future.delayed(
                              const Duration(milliseconds: 1500),
                              () {
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                }
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A helper method to create a consistently styled text form field.
  Widget _buildTextFormField({
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    // A standard TextFormField with consistent styling for this page.
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.surface,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
      ),
      // A default validator that checks if the field is empty.
      validator:
          validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'This field cannot be empty.';
            }
            return null;
          },
    );
  }
}

/// A custom submit button with a hover animation for a better desktop experience.
class _SubmitButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SubmitButton({required this.onPressed});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

/// The state for [_SubmitButton], which manages the hover effect.
class _SubmitButtonState extends State<_SubmitButton> {
  /// A flag to track whether the mouse cursor is currently over the button.
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Determine the scale and shadow color based on the hover state.
    final scale = _isHovered ? 1.02 : 1.0;
    final shadowColor = _isHovered
        ? theme.colorScheme.secondary.withOpacity(0.5)
        : Colors.black.withOpacity(0.2);

    /// [MouseRegion] detects when the cursor enters or leaves the widget's area to trigger the hover effect.
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),

      /// [AnimatedScale] and [AnimatedContainer] provide smooth transitions for the hover effect.
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 15, spreadRadius: 1),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Submit'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
