/// Quiz results page showing curated recommended builds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/explore_build_model.dart' as build_model;
import 'package:frontend/models/quiz_provider.dart';
import 'package:frontend/screens/builder/build_now_page.dart'
    show buildProvider;
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
        backgroundColor: const Color(0xFF0F0915),
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
      backgroundColor: const Color(0xFF0F0915),
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: buildsAsync.when(
              data: (builds) =>
                  _ResultsBody(ref: ref, builds: builds, theme: theme),
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
    required this.ref,
  });

  final List<build_model.Build> builds;
  final ThemeData theme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final displayedBuilds = builds.take(3).toList();
    final isEmpty = displayedBuilds.isEmpty;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text(
                'Your Recommended Builds',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your preferences, we\'ve curated these builds for you',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: isEmpty
                    ? _EmptyRecommendations(theme: theme)
                    : _BuildGrid(builds: displayedBuilds, ref: ref),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/build-now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsDark.buttonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Build Your Own PC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildGrid extends StatelessWidget {
  const _BuildGrid({required this.builds, required this.ref});

  final List<build_model.Build> builds;
  final WidgetRef ref;

  Future<void> _openBuildInBuilder(
    BuildContext context,
    build_model.Build build,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    bool dialogShown = false;
    void showLoading() {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      showLoading();
      final detailed = await ref.read(buildDetailProvider(build.id).future);
      final components = detailed.components;

      if (components.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to load components for this build.'),
          ),
        );
        return;
      }

      final componentService = ref.read(componentServiceProvider);
      await ref
          .read(buildProvider.notifier)
          .loadComponentsFromBuildWithPrices(components, componentService);

      if (context.mounted) {
        context.go('/build-now');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to open build: $e')),
      );
    } finally {
      if (dialogShown && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1200
            ? 3
            : width > 900
            ? 2
            : 1;
        const spacing = 24.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return SingleChildScrollView(
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.start,
            children: builds.map((build) {
              final effectiveWidth = cardWidth.clamp(280.0, 520.0);
              return SizedBox(
                width: effectiveWidth,
                child: FutureBuilder<build_model.Build>(
                  future: ref.read(buildDetailProvider(build.id).future),
                  builder: (context, snapshot) {
                    final detailed = snapshot.data ?? build;
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData;
                    return _BuildCard(
                      buildData: detailed,
                      onViewDetails: () =>
                          _openBuildInBuilder(context, detailed),
                      isLoading: loading,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _EmptyRecommendations extends StatelessWidget {
  const _EmptyRecommendations({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'No builds were generated for your answers.',
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Try adjusting your preferences and run the quiz again.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({
    required this.buildData,
    required this.onViewDetails,
    required this.isLoading,
  });

  final build_model.Build buildData;
  final Future<void> Function() onViewDetails;
  final bool isLoading;

  String _componentTypeLabel(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'Motherboard';
      case ComponentType.ram:
        return 'RAM';
      case ComponentType.storage:
        return 'Storage';
      case ComponentType.psu:
        return 'PSU';
      case ComponentType.cooler:
        return 'Cooler';
      case ComponentType.caseFan:
        return 'Case Fan';
      case ComponentType.pcCase:
        return 'Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }

  Widget _componentsListSection() {
    final components = buildData.components;

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.85),
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );

    if (isLoading) {
      return Text(
        'Loading components...',
        style: textStyle.copyWith(color: Colors.white.withOpacity(0.7)),
      );
    }

    if (components.isEmpty) {
      return Text(
        'Components unavailable',
        style: textStyle.copyWith(color: Colors.white.withOpacity(0.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: components
          .map(
            (component) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    size: 14,
                    color: Colors.white.withOpacity(0.75),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_componentTypeLabel(component.type)}: ${component.name}',
                      style: textStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.monitor_outlined,
        color: Colors.white.withOpacity(0.4),
        size: 48,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF181225);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: const Color(0xFF120D1E),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : (buildData.imageUrl != null &&
                                buildData.imageUrl!.isNotEmpty)
                          ? Image.network(
                              buildData.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  buildData.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  buildData.description?.isNotEmpty == true
                      ? buildData.description!
                      : 'A balanced build tailored to your preferences.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'All components',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _componentsListSection(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: AppColorsDark.buttonPurple.withOpacity(0.6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColorsDark.buttonPurple.withOpacity(
                        0.08,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'View Details',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Spec row widget removed; component list now serves as primary details.

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
