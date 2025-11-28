@JS('google.accounts.id')
library google_id_web;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:js/js.dart';

// Google Identity Services - ID token
@JS('google.accounts.id')
external GoogleAccountsId get googleAccountsId;

@JS()
@anonymous
class GoogleAccountsId {
  external void initialize(IdInitOptions options);
  external void prompt([void Function(dynamic)? callback]);
}

@JS()
@anonymous
class IdInitOptions {
  external String get client_id;
  external Function get callback;
  external factory IdInitOptions({String client_id, Function callback});
}

/// The response object provided by Google Identity Services
@JS()
@anonymous
class CredentialResponse {
  external String get credential;
}

// Google OAuth2 - For popup login
@JS('google.accounts.oauth2')
external GoogleAccountsOAuth2 get googleAccountsOAuth2;

@JS()
@anonymous
class GoogleAccountsOAuth2 {
  external TokenClient initTokenClient(TokenClientConfig config);
}

@JS()
@anonymous
class TokenClient {
  external void requestAccessToken([TokenClientRequestOptions? options]);
}

@JS()
@anonymous
class TokenClientConfig {
  external String get client_id;
  external String get scope;
  external Function get callback;
  external factory TokenClientConfig({String client_id, String scope, Function callback});
}

@JS()
@anonymous
class TokenClientRequestOptions {
  external String? get prompt;
  external factory TokenClientRequestOptions({String? prompt});
}

@JS()
@anonymous
class TokenResponse {
  external String get access_token;
  external String? get error;
  external String? get error_description;
}

/// Waits for Google Identity Services script to be available
/// The script is already in index.html, we just need to wait for it to load
Future<void> _loadGoogleScript() async {
  int attempts = 0;
  const maxAttempts = 50; // 5 seconds total (50 * 100ms)
  
  // Check if already loaded using dart:html
  while (attempts < maxAttempts) {
    try {
      // Check if google.accounts.id exists using window from dart:html
      final google = js_util.getProperty(html.window, 'google');
      if (google != null) {
        final accounts = js_util.getProperty(google, 'accounts');
        if (accounts != null) {
          final id = js_util.getProperty(accounts, 'id');
          if (id != null) {
            // Script is loaded and ready!
            return;
          }
        }
      }
    } catch (e) {
      // Continue waiting
    }
    
    // Wait a bit before checking again
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
  
  // Final check
  try {
    final google = js_util.getProperty(html.window, 'google');
    if (google != null) {
      final accounts = js_util.getProperty(google, 'accounts');
      if (accounts != null) {
        final id = js_util.getProperty(accounts, 'id');
        if (id != null) {
          return;
        }
      }
    }
  } catch (e) {
    // Fall through
  }
  
  throw Exception('Google Identity Services script failed to load. Please check your internet connection and refresh the page.');
}

/// Gets Google ID token using Google Identity Services (for button clicks)
/// This will show a popup when called from a user interaction (button click)
/// Uses OAuth2 code flow as a fallback if ID token flow fails
Future<String?> getGoogleIdToken(String clientId) async {
  final completer = Completer<String?>();
  
  try {
    // Load or wait for Google Identity Services script
    await _loadGoogleScript();

    // Get google.accounts.id directly from window using dart:html and js_util
    final google = js_util.getProperty(html.window, 'google');
    if (google == null) {
      throw Exception('Google object not found');
    }
    
    final accounts = js_util.getProperty(google, 'accounts');
    if (accounts == null) {
      throw Exception('Google accounts not found');
    }
    
    final id = js_util.getProperty(accounts, 'id');
    if (id == null) {
      throw Exception('Google accounts.id not found');
    }

    // Use the initialize method directly from the JS object
    final initializeFunc = js_util.getProperty(id, 'initialize');
    final promptFunc = js_util.getProperty(id, 'prompt');
    
    if (initializeFunc == null || promptFunc == null) {
      throw Exception('Google Identity Services methods not available');
    }

    // Track if we've received a response
    bool responseReceived = false;

    // Initialize with callback
    final initOptions = js_util.jsify({
      'client_id': clientId,
      'callback': allowInterop((dynamic response) {
        if (responseReceived) return;
        responseReceived = true;
        
        try {
          final token = js_util.getProperty(response, 'credential') as String?;
          
          if (token != null && token.isNotEmpty) {
            completer.complete(token);
          } else {
            completer.completeError('');
          }
        } catch (e) {
          completer.completeError(': $e');
        }
      }),
      'cancel_callback': allowInterop((dynamic response) {
        if (!completer.isCompleted && !responseReceived) {
          completer.completeError('');
        }
      }),
      'auto_select': false,
      'itp_support': true,
      'ux_mode': 'popup',
      'context': 'signin',
    });
    
    // Call initialize function
    (initializeFunc as Function)(initOptions);

    // Show the prompt
    try {
      (promptFunc as Function)();
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError('Google sign-in failed: $e');
      }
    }

    // Timeout after 60s if user cancels or closes
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.completeError('Google sign-in timed out or was cancelled');
        }
        return null;
      },
    );
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError('Failed to initialize Google sign-in: $e');
    }
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.completeError('Google sign-in timed out');
        }
        return null;
      },
    );
  }
}
