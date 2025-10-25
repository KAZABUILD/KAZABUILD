/// This file defines the UI for the user's profile page.
///
/// It displays the user's public information, including their avatar, username,
/// stats (like posts and followers), a bio, and a grid of their completed
/// PC builds. It fetches user data using the Riverpod `authProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/widgets/app_bar_actions.dart';

/// A page that displays the public profile of the currently authenticated user.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    /// Watch the authentication provider to get the current user's data.
    final user = ref.watch(authProvider);

    /// If no user is logged in, show a message. This page should not be
    /// accessible without an authenticated user.
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      /// The main app bar for the profile page, with the user's name in the title.
      appBar: AppBar(
        title: Text('${user.username}\'s Profile'),
        backgroundColor: theme.colorScheme.surface,
        actions: const [
          LanguageSelector(),
          SizedBox(width: 8),
          ThemeToggleButton(),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// The main header section with the user's avatar and stats.
            Row(
              children: [
                /// User's profile picture or initial.
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? Text(
                          user.username.substring(0, 1).toUpperCase(),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username, style: theme.textTheme.headlineSmall),

                      /// Display the user's country if it's available.
                      if (user.country != null) ...[
                        const SizedBox(height: 4),
                        Text(user.country!, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        // TODO: Fetch these stats (Posts, Builds) from the backend instead of hardcoding.
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Posts', '15'),
                          _buildStatColumn('Builds', '3'),

                          // _buildStatColumn(
                          //   'Followers',
                          //   user.followers.toString(),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// "About Me" section, only shown if the user has entered a bio.
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const Divider(height: 48),
              Text("About Me", style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(user.bio!, style: theme.textTheme.bodyMedium),
            ],

            /// Section to display the user's public PC builds.
            const Divider(height: 48),
            Text("Completed Builds", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            /// A placeholder grid for the user's builds.
            _buildGridPlaceholder(context),
          ],
        ),
      ),
    );
  }

  /// A helper widget to build a single column for the statistics row (e.g., Posts, Followers).
  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  /// A helper widget that builds a placeholder grid for the user's completed builds.
  /// TODO: Replace this with a real grid that fetches and displays the user's actual builds.
  Widget _buildGridPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: NetworkImage(
                'https://placehold.co/300x300/222/fff?text=Build',
              ),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
