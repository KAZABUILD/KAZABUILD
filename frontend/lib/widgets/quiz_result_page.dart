import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/quiz_provider.dart';

class QuizResultsPage extends ConsumerWidget {
  const QuizResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quizAnswers = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);

    //static data for now we will delete it ziyad
    final List<Map<String, dynamic>> recommendedBuilds = [
      {
        'name': 'Balanced Performer',
        'description':
            '1440p gaming and content creation without breaking the bank',
        'price': '\$1,499',
        'cpu': 'AMD Ryzen 7 7700X',
        'gpu': 'NVIDIA RTX 4070',
        'ram': '32GB DDR5',
        'storage': '1TB Gen4 NVMe SSD',
      },
      {
        'name': 'Sweet Spot Build',
        'description':
            'Great for gaming, programming, and everyday multitasking',
        'price': '\$1,299',
        'cpu': 'Intel Core i5-14600K',
        'gpu': 'AMD RX 7800 XT',
        'ram': '32GB DDR5',
        'storage': '1TB Gen3 NVMe SSD',
      },
      {
        'name': 'Esports Champion',
        'description': 'High refresh rate 1080p gaming and competitive play',
        'price': '\$1,199',
        'cpu': 'AMD Ryzen 5 7600X',
        'gpu': 'NVIDIA RTX 4060 Ti',
        'ram': '16GB DDR5',
        'storage': '1TB Gen3 NVMe SSD',
      },
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

                      GridView.builder(
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
                          return Card(
                            color: theme.colorScheme.surface.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    height: 100,
                                    width: 100,
                                    color: theme.colorScheme.surface
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    build['name'] as String,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    build['description'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    build['price'] as String,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('• CPU: ${build['cpu']}'),
                                      Text('• GPU: ${build['gpu']}'),
                                      Text('• RAM: ${build['ram']}'),
                                      Text('• Storage: ${build['storage']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
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
