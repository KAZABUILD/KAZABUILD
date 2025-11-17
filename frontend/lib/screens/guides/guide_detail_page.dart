/// This file defines the UI for displaying the full content of a single guide.
///
/// It features a visually engaging collapsing app bar (`SliverAppBar`) with a
/// hero image animation for a smooth transition from the guides list. The page
/// dynamically renders the guide's content, which is structured as a list of
/// different text blocks (e.g., headers and paragraphs), making it flexible
/// for various article formats.
library;

import 'package:flutter/material.dart';
import 'package:frontend/models/guide_model.dart';
import 'package:frontend/widgets/linkable_text.dart';
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

      /// [CustomScrollView] allows for combining different scrollable elements,
      /// like a collapsing app bar and a list of content, to create rich scroll effects.
      body: CustomScrollView(
        slivers: [
          /// The app bar that collapses as the user scrolls, providing a dynamic header.
          SliverAppBar(
            /// The height of the app bar when it is fully expanded.
            expandedHeight: 300.0,

            /// Keeps the app bar visible at the top when collapsed, showing only the title.
            pinned: true,

            /// The flexible part of the app bar that shrinks and expands.
            flexibleSpace: FlexibleSpaceBar(
              title: Text(guide.title, style: const TextStyle(fontSize: 16)),

              /// The background of the app bar, which includes the hero image.
              background: Hero(
                /// The tag must match the tag on the source page (`_GuideCard`)
                /// to enable the hero (shared element) transition animation.
                tag: 'guide_image_${guide.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      guide.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.3),
                                theme.colorScheme.secondary.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                          ),
                        );
                      },
                    ),
                    /// Apply a dark overlay to the image to make the title text more readable
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// The main content of the guide, rendered as a list of widgets below the app bar.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),

              /// Constrains the width of the content for better readability on wide screens.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        guide.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    /// Metadata row for author, read time, and publication date.
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'By ${guide.author}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    guide.readTime,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat.yMMMMd().format(guide.publishedDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),

                    /// Dynamically render the content blocks from the guide data.
                    // TODO: Add support for more content block types like images, lists, or code blocks.
                    ...guide.content.map((block) {
                      /// If the block type is a header, render it with headline style.
                      if (block['type'] == 'h2') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text(
                            block['text']!,
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }

                      /// Otherwise, render it as a standard paragraph with clickable links.
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: LinkableText(
                          text: block['text']!,
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
