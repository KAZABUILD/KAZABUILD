import 'package:flutter/material.dart';
import 'package:frontend/screens/home/homepage.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;

  // GÜNCELLENDİ: Test için sahte kayıtlı e-posta listesi
  final List<String> _registeredEmails = [
    'artun@gmail.com',
    'ziyad@gmail.com',
    'adrian@gmail.com',
    'kacper@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Belirli bir aralıkta hem fade hem de slide animasyonu oluşturan yardımcı fonksiyon
  Widget _buildAnimatedWidget({
    required Widget child,
    required Interval interval,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
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
    // GÜNCELLENDİ: E-posta formatını kontrol etmek için Regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
        backgroundColor: theme.colorScheme.surface,
      ),
      backgroundColor: theme.colorScheme.background,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    _buildAnimatedWidget(
                      interval: const Interval(0.1, 0.5, curve: Curves.easeOut),
                      child: Text(
                        'Help us improve Kaza Build by sharing your thoughts or reporting a bug.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                      // GÜNCELLENDİ: E-posta alanı artık özel doğrulama kuralları içeriyor
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
                          if (!_registeredEmails.contains(
                            value.toLowerCase(),
                          )) {
                            return 'This email is not registered in our system.';
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
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Your message has been sent successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );

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

  // Metin alanlarını oluşturan yardımcı widget
  Widget _buildTextFormField({
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)?
    validator, // GÜNCELLENDİ: Validator parametresi eklendi
  }) {
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
      // GÜNCELLENDİ: Özel veya varsayılan validator kullanılır
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

// Gönder butonunun animasyonlu ve efektli hali
class _SubmitButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _SubmitButton({required this.onPressed});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = _isHovered ? 1.02 : 1.0;
    final shadowColor = _isHovered
        ? theme.colorScheme.secondary.withOpacity(0.5)
        : Colors.black.withOpacity(0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
