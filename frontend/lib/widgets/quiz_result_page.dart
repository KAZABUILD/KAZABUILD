/// This file defines the UI for the quiz results page.
///
/// It displays a curated list of recommended PC builds based on the answers the
/// user provided in the interactive quiz. Each recommendation is shown as a
/// card with key specifications and a link to view more details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/screens/quiz/quiz_provider.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';

/// A page that displays the recommended PC builds after a user completes the quiz.
/// It's a `ConsumerWidget` to interact with Riverpod providers.
class QuizResultsPage extends ConsumerWidget {
  const QuizResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    /// Read the quiz notifier to access its methods for getting recommendations.
    final quizNotifier = ref.read(quizProvider.notifier);

    // TODO: This currently calls a synchronous method. This should be updated
    // to watch a FutureProvider that fetches recommendations from the backend
    // based on the quiz answers.
    final List<CommunityBuild> recommendedBuilds = quizNotifier
        .getRecommendedBuilds(null);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: Center(
              /// Constrains the width of the content for better readability on wide screens.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Page header and subtitle.
                      Text(
                        'Your Recommended Builds',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Based on your preferences, we\'ve curated these builds for you',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      /// If no builds are recommended, show a message. Otherwise, display the grid.
                      recommendedBuilds.isEmpty
                          ? const Center(
                              child: Text(
                                "No recommended builds found based on your answers.",
                              ),
                            )
                          : GridView.builder(
                              /// The grid displays up to 3 build cards per row.
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount: recommendedBuilds.length,
                              itemBuilder: (context, index) {
                                final build = recommendedBuilds[index];

                                /// A helper function to safely find a component of a specific type in the build.
                                BaseComponent? getComponent(
                                  ComponentType type,
                                ) {
                                  try {
                                    return build.components.firstWhere(
                                      (c) => c.type == type,
                                    );
                                  } catch (e) {
                                    return null;
                                  }
                                }

                                /// Get key components to display in the summary.
                                final cpu = getComponent(ComponentType.cpu);
                                final gpu = getComponent(ComponentType.gpu);
                                final ram = getComponent(ComponentType.ram);

                                return Card(
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        /// The main image for the build.
                                        Image.network(
                                          build.imageUrl,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          // Shows a fallback icon if the image fails to load.
                                          errorBuilder: (c, e, s) => Container(
                                            height: 100,
                                            width: 100,
                                            color: theme.colorScheme.surface
                                                .withOpacity(0.3),
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        /// The title of the build.
                                        Text(
                                          build.title,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),

                                        /// A short description of the build.
                                        Text(
                                          build.description,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7),
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),

                                        /// The total price of the build.
                                        Text(
                                          '\$${build.totalPrice.toStringAsFixed(2)}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Column(
                                          /// A summary of the key components.
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• CPU: ${cpu?.name ?? 'N/A'}',
                                            ),
                                            Text(
                                              '• GPU: ${gpu?.name ?? 'N/A'}',
                                            ),
                                            Text(
                                              '• RAM: ${ram?.name ?? 'N/A'}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          // TODO: Implement navigation to the BuildDetailPage.
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor:
                                                theme.colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('View Details'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                      /// A section for users who want to create their own build instead.
                      const SizedBox(height: 32),
                      Text(
                        'Don\'t see what you\'re looking for?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        // TODO: Implement navigation to the BuildNowPage.
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.tertiary,
                          foregroundColor: theme.colorScheme.onTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Build Your Own PC'),
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
}
