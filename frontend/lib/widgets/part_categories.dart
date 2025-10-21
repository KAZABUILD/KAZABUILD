/// This file defines the "Part Categories" section displayed on the homepage.
///
/// It presents a visually appealing, asymmetrical grid layout to showcase different
/// PC component categories, encouraging users to start exploring parts for their build.

import 'package:flutter/material.dart';

/// The main widget for the part categories section.
///
/// It arranges a large featured card on the left and a 2x2 grid of smaller
/// cards on the right, creating a dynamic and engaging layout for desktop views.
// TODO: Make this layout responsive, stacking the cards vertically on mobile screens.
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
              // The large featured card on the left, taking up 2/5 of the space.
              const Expanded(flex: 2, child: _LargePartCard()),
              const SizedBox(width: 24),
              // The right side, containing the 2x2 grid, taking up 3/5 of the space.
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    const Row(
                      children: [
                        const Expanded(child: _SmallPartCard()),
                        const SizedBox(width: 24),
                        const Expanded(child: _SmallPartCard()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Row(
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

/// A placeholder widget for the large, featured part category card.
// TODO: Replace this with a dynamic widget. It should display an image and title
// for a specific category (e.g., "GPUs") and navigate to the corresponding
// part picker page when tapped.
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

/// A placeholder widget for the smaller part category cards.
// TODO: Replace this with a dynamic widget. It should display an image and title
// for a specific category (e.g., "CPUs", "Motherboards") and navigate to the
// corresponding part picker page when tapped.
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
