import 'package:flutter/material.dart';

class IconBar extends StatelessWidget {
  const IconBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: theme.colorScheme.primaryContainer,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.star, size: 24),
          Icon(Icons.favorite, size: 24),
          Icon(Icons.settings, size: 24),
        ],
      ),
    );
  }
}
