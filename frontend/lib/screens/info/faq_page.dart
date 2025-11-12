/// This file defines the FAQ (Frequently Asked Questions) page.
///
/// It displays a comprehensive list of questions and answers relevant to
/// the KazaBuild platform, helping users understand how to use the service.
library;

import 'package:flutter/material.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/widgets/navigation_bar.dart' show CustomDrawer, CustomNavigationBar;

/// A simple data class to hold the data for a single FAQ item.
class FaqItem {
  /// The question text.
  final String question;

  /// The answer text.
  final String answer;

  /// Creates an instance of an FAQ item.
  const FaqItem({required this.question, required this.answer});
}

/// A page that displays frequently asked questions about KazaBuild.
class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // FAQ items relevant to KazaBuild platform
    final List<FaqItem> faqs = _getFaqItems(context);

    return Scaffold(
      drawer: const CustomDrawer(showProfileArea: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            const CustomNavigationBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.help_outline,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.frequentlyAskedQuestions,
                                    style: theme.textTheme.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!.findAnswersToCommonQuestions,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // FAQ Items List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: faqs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final faq = faqs[index];
                            return _FaqItem(
                              question: faq.question,
                              answer: faq.answer,
                              index: index,
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        // Contact Section
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.contact_support,
                                size: 32,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Still have questions?',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'If you couldn\'t find the answer you\'re looking for, please contact our support team or visit our feedback page.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns FAQ items relevant to KazaBuild platform.
  List<FaqItem> _getFaqItems(BuildContext context) {
    return [
      FaqItem(
        question: 'What is KazaBuild?',
        answer: 'KazaBuild is a comprehensive PC building platform that helps you plan, build, and share your custom PC configurations. You can browse components, check compatibility, create builds, and get recommendations based on your needs.',
      ),
      FaqItem(
        question: 'How do I create a PC build?',
        answer: 'To create a build, navigate to the "Build Now" page from the main menu. You can add components by category (CPU, GPU, RAM, etc.), and our system will automatically check compatibility between components. Once you\'re satisfied with your build, you can save it and share it with the community.',
      ),
      FaqItem(
        question: 'How does component compatibility checking work?',
        answer: 'KazaBuild automatically checks compatibility between components as you add them to your build. The system verifies socket compatibility for CPUs and motherboards, RAM compatibility, power supply requirements, case size constraints, and other technical specifications to ensure your build will work together.',
      ),
      FaqItem(
        question: 'Are the component prices up to date?',
        answer: 'We strive to keep our component database as current as possible. Prices are updated regularly, but we recommend checking with retailers for the most current pricing before making a purchase. Prices may vary by region and availability.',
      ),
      FaqItem(
        question: 'Can I share my builds with others?',
        answer: 'Yes! Once you create a build, you can publish it to the community. Other users can view your builds, rate them, and get inspiration for their own projects. You can also keep builds private if you prefer.',
      ),
      FaqItem(
        question: 'Is KazaBuild free to use?',
        answer: 'Yes, KazaBuild is completely free to use. You can create unlimited builds, browse components, participate in forums, and access all features without any cost.',
      ),
      FaqItem(
        question: 'How do I find similar builds to mine?',
        answer: 'You can browse the "Explore Builds" section to see builds shared by the community. Use filters to find builds with similar components, price ranges, or use cases. You can also search by tags or component types.',
      ),
      FaqItem(
        question: 'Can I save multiple builds?',
        answer: 'Absolutely! You can create and save as many builds as you want. Each build is saved to your profile, and you can access, edit, or delete them at any time from your profile page.',
      ),
      FaqItem(
        question: 'What if I need help choosing components?',
        answer: 'KazaBuild offers several resources to help you: use our Quiz feature to get personalized recommendations based on your needs, browse our Guides section for detailed information, or participate in the Forums to ask questions and get advice from the community.',
      ),
      FaqItem(
        question: 'How do I update or delete a build?',
        answer: 'You can manage your builds from your profile page. Click on any of your saved builds to view details, make changes, or delete it. Published builds can be edited or unpublished at any time.',
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

