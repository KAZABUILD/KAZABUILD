/// Admin Analytics Page
/// 
/// Provides analytics and statistics dashboard with real data from backend.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';

class AdminAnalyticsPage extends ConsumerStatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  ConsumerState<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends ConsumerState<AdminAnalyticsPage> {
  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periods = ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'Last Year'];

  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedUsersParams;
  Map<String, dynamic>? _cachedBuildsParams;
  Map<String, dynamic>? _cachedForumPostsParams;
  Map<String, dynamic>? _cachedComponentsParams;

  Map<String, dynamic> _buildUsersParams() {
    final newParams = {
      'query': null,
      'page': null,
      'pageLength': null,
      'orderBy': 'DatabaseEntryAt',
      'sortDirection': 'desc',
    };

    if (_cachedUsersParams != null &&
        _cachedUsersParams!.toString() == newParams.toString()) {
      return _cachedUsersParams!;
    }

    _cachedUsersParams = newParams;
    return _cachedUsersParams!;
  }

  Map<String, dynamic> _buildBuildsParams() {
    final newParams = {
      'query': null,
      'page': null,
      'pageLength': null,
      'orderBy': 'DatabaseEntryAt',
      'sortDirection': 'desc',
    };

    if (_cachedBuildsParams != null &&
        _cachedBuildsParams!.toString() == newParams.toString()) {
      return _cachedBuildsParams!;
    }

    _cachedBuildsParams = newParams;
    return _cachedBuildsParams!;
  }

  Map<String, dynamic> _buildForumPostsParams() {
    final newParams = {
      'query': null,
      'page': null,
      'pageLength': null,
      'orderBy': 'PostedAt',
      'sortDirection': 'desc',
    };

    if (_cachedForumPostsParams != null &&
        _cachedForumPostsParams!.toString() == newParams.toString()) {
      return _cachedForumPostsParams!;
    }

    _cachedForumPostsParams = newParams;
    return _cachedForumPostsParams!;
  }

  Map<String, dynamic> _buildComponentsParams() {
    final newParams = {
      'query': null,
      'componentTypes': null,
      'page': null,
      'pageLength': null,
      'orderBy': 'DatabaseEntryAt',
      'sortDirection': 'desc',
    };

    if (_cachedComponentsParams != null &&
        _cachedComponentsParams!.toString() == newParams.toString()) {
      return _cachedComponentsParams!;
    }

    _cachedComponentsParams = newParams;
    return _cachedComponentsParams!;
  }

  DateTime _getPeriodStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      case 'Last Year':
        return now.subtract(const Duration(days: 365));
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch all data
    final usersAsync = ref.watch(adminUsersProvider(_buildUsersParams()));
    final buildsAsync = ref.watch(adminBuildsProvider(_buildBuildsParams()));
    final forumPostsAsync = ref.watch(adminForumPostsProvider(_buildForumPostsParams()));
    final componentsAsync = ref.watch(adminComponentsProvider(_buildComponentsParams()));

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(
              isDark,
              usersAsync,
              buildsAsync,
              forumPostsAsync,
              componentsAsync,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Analytics Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundTertiary
                  : AppColorsLight.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(
                    period,
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
              underline: Container(),
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isDark,
    AsyncValue<List<AdminUser>> usersAsync,
    AsyncValue<List<AdminBuild>> buildsAsync,
    AsyncValue<List<AdminForumPost>> forumPostsAsync,
    AsyncValue<List<AdminComponent>> componentsAsync,
  ) {
    return usersAsync.when(
      data: (users) {
        return buildsAsync.when(
          data: (builds) {
            return forumPostsAsync.when(
              data: (forumPosts) {
                return componentsAsync.when(
                  data: (components) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKeyMetrics(
                              isDark,
                              users,
                              builds,
                              forumPosts,
                              components,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildUserGrowthChart(isDark, users),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildTopUsers(isDark, users, builds),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: _buildTopBuilds(isDark, builds),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildActivityChart(isDark, builds, forumPosts),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => _buildLoading(isDark),
                  error: (error, stack) => _buildError(isDark, error.toString()),
                );
              },
              loading: () => _buildLoading(isDark),
              error: (error, stack) => _buildError(isDark, error.toString()),
            );
          },
          loading: () => _buildLoading(isDark),
          error: (error, stack) => _buildError(isDark, error.toString()),
        );
      },
      loading: () => _buildLoading(isDark),
      error: (error, stack) => _buildError(isDark, error.toString()),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Center(
      child: CircularProgressIndicator(
        color: isDark ? AppColorsDark.buttonBlue : AppColorsLight.buttonBlue,
      ),
    );
  }

  Widget _buildError(bool isDark, String error) {
    return Center(
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
            'Error loading analytics: $error',
            style: TextStyle(
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(
    bool isDark,
    List<AdminUser> users,
    List<AdminBuild> builds,
    List<AdminForumPost> forumPosts,
    List<AdminComponent> components,
  ) {
    final periodStart = _getPeriodStartDate();
    
    // Calculate metrics based on selected period
    final totalUsers = users.length;
    final activeUsers = users.where((u) => 
      u.registeredAt != null && u.registeredAt!.isAfter(periodStart)
    ).length;
    
    final newBuilds = builds.where((b) => 
      b.lastEditedAt != null && b.lastEditedAt!.isAfter(periodStart)
    ).length;
    
    final newForumPosts = forumPosts.where((f) => 
      f.postedAt != null && f.postedAt!.isAfter(periodStart)
    ).length;

    // Calculate changes (comparing with previous period)
    final previousPeriodStart = periodStart.subtract(
      Duration(days: periodStart.difference(_getPeriodStartDate()).inDays.abs()),
    );
    
    final previousActiveUsers = users.where((u) => 
      u.registeredAt != null && 
      u.registeredAt!.isAfter(previousPeriodStart) &&
      u.registeredAt!.isBefore(periodStart)
    ).length;
    
    final previousNewBuilds = builds.where((b) => 
      b.lastEditedAt != null && 
      b.lastEditedAt!.isAfter(previousPeriodStart) &&
      b.lastEditedAt!.isBefore(periodStart)
    ).length;
    
    final previousNewForumPosts = forumPosts.where((f) => 
      f.postedAt != null && 
      f.postedAt!.isAfter(previousPeriodStart) &&
      f.postedAt!.isBefore(periodStart)
    ).length;

    final activeUsersChange = previousActiveUsers > 0
        ? ((activeUsers - previousActiveUsers) / previousActiveUsers * 100).round()
        : 0;
    
    final newBuildsChange = previousNewBuilds > 0
        ? ((newBuilds - previousNewBuilds) / previousNewBuilds * 100).round()
        : 0;
    
    final newForumPostsChange = previousNewForumPosts > 0
        ? ((newForumPosts - previousNewForumPosts) / previousNewForumPosts * 100).round()
        : 0;

    final metrics = [
      {
        'label': 'Total Users',
        'value': totalUsers.toString(),
        'change': '+${((totalUsers - (users.length - activeUsers)) / (users.length - activeUsers) * 100).round()}%',
        'icon': Icons.people,
        'color': AppColorsDark.buttonBlue
      },
      {
        'label': 'Active Users',
        'value': activeUsers.toString(),
        'change': activeUsersChange >= 0 ? '+$activeUsersChange%' : '$activeUsersChange%',
        'icon': Icons.person,
        'color': AppColorsDark.buttonGreen
      },
      {
        'label': 'New Builds',
        'value': newBuilds.toString(),
        'change': newBuildsChange >= 0 ? '+$newBuildsChange%' : '$newBuildsChange%',
        'icon': Icons.computer,
        'color': AppColorsDark.buttonPurple
      },
      {
        'label': 'Forum Posts',
        'value': newForumPosts.toString(),
        'change': newForumPostsChange >= 0 ? '+$newForumPostsChange%' : '$newForumPostsChange%',
        'icon': Icons.forum,
        'color': AppColorsDark.warning
      },
    ];

    return Row(
      children: metrics.map((metric) {
        final changeValue = metric['change'] as String;
        final isPositive = !changeValue.startsWith('-');
        final changeColor = isPositive ? AppColorsDark.buttonGreen : AppColorsDark.error;
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (metric['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        metric['icon'] as IconData,
                        color: metric['color'] as Color,
                        size: 20,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        changeValue,
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatNumber(int.tryParse(metric['value'] as String) ?? 0),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserGrowthChart(bool isDark, List<AdminUser> users) {
    final periodStart = _getPeriodStartDate();
    final now = DateTime.now();
    final days = now.difference(periodStart).inDays;
    
    // Group users by day
    final Map<int, int> dailyUsers = {};
    for (var user in users) {
      if (user.registeredAt != null && user.registeredAt!.isAfter(periodStart)) {
        final daysSinceStart = user.registeredAt!.difference(periodStart).inDays;
        dailyUsers[daysSinceStart] = (dailyUsers[daysSinceStart] ?? 0) + 1;
      }
    }
    
    // Create cumulative data
    final List<int> cumulativeUsers = [];
    int cumulative = 0;
    for (int i = 0; i <= days; i++) {
      cumulative += dailyUsers[i] ?? 0;
      cumulativeUsers.add(cumulative);
    }

    final maxUsers = cumulativeUsers.isNotEmpty ? cumulativeUsers.reduce((a, b) => a > b ? a : b) : 1;

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
            'User Growth',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            child: cumulativeUsers.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                            : AppColorsLight.textBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _LineChartPainter(
                      data: cumulativeUsers,
                      maxValue: maxUsers,
                      color: AppColorsDark.buttonBlue,
                      isDark: isDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUsers(bool isDark, List<AdminUser> users, List<AdminBuild> builds) {
    // Count builds per user
    final Map<String, int> userBuildCounts = {};
    for (var build in builds) {
      if (build.userId != null) {
        userBuildCounts[build.userId!] = (userBuildCounts[build.userId!] ?? 0) + 1;
      }
    }
    
    // Get top users
    final topUserIds = userBuildCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topUsers = topUserIds.take(5).map((entry) {
      final user = users.firstWhere(
        (u) => u.id == entry.key,
        orElse: () => AdminUser(
          id: entry.key,
          login: 'Unknown',
          userRole: 'GUEST',
        ),
      );
      return {'user': user, 'builds': entry.value};
    }).toList();

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
            'Top Users',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...topUsers.map((item) {
            final user = item['user'] as AdminUser;
            final buildCount = item['builds'] as int;
            final userName = user.displayName ?? user.login;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColorsDark.buttonBlue,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$buildCount builds',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (topUsers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No users with builds',
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                        : AppColorsLight.textBlack.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBuilds(bool isDark, List<AdminBuild> builds) {
    // Sort builds by published date (most recent first)
    final sortedBuilds = List<AdminBuild>.from(builds)
      ..sort((a, b) {
        final aDate = a.publishedAt ?? a.lastEditedAt ?? DateTime(1970);
        final bDate = b.publishedAt ?? b.lastEditedAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    
    final topBuilds = sortedBuilds.take(5).toList();

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
            'Recent Builds',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...topBuilds.map((build) {
            final buildName = build.name ?? 'Unnamed Build';
            final buildDate = build.publishedAt ?? build.lastEditedAt;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColorsDark.buttonPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.computer, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildName,
                          style: TextStyle(
                            color: isDark
                                ? AppColorsDark.textWhite
                                : AppColorsLight.textBlack,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (buildDate != null)
                          Text(
                            _formatDate(buildDate),
                            style: TextStyle(
                              color: isDark
                                  ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                                  : AppColorsLight.textBlack.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(build.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      build.status,
                      style: TextStyle(
                        color: _getStatusColor(build.status),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (topBuilds.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No builds available',
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                        : AppColorsLight.textBlack.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(bool isDark, List<AdminBuild> builds, List<AdminForumPost> forumPosts) {
    final periodStart = _getPeriodStartDate();
    final now = DateTime.now();
    final days = now.difference(periodStart).inDays;
    
    // Group builds and posts by day
    final Map<int, int> dailyActivity = {};
    for (var build in builds) {
      if (build.lastEditedAt != null && build.lastEditedAt!.isAfter(periodStart)) {
        final daysSinceStart = build.lastEditedAt!.difference(periodStart).inDays;
        dailyActivity[daysSinceStart] = (dailyActivity[daysSinceStart] ?? 0) + 1;
      }
    }
    for (var post in forumPosts) {
      if (post.postedAt != null && post.postedAt!.isAfter(periodStart)) {
        final daysSinceStart = post.postedAt!.difference(periodStart).inDays;
        dailyActivity[daysSinceStart] = (dailyActivity[daysSinceStart] ?? 0) + 1;
      }
    }
    
    // Create daily activity list
    final List<int> dailyActivityList = [];
    for (int i = 0; i <= days; i++) {
      dailyActivityList.add(dailyActivity[i] ?? 0);
    }

    final maxActivity = dailyActivityList.isNotEmpty 
        ? dailyActivityList.reduce((a, b) => a > b ? a : b) 
        : 1;

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
            'Activity Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            child: dailyActivityList.isEmpty
                ? Center(
                    child: Text(
                      'No activity data',
                      style: TextStyle(
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                            : AppColorsLight.textBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _BarChartPainter(
                      data: dailyActivityList,
                      maxValue: maxActivity,
                      color: AppColorsDark.buttonGreen,
                      isDark: isDark,
                    ),
                  ),
          ),
        ],
      ),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String? status) {
    if (status == null) return AppColorsDark.textWhite;
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return AppColorsDark.buttonGreen;
      case 'DRAFT':
        return AppColorsDark.warning;
      case 'OFFICIAL':
        return AppColorsDark.buttonBlue;
      default:
        return AppColorsDark.textWhite;
    }
  }
}

// Simple line chart painter
class _LineChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final Color color;
  final bool isDark;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final scaleY = size.height / maxValue;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * scaleY);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}

// Simple bar chart painter
class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final int maxValue;
  final Color color;
  final bool isDark;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / data.length;
    final scaleY = size.height / maxValue;

    for (int i = 0; i < data.length; i++) {
      final x = i * barWidth;
      final barHeight = data[i] * scaleY;
      final rect = Rect.fromLTWH(
        x + 2,
        size.height - barHeight,
        barWidth - 4,
        barHeight,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}
