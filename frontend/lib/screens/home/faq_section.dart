import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<FaqItem> faqs = [];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text('FaQ', style: theme.textTheme.displaySmall),
              const SizedBox(height: 32),
              if (faqs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Text(
                    'Frequently Asked Questions will be shown here soon.',
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
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

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(question, style: theme.textTheme.titleMedium),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
