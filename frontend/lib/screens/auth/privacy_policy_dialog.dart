/// This file defines a dialog widget that displays a summary of the privacy
/// policy and terms of service.
///
/// It is designed to be shown during the user registration process to obtain
/// consent before an account is created. The dialog is intentionally kept
/// simple, providing a brief overview and actions to accept or reject the terms.
library;

import 'package:flutter/material.dart';

/// A modal dialog that presents a concise overview of the application's
/// privacy policy and terms.
///
/// It features a title, scrollable content explaining data usage, and two
/// action buttons: 'Reject' and 'Accept'.
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// The base widget for the dialog, providing standard Material Design styling.
    return AlertDialog(
      /// Customizing the dialog's appearance to match the app's theme.
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      /// The main title of the dialog.
      title: const Text('Privacy and Terms'),

      /// The body of the dialog, containing the policy text.
      /// Wrapped in a [SingleChildScrollView] to prevent overflow on smaller screens.
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

            /// A bulleted list outlining specific uses of user data.
            Text('• Save your PC builds and personal preferences.'),
            Text('• Personalize content and suggestions.'),
            Text('• Ensure the security of our platform.'),
            SizedBox(height: 16),

            /// A paragraph explaining the use of cookies and requesting user consent.
            /// It also mentions that a full policy is available elsewhere.
            Text(
              'We also use cookies and similar technologies to help us understand how you use our service. By clicking "Accept", you agree to our use of this data as described in our full Privacy Policy.',
            ),
          ],
        ),
      ),

      /// A list of widgets to display at the bottom of the dialog.
      actions: <Widget>[
        /// A button for the user to reject the terms.
        TextButton(
          child: const Text('Reject'),
          onPressed: () {
            // Closes the dialog and returns `false`.
            Navigator.of(context).pop(false);
          },
        ),

        /// A primary button for the user to accept the terms.
        ElevatedButton(
          child: const Text('Accept'),
          onPressed: () {
            // Closes the dialog and returns `true`.
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
