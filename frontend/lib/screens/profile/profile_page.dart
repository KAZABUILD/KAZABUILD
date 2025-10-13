import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/widgets/app_bar_actions.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
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
            Row(
              children: [
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

                      if (user.country != null) ...[
                        const SizedBox(height: 4),
                        Text(user.country!, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Posts', '15'),
                          _buildStatColumn('Builds', '3'),

                          _buildStatColumn(
                            'Followers',
                            user.followers.toString(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const Divider(height: 48),
              Text("About Me", style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(user.bio!, style: theme.textTheme.bodyMedium),
            ],
            const Divider(height: 48),
            Text("Completed Builds", style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildGridPlaceholder(context),
          ],
        ),
      ),
    );
  }

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
