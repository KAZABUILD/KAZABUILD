import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/forum/forums_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/home/homepage.dart';
import 'package:frontend/screens/builder/part_picker_page.dart';
import 'package:frontend/widgets/app_bar_actions.dart';
import 'package:frontend/screens/guides/guides_page.dart';

class PcPart {
  final String name;
  final IconData icon;
  final ComponentType type;

  PcPart({required this.name, required this.icon, required this.type});
}

class CustomNavigationBar extends ConsumerWidget {
  final bool showProfileArea;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CustomNavigationBar({
    super.key,
    this.showProfileArea = true,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use drawer for screens smaller than 1000px
    if (screenWidth < 1000) {
      return _MobileAppBar(
        showProfileArea: showProfileArea,
        scaffoldKey: scaffoldKey,
      );
    }

    // Desktop navigation bar
    final user = ref.watch(authProvider);

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
                  'KazaBuild',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
          ),
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
              if (showProfileArea) const SizedBox(width: 20),
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

class _MobileAppBar extends ConsumerWidget {
  final bool showProfileArea;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _MobileAppBar({
    required this.showProfileArea,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (scaffoldKey?.currentState != null) {
                scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
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
                Icon(Icons.build, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'KazaBuild',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ThemeToggleButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomDrawer extends ConsumerWidget {
  final bool showProfileArea;
  const CustomDrawer({super.key, this.showProfileArea = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.build,
                  color: theme.colorScheme.onPrimary,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'Kaza Build',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (showProfileArea && user != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(user.username.substring(0, 1).toUpperCase())
                    : null,
              ),
              title: Text(user.username),
              subtitle: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            const Divider(),
          ],
          if (showProfileArea && user == null) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Sign Up'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.construction),
            title: const Text('Build Now'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuildNowPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Explore Builds'),
            onTap: () {
              Navigator.pop(context);
              // Add your navigation here
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Guides'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuidesPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum),
            title: const Text('Forums'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForumsPage()),
              );
            },
          ),
          const Divider(),
          ExpansionTile(
            leading: const Icon(Icons.category),
            title: const Text('Parts'),
            children: _PartsDropdownMenu.parts.map((part) {
              return ListTile(
                leading: Icon(part.icon, size: 20),
                title: Text(part.name),
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartPickerPage(
                        componentType: part.type,
                        currentBuild: const [],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          if (showProfileArea && user != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () {
                Navigator.pop(context);
                ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                LanguageSelector(),
              ],
            ),
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
          } else if (title == 'Guides') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GuidesPage()),
            );
          } else if (title == 'Forums') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForumsPage()),
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
          radius: 14,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.person, size: 18, color: theme.colorScheme.primary),
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
    PcPart(name: 'CPU', icon: Icons.memory, type: ComponentType.cpu),
    PcPart(name: 'GPU', icon: Icons.developer_board, type: ComponentType.gpu),
    PcPart(
      name: 'Motherboard',
      icon: Icons.dns,
      type: ComponentType.motherboard,
    ),
    PcPart(
      name: 'Case',
      icon: Icons.desktop_windows_outlined,
      type: ComponentType.pcCase,
    ),
    PcPart(name: 'Power Supply', icon: Icons.power, type: ComponentType.psu),
    PcPart(name: 'Memory', icon: Icons.sd_storage, type: ComponentType.ram),
    PcPart(name: 'Cooler', icon: Icons.air, type: ComponentType.cooler),
    PcPart(name: 'Fan', icon: Icons.wind_power, type: ComponentType.caseFan),
    PcPart(name: 'Monitor', icon: Icons.monitor, type: ComponentType.monitor),
  ];

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PartPickerPage(
                  componentType: ComponentType.cpu,
                  currentBuild: [],
                ),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text('Parts', style: textStyle),
        ),
        PopupMenuButton<PcPart>(
          offset: const Offset(0, 45),
          onSelected: (PcPart part) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PartPickerPage(
                  componentType: part.type,
                  currentBuild: const [],
                ),
              ),
            );
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
            padding: const EdgeInsets.only(left: 4.0, right: 8.0),
            child: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
