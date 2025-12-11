/// Admin Dashboard Screen
///
/// Provides a comprehensive admin interface with sidebar navigation,
/// dashboard statistics, and management tools.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';
import '../../models/auth_provider.dart';
import '../../utils/user_image_utils.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Cache query params to prevent unnecessary rebuilds
  static final Map<String, dynamic> _usersParams = {
    'query': null,
    'page': null,
    'pageLength': null,
    'orderBy': 'DatabaseEntryAt',
    'sortDirection': 'desc',
  };
  static final Map<String, dynamic> _buildsParams = {
    'query': null,
    'status': null,
    'userIds': null,
    'page': null,
    'pageLength': null,
    'orderBy': 'DatabaseEntryAt',
    'sortDirection': 'desc',
  };
  static final Map<String, dynamic> _forumPostsParams = {
    'query': null,
    'topics': null,
    'creatorIds': null,
    'page': null,
    'pageLength': null,
    'orderBy': 'DatabaseEntryAt',
    'sortDirection': 'desc',
  };

  List<NavigationItem> _getNavigationItems() {
    final authState = ref.read(authProvider);
    final user = authState.valueOrNull;
    final isAdmin = user?.userRole.isAdministrator ?? false;

    final items = [
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
      NavigationItem(icon: Icons.book, label: 'Guides', route: '/admin/guides'),
      NavigationItem(icon: Icons.quiz, label: 'Quiz', route: '/admin/quiz'),
    ];

    // Admin-only items
    if (isAdmin) {
      items.addAll([
        NavigationItem(
          icon: Icons.shopping_cart,
          label: 'Parts',
          route: '/admin/parts',
        ),
        NavigationItem(icon: Icons.label, label: 'Tags', route: '/admin/tags'),
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
      ]);
    }

    return items;
  }

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
        body: _buildDashboardContent(isDark, colors, isMobile),
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
                Expanded(child: _buildDashboardContent(isDark, colors, isMobile)),
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
          child: Builder(
            builder: (context) {
              final navigationItems = _getNavigationItems();
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: navigationItems.length,
                itemBuilder: (context, index) {
                  final item = navigationItems[index];
                  final isSelected = _selectedIndex == index;
                  return _buildNavItem(item, isSelected, isDark, colors);
                },
              );
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
            color: Colors.black.withValues(alpha: 0.1),
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
            child: Builder(
              builder: (context) {
                final navigationItems = _getNavigationItems();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = navigationItems[index];
                    final isSelected = _selectedIndex == index;
                    return _buildNavItem(item, isSelected, isDark, colors);
                  },
                );
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
              final navigationItems = _getNavigationItems();
              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 768;
              setState(() {
                _selectedIndex = navigationItems.indexOf(item);
              });
              if (isMobile) {
                Navigator.pop(context); // Close drawer on mobile
              }
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
          final navigationItems = _getNavigationItems();
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;
          setState(() {
            _selectedIndex = navigationItems.indexOf(item);
          });
          if (isMobile) {
            Navigator.pop(context); // Close drawer on mobile
          }
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
            color: Colors.black.withValues(alpha: 0.05),
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
          _buildUserProfile(isDark),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(bool isDark, dynamic colors, bool isMobile) {
    // Use cached params to prevent unnecessary rebuilds
    final usersAsync = ref.watch(adminUsersProvider(_usersParams));
    final buildsAsync = ref.watch(adminBuildsProvider(_buildsParams));
    final forumPostsAsync = ref.watch(adminForumPostsProvider(_forumPostsParams));

    // Debug logging
    debugPrint('Dashboard State: Users - loading: ${usersAsync.isLoading}, error: ${usersAsync.hasError}, hasValue: ${usersAsync.valueOrNull != null}');
    debugPrint('Dashboard State: Builds - loading: ${buildsAsync.isLoading}, error: ${buildsAsync.hasError}, hasValue: ${buildsAsync.valueOrNull != null}');
    debugPrint('Dashboard State: Posts - loading: ${forumPostsAsync.isLoading}, error: ${forumPostsAsync.hasError}, hasValue: ${forumPostsAsync.valueOrNull != null}');

    // Check if ALL providers have errors - only then show full error screen
    final allProvidersHaveError = usersAsync.hasError && 
                                  buildsAsync.hasError && 
                                  forumPostsAsync.hasError;

    // Show error message only if ALL providers failed
    if (allProvidersHaveError) {
      debugPrint('Dashboard Error: All providers failed');
      debugPrint('Dashboard Error: Users error: ${usersAsync.error}');
      debugPrint('Dashboard Error: Builds error: ${buildsAsync.error}');
      debugPrint('Dashboard Error: Posts error: ${forumPostsAsync.error}');
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColorsDark.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading dashboard data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load dashboard data. Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(adminUsersProvider(_usersParams));
                  ref.invalidate(adminBuildsProvider(_buildsParams));
                  ref.invalidate(adminForumPostsProvider(_forumPostsParams));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(isDark, colors, isMobile),
            SizedBox(height: isMobile ? 20 : 32),
            // Quick Actions
            _buildQuickActions(isDark, colors, isMobile),
            SizedBox(height: isMobile ? 20 : 32),
            // Recent Activity Section
            _buildRecentActivity(isDark, colors, usersAsync, buildsAsync, forumPostsAsync, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark, dynamic colors, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                  AppColorsDark.buttonPurple.withValues(alpha: 0.2),
                ]
              : [
                  AppColorsLight.buttonBlue.withValues(alpha: 0.1),
                  AppColorsLight.buttonPurple.withValues(alpha: 0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Admin Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage your platform, review content, and monitor activity from one central location.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.8)
                        : AppColorsLight.textBlack.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final authState = ref.read(authProvider);
                    final user = authState.valueOrNull;
                    final isAdmin = user?.userRole.isAdministrator ?? false;

                    final chips = [
                      _buildInfoChip(
                        Icons.people,
                        'Users',
                        '/admin/users',
                        isDark,
                      ),
                      _buildInfoChip(
                        Icons.computer,
                        'Builds',
                        '/admin/builds',
                        isDark,
                      ),
                      _buildInfoChip(
                        Icons.forum,
                        'Forums',
                        '/admin/forums',
                        isDark,
                      ),
                    ];

                    // Admin-only chips
                    if (isAdmin) {
                      chips.add(
                        _buildInfoChip(
                          Icons.shopping_cart,
                          'Parts',
                          '/admin/parts',
                          isDark,
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips,
                    );
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Admin Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Manage your platform, review content, and monitor activity from one central location.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.8)
                              : AppColorsLight.textBlack.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (context) {
                          final authState = ref.read(authProvider);
                          final user = authState.valueOrNull;
                          final isAdmin = user?.userRole.isAdministrator ?? false;

                          final chips = [
                            _buildInfoChip(
                              Icons.people,
                              'Users',
                              '/admin/users',
                              isDark,
                            ),
                            _buildInfoChip(
                              Icons.computer,
                              'Builds',
                              '/admin/builds',
                              isDark,
                            ),
                            _buildInfoChip(
                              Icons.forum,
                              'Forums',
                              '/admin/forums',
                              isDark,
                            ),
                          ];

                          // Admin-only chips
                          if (isAdmin) {
                            chips.add(
                              _buildInfoChip(
                                Icons.shopping_cart,
                                'Parts',
                                '/admin/parts',
                                isDark,
                              ),
                            );
                          }

                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: chips,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColorsDark.buttonBlue,
                        AppColorsDark.buttonPurple,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String route,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColorsDark.buttonBlue
                  : AppColorsLight.buttonBlue,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    bool isDark,
    dynamic colors,
    AsyncValue<List<AdminUser>> usersAsync,
    AsyncValue<List<AdminBuild>> buildsAsync,
    AsyncValue<List<AdminForumPost>> forumPostsAsync,
    bool isMobile,
  ) {
    // Collect recent activities from all data sources
    final activities = <ActivityItem>[];

    final users = usersAsync.valueOrNull ?? [];
    final builds = buildsAsync.valueOrNull ?? [];
    final posts = forumPostsAsync.valueOrNull ?? [];

    // Add recent users
    final recentUsers = users
        .where((u) => u.registeredAt != null)
        .toList()
      ..sort((a, b) => (b.registeredAt ?? DateTime(1970)).compareTo(a.registeredAt ?? DateTime(1970)));
    
    for (var user in recentUsers.take(3)) {
      if (user.registeredAt != null) {
        activities.add(ActivityItem(
          title: 'New user registered: ${user.displayName ?? user.login}',
          time: user.registeredAt!,
          icon: Icons.person_add,
        ));
      }
    }

    // Add recent builds
    final recentBuilds = builds
        .where((b) => b.databaseEntryAt != null)
        .toList()
      ..sort((a, b) => (b.databaseEntryAt ?? DateTime(1970)).compareTo(a.databaseEntryAt ?? DateTime(1970)));
    
    for (var build in recentBuilds.take(3)) {
      if (build.databaseEntryAt != null) {
        activities.add(ActivityItem(
          title: 'Build created: ${build.name ?? "Untitled"}',
          time: build.databaseEntryAt!,
          icon: Icons.computer,
        ));
      }
    }

    // Add recent forum posts
    final recentPosts = posts
        .where((p) => p.postedAt != null)
        .toList()
      ..sort((a, b) => (b.postedAt ?? DateTime(1970)).compareTo(a.postedAt ?? DateTime(1970)));
    
    for (var post in recentPosts.take(3)) {
      if (post.postedAt != null) {
        activities.add(ActivityItem(
          title: 'Forum post published: ${post.title ?? "Untitled"}',
          time: post.postedAt!,
          icon: Icons.forum,
        ));
      }
    }

    // Sort all activities by time (most recent first)
    activities.sort((a, b) => b.time.compareTo(a.time));

    // Take only the 5 most recent activities
    final recentActivities = activities.take(5).toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (usersAsync.isLoading || buildsAsync.isLoading || forumPostsAsync.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (recentActivities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'No recent activity',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                      : AppColorsLight.textBlack.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ...recentActivities.map((activity) => _buildActivityItem(
              activity.title,
              _formatTimeAgo(activity.time),
              activity.icon,
              isDark,
              colors,
              isMobile,
            )),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    bool isDark,
    dynamic colors,
    bool isMobile,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? AppColorsDark.buttonBlue
                          : AppColorsLight.buttonBlue)
                      .withValues(alpha: 0.2),
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
                        ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                        : AppColorsLight.textBlack.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, dynamic colors, bool isMobile) {
    final authState = ref.read(authProvider);
    final user = authState.valueOrNull;
    final isAdmin = user?.userRole.isAdministrator ?? false;

    final actions = [
      QuickAction(
        title: 'Manage Users',
        icon: Icons.people,
        color: AppColorsDark.buttonBlue,
        route: '/admin/users',
      ),
      QuickAction(
        title: 'Review Builds',
        icon: Icons.computer,
        color: AppColorsDark.buttonGreen,
        route: '/admin/builds',
      ),
      QuickAction(
        title: 'Moderate Forums',
        icon: Icons.forum,
        color: AppColorsDark.buttonPurple,
        route: '/admin/forums',
      ),
    ];

    // Admin-only actions
    if (isAdmin) {
      actions.add(
        QuickAction(
          title: 'Update Parts',
          icon: Icons.memory,
          color: AppColorsDark.warning,
          route: '/admin/parts',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        isMobile
            ? Column(
                children: actions.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuickActionCard(action, isDark, colors, isMobile),
                  );
                }).toList(),
              )
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: actions.map((action) {
                  return _buildQuickActionCard(action, isDark, colors, isMobile);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    QuickAction action,
    bool isDark,
    dynamic colors,
    bool isMobile,
  ) {
    return InkWell(
      onTap: () {
        context.go(action.route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: isMobile ? double.infinity : 200,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.2),
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

  Widget _buildUserProfile(bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.buttonBlue
              : AppColorsLight.buttonBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white),
      );
    }

    return Row(
      children: [
        UserImageUtils.buildUserAvatar(
          imageUrl: user.photoURL,
          username: user.displayName.isNotEmpty ? user.displayName : user.username,
          userId: user.uid,
          radius: 20,
        ),
        const SizedBox(width: 12),
        Text(
          user.displayName.isNotEmpty ? user.displayName : user.username,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColorsDark.textWhite
                : AppColorsLight.textBlack,
          ),
        ),
      ],
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
  final String changeLabel; // Açıklayıcı label (örn: "vs last month")
  final bool isPositive;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool hasError;

  StatCard({
    required this.title,
    required this.value,
    required this.change,
    this.changeLabel = '',
    required this.isPositive,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.hasError = false,
  });
}

class QuickAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  QuickAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class ActivityItem {
  final String title;
  final DateTime time;
  final IconData icon;

  ActivityItem({
    required this.title,
    required this.time,
    required this.icon,
  });
}
