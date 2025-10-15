import 'package:flutter/material.dart';
import 'package:frontend/screens/guides/guide_model.dart';
import 'package:intl/intl.dart';

class GuideDetailPage extends StatelessWidget {
  final Guide guide;
  const GuideDetailPage({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(guide.title, style: const TextStyle(fontSize: 16)),
              background: Hero(
                tag: 'guide_image_${guide.id}',
                child: Image.network(
                  guide.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    ...guide.content.map((block) {
                      if (block['type'] == 'h2') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text(
                            block['text']!,
                            style: theme.textTheme.headlineSmall,
                          ),
                        );
                      }

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
