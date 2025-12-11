/// This file defines the UI for the user's profile page.
///
/// It displays the logged-in user's information, such as their profile picture,
/// display name, username, and bio. It also fetches and displays a grid of
/// the user's completed builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/authenticated_image.dart';
import 'package:frontend/l10n/app_localization.dart';

/// Provider to fetch a user's profile by ID
final userProfileProvider = FutureProvider.family<AppUser?, String>((ref, userId) async {
  try {
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);
    
    if (userResponse.statusCode == 200 && userResponse.data != null) {
      try {
        final user = AppUser.fromJson(userResponse.data);
        return user;
      } catch (parseError) {
        debugPrint('Error parsing user $userId: $parseError');
        debugPrint('Response data: ${userResponse.data}');
        throw Exception('Failed to parse user data: $parseError');
      }
    } else {
      throw Exception('Failed to fetch user: Status ${userResponse.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching user $userId: $e');
    rethrow; // Re-throw to trigger error state
  }
});

/// Provider to check if current user is following another user
final isFollowingProvider = FutureProvider.family<bool, String>((ref, followedUserId) async {
  try {
    final currentUser = ref.read(authProvider).valueOrNull;
    if (currentUser == null) return false;
    
    final authService = ref.read(authServiceProvider);
    final followId = await authService.getFollowId(currentUser.uid, followedUserId);
    return followId != null;
  } catch (e) {
    debugPrint('Error checking follow status: $e');
    return false;
  }
});

/// Provider to get the follow ID between two users
final followIdProvider = FutureProvider.family<String?, String>((ref, followedUserId) async {
  try {
    final currentUser = ref.read(authProvider).valueOrNull;
    if (currentUser == null) return null;
    
    final authService = ref.read(authServiceProvider);
    return await authService.getFollowId(currentUser.uid, followedUserId);
  } catch (e) {
    debugPrint('Error getting follow ID: $e');
    return null;
  }
});

