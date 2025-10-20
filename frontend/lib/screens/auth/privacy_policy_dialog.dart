/// This file defines a simple dialog widget that displays a summary of the
/// privacy policy and terms of service.

/// It is typically shown during the sign-up process to inform users about
/// data usage and to get their consent.

import 'package:flutter/material.dart';

/// A dialog widget that presents a brief overview of the privacy policy.

/// It includes "Accept" and "Reject" actions for the user to respond.
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // AlertDialog provides a standard material design dialog structure.
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Privacy and Terms'),
      // The main content of the dialog, made scrollable for smaller screens.
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section explaining the purpose of data collection.
            Text(
              'To provide you with the best experience, we use your data to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // List of specific data uses.
            Text('• Save your PC builds and personal preferences.'),
            Text('• Personalize content and suggestions.'),
            Text('• Ensure the security of our platform.'),
            SizedBox(height: 16),
            // Paragraph about cookies and user consent.
            Text(
              'We also use cookies and similar technologies to help us understand how you use our service. By clicking "Accept", you agree to our use of this data as described in our full Privacy Policy.',
            ),
          ],
        ),
      ),
      // Action buttons at the bottom of the dialog.
      actions: <Widget>[
        TextButton(
          child: const Text('Reject'),
          onPressed: () {
            // TODO: Implement logic for when the user rejects the terms.
            // This might prevent them from signing up.
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Accept'),
          onPressed: () {
            // TODO: Implement logic for when the user accepts the terms.
            // This could set a flag allowing the sign-up process to continue.
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
