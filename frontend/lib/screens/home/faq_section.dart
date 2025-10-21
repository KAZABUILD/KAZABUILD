/// This file defines the "Frequently Asked Questions" (FAQ) section, which is
/// displayed on the homepage.
///
/// It uses a simple data class, [FaqItem], to represent each question/answer
/// pair and renders them in a list of expandable tiles ([ExpansionTile]).

import 'package:flutter/material.dart';

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

    // TODO: Replace this mock data with a list fetched from a backend service.
    final List<FaqItem> faqs = [];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              // The main title for the section.
              Text('FaQ', style: theme.textTheme.displaySmall),
              const SizedBox(height: 32),
              // If there are no FAQs, display a placeholder message.
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Text(
                    'Frequently Asked Questions will be shown here soon.',
                  ),
                )
              else
                // Otherwise, build a list of expandable FAQ items.
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  // Adds a divider between each FAQ item for visual separation.
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.grey),
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return _FaqItem(question: faq.question, answer: faq.answer);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that represents a single, expandable FAQ item.
class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ExpansionTile is a built-in Flutter widget that can be tapped to expand or collapse.
    return ExpansionTile(
      // The question is always visible as the title of the tile.
      title: Text(question, style: theme.textTheme.titleMedium),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      // The answer is displayed in the `children` list and is only visible when the tile is expanded.
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
