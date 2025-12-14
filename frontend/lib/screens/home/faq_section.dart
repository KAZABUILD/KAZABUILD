/// This file defines the "Frequently Asked Questions" (FAQ) section, which is
/// displayed on the homepage.
///
/// It uses a simple data class, [FaqItem], to represent each question/answer
/// pair and renders them in a list of expandable tiles ([ExpansionTile]).
library;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/l10n/app_localization.dart';

/// A simple data class to hold the data for a single FAQ item.
class FaqItem {
  /// The question text.
  final String question;

  /// The answer text.
  final String answer;

  /// Creates an instance of an FAQ item.
  const FaqItem({required this.question, required this.answer});
}

/// A widget that displays a list of frequently asked questions.
class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default FAQ items - Can be replaced with backend data later
    final List<FaqItem> faqs = _getDefaultFaqs(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface.withValues(alpha: 0.0),
            theme.colorScheme.surface.withValues(alpha: 0.3),
            theme.colorScheme.surface.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // The main title for the section.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 40,
                    color: AppColorsDark.buttonBlue,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.frequentlyAskedQuestions,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.findAnswersToCommonQuestions,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),
              // Build a list of expandable FAQ items.
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                // Adds a divider between each FAQ item for visual separation.
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return _FaqItem(
                    question: faq.question,
                    answer: faq.answer,
                    index: index,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns default FAQ items for the homepage.
  /// In the future, this can be replaced with data from the backend.
  List<FaqItem> _getDefaultFaqs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      FaqItem(
        question: l10n.whatIsKazabuild,
        answer: l10n.whatIsKazabuildAnswer,
      ),
      FaqItem(
        question: l10n.howDoICreateABuild,
        answer: l10n.howDoICreateABuildAnswer,
      ),
      FaqItem(
        question: l10n.howDoICheckCompatibility,
        answer: l10n.howDoICheckCompatibilityAnswer,
      ),
    ];
  }
}

/// A widget that represents a single, expandable FAQ item.
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final int index;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundTertiary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          // The question is always visible as the title of the tile.
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: AppColorsDark.buttonBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ),
            ],
          ),
          iconColor: AppColorsDark.buttonBlue,
          collapsedIconColor: AppColorsDark.buttonBlue,
          // The answer is displayed in the `children` list and is only visible when the tile is expanded.
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.8)
                      : AppColorsLight.textBlack.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
