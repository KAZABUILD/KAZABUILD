@JS('google.accounts.id')
library google_id_web;

import 'dart:async';
import 'package:js/js.dart';

@JS()
external void initialize(InitOptions options);

@JS()
external void prompt([void Function(dynamic)? callback]);

@JS()
@anonymous
class InitOptions {
  external String get client_id;
  external Function get callback;
  external factory InitOptions({String client_id, Function callback});
}

/// The response object provided by Google Identity Services
@JS()
@anonymous
class CredentialResponse {
  external String get credential;
}

Future<String?> getGoogleIdToken(String clientId) async {
  final completer = Completer<String?>();
  initialize(
    InitOptions(
      client_id: clientId,
      callback: allowInterop((dynamic response) {
        try {
          // response is expected to be a CredentialResponse
          final token = (response as CredentialResponse).credential;
          completer.complete(token);
        } catch (_) {
          // If the cast fails, try to access via JS dynamic map
          final token = (response as dynamic)?.credential as String?;
          completer.complete(token);
        }
      }),
    ),
  );

  // Show the One Tap prompt / popup
  prompt();

  // Timeout after 60s if user cancels or closes
  return completer.future.timeout(const Duration(seconds: 60), onTimeout: () => null);
}

