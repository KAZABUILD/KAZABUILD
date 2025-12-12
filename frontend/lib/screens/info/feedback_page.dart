/// This file defines the UI for the user feedback page.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/utils/error_utils.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _controller;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  // Focus nodes for navigation between fields
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _subjectFocusNode = FocusNode();
  final _messageFocusNode = FocusNode();

  
  String _selectedCategory = 'Suggestion';
  int _rating = 0;
  bool _isSubmitting = false;

  final List<String> _categories = ['Bug Report', 'Suggestion', 'Other'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _controller.forward();

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user.displayName;
        
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _subjectFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWidget({
    required Widget child,
    required Interval interval,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: interval)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Monotone background matching build now page
    final backgroundColor = theme.brightness == Brightness.dark 
        ? const Color(0xFF0F0915) 
        : theme.colorScheme.background;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth < 600 ? 16.0 : 24.0,
                vertical: 20.0,
              ),
              child: Center(
                child: _buildAnimatedWidget(
                  interval: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth < 600 
                          ? double.infinity 
                          : screenWidth < 1200 
                              ? 800 
                              : 1200,
                    ),
                    child: _buildGlassForm(theme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Form container matching build now page style
  Widget _buildGlassForm(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Başlık Alanı
                const Icon(Icons.feedback_outlined, size: 40, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  'We Value Your Feedback',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us improve Kaza Build by sharing your thoughts.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),

               
                Text('What kind of feedback is this?', 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2) 
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Form Alanları
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassTextField(
                        label: 'Name',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        helperText: 'Enter your full name or username',
                        focusNode: _nameFocusNode,
                        nextFocusNode: _emailFocusNode,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildGlassTextField(
                        label: 'Email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        validator: (v) => (v != null && !v.contains('@')) ? 'Invalid email' : null,
                        helperText: 'We\'ll use this to respond to your feedback',
                        focusNode: _emailFocusNode,
                        nextFocusNode: _subjectFocusNode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  label: 'Subject',
                  icon: Icons.title,
                  controller: _subjectController,
                  helperText: 'Brief summary of your feedback (e.g., "Bug Report", "Feature Request")',
                  focusNode: _subjectFocusNode,
                  nextFocusNode: _messageFocusNode,
                ),
                const SizedBox(height: 16),
                _buildGlassTextField(
                  label: 'Message',
                  icon: Icons.message_outlined,
                  controller: _messageController,
                  maxLines: 4,
                  helperText: 'Provide detailed information about your feedback, suggestions, or issues',
                  focusNode: _messageFocusNode,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                
                Center(
                  child: Column(
                    children: [
                      Text('Rate your experience', 
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.white.withOpacity(index < _rating ? 0.9 : 0.4),
                              size: 32,
                            ),
                            onPressed: () => setState(() => _rating = index + 1),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Butonu
                _SubmitButton(
                  isLoading: _isSubmitting,
                  onPressed: _submitFeedback,
                ),
              ],
            ),
          ),
    );
  }

  // Modern, saydam text field
  Widget _buildGlassTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? helperText,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      textInputAction: textInputAction ?? (nextFocusNode != null ? TextInputAction.next : TextInputAction.done),
      onFieldSubmitted: nextFocusNode != null 
          ? (_) => nextFocusNode.requestFocus()
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        helperText: helperText,
        helperStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
        ),
      ),
      validator: validator ?? (val) => (val == null || val.isEmpty) ? 'Required' : null,
    );
  }

  Future<void> _submitFeedback() async {
    // 1. Close keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // 2. CAPTURE THE MESSENGER HERE
    // We do this BEFORE the 'await' so we have a safe reference to it.
    final messenger = ScaffoldMessenger.of(context);

    if (_rating == 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please give a rating!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please login first.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(authProvider.notifier).getDioInstance();

      final fullMessage = '''
Type: $_selectedCategory
Rating: $_rating / 5 Stars
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}
Subject: ${_subjectController.text.trim()}

Message:
${_messageController.text.trim()}
''';

      debugPrint('Sending request...');

    
      final response = await dio.post(
        '$apiBaseUrl/UserFeedback/add',
        data: {
          'UserId': user.uid,
          'Feedback': fullMessage.trim(),
        },
      );

      debugPrint('Backend responded successfully. Status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      // 4. Show success dialog
      if (!mounted) {
        debugPrint('Widget not mounted, cannot show dialog');
        return;
      }
      
      // Loading durumunu kapat
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      
     
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Successfully Sent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your feedback has been successfully sent.\nThank you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Formu temizle
                    _nameController.clear();
                    _emailController.clear();
                    _subjectController.clear();
                    _messageController.clear();
                    if (mounted) {
                      setState(() {
                        _rating = 0;
                        _selectedCategory = 'Suggestion';
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

    } catch (e, stackTrace) {
      debugPrint("ERROR: $e");
      debugPrint("Stack trace: $stackTrace");
      debugPrint("Mounted in catch: $mounted");
      
      // Use the captured messenger for errors too, but check mounted first
      if (mounted) {
        final errorMessenger = ScaffoldMessenger.of(context);
        errorMessenger.clearSnackBars();
        errorMessenger.showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyError(e)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.all(20),
          ),
        );
        debugPrint('Error SnackBar gösterildi');
      } else {
        debugPrint('Widget not mounted, cannot show error SnackBar');
      }
    } finally {
     
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }
    }
    
class _SubmitButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _SubmitButton({required this.onPressed, this.isLoading = false});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isHovered ? 1.05 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(_isHovered ? 0.25 : 0.2),
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text(
                  'SUBMIT FEEDBACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}