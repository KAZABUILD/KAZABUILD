import 'package:flutter/material.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Privacy and Terms'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To provide you with the best experience, we use your data to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Save your PC builds and personal preferences.'),
            Text('• Personalize content and suggestions.'),
            Text('• Ensure the security of our platform.'),
            SizedBox(height: 16),
            Text(
              'We also use cookies and similar technologies to help us understand how you use our service. By clicking "Accept", you agree to our use of this data as described in our full Privacy Policy.',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Reject'),
          onPressed: () {
            // todo when suer reject
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Accept'),
          onPressed: () {
            // todo when user accept
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
