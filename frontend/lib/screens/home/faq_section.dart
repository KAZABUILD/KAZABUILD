import 'package:flutter/material.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text('FaQ', style: theme.textTheme.displaySmall),
              const SizedBox(height: 32),
              const _FaqItem(
                question: 'Question 1 will be there',
                answer: 'We will get the answer in data file',
              ),
              const Divider(color: Colors.grey),
              const _FaqItem(
                question: 'Question 2 will be there',
                answer: 'We will get the answer in data file',
              ),
              const Divider(color: Colors.grey),
              const _FaqItem(
                question: 'Question 3 will be there',
                answer: 'We will get the answer in data file ',
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
