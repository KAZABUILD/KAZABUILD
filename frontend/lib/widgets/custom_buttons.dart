import 'package:flutter/material.dart';

class CustomStartButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const CustomStartButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      style: theme.elevatedButtonTheme.style,
      onPressed: onPressed ?? () {},
      child: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
