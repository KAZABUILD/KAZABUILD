/// This file defines the UI for displaying the full content of a single guide.
///
/// It features a collapsing app bar with a hero image animation and renders
/// the guide's content, which is structured as a list of text blocks (e.g.,
/// headers and paragraphs).

import 'package:flutter/material.dart';
import 'package:frontend/screens/guides/guide_model.dart';
import 'package:intl/intl.dart';

/// A page that displays the detailed content of a [Guide].
class GuideDetailPage extends StatelessWidget {
  /// The [Guide] object containing the data to be displayed.
  final Guide guide;
  const GuideDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      // CustomScrollView allows for combining different scrollable elements,
      // like a collapsing app bar and a list of content.
      body: CustomScrollView(
        slivers: [
          // The app bar that collapses as the user scrolls.
          SliverAppBar(
            // The height of the app bar when it is fully expanded.
            expandedHeight: 300.0,
            // Keeps the app bar visible at the top when collapsed.
            pinned: true,
            // The flexible part of the app bar that shrinks and expands.
            flexibleSpace: FlexibleSpaceBar(
              title: Text(guide.title, style: const TextStyle(fontSize: 16)),
              // The background of the app bar, which includes the hero image.
              background: Hero(
                // The tag must match the tag on the source page (_GuideCard)
                // to enable the hero animation.
                tag: 'guide_image_${guide.id}',
                child: Image.network(
                  guide.imageUrl,
                  fit: BoxFit.cover,
                  // Apply a dark overlay to the image to make the title text more readable.
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          // The main content of the guide, rendered below the app bar.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              // Constrains the width of the content for better readability on wide screens.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata row for author and publication date.
                    Row(
                      children: [
                        Text(
                          'By ${guide.author}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          DateFormat.yMMMMd().format(guide.publishedDate),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    // Dynamically render the content blocks from the guide data.
                    ...guide.content.map((block) {
                      // If the block type is a header, render it with headline style.
                      if (block['type'] == 'h2') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text(
                            block['text']!,
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }

                      // Otherwise, render it as a standard paragraph.
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          block['text']!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
