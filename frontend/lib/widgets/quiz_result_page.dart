/// This file defines the UI for the quiz results page.
///
/// It displays a curated list of recommended PC builds based on the answers the
/// user provided in the interactive quiz. Each recommendation is shown as a
/// card with key specifications and a link to view more details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/explore_build_model.dart' as build_model;
import 'package:frontend/models/quiz_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class QuizResultsPage extends ConsumerWidget {
  const QuizResultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: Column(
          children: [
            const CustomNavigationBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in to view your personalized recommendations.',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final buildsAsync = ref.watch(quizRecommendedBuildsProvider(user.uid));

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: buildsAsync.when(
              data: (builds) => _ResultsBody(
                builds: builds,
                theme: theme,
                onRetake: () {
                  ref.read(quizProvider.notifier).resetQuiz();
                  ref.read(quizStepProvider.notifier).state = 0;
                  context.go('/quiz');
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ResultsError(
                error: error,
                onRetry: () =>
                    ref.refresh(quizRecommendedBuildsProvider(user.uid)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.builds,
    required this.theme,
    required this.onRetake,
  });

  final List<build_model.Build> builds;
  final ThemeData theme;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Recommended Builds',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your answers, these builds should be a great fit.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: builds.isEmpty
                    ? _EmptyRecommendations(theme: theme, onRetake: onRetake)
                    : ListView.separated(
                        itemCount: builds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final build = builds[index];
                          return _BuildCard(theme: theme, buildData: build);
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: FilledButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations({required this.theme, required this.onRetake});

  final ThemeData theme;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'No builds were generated for your answers.',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Try adjusting your preferences and run the quiz again.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.theme, required this.buildData});

  final ThemeData theme;
  final build_model.Build buildData;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _BuildImage(imageUrl: buildData.imageUrl),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buildData.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    buildData.description?.isNotEmpty == true
                        ? buildData.description!
                        : 'No description provided.',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.person_outline,
                        label: buildData.author?.displayName ?? 'Unknown author',
                      ),
                      _InfoChip(
                        icon: Icons.timelapse,
                        label: _formatGeneratedAt(buildData.databaseEntryAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () {
                        GoRouter.of(context).go('/build/${buildData.id}');
                      },
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatGeneratedAt(DateTime? timestamp) {
  if (timestamp == null) return 'Recently generated';
  final formatted = DateFormat.yMMMd().format(timestamp.toLocal());
  return 'Generated $formatted';
}

class _BuildImage extends StatelessWidget {
  const _BuildImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        width: 120,
        color: theme.colorScheme.surfaceVariant,
            child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 36,
                ),
              )
            : Icon(
                Icons.desktop_windows_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 36,
              ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ResultsError extends StatelessWidget {
  const _ResultsError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56),
          const SizedBox(height: 16),
          Text(
            'Unable to load your builds.\n${error.toString()}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
