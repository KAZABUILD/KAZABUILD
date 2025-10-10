import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/theme_provider.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.build_circle, color: theme.colorScheme.primary, size: 48),
        const SizedBox(height: 16),
        Text(
          'KAZABUILD',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text('PC Building Platform', style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class CustomTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(
          widget.icon,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.iconTheme.color?.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;

  const PrimaryButton({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(text),
        ],
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String text;
  final String iconPath;

  const SocialButton({super.key, required this.text, required this.iconPath});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.8),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            height: 20,
            width: 20,
            errorBuilder: (c, e, s) {
              return const Icon(Icons.error, size: 20);
            },
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider({super.key, this.text = 'or continue with'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          const Expanded(child: Divider(thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(text),
          ),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }
}

class BackgroundCircle extends StatelessWidget {
  final Color color;
  final double radius;

  const BackgroundCircle({
    super.key,
    required this.color,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class AuthThemeToggleButton extends ConsumerWidget {
  const AuthThemeToggleButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    return IconButton(
      splashRadius: 20,
      icon: Icon(
        currentTheme == ThemeMode.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
    );
  }
}

class AuthLanguageSelector extends StatefulWidget {
  const AuthLanguageSelector({super.key});
  @override
  State<AuthLanguageSelector> createState() => _AuthLanguageSelectorState();
}

class _AuthLanguageSelectorState extends State<AuthLanguageSelector> {
  String _selectedLanguageCode = 'uk';

  final Map<String, Map<String, String>> _languages = {
    'uk': {'flag': 'assets/uk_flag.png', 'name': 'English'},
    'tr': {'flag': 'assets/tr_flag.png', 'name': 'Türkçe'},
    'pl': {'flag': 'assets/pl_flag.png', 'name': 'Polski'},
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String newLangCode) {
        setState(() {
          _selectedLanguageCode = newLangCode;
        });
        print('${_languages[newLangCode]!['name']} choose.');
      },
      itemBuilder: (BuildContext context) {
        return _languages.keys
            .where((langCode) => langCode != _selectedLanguageCode)
            .map((langCode) {
              return PopupMenuItem<String>(
                value: langCode,
                child: Row(
                  children: [
                    Image.asset(
                      _languages[langCode]!['flag']!,
                      width: 24,
                      height: 16,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) =>
                          const Icon(Icons.flag, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(_languages[langCode]!['name']!),
                  ],
                ),
              );
            })
            .toList();
      },
      child: Image.asset(
        _languages[_selectedLanguageCode]!['flag']!,
        width: 24,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) =>
            Icon(Icons.language, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}
