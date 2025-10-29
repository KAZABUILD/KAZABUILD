/// This file defines the UI for the user's profile page.
///
/// It displays the logged-in user's information, such as their profile picture,
/// display name, username, and bio. It also fetches and displays a grid of
/// the user's completed builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// A page that displays the profile of the currently authenticated user.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authAsyncValue = ref.watch(authProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: const CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,
      body: authAsyncValue.when(
              data: (user) {
                if (user == null) {
                  // This should ideally not happen due to router redirects,
                  // but it's a good fallback.
                  return const Center(child: Text('Not logged in.'));
                }
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: Text(user.username), // Using username as display name for now
                      backgroundColor: theme.colorScheme.surface,
                      floating: true,
                      snap: true,
                      actions: const [
                        //LanguageSelector(),
                        SizedBox(width: 8),
                        //ThemeToggleButton(),
                        SizedBox(width: 16),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(context, ref, user),
                    ),
                    _buildBuildsGrid(context, ref, user.uid),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }

  /// Builds the header section of the profile page containing user info and actions.
  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, AppUser user) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),

                // Display Name
                Text(
                  user.username, // TODO: Use DisplayName from user model
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                // Username (Login)
                Text(
                  '@${user.username}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 24),

                // Action Buttons (Edit Profile, Sign Out)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/settings');
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        // GoRouter will automatically redirect to /login
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                            color: theme.colorScheme.error.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Bio section
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  Text(
                    'About Me',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Divider(height: 48),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Fetches and builds the grid of the user's builds.
  Widget _buildBuildsGrid(BuildContext context, WidgetRef ref, String userId) {
    final theme = Theme.of(context);
    final buildsAsyncValue = ref.watch(userBuildsProvider(userId));

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: buildsAsyncValue.when(
        data: (builds) {
          if (builds.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                heightFactor: 5,
                child: Text('No builds to show yet.'),
              ),
            );
          }
          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Adjust for responsiveness
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final build = builds[index];
                return InkWell(
                  onTap: () => context.go('/build/${build.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      image: build.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(build.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: build.imageUrl == null ? Center(child: Text(build.name)) : null,
                  ),
                );
              },
              childCount: builds.length,
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
        error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Could not load builds: $err'))),
      ),
    );
  }
}
