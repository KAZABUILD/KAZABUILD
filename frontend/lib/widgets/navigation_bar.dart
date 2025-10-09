import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/theme_provider.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/home/homepage.dart';

class PcPart {
  final String name;
  final IconData icon;
  PcPart({required this.name, required this.icon});
}

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (Route<dynamic> route) => false,
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(Icons.build, color: colorScheme.primary, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Kaza Build',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
          ),

          // mid side menu
          Row(
            children: const [
              _NavButton(title: 'Build Now'),
              _NavButton(title: 'Explore Builds'),
              _NavButton(title: 'Guides'),
              _NavButton(title: 'Forums'),
              _PartsDropdownMenu(),
            ],
          ),

          // right side profile lang and theme
          Row(
            children: [
              const _ProfileArea(),
              const SizedBox(width: 20),
              _LanguageSelector(),
              const SizedBox(width: 15),
              _ThemeToggleButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
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

class _NavButton extends StatelessWidget {
  final String title;
  const _NavButton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {
          if (title == 'Build Now') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BuildNowPage()),
            );
          } else {
            print('$title clicked');
          }
        },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        child: Text(title),
      ),
    );
  }
}

class _ProfileArea extends StatelessWidget {
  const _ProfileArea();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome', style: theme.textTheme.bodySmall),
            InkWell(
              onTap: () {
                print('Sign In / Register clicked!');
              },
              child: Text(
                'Sign In / Register',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PartsDropdownMenu extends StatelessWidget {
  const _PartsDropdownMenu();

  static final List<PcPart> parts = [
    PcPart(name: 'CPU', icon: Icons.memory),
    PcPart(name: 'GPU', icon: Icons.developer_board),
    PcPart(name: 'Motherboard', icon: Icons.dns),
    PcPart(name: 'Case', icon: Icons.desktop_windows_outlined),
    PcPart(name: 'Power Supply', icon: Icons.power),
    PcPart(name: 'Memory', icon: Icons.sd_storage),
    PcPart(name: 'Cooler', icon: Icons.air),
    PcPart(name: 'Fan', icon: Icons.wind_power),
    PcPart(name: 'Monitor', icon: Icons.monitor),
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PcPart>(
      offset: const Offset(0, 45),
      onSelected: (PcPart part) {
        print('${part.name} choose');
      },
      itemBuilder: (BuildContext context) {
        return parts.map((PcPart part) {
          return PopupMenuItem<PcPart>(
            value: part,
            child: Row(
              children: [
                Icon(part.icon, size: 20),
                const SizedBox(width: 12),
                Text(part.name),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              'Parts +',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  @override
  __LanguageSelectorState createState() => __LanguageSelectorState();
}

class __LanguageSelectorState extends State<_LanguageSelector> {
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
