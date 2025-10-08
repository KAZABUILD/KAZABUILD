import 'package:flutter/material.dart';

class PartCategoriesSection extends StatelessWidget {
  const PartCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // left big card
              const Expanded(flex: 2, child: _LargePartCard()),
              const SizedBox(width: 24),
              // right 4 small card
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: _SmallPartCard()),
                        const SizedBox(width: 24),
                        const Expanded(child: _SmallPartCard()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: _SmallPartCard()),
                        const SizedBox(width: 24),
                        const Expanded(child: _SmallPartCard()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargePartCard extends StatelessWidget {
  const _LargePartCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 424,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _SmallPartCard extends StatelessWidget {
  const _SmallPartCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
