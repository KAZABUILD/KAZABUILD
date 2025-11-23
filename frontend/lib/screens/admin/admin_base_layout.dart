/// Base Admin Layout
/// 
/// Provides a shared layout with sidebar for all admin pages.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';

class AdminBaseLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;

  const AdminBaseLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
  });

  @override
  State<AdminBaseLayout> createState() => _AdminBaseLayoutState();
}

class _AdminBaseLayoutState extends State<AdminBaseLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin'),
    NavigationItem(icon: Icons.people, label: 'Users', route: '/admin/users'),
    NavigationItem(
      icon: Icons.computer,
      label: 'Builds',
      route: '/admin/builds',
    ),
    NavigationItem(
      icon: Icons.star,
      label: 'Featured Builds',
      route: '/admin/featured-builds',
    ),
    NavigationItem(icon: Icons.forum, label: 'Forums', route: '/admin/forums'),
    NavigationItem(
      icon: Icons.shopping_cart,
      label: 'Parts',
      route: '/admin/parts',
    ),
    NavigationItem(icon: Icons.label, label: 'Tags', route: '/admin/tags'),
    NavigationItem(icon: Icons.book, label: 'Guides', route: '/admin/guides'),
    NavigationItem(
      icon: Icons.quiz,
      label: 'Quiz',
      route: '/admin/quiz',
    ),
    NavigationItem(
      icon: Icons.notifications,
      label: 'Notifications',
      route: '/admin/notifications',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/admin/settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateSelectedIndex();
  }

  @override
  void didUpdateWidget(AdminBaseLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _updateSelectedIndex();
    }
  }

  void _updateSelectedIndex() {
    final index = _navigationItems.indexWhere(
      (item) => item.route == widget.currentRoute,
    );
    if (index != -1) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColorsDark() : AppColorsLight();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.pageTitle),
          backgroundColor: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ),
        drawer: Drawer(
          child: _buildMobileSidebar(isDark, colors),
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Row(
        children: [
          _buildSidebar(isDark, colors),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(bool isDark, dynamic colors) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColorsDark.buttonBlue,
                      AppColorsDark.buttonPurple,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _navigationItems.length,
            itemBuilder: (context, index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;
              return _buildNavItem(item, isSelected, isDark, colors);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              context.go('/home');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Back to Site'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColorsDark.buttonBlue
                  : AppColorsLight.buttonBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(bool isDark, dynamic colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isSidebarCollapsed ? 8 : 16,
              vertical: 16,
            ),
            child: _isSidebarCollapsed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColorsDark.buttonBlue,
                              AppColorsDark.buttonPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.chevron_right,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColorsDark.buttonBlue,
                                    AppColorsDark.buttonPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Flexible(
                              child: Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.chevron_left,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;
                return _buildNavItem(item, isSelected, isDark, colors);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(_isSidebarCollapsed ? 8 : 16),
            child: _isSidebarCollapsed
                ? IconButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    icon: const Icon(Icons.logout),
                    tooltip: 'Back to Site',
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/home');
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Back to Site'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColorsDark.buttonBlue
                            : AppColorsLight.buttonBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      NavigationItem item, bool isSelected, bool isDark, dynamic colors) {
    if (_isSidebarCollapsed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = _navigationItems.indexOf(item);
              });
              context.go(item.route);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          item.icon,
          color: isSelected
              ? Colors.white
              : (isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          setState(() {
            _selectedIndex = _navigationItems.indexOf(item);
          });
          context.go(item.route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

