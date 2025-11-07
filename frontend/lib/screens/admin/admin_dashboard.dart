/// Admin Dashboard Screen
///
/// Provides a comprehensive admin interface with sidebar navigation,
/// dashboard statistics, and management tools.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
    NavigationItem(icon: Icons.forum, label: 'Forums', route: '/admin/forums'),
    NavigationItem(
      icon: Icons.shopping_cart,
      label: 'Parts',
      route: '/admin/parts',
    ),
    NavigationItem(icon: Icons.book, label: 'Guides', route: '/admin/guides'),
    NavigationItem(
      icon: Icons.analytics,
      label: 'Analytics',
      route: '/admin/analytics',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/admin/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Debug print to verify this widget is being built
    debugPrint('AdminDashboard build() called');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColorsDark() : AppColorsLight();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
        drawer: Drawer(child: _buildMobileSidebar(isDark, colors)),
        body: Column(
          children: [
            // Mobile App Bar Content
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColorsDark.buttonBlue
                          : AppColorsLight.buttonBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Dashboard Content
            Expanded(child: _buildDashboardContent(isDark, colors)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(isDark, colors),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildAppBar(isDark, colors),
                // Dashboard Content
                Expanded(child: _buildDashboardContent(isDark, colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(bool isDark, dynamic colors) {
    return Column(
      children: [
        // Logo/Header Section
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Navigation Items
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
        // Footer
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header Section
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
                        icon: const Icon(Icons.chevron_right, size: 20),
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
                        icon: const Icon(Icons.chevron_left, size: 20),
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
          // Navigation Items
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
          // Footer
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
    NavigationItem item,
    bool isSelected,
    bool isDark,
    dynamic colors,
  ) {
    if (_isSidebarCollapsed) {
      // Collapsed state - just show icon with centered alignment
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

    // Expanded state - show icon and text
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
                : (isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          setState(() {
            _selectedIndex = _navigationItems.indexOf(item);
          });
          // Navigate to route
          context.go(item.route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.buttonBlue
                      : AppColorsLight.buttonBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isDark, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            _buildStatsGrid(isDark, colors),
            const SizedBox(height: 32),
            // Recent Activity Section
            _buildRecentActivity(isDark, colors),
            const SizedBox(height: 32),
            // Quick Actions
            _buildQuickActions(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark, dynamic colors) {
    final stats = [
      StatCard(
        title: 'Total Users',
        value: '1,234',
        change: '+12%',
        isPositive: true,
        icon: Icons.people,
        color: AppColorsDark.buttonBlue,
      ),
      StatCard(
        title: 'Total Builds',
        value: '5,678',
        change: '+8%',
        isPositive: true,
        icon: Icons.computer,
        color: AppColorsDark.buttonGreen,
      ),
      StatCard(
        title: 'Forum Posts',
        value: '3,456',
        change: '+15%',
        isPositive: true,
        icon: Icons.forum,
        color: AppColorsDark.buttonPurple,
      ),
      StatCard(
        title: 'Active Parts',
        value: '2,890',
        change: '+5%',
        isPositive: true,
        icon: Icons.memory,
        color: AppColorsDark.warning,
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
        ? 3
        : screenWidth > 600
        ? 2
        : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], isDark, colors);
      },
    );
  }

  Widget _buildStatCard(StatCard stat, bool isDark, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stat.isPositive
                      ? AppColorsDark.success.withOpacity(0.2)
                      : AppColorsDark.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      stat.isPositive
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 14,
                      color: stat.isPositive
                          ? AppColorsDark.success
                          : AppColorsDark.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat.change,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stat.isPositive
                            ? AppColorsDark.success
                            : AppColorsDark.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isDark, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 20),
          _buildActivityItem(
            'New user registered',
            '2 minutes ago',
            Icons.person_add,
            isDark,
            colors,
          ),
          _buildActivityItem(
            'Build created',
            '15 minutes ago',
            Icons.computer,
            isDark,
            colors,
          ),
          _buildActivityItem(
            'Forum post published',
            '1 hour ago',
            Icons.forum,
            isDark,
            colors,
          ),
          _buildActivityItem(
            'Part added to database',
            '2 hours ago',
            Icons.memory,
            isDark,
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    bool isDark,
    dynamic colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColorsDark.buttonBlue
                          : AppColorsLight.buttonBlue)
                      .withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? AppColorsDark.buttonBlue
                  : AppColorsLight.buttonBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withOpacity(0.6)
                        : AppColorsLight.textBlack.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, dynamic colors) {
    final actions = [
      QuickAction(
        title: 'Manage Users',
        icon: Icons.people,
        color: AppColorsDark.buttonBlue,
      ),
      QuickAction(
        title: 'Review Builds',
        icon: Icons.computer,
        color: AppColorsDark.buttonGreen,
      ),
      QuickAction(
        title: 'Moderate Forums',
        icon: Icons.forum,
        color: AppColorsDark.buttonPurple,
      ),
      QuickAction(
        title: 'Update Parts',
        icon: Icons.memory,
        color: AppColorsDark.warning,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions.map((action) {
            return _buildQuickActionCard(action, isDark, colors);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    QuickAction action,
    bool isDark,
    dynamic colors,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 200.0 : double.infinity;

    return InkWell(
      onTap: () {
        // Handle action
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
            ),
          ],
        ),
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

class StatCard {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
}

class QuickAction {
  final String title;
  final IconData icon;
  final Color color;

  QuickAction({required this.title, required this.icon, required this.color});
}
