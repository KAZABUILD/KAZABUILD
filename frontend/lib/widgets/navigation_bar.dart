/// This file defines the main navigation components for the application.
///
/// It includes:
/// - `CustomNavigationBar`: A responsive app bar that adapts to desktop and mobile.
/// - `_MobileAppBar`: The app bar specifically for smaller screens.
/// - `CustomDrawer`: The slide-out navigation drawer for mobile.
/// - Helper widgets for navigation buttons, dropdowns, and user profile areas.
library;
import 'package:go_router/go_router.dart';
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
import 'package:frontend/utils/user_image_utils.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/l10n/app_localization.dart';

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
    final authState = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// The logo and app name, which navigates to the homepage on tap.
          InkWell(
            onTap: () {
              context.go('/home');
              
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
            children:  [
              _NavButton(title: AppLocalizations.of(context)!.buildNow, route: '/build-now'),
              _NavButton(title: AppLocalizations.of(context)!.exploreBuilds, route: '/explore'),
              _NavButton(title: AppLocalizations.of(context)!.guides,route: '/guides'),
              _NavButton(title: AppLocalizations.of(context)!.forums, route: '/forums'),
              Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  return authState.when(
                    data: (user) {
                      if (user != null) {
                        return _NavButton(title: 'Messages', route: '/messages');
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
              _NavButton(title: AppLocalizations.of(context)!.aboutUs, route: '/about'),
              _PartsDropdownMenu(),
            ],
          ),

          /// The right-hand side of the bar with user profile and other actions.
          Row(
            children: [
              if (showProfileArea) ...[
                authState.when(
                  data: (user) => user == null ? const _SignInArea() : const _LoggedInProfileArea(),
                  loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (err, stack) => const Icon(Icons.error),
                ),
              ],
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
              context.go('/home');
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color:Color.fromRGBO(143, 104, 255, 1)),
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
         // if (showProfileArea && user != null) ...[
           // ListTile(
             // leading: CircleAvatar(
               // backgroundColor: theme.colorScheme.primaryContainer,
               ///   ? NetworkImage(user.photoURL!)
                   // : null,
                //child: user.photoURL == null
                    //? Text(user.username.substring(0, 1).toUpperCase())
                    //: null,
              //),
              //title: Text(user.username),
             // subtitle: const Text('View Profile'),
              //onTap: () {
              //  Navigator.pop(context);
               // Navigator.push(
                 // context,
                 //MaterialPageRoute(builder: (_) => const ProfilePage()),
               // );
              //},
           //),
            //const Divider(),
          //],

          /// If no user is logged in, show Sign In and Sign Up options.
          if (showProfileArea && user == null) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(AppLocalizations.of(context)!.signIn),
              onTap: () {
                Navigator.pop(context);
                context.go('/login');
                //Navigator.push(
                  //context,
                  //MaterialPageRoute(builder: (_) => const LoginPage
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: Text(AppLocalizations.of(context)!.signUp),
              onTap: () {
                Navigator.pop(context);
                context.go('/signup');
              },
            ),
            const Divider(),
          ],

          /// Main navigation links.
          // TODO: Refactor these to use named routes for better maintainability.
          ListTile(
            leading: const Icon(Icons.construction),
            title: Text(AppLocalizations.of(context)!.buildNow),
            onTap: () {
              Navigator.pop(context);
              context.go('/build-now');
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: Text(AppLocalizations.of(context)!.exploreBuilds),
            onTap: () {
              Navigator.pop(context);
              context.go('/explore');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: Text(AppLocalizations.of(context)!.guides),
            onTap: () {
              Navigator.pop(context);
              context.go('/guides');
            },
          ),
          ListTile(
            leading: const Icon(Icons.forum),
            title: Text(AppLocalizations.of(context)!.forums),
            onTap: () {
              Navigator.pop(context);
              context.go('/forums');
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              return authState.when(
                data: (user) {
                  if (user != null) {
                    return ListTile(
                      leading: const Icon(Icons.message),
                      title: const Text('Messages'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/messages');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(AppLocalizations.of(context)!.aboutUs),
            onTap: () {
              Navigator.pop(context);
              context.go('/about');
            },
          ),
          const Divider(),
          // Admin panel link - only show for administrators
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              return authState.when(
                data: (user) {
                  if (user != null && user.userRole.isAdministrator) {
                    return ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                      title: Text(AppLocalizations.of(context)!.adminPanel, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/admin');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          const Divider(),

          /// An expandable tile for all the individual part categories.
          Builder(
            builder: (context) {
              // Helper function to get localized part name
              String getLocalizedPartName(ComponentType type) {
                final l10n = AppLocalizations.of(context)!;
                switch (type) {
                  case ComponentType.cpu:
                    return l10n.cpu;
                  case ComponentType.gpu:
                    return l10n.gpu;
                  case ComponentType.motherboard:
                    return l10n.motherboard;
                  case ComponentType.ram:
                    return l10n.memoryRam;
                  case ComponentType.storage:
                    return l10n.storage;
                  case ComponentType.psu:
                    return l10n.powerSupply;
                  case ComponentType.cooler:
                    return l10n.cooler;
                  case ComponentType.caseFan:
                    return l10n.caseFan;
                  case ComponentType.pcCase:
                    return l10n.pcCase;
                  case ComponentType.monitor:
                    return l10n.monitor;
                }
              }
              return ExpansionTile(
                leading: const Icon(Icons.category),
                title: Text(AppLocalizations.of(context)!.parts),
                children: _PartsDropdownMenu.parts.map((part) {
                  return ListTile(
                    leading: Icon(part.icon, size: 20),
                    title: Text(getLocalizedPartName(part.type)),
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/parts/${part.type.name}');
                    },
                  );
                }).toList(),
              );
            },
          ),

          /// If a user is logged in, show Settings and Log Out options.
          if (showProfileArea && user != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(AppLocalizations.of(context)!.settings),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
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
  final String route;
  const _NavButton({required this.title, required this.route, Key? key}) : super(key: key);

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
                context.go(widget.route);
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
    final textStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);

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
            Text(AppLocalizations.of(context)!.welcome, style: theme.textTheme.bodySmall),
            Row(
              children: [
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => context.go('/login'),
                  child: Text(AppLocalizations.of(context)!.signIn, style: textStyle),
                ),
                Text(' / ', style: theme.textTheme.bodySmall),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => context.go('/signup'),
                  child: Text(AppLocalizations.of(context)!.signUp, style: textStyle),
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
  const _LoggedInProfileArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: (value) {
        if (value == 'profile') context.go('/profile');
        if (value == 'settings') context.go('/settings');
        if (value == 'logout') ref.read(authProvider.notifier).signOut();
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'profile', child: Text(AppLocalizations.of(context)!.profile)),
        PopupMenuItem(value: 'settings', child: Text(AppLocalizations.of(context)!.settings)),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: Text(AppLocalizations.of(context)!.logout)),
      ],
      child: authState.when(
        data: (user) {
          if (user == null) return const _SignInArea(); // Should not happen, but as a fallback
          return Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: UserImageUtils.getUserImageUrl(user.photoURL) != null
                    ? NetworkImage(UserImageUtils.getUserImageUrl(user.photoURL)!)
                    : null,
                child: UserImageUtils.getUserImageUrl(user.photoURL) == null
                    ? Text(user.username[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(AppLocalizations.of(context)!.viewProfile, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          );
        },
        loading: () => const SizedBox(width: 150, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (e, s) => const Icon(Icons.error),
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
    PcPart(name: 'CPU', icon: Icons.speed, type: ComponentType.cpu),
    PcPart(name: 'GPU', icon: Icons.videogame_asset, type: ComponentType.gpu),
    PcPart(name: 'Motherboard', icon: Icons.developer_board, type: ComponentType.motherboard),
    PcPart(name: 'Memory (RAM)', icon: Icons.memory, type: ComponentType.ram),
    PcPart(name: 'Storage', icon: Icons.save, type: ComponentType.storage),
    PcPart(name: 'Power Supply', icon: Icons.power, type: ComponentType.psu),
    PcPart(name: 'Cooler', icon: Icons.ac_unit, type: ComponentType.cooler),
    PcPart(name: 'Case Fan', icon: Icons.air, type: ComponentType.caseFan),
    PcPart(name: 'Case', icon: Icons.computer, type: ComponentType.pcCase),
    PcPart(name: 'Monitor', icon: Icons.monitor, type: ComponentType.monitor),
  ];
  @override
  State<_PartsDropdownMenu> createState() => _PartsDropdownMenuState();
}

class _PartsDropdownMenuState extends State<_PartsDropdownMenu> {
  OverlayEntry? _overlayEntry;
  bool _isHoveringDropdown = false;
  bool _isHoveringButton = false;
  bool _isDropdownOpen = false;

  /// Returns the localized name for a component type
  String _getLocalizedPartName(ComponentType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ComponentType.cpu:
        return l10n.cpu;
      case ComponentType.gpu:
        return l10n.gpu;
      case ComponentType.motherboard:
        return l10n.motherboard;
      case ComponentType.ram:
        return l10n.memoryRam;
      case ComponentType.storage:
        return l10n.storage;
      case ComponentType.psu:
        return l10n.powerSupply;
      case ComponentType.cooler:
        return l10n.cooler;
      case ComponentType.caseFan:
        return l10n.caseFan;
      case ComponentType.pcCase:
        return l10n.pcCase;
      case ComponentType.monitor:
        return l10n.monitor;
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;
    
    setState(() => _isDropdownOpen = true);
    
    final RenderBox? buttonBox = context.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;
    
    final offset = buttonBox.localToGlobal(Offset.zero);
    final size = buttonBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx, // Align with the left edge of the Parts button
        top: offset.dy + size.height + 4,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHoveringDropdown = true),
          onExit: (_) {
            setState(() => _isHoveringDropdown = false);
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!_isHoveringDropdown && !_isHoveringButton) {
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
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _PartsDropdownMenu.parts.map((part) {
                  return _DropdownItem(
                    part: part,
                    localizedName: _getLocalizedPartName(part.type),
                    onTap: () {
                      _hideDropdown();
                      context.go('/parts/${part.type.name}');
                    },
                  );
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
    setState(() => _isDropdownOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) {
            setState(() => _isHoveringButton = true);
            _showDropdown();
          },
          onExit: (_) {
            setState(() => _isHoveringButton = false);
            // Only hide dropdown if not hovering over dropdown itself
            Future.delayed(const Duration(milliseconds: 150), () {
              if (!_isHoveringDropdown && !_isHoveringButton) {
                _hideDropdown();
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => context.go('/parts'),
                style: TextButton.styleFrom(
                  foregroundColor: _isHoveringButton
                      ? colorScheme.secondary
                      : theme.textTheme.bodyLarge?.color,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                  padding: const EdgeInsets.only(left: 12, right: 0, top: 8, bottom: 8),
                ),
                child: Text(AppLocalizations.of(context)!.parts),
              ),
              InkWell(
                onTap: () {
                  if (_isDropdownOpen) {
                    _hideDropdown();
                  } else {
                    _showDropdown();
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.only(left: 0, right: 8.0, top: 8.0, bottom: 8.0),
                  child: Icon(
                    _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 20,
                    color: _isHoveringButton
                        ? colorScheme.secondary
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          width: _isHoveringButton ? 20 : 0,
          color: colorScheme.secondary,
        ),
      ],
    );
  }
}

/// A dropdown item widget with hover effects for the parts dropdown menu.
class _DropdownItem extends StatefulWidget {
  final PcPart part;
  final String localizedName;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.part,
    required this.localizedName,
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
                widget.localizedName,
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