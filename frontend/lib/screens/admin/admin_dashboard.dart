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
import '../../models/build_provider.dart';
import '../../models/tag_model.dart';

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
  static final Map<String, dynamic> _componentsParams = {
    'query': null,
    'componentTypes': null,
    'names': null,
    'manufacturers': null,
    'page': null,
    'pageLength': null,
    'orderBy': null,
    'sortDirection': 'asc',
  };

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
    NavigationItem(icon: Icons.label, label: 'Tags', route: '/admin/tags'),
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
    // Use cached params to prevent unnecessary rebuilds
    final usersAsync = ref.watch(adminUsersProvider(_usersParams));
    final buildsAsync = ref.watch(adminBuildsProvider(_buildsParams));
    final forumPostsAsync = ref.watch(adminForumPostsProvider(_forumPostsParams));
    final componentsAsync = ref.watch(adminComponentsProvider(_componentsParams));
    final tagsAsync = ref.watch(tagsProvider);

    // Debug logging
    debugPrint('Dashboard State: Users - loading: ${usersAsync.isLoading}, error: ${usersAsync.hasError}, hasValue: ${usersAsync.valueOrNull != null}');
    debugPrint('Dashboard State: Builds - loading: ${buildsAsync.isLoading}, error: ${buildsAsync.hasError}, hasValue: ${buildsAsync.valueOrNull != null}');
    debugPrint('Dashboard State: Posts - loading: ${forumPostsAsync.isLoading}, error: ${forumPostsAsync.hasError}, hasValue: ${forumPostsAsync.valueOrNull != null}');
    debugPrint('Dashboard State: Components - loading: ${componentsAsync.isLoading}, error: ${componentsAsync.hasError}, hasValue: ${componentsAsync.valueOrNull != null}');

    // Check if ALL providers have errors - only then show full error screen
    final allProvidersHaveError = usersAsync.hasError && 
                                  buildsAsync.hasError && 
                                  forumPostsAsync.hasError && 
                                  componentsAsync.hasError;

    // Show error message only if ALL providers failed
    if (allProvidersHaveError) {
      debugPrint('Dashboard Error: All providers failed');
      debugPrint('Dashboard Error: Users error: ${usersAsync.error}');
      debugPrint('Dashboard Error: Builds error: ${buildsAsync.error}');
      debugPrint('Dashboard Error: Posts error: ${forumPostsAsync.error}');
      debugPrint('Dashboard Error: Components error: ${componentsAsync.error}');
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
                  ref.invalidate(adminComponentsProvider(_componentsParams));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            _buildStatsGrid(isDark, colors, usersAsync, buildsAsync, forumPostsAsync, componentsAsync, tagsAsync),
            const SizedBox(height: 32),
            // Recent Activity Section
            _buildRecentActivity(isDark, colors, usersAsync, buildsAsync, forumPostsAsync),
            const SizedBox(height: 32),
            // Quick Actions
            _buildQuickActions(isDark, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    bool isDark,
    dynamic colors,
    AsyncValue<List<AdminUser>> usersAsync,
    AsyncValue<List<AdminBuild>> buildsAsync,
    AsyncValue<List<AdminForumPost>> forumPostsAsync,
    AsyncValue<List<AdminComponent>> componentsAsync,
    AsyncValue<List<Tag>> tagsAsync,
  ) {
    // Handle loading state - show loading for all cards if any is loading
    if (usersAsync.isLoading || buildsAsync.isLoading || 
        forumPostsAsync.isLoading || componentsAsync.isLoading || tagsAsync.isLoading) {
      final screenWidth = MediaQuery.of(context).size.width;
      final crossAxisCount = screenWidth > 1400
          ? 5
          : screenWidth > 1200
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
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    // Calculate statistics from fetched data
    final users = usersAsync.valueOrNull ?? [];
    final builds = buildsAsync.valueOrNull ?? [];
    final posts = forumPostsAsync.valueOrNull ?? [];
    final components = componentsAsync.valueOrNull ?? [];
    final tags = tagsAsync.valueOrNull ?? [];

    // Debug logging
    debugPrint('Dashboard Stats: Users: ${users.length}, Builds: ${builds.length}, Posts: ${posts.length}, Components: ${components.length}');

    final totalUsers = users.length;
    final totalBuilds = builds.length;
    final totalForumPosts = posts.length;
    final totalComponents = components.length;
    final totalTags = tags.length;

    // Calculate growth percentages (this month vs last month)
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);

    final newUsersThisMonth = users.where((u) =>
      u.registeredAt != null && u.registeredAt!.isAfter(startOfMonth)
    ).length;
    final newUsersLastMonth = users.where((u) =>
      u.registeredAt != null &&
      u.registeredAt!.isAfter(startOfLastMonth) &&
      u.registeredAt!.isBefore(startOfMonth)
    ).length;

    final newBuildsThisMonth = builds.where((b) =>
      b.databaseEntryAt != null && b.databaseEntryAt!.isAfter(startOfMonth)
    ).length;
    final newBuildsLastMonth = builds.where((b) =>
      b.databaseEntryAt != null &&
      b.databaseEntryAt!.isAfter(startOfLastMonth) &&
      b.databaseEntryAt!.isBefore(startOfMonth)
    ).length;

    final newPostsThisMonth = posts.where((p) =>
      p.postedAt != null && p.postedAt!.isAfter(startOfMonth)
    ).length;
    final newPostsLastMonth = posts.where((p) =>
      p.postedAt != null &&
      p.postedAt!.isAfter(startOfLastMonth) &&
      p.postedAt!.isBefore(startOfMonth)
    ).length;

    String calculateChange(int current, int last) {
      if (last == 0) {
        
        return current > 0 ? '+100%' : '0%';
      }
      
      final change = ((current - last) / last * 100).round();
      return change >= 0 ? '+$change%' : '$change%';
    }

    
    debugPrint('Dashboard Growth:');
    debugPrint('  Users - This month: $newUsersThisMonth, Last month: $newUsersLastMonth, Change: ${calculateChange(newUsersThisMonth, newUsersLastMonth)}');
    debugPrint('  Builds - This month: $newBuildsThisMonth, Last month: $newBuildsLastMonth, Change: ${calculateChange(newBuildsThisMonth, newBuildsLastMonth)}');
    debugPrint('  Posts - This month: $newPostsThisMonth, Last month: $newPostsLastMonth, Change: ${calculateChange(newPostsThisMonth, newPostsLastMonth)}');

    final stats = [
      StatCard(
        title: 'Total Users',
        value: _formatNumber(totalUsers),
        change: calculateChange(newUsersThisMonth, newUsersLastMonth),
        changeLabel: 'vs last month',
        isPositive: newUsersThisMonth >= newUsersLastMonth,
        icon: Icons.people,
        color: AppColorsDark.buttonBlue,
        isLoading: false,
        hasError: usersAsync.hasError,
      ),
      StatCard(
        title: 'Total Builds',
        value: _formatNumber(totalBuilds),
        change: calculateChange(newBuildsThisMonth, newBuildsLastMonth),
        changeLabel: 'vs last month',
        isPositive: newBuildsThisMonth >= newBuildsLastMonth,
        icon: Icons.computer,
        color: AppColorsDark.buttonGreen,
        isLoading: false,
        hasError: buildsAsync.hasError,
      ),
      StatCard(
        title: 'Forum Posts',
        value: _formatNumber(totalForumPosts),
        change: calculateChange(newPostsThisMonth, newPostsLastMonth),
        changeLabel: 'vs last month',
        isPositive: newPostsThisMonth >= newPostsLastMonth,
        icon: Icons.forum,
        color: AppColorsDark.buttonPurple,
        isLoading: false,
        hasError: forumPostsAsync.hasError,
      ),
      StatCard(
        title: 'Active Parts',
        value: _formatNumber(totalComponents),
        change: '+0%', // Components don't have date tracking for now
        changeLabel: '',
        isPositive: true,
        icon: Icons.memory,
        color: AppColorsDark.warning,
        isLoading: false,
        hasError: componentsAsync.hasError,
      ),
      StatCard(
        title: 'Total Tags',
        value: _formatNumber(totalTags),
        change: '+0%', // Tags don't have date tracking for now
        changeLabel: '',
        isPositive: true,
        icon: Icons.label,
        color: AppColorsDark.buttonPurple,
        isLoading: false,
        hasError: tagsAsync.hasError,
      ),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 5
        : screenWidth > 1200
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatCard(StatCard stat, bool isDark, dynamic colors) {
    if (stat.isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
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
        child: Center(
          child: CircularProgressIndicator(
            color: stat.color,
          ),
        ),
      );
    }

    if (stat.hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorsDark.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColorsDark.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 12,
                color: AppColorsDark.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                  color: stat.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat.icon, color: stat.color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stat.isPositive
                          ? AppColorsDark.success.withValues(alpha: 0.2)
                          : AppColorsDark.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  if (stat.changeLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stat.changeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                            : AppColorsLight.textBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
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
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
    bool isDark,
    dynamic colors,
    AsyncValue<List<AdminUser>> usersAsync,
    AsyncValue<List<AdminBuild>> buildsAsync,
    AsyncValue<List<AdminForumPost>> forumPostsAsync,
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
      padding: const EdgeInsets.all(24),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 20),
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

  Widget _buildQuickActions(bool isDark, dynamic colors) {
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
      QuickAction(
        title: 'Update Parts',
        icon: Icons.memory,
        color: AppColorsDark.warning,
        route: '/admin/parts',
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
        context.go(action.route);
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
