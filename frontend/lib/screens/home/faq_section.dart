/// This file defines the "Frequently Asked Questions" (FAQ) section, which is
/// displayed on the homepage.
///
/// It uses a simple data class, [FaqItem], to represent each question/answer
/// pair and renders them in a list of expandable tiles ([ExpansionTile]).
library;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_color.dart';

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
    final List<FaqItem> faqs = _getDefaultFaqs();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary.withOpacity(0.5)
            : AppColorsLight.backgroundSecondary.withOpacity(0.3),
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
                    'Frequently Asked Questions',
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
                'Find answers to common questions about KAZABUILD',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColorsDark.textWhite.withOpacity(0.7)
                      : AppColorsLight.textBlack.withOpacity(0.7),
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
  List<FaqItem> _getDefaultFaqs() {
    return const [
      FaqItem(
        question: 'What is KAZABUILD?',
        answer:
            'KAZABUILD is a comprehensive PC building platform where enthusiasts can create, share, and explore custom PC builds. Whether you\'re a beginner or an expert, KAZABUILD helps you design the perfect PC configuration, get expert advice, and connect with the PC building community.',
      ),
      FaqItem(
        question: 'How do I create a PC build?',
        answer:
            'Creating a PC build is easy! Click on "Build Now" from the navigation menu, and you\'ll be guided through our interactive build wizard. You can select components from various categories like CPU, GPU, RAM, storage, and more. Our system will help you check compatibility and suggest optimal configurations based on your needs and budget.',
      ),
      FaqItem(
        question: 'Are the component prices up to date?',
        answer:
            'We strive to keep our component database and pricing as up-to-date as possible. However, prices can fluctuate frequently in the market. We recommend checking the latest prices from official retailers before making a purchase. Our platform provides a good estimate to help you plan your budget.',
      ),
      FaqItem(
        question: 'Can I share my builds with others?',
        answer:
            'Absolutely! KAZABUILD is designed to be a social platform. You can share your builds with the community, get feedback, and inspire others. You can also explore builds created by other users, save your favorites, and learn from different configurations.',
      ),
      FaqItem(
        question: 'How do I check component compatibility?',
        answer:
            'Our build wizard automatically checks component compatibility as you select parts. The system validates factors like socket compatibility, power supply requirements, case size, and more. If there are any compatibility issues, you\'ll be notified with suggestions for compatible alternatives.',
      ),
      FaqItem(
        question: 'Is KAZABUILD free to use?',
        answer:
            'Yes! KAZABUILD is completely free to use. You can create unlimited builds, browse the community, participate in forums, and access all our guides and resources without any cost. Simply create an account to get started and unlock additional features like saving your builds and joining discussions.',
      ),
      FaqItem(
        question: 'How can I get help with my build?',
        answer:
            'There are several ways to get help on KAZABUILD. You can post questions in our forums, where experienced builders and enthusiasts will be happy to help. You can also browse our comprehensive guides section for tutorials and tips. Additionally, you can comment on similar builds in the community to get specific advice.',
      ),
      FaqItem(
        question: 'Can I save multiple builds?',
        answer:
            'Yes! Once you create an account, you can save multiple builds and access them anytime. This is perfect for planning different builds for various purposes like gaming, content creation, or workstation setups. You can also edit, duplicate, and share your saved builds.',
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
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
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
                  color: AppColorsDark.buttonBlue.withOpacity(0.2),
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
                      ? AppColorsDark.textWhite.withOpacity(0.8)
                      : AppColorsLight.textBlack.withOpacity(0.8),
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
