/// This file defines the detail page for a community-submitted PC build.
///
/// It presents a comprehensive view of a single build, including its main image,
/// title, description, author details, and a detailed list of all the components
/// used. Each component is displayed with its name, price, and actions.
/// Users can interact with the build through actions like "Wishlist" or "Follow".
library;

import 'package:flutter/material.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

/// A page that displays the full details of a specific [CommunityBuild].
class BuildDetailPage extends StatefulWidget {
  /// The [CommunityBuild] object containing all the data for the page.
  final CommunityBuild build;
  const BuildDetailPage({super.key, required this.build});

  @override
  State<BuildDetailPage> createState() => _BuildDetailPageState();
}

/// The state for the [BuildDetailPage].
class _BuildDetailPageState extends State<BuildDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  // Constrains the maximum width for better readability on large screens.
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// The main image for the build, with rounded corners.
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          widget.build.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Meta information like author and post date.
                      _buildMetaInfo(theme),
                      const SizedBox(height: 16),

                      /// The title of the build and its star rating.
                      _buildTitleAndRating(theme),
                      const SizedBox(height: 24),

                      /// The user-written description of the build, displayed in a styled container.
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.build.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 32),

                      /// Header for the component list section.
                      Text(
                        'Specifications:',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      // A list of all components in the build, each rendered as a tile.
                      ...widget.build.components.map(
                        (component) => _ComponentTile(component: component),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the row containing metadata about the build, such as the author and post date.
  Widget _buildMetaInfo(ThemeData theme) {
    return Row(
      children: [
        // Author's avatar.
        CircleAvatar(
          radius: 12,
          backgroundImage: widget.build.author.photoURL != null
              ? NetworkImage(widget.build.author.photoURL!)
              : null,
          child: widget.build.author.photoURL == null
              ? Text(
                  widget.build.author.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 10),
                )
              : null,
        ),
        const SizedBox(width: 8),
        // Author's username.
        Text(widget.build.author.username, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Text('•', style: theme.textTheme.bodySmall),
        const SizedBox(width: 8),
        // Date the build was posted.
        Text(
          'Posted on: ${DateFormat.yMMMMd().format(widget.build.postedDate)}',
          style: theme.textTheme.bodySmall,
        ),
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
  Widget _buildTitleAndRating(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The main title of the build.
        Text(
          widget.build.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),

        /// Generates the star rating display based on the build's rating value.
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < widget.build.rating.floor()
                  ? Icons.star
                  : (index < widget.build.rating
                        ? Icons.star_half
                        : Icons.star_border),
              color: Colors.amber,
            );
          }),
        ),
      ],
    );
  }
}

/// A tile widget that displays information about a single component in the build list.
class _ComponentTile extends StatelessWidget {
  final BaseComponent component;
  const _ComponentTile({required this.component});

  /// A helper method that returns an appropriate icon for a given [ComponentType].
  IconData _getIconForType(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.memory;
      case ComponentType.gpu:
        return Icons.developer_board;
      case ComponentType.motherboard:
        return Icons.dns;
      case ComponentType.ram:
        return Icons.sd_storage;
      case ComponentType.storage:
        return Icons.save;
      case ComponentType.psu:
        return Icons.power;
      default:
        return Icons.settings_input_component;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            /// Dynamically sets the icon based on the component type.
            Icon(_getIconForType(component.type), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(component.name, style: theme.textTheme.titleMedium),
            ),

            /// Displays the lowest price found for the component.
            Text(
              '\$${component.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 24),
            // TODO: This should be dynamic, showing the vendor with the lowest price, not hardcoded.
            InkWell(
              onTap: () {},
              child: const Text(
                'allegro',
                style: TextStyle(
                  color: Colors.orange,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // TODO: Implement "Add to build" functionality.
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add to build'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
