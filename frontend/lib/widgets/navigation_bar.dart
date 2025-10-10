import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/home/homepage.dart';
import 'package:frontend/widgets/app_bar_actions.dart';

class PcPart {
  final String name;
  final IconData icon;
  PcPart({required this.name, required this.icon});
}

class CustomNavigationBar extends ConsumerWidget {
  final bool showProfileArea;

  const CustomNavigationBar({super.key, this.showProfileArea = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authProvider);
    //left part of bar
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
          //mid part of nav
          Row(
            children: const [
              _NavButton(title: 'Build Now'),
              _NavButton(title: 'Explore Builds'),
              _NavButton(title: 'Guides'),
              _NavButton(title: 'Forums'),
              _PartsDropdownMenu(),
            ],
          ),

          Row(
            children: [
              if (showProfileArea)
                user == null
                    ? const _SignInArea()
                    : _LoggedInProfileArea(user: user),
              const SizedBox(width: 20),
              const LanguageSelector(),
              const SizedBox(width: 15),
              const ThemeToggleButton(),
            ],
          ),
        ],
      ),
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

//right side of the bar
class _SignInArea extends StatelessWidget {
  const _SignInArea();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textButtonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: Alignment.centerLeft,
    );
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome', style: theme.textTheme.bodySmall),
            Row(
              children: [
                TextButton(
                  style: textButtonStyle,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text('Sign In', style: textStyle),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('/', style: theme.textTheme.bodySmall),
                ),
                TextButton(
                  style: textButtonStyle,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  ),
                  child: Text('Sign Up', style: textStyle),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _LoggedInProfileArea extends ConsumerWidget {
  final AppUser user;
  const _LoggedInProfileArea({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        } else if (value == 'settings') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        } else if (value == 'logout') {
          ref.read(authProvider.notifier).signOut();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
        const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'logout', child: Text('Log Out')),
      ],
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(user.username.substring(0, 1).toUpperCase())
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('View Profile', style: theme.textTheme.bodySmall),
            ],
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
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
              'Parts',
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
