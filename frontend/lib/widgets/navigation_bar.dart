/// This file defines the main navigation components for the application.
///
/// It includes:
/// - `CustomNavigationBar`: A responsive app bar that adapts to desktop and mobile.
/// - `_MobileAppBar`: The app bar specifically for smaller screens.
/// - `CustomDrawer`: The slide-out navigation drawer for mobile.
/// - Helper widgets for navigation buttons, dropdowns, and user profile areas.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/login_page.dart';
import 'package:frontend/screens/auth/signup_page.dart';
import 'package:frontend/screens/explore_build/explore_builds_page.dart';
import 'package:frontend/screens/forum/forums_page.dart';
import 'package:frontend/screens/profile/profile_page.dart';
import 'package:frontend/screens/profile/settings_page.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/screens/home/homepage.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/widgets/app_bar_actions.dart';
import 'package:frontend/screens/guides/guides_page.dart';

/// A simple data class to represent a PC part in the dropdown menu.
class PcPart {
  /// The display name of the part (e.g., "CPU").
  final String name;

  /// The icon to display next to the part name.
  final IconData icon;

  /// The [ComponentType] associated with the part, used for navigation.
  final ComponentType type;

  /// Creates an instance of a PC part for the navigation menu.
  PcPart({required this.name, required this.icon, required this.type});
}

/// A responsive navigation bar that shows a full bar on desktop and a
/// minimal app bar with a drawer on mobile.
class CustomNavigationBar extends ConsumerWidget {
  /// Determines whether to show the user profile/login area.
  /// Defaults to `true`.
  final bool showProfileArea;

  /// A key to control the Scaffold's drawer, passed from the parent page.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Creates a responsive navigation bar.
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

    /// For screens smaller than 1000px, show the mobile-specific app bar.
    if (screenWidth < 1100) {
      return _MobileAppBar(
        showProfileArea: showProfileArea,
        scaffoldKey: scaffoldKey,
      );
    }

    /// For wider screens, show the full desktop navigation bar.
    final user = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// The logo and app name, which navigates to the homepage on tap.
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
                Image.asset(
                  "assets/logo/kaza.png",
                  width: 40,
                  height: 40,
                ),
                const Text(
                  'AZABUILD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
          ),

          /// The main navigation buttons in the center of the bar.
          Row(
            children: const [
              _NavButton(title: 'Build Now'),
              _NavButton(title: 'Explore Builds'),
              _NavButton(title: 'Guides'),
              _NavButton(title: 'Forums'),
              _PartsDropdownMenu(),
            ],
          ),

          /// The right-hand side of the bar with user profile and other actions.
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

/// The app bar designed for mobile layouts.
class _MobileAppBar extends ConsumerWidget {
  final bool showProfileArea;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _MobileAppBar({required this.showProfileArea, this.scaffoldKey});

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
          /// The hamburger menu icon to open the drawer.
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

          /// The app logo and name, centered.
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
                Image.asset(
                  "assets/logo/kaza.png",
                  width: 30,
                  height: 30,
                ),
                const Text(
                  'AZABUILD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color:Color.fromRGBO(143, 104, 255, 100)),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,

            /// Actions like the theme toggle button.
            children: const [ThemeToggleButton()],
          ),
        ],
      ),
    );
  }
}

/// The slide-out navigation drawer for mobile layouts.
/// It contains all the navigation links and user-specific actions.
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
          /// The header of the drawer.
          DrawerHeader(
            decoration: BoxDecoration(color:Color.fromARGB(255, 9, 0, 26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset(
                  "assets/logo/kaza.png",
                  width: 45,
                  height: 45,
                ),
                Text(
                  'KazaBuild',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// If a user is logged in, show their profile information.
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

          /// If no user is logged in, show Sign In and Sign Up options.
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

          /// Main navigation links.
          // TODO: Refactor these to use named routes for better maintainability.
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExploreBuildsPage()),
              );
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

          /// An expandable tile for all the individual part categories.
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

          /// If a user is logged in, show Settings and Log Out options.
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

          /// Language selector at the bottom of the drawer.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [LanguageSelector()],
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable text button for the main desktop navigation bar.
class _NavButton extends StatefulWidget {
  final String title;
  const _NavButton({required this.title, Key? key}) : super(key: key);

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                final title = widget.title;
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
                } else if (title == 'Explore Builds') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExploreBuildsPage()),
                  );
                } else {
                  print('$title clicked');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: _isHovering
                    ? colorScheme.secondary
                    : theme.textTheme.bodyLarge?.color,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(widget.title),
            ),

            /// Animated underline on hover
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: _isHovering ? 20 : 0,
              color: colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}


/// The widget displayed in the profile area when the user is not logged in.
/// It provides "Sign In" and "Sign Up" buttons.
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
        /// A generic user icon.
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: Icon(Icons.person, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// "Sign In" and "Sign Up" links.
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

/// The widget displayed in the profile area when a user is logged in.
///
/// It shows the user's avatar and name and provides a dropdown menu with
/// links to their profile, settings, and a log out option.
class _LoggedInProfileArea extends ConsumerWidget {
  final AppUser user;
  const _LoggedInProfileArea({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),

      /// Handle navigation or actions based on the selected menu item.
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

      /// Define the items to be shown in the dropdown menu.
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
        const PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(value: 'logout', child: Text('Log Out')),
      ],

      /// The child of the [PopupMenuButton] is the widget that is displayed on the AppBar.
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

/// A dropdown menu specifically for navigating to different PC part categories.
class _PartsDropdownMenu extends StatefulWidget {
  const _PartsDropdownMenu();

  /// A static list of all PC part categories to be displayed in the menu.
  /// This keeps the data self-contained within the widget.
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
  State<_PartsDropdownMenu> createState() => _PartsDropdownMenuState();
}

class _PartsDropdownMenuState extends State<_PartsDropdownMenu> {
  OverlayEntry? _overlayEntry;
  bool _isHoveringDropdown = false;
  bool _isHoveringButton = false;

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHoveringDropdown = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHoveringDropdown = false;
            });
            // Add a small delay before hiding to allow for clicking
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!_isHoveringDropdown) {
                _hideDropdown();
              }
            });
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _PartsDropdownMenu.parts.map((PcPart part) {
                  return _DropdownItem(part: part, onTap: () {
                    _hideDropdown();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartPickerPage(
                          componentType: part.type,
                          currentBuild: const [],
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Theme.of(context).textTheme.bodyLarge?.color,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHoveringButton = true);
        _showDropdown();
      },
      onExit: (_) {
        setState(() => _isHoveringButton = false);
        // Add a small delay before hiding to allow for clicking
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!_isHoveringDropdown) {
            _hideDropdown();
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// A "Parts" button that navigates to a default part picker page (CPU).
          /// This is useful for users who just want to start browsing parts.
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
              foregroundColor: _isHoveringButton
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).textTheme.bodyLarge?.color,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Parts', style: textStyle),
          ),

          /// Animated underline on hover
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: _isHoveringButton ? 20 : 0,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

/// A dropdown item widget with hover effects for the parts dropdown menu.
class _DropdownItem extends StatefulWidget {
  final PcPart part;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.part,
    required this.onTap,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _isHovering 
                ? colorScheme.secondary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                widget.part.icon, 
                size: 20,
                color: _isHovering 
                    ? colorScheme.secondary
                    : theme.textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 12),
              Text(
                widget.part.name,
                style: TextStyle(
                  color: _isHovering 
                      ? colorScheme.secondary
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: _isHovering ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