/// A page that displays a user's profile.
/// If userId is provided, shows that user's profile, otherwise shows the current user's profile.
class ProfilePage extends ConsumerWidget {
  final String? userId;
  
  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserAsync = ref.watch(authProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.surface,
      body: currentUserAsync.when(
        data: (currentUser) {
          // If userId is provided, fetch that user's profile
          if (userId != null && userId != currentUser?.uid) {
            return _buildOtherUserProfile(context, ref, userId!, currentUser, theme, isDark, scaffoldKey);
          }
          
          // Otherwise show current user's profile
          if (currentUser == null) {
            return const Center(child: Text('Not logged in.'));
          }
          
          return Column(
            children: [
              CustomNavigationBar(scaffoldKey: scaffoldKey),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.surface.withValues(alpha: 0.5),
                              theme.colorScheme.background,
                            ],
                          )
                        : null,
                  ),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          children: [
                            // Profile Header Card (own profile - show edit options)
                            _buildProfileCard(context, ref, currentUser, theme, isDark, isOwnProfile: true),
                            const SizedBox(height: 32),
                            // Builds Section
                            _buildBuildsSection(context, ref, currentUser.uid, theme, isDark, isOwnProfile: true),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }

  /// Builds the profile page for another user
  Widget _buildOtherUserProfile(
    BuildContext context,
    WidgetRef ref,
    String userId,
    AppUser? currentUser,
    ThemeData theme,
    bool isDark,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) {
    final profileUserAsync = ref.watch(userProfileProvider(userId));
    
    return profileUserAsync.when(
      data: (profileUser) {
        if (profileUser == null) {
          return Column(
            children: [
              CustomNavigationBar(scaffoldKey: scaffoldKey),
              const Expanded(
                child: Center(child: Text('User not found.')),
              ),
            ],
          );
        }
        
        final isOwnProfile = currentUser?.uid == profileUser.uid;
        
        return Column(
          children: [
            CustomNavigationBar(scaffoldKey: scaffoldKey),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withValues(alpha: 0.5),
                            theme.colorScheme.background,
                          ],
                        )
                      : null,
                ),
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        children: [
                          // Profile Header Card (other user - show follow button)
                          _buildProfileCard(context, ref, profileUser, theme, isDark, isOwnProfile: isOwnProfile, currentUser: currentUser),
                          const SizedBox(height: 32),
                          // Builds Section
                          _buildBuildsSection(context, ref, profileUser.uid, theme, isDark, isOwnProfile: isOwnProfile),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Column(
        children: [
          CustomNavigationBar(scaffoldKey: scaffoldKey),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
      error: (err, stack) => Column(
        children: [
          CustomNavigationBar(scaffoldKey: scaffoldKey),
          Expanded(child: Center(child: Text('Error loading profile: $err'))),
        ],
      ),
    );
  }

  /// Builds the main profile card with user information
  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    ThemeData theme,
    bool isDark, {
    bool isOwnProfile = false,
    AppUser? currentUser,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark
                ? theme.colorScheme.outline.withValues(alpha: 0.2)
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              // Profile Avatar Section
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: theme.colorScheme.surface,
                      child: AuthenticatedImage(
                        imageUrl: user.photoURL,
                        isCircle: true,
                        radius: 66,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        username: user.username,
                        userId: user.uid,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User Name
              Text(
                user.displayName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Username
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '@${user.username}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bio Section
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'About',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.bio!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Action Buttons - Different for own profile vs other users
              if (isOwnProfile) ...[
                // Own profile: Show Settings and Sign Out
                LayoutBuilder(
                  builder: (context, constraints) {
                    // For mobile, stack buttons vertically if needed
                    if (constraints.maxWidth < 400) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _ActionButton(
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              onPressed: () => context.push('/settings'),
                              isPrimary: true,
                              theme: theme,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _ActionButton(
                              icon: Icons.logout_rounded,
                              label: 'Sign Out',
                              onPressed: () async {
                                await ref.read(authProvider.notifier).signOut();
                              },
                              isPrimary: false,
                              theme: theme,
                            ),
                          ),
                        ],
                      );
                    }
                    // For larger screens, show buttons side by side
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: _ActionButton(
                            icon: Icons.settings_rounded,
                            label: 'Settings',
                            onPressed: () => context.push('/settings'),
                            isPrimary: true,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: _ActionButton(
                            icon: Icons.logout_rounded,
                            label: 'Sign Out',
                            onPressed: () async {
                              await ref.read(authProvider.notifier).signOut();
                            },
                            isPrimary: false,
                            theme: theme,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else if (currentUser != null) ...[
                // Other user's profile: Show Follow/Unfollow button and Edit button if admin
                Column(
                  children: [
                    _FollowButton(
                      followedUserId: user.uid,
                      currentUserId: currentUser.uid,
                      theme: theme,
                    ),
                    if (currentUser.userRole.isAdministrator) ...[
                      const SizedBox(height: 12),
                      _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit User',
                        onPressed: () {
                          // Navigate to settings page with userId query parameter
                          final settingsUrl = '/settings?userId=${user.uid}';
                          debugPrint('Navigating to settings: $settingsUrl');
                          context.go(settingsUrl);
                        },
                        isPrimary: false,
                        theme: theme,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the builds section with header and grid
  Widget _buildBuildsSection(
    BuildContext context,
    WidgetRef ref,
    String userId,
    ThemeData theme,
    bool isDark, {
    bool isOwnProfile = false,
  }) {
    final buildsAsyncValue = ref.watch(userBuildsProvider(userId));
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive grid columns
    int crossAxisCount = 4;
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else if (screenWidth < 1200) {
      crossAxisCount = 3;
    } else if (screenWidth < 1600) {
      crossAxisCount = 4;
    } else {
      crossAxisCount = 5;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: buildsAsyncValue.when(
        data: (builds) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.computer_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwnProfile 
                              ? AppLocalizations.of(context)!.myBuilds
                              : AppLocalizations.of(context)!.builds,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.buildsCount(builds.length),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Only show "New Build" button for own profile
                  if (isOwnProfile)
                    FilledButton.icon(
                      onPressed: () {
                        context.push('/build-now');
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('New Build'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Builds Grid or Empty State
              if (builds.isEmpty)
                _buildEmptyState(context, theme, isOwnProfile: isOwnProfile)
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: builds.length,
                  itemBuilder: (context, index) {
                    return _BuildCard(buildData: builds[index], isOwnProfile: isOwnProfile);
                  },
                ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load builds',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the empty state when no builds exist
  Widget _buildEmptyState(BuildContext context, ThemeData theme, {bool isOwnProfile = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 40.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.computer_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No builds yet',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first PC build to get started!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // Only show "Create Your First Build" button for own profile
          if (isOwnProfile) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.push('/build-now');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Build'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget for the Follow/Unfollow button on other users' profiles
class _FollowButton extends ConsumerWidget {
  final String followedUserId;
  final String currentUserId;
  final ThemeData theme;

  const _FollowButton({
    required this.followedUserId,
    required this.currentUserId,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(followedUserId));
    final followIdAsync = ref.watch(followIdProvider(followedUserId));

    return isFollowingAsync.when(
      data: (isFollowing) {
        return FilledButton.icon(
          onPressed: () async {
            try {
              final authService = ref.read(authServiceProvider);
              
              if (isFollowing) {
                // Unfollow
                final followIdValue = await followIdAsync.value;
                if (followIdValue != null) {
                  await authService.unfollowUser(followIdValue);
                  // Invalidate providers to refresh
                  ref.invalidate(isFollowingProvider(followedUserId));
                  ref.invalidate(followIdProvider(followedUserId));
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unfollowed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Follow relationship not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                // Follow
                await authService.followUser(currentUserId, followedUserId);
                // Invalidate providers to refresh
                ref.invalidate(isFollowingProvider(followedUserId));
                ref.invalidate(followIdProvider(followedUserId));
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Followed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: Icon(isFollowing ? Icons.person_remove : Icons.person_add),
          label: Text(isFollowing ? 'Unfollow' : 'Follow'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 120,
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, stack) => FilledButton.icon(
        onPressed: () {
          ref.invalidate(isFollowingProvider(followedUserId));
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// A reusable action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(
            color: theme.colorScheme.error,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

/// A card widget that displays a summary of a single build.
/// Shows the build name and component information.
class _BuildCard extends ConsumerWidget {
  final Build buildData;
  final bool isOwnProfile;

  const _BuildCard({
    required this.buildData,
    this.isOwnProfile = false,
  });


  /// Builds a placeholder image widget when no image is available
  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceVariant.withValues(alpha: 0.4),
            theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.computer_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns a short name for component type
  String _getComponentTypeShortName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'MB';
      case ComponentType.ram:
        return 'RAM';
      case ComponentType.storage:
        return 'SSD';
      case ComponentType.psu:
        return 'PSU';
      case ComponentType.cooler:
        return 'Cooler';
      case ComponentType.caseFan:
        return 'Fan';
      case ComponentType.pcCase:
        return 'Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            // Build Image - always show placeholder to avoid loading and 429 errors
            // Images will be loaded on the detail page
            InkWell(
              onTap: () {
                context.go('/build/${buildData.id}');
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlaceholderImage(context, theme),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Build Name
                  Text(
                    buildData.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Components preview
                  if (buildData.components.isNotEmpty) ...[
                    Text(
                      'Components',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: buildData.components.take(6).map((component) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getComponentIcon(component.type),
                                size: 14,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getComponentTypeShortName(component.type),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (buildData.components.length > 6)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '+${buildData.components.length - 6} more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ] else ...[
                    Text(
                      'No components',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Status, Rating, and Edit Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            buildData.averageRating > 0
                                ? buildData.averageRating.toStringAsFixed(1)
                                : 'New',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      // Status and Edit Button (only for own profile)
                      Row(
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _getStatusColor(buildData.status, theme).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(buildData.status, theme).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              buildData.status,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(buildData.status, theme),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          // Edit Button (only for own profile)
                          if (isOwnProfile) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                context.go('/build/${buildData.id}/edit');
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Build',
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(6),
                                minimumSize: const Size(32, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.memory_rounded;
      case ComponentType.gpu:
        return Icons.videogame_asset_rounded;
      case ComponentType.motherboard:
        return Icons.developer_board_rounded;
      case ComponentType.ram:
        return Icons.storage_rounded;
      case ComponentType.storage:
        return Icons.save_rounded;
      case ComponentType.psu:
        return Icons.power_rounded;
      case ComponentType.cooler:
        return Icons.ac_unit_rounded;
      case ComponentType.caseFan:
        return Icons.air_rounded;
      case ComponentType.pcCase:
        return Icons.computer_rounded;
      case ComponentType.monitor:
        return Icons.monitor_rounded;
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
  }
}
