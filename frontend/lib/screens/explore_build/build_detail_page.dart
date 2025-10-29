/// This file defines the detail page for a community-submitted PC build.
///
/// It presents a comprehensive view of a single build, including its main image,
/// title, description, author details, and a detailed list of all the components
/// used. Each component is displayed with its name, price, and actions.
/// Users can interact with the build through actions like "Wishlist" or "Follow".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

/// A page that displays the full details of a specific [CommunityBuild].
class BuildDetailPage extends ConsumerWidget {
  /// The ID of the build to display.
  final String buildId;
  const BuildDetailPage({super.key, required this.buildId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final buildAsyncValue = ref.watch(buildDetailProvider(buildId));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: buildAsyncValue.when(
              data: (build) => _buildContentView(context, build),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(BuildContext context, Build build) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (build.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    build.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 400,
                  ),
                ),
              const SizedBox(height: 24),
              _buildMetaInfo(context, theme, build),
              const SizedBox(height: 16),
              _buildTitleAndRating(theme, build),
              const SizedBox(height: 24),
              if (build.description != null && build.description!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    build.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 32),
              Text(
                'Specifications:',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // TODO: Fetch and display the list of components for this build.
              const Text('Component list will be displayed here.'),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the row containing metadata about the build, such as the author and post date.
  Widget _buildMetaInfo(BuildContext context, ThemeData theme, Build build) {
    return Row(
      children: [
        if (build.author != null) ...[
          CircleAvatar(
            radius: 12,
            backgroundImage: build.author!.photoURL != null
                ? NetworkImage(build.author!.photoURL!)
                : null,
            child: build.author!.photoURL == null
                ? Text(
                    build.author!.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(build.author!.username, style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          Text('•', style: theme.textTheme.bodySmall),
          const SizedBox(width: 8),
        ],
        // TODO: Add 'Posted on' date when available from backend
        Text('Posted on: ${DateFormat.yMMMMd().format(DateTime.now())}', style: theme.textTheme.bodySmall),
        const Spacer(),
        // TODO: Implement "Wishlist" functionality.
        OutlinedButton(onPressed: () {}, child: const Text('Wishlist Build')),
        const SizedBox(width: 12),
        // TODO: Implement "Follow" functionality.
        ElevatedButton(onPressed: () {}, child: const Text('Follow Builds')),
      ],
    );
  }

  /// Builds the row containing the build's title and its star rating.
  Widget _buildTitleAndRating(ThemeData theme, Build build) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The main title of the build.
        Text(
          build.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // TODO: Add rating when available from backend
        const Icon(Icons.star_border, color: Colors.amber),
      ],
    );
  }
}
