/// Admin Users Management Page
/// 
/// Provides user management interface with search, filter, and user actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';
import '../../utils/error_utils.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _orderBy;
  String _sortDirection = 'asc';
  int _currentPage = 1;
  final int _pageSize = 20; // Show 20 users per page
  
  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedQueryParams;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark, isMobile),
          Expanded(
            child: _buildContent(isDark, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColorsDark.buttonGreen
                              : AppColorsLight.buttonGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColorsDark.buttonGreen
                            : AppColorsLight.buttonGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 16 : 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isMobile
                  ? 'Search users...'
                  : 'Search users by name, email, or ID...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? AppColorsDark.backgroundTertiary
                  : AppColorsLight.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _currentPage = 1; // Reset to first page on search
                _cachedQueryParams = null; // Invalidate cache
              });
            },
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildQueryParams() {
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'orderBy': _orderBy ?? 'DatabaseEntryAt',
      'sortDirection': _sortDirection,
      'page': _currentPage,
      'pageLength': _pageSize,
    };
    
    // Check if params actually changed to prevent unnecessary rebuilds
    if (_cachedQueryParams != null) {
      bool changed = false;
      for (var key in newParams.keys) {
        if (_cachedQueryParams![key] != newParams[key]) {
          changed = true;
          break;
        }
      }
      if (!changed) {
        return _cachedQueryParams!;
      }
    }
    
    _cachedQueryParams = newParams;
    return _cachedQueryParams!;
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final queryParams = _buildQueryParams();
    final usersAsync = ref.watch(adminUsersProvider(queryParams));

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 24),
          child: _buildStatsRow(isDark, usersAsync, isMobile),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.backgroundSecondary
                    : AppColorsLight.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: usersAsync.when(
                data: (users) {
                  print('AdminUsersPage: Received ${users.length} users from backend');
                  
                  // Debug: Print all users and their status
                  for (var user in users) {
                    print('AdminUsersPage: User ${user.id} - Role: ${user.userRole}, Status: ${user.status}, isBlocked: ${user.isBlocked}, bannedUntil: ${user.bannedUntil}');
                  }
                  
                  // Count statuses
                  final statusCounts = <String, int>{};
                  for (var user in users) {
                    statusCounts[user.status] = (statusCounts[user.status] ?? 0) + 1;
                  }
                  print('AdminUsersPage: Status counts: $statusCounts');
                  
                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: isDark
                                ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                                : AppColorsLight.textBlack.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark
                                  ? AppColorsDark.textWhite
                                  : AppColorsLight.textBlack,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  print('AdminUsersPage: Rendering ${users.length} users in ListView');
                  
                  return Column(
                    children: [
                      if (!isMobile) _buildTableHeader(isDark),
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _buildUserRow(user, isDark, isMobile);
                          },
                        ),
                      ),
                      _buildPagination(isDark, usersAsync),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColorsDark.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load users. Please try again.',
                        style: TextStyle(
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(adminUsersProvider(queryParams)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, AsyncValue<List<AdminUser>> usersAsync, bool isMobile) {
    return usersAsync.when(
      data: (users) {
        final totalUsers = users.length;
        final activeUsers = users.where((u) => u.status == 'Active').length;
        final bannedUsers = users.where((u) => u.status == 'Banned').length;
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final newThisMonth = users.where((u) => 
          u.registeredAt != null && u.registeredAt!.isAfter(startOfMonth)
        ).length;

        final stats = [
          {'label': 'Total Users', 'value': totalUsers.toString(), 'icon': Icons.people, 'color': AppColorsDark.buttonBlue},
          {'label': 'Active Users', 'value': activeUsers.toString(), 'icon': Icons.check_circle, 'color': AppColorsDark.buttonGreen},
          {'label': 'Banned Users', 'value': bannedUsers.toString(), 'icon': Icons.block, 'color': AppColorsDark.error},
          {'label': 'New This Month', 'value': newThisMonth.toString(), 'icon': Icons.person_add, 'color': AppColorsDark.buttonPurple},
        ];
        
        return _buildStatsContent(isDark, stats, isMobile);
      },
      loading: () => _buildStatsContent(isDark, [
        {'label': 'Total Users', 'value': '...', 'icon': Icons.people, 'color': AppColorsDark.buttonBlue},
        {'label': 'Active Users', 'value': '...', 'icon': Icons.check_circle, 'color': AppColorsDark.buttonGreen},
        {'label': 'Banned Users', 'value': '...', 'icon': Icons.block, 'color': AppColorsDark.error},
        {'label': 'New This Month', 'value': '...', 'icon': Icons.person_add, 'color': AppColorsDark.buttonPurple},
      ], isMobile),
      error: (_, __) => _buildStatsContent(isDark, [
        {'label': 'Total Users', 'value': '0', 'icon': Icons.people, 'color': AppColorsDark.buttonBlue},
        {'label': 'Active Users', 'value': '0', 'icon': Icons.check_circle, 'color': AppColorsDark.buttonGreen},
        {'label': 'Banned Users', 'value': '0', 'icon': Icons.block, 'color': AppColorsDark.error},
        {'label': 'New This Month', 'value': '0', 'icon': Icons.person_add, 'color': AppColorsDark.buttonPurple},
      ], isMobile),
    );
  }

  Widget _buildStatsContent(bool isDark, List<Map<String, dynamic>> stats, bool isMobile) {
    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundSecondary
                  : AppColorsLight.backgroundTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Desktop: show stats in a row
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < stats.length - 1 ? 16 : 0),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildHeaderCell('User', isDark)),
          Expanded(flex: 2, child: _buildHeaderCell('Email', isDark)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Status', isDark),
            ),
          ),
          Expanded(flex: 1, child: _buildHeaderCell('Joined', isDark)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Builds', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Posts', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Actions', isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
    );
  }

  Widget _buildUserRow(AdminUser user, bool isDark, bool isMobile) {
    if (isMobile) {
      return _buildUserCard(user, isDark);
    }
    final statusColor = user.status == 'Active'
        ? AppColorsDark.buttonGreen
        : user.status == 'Banned'
            ? AppColorsDark.error
            : Colors.grey;

    final displayName = user.displayName ?? user.login;
    final email = user.email ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColorsDark.buttonBlue,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.userRole.isNotEmpty)
                        Text(
                          user.userRole,
                          style: TextStyle(
                            color: isDark
                                ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                                : AppColorsLight.textBlack.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              email,
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  minWidth: 80,
                ),
                child: Text(
                  user.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              user.registeredAt != null
                  ? _formatDate(user.registeredAt!)
                  : 'N/A',
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '-', // Builds count - would need separate API call
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '-', // Posts count - would need separate API call
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () {
                    // Navigate to user's profile page
                    context.go('/profile/${user.id}');
                  },
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    // Navigate directly to settings page for editing user
                    context.go('/settings?userId=${user.id}');
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {
                    _showDeleteConfirmation(context, user, isDark);
                  },
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context, AdminUser user, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName ?? user.login}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final adminService = ref.read(adminServiceProvider);
                await adminService.deleteUser(user.id);
                
                if (mounted) {
                  // Invalidate the users provider to refresh the list
                  ref.invalidate(adminUsersProvider(_cachedQueryParams ?? {}));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUserFriendlyError(e)),
                      backgroundColor: AppColorsDark.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColorsDark.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AdminUser user, bool isDark) {
    final statusColor = user.status == 'Active'
        ? AppColorsDark.buttonGreen
        : user.status == 'Banned'
            ? AppColorsDark.error
            : Colors.grey;

    final displayName = user.displayName ?? user.login;
    final email = user.email ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? AppColorsDark.backgroundSecondary
          : AppColorsLight.backgroundTertiary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColorsDark.buttonBlue,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.userRole.isNotEmpty)
                        Text(
                          user.userRole,
                          style: TextStyle(
                            color: isDark
                                ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                                : AppColorsLight.textBlack.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.email,
                  size: 16,
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                      : AppColorsLight.textBlack.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (user.registeredAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                        : AppColorsLight.textBlack.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined: ${_formatDate(user.registeredAt!)}',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () {
                    context.go('/profile/${user.id}');
                  },
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    context.go('/settings?userId=${user.id}');
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, user, isDark);
                  },
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPagination(bool isDark, AsyncValue<List<AdminUser>> usersAsync) {
    return usersAsync.when(
      data: (users) {
        final currentPageUsers = users.length;
        final start = currentPageUsers > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
        final end = currentPageUsers > 0 ? start + currentPageUsers - 1 : 0;
        
        // If we got a full page, there might be more pages
        // If we got less than pageSize, we're on the last page
        final hasMore = currentPageUsers == _pageSize;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentPageUsers > 0
                    ? 'Showing $start-$end users (Page $_currentPage${hasMore ? '+' : ''})'
                    : 'No users',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                              _cachedQueryParams = null; // Invalidate cache to trigger refetch
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: hasMore || currentPageUsers == _pageSize
                        ? () {
                            setState(() {
                              _currentPage++;
                              _cachedQueryParams = null; // Invalidate cache to trigger refetch
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}

