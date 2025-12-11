import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:universal_html/html.dart' as html;

import 'dart:async';
import 'package:frontend/utils/error_utils.dart';

/// A widget that automatically confirms user registration.
///
/// It extracts the token from URL query parameters and sends it to the backend.
class ConfirmRegisterPage extends ConsumerStatefulWidget {
  /// The registration token from the URL.
  final String? token;
  /// The user ID from the URL (optional).
  final String? userId;

  const ConfirmRegisterPage({
    super.key,
    this.token,
    this.userId,
  });

  @override
  ConsumerState<ConfirmRegisterPage> createState() =>
      _ConfirmRegisterPageState();
}

class _ConfirmRegisterPageState
    extends ConsumerState<ConfirmRegisterPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _savedToken; // Store token before URL is cleaned

  @override
  void initState() {
    super.initState();

    // CRITICAL: Save token from URL BEFORE cleaning it
    // Email URL format: ?token=xxx&userId=yyy
    _savedToken = widget.token;
    debugPrint('🔑 Token from widget: $_savedToken');

    if (_savedToken == null || _savedToken!.isEmpty) {
      try {
        // Get token from current URL (before cleaning)
        final currentHref = html.window.location.href;
        debugPrint('🔑 Current URL: $currentHref');

        // Check main URL first (before hash)
        final mainPart = currentHref.split('#').first;
        final mainUri = Uri.parse(mainPart);
        _savedToken = mainUri.queryParameters['token'];
        debugPrint('🔑 Token from main URL: $_savedToken');

        // If not found in main URL, check hash fragment
        if ((_savedToken == null || _savedToken!.isEmpty) && currentHref.contains('#')) {
          final hashPart = currentHref.split('#').last;
          debugPrint('🔑 Hash part: $hashPart');

          // Check if hash contains query params like #/auth/confirm-register?token=xxx
          if (hashPart.contains('?')) {
            final hashUri = Uri.parse('?${hashPart.split('?').last}');
            _savedToken = hashUri.queryParameters['token'];
            debugPrint('🔑 Token from hash query: $_savedToken');
          }

          // Also try parsing the full hash as a path
          if ((_savedToken == null || _savedToken!.isEmpty)) {
            try {
              final hashUri = Uri.parse('https://example.com$hashPart');
              _savedToken = hashUri.queryParameters['token'];
              debugPrint('🔑 Token from hash URI: $_savedToken');
            } catch (e) {
              debugPrint('❌ Error parsing hash URI: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting token from URL: $e');
      }
    }

    debugPrint('🔑 Final saved token: $_savedToken');

    // Wait a bit before cleaning URL to ensure token is saved
    Future.microtask(() async {
      // Small delay to let router settle
      await Future.delayed(const Duration(milliseconds: 100));

      // Clean URL hash
      _cleanAndRebuildUrlImmediately();

      // Wait a bit more, then confirm
      await Future.delayed(const Duration(milliseconds: 200));

      // Automatically confirm registration when page loads
      if (mounted) {
        _confirmRegistration();
      }
    });

    // Also clean after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanAndRebuildUrlImmediately();
    });

    // CRITICAL: Continuously monitor and clean hash fragment
    // This prevents GoRouter or browser from re-adding hash
    _startHashMonitoring();
  }

  /// Continuously monitors and removes hash fragments
  void _startHashMonitoring() {
    // Check every 100ms for the first 3 seconds to catch any hash additions
    Timer? timer;
    int checks = 0;
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      checks++;
      if (mounted) {
        _cleanAndRebuildUrlImmediately();
      }
      // Stop after 3 seconds (30 checks)
      if (checks >= 30) {
        timer?.cancel();
        // Then check periodically every 500ms
        Timer.periodic(const Duration(milliseconds: 500), (t) {
          if (mounted) {
            if (html.window.location.href.contains('#')) {
              _cleanAndRebuildUrlImmediately();
            }
          } else {
            t.cancel();
          }
        });
      }
    });
  }

  /// Cleans the URL hash but keeps token and userId
  /// This is called multiple times to ensure hash is removed
  void _cleanAndRebuildUrlImmediately() {
    try {
      // Get current URL and remove hash immediately
      var currentHref = html.window.location.href;

      // CRITICAL: Check if hash exists and remove it
      if (currentHref.contains('#')) {
        // Remove hash fragment completely from URL
        final mainPart = currentHref.split('#').first;

        // Parse URL to get userId and token (from cleaned URL without hash)
        final uri = Uri.parse(mainPart);
        final userId = uri.queryParameters['userId'];
        final token = uri.queryParameters['token'];

        // Build new URL with userId and token (keep both, remove hash)
        String newUrl;
        if (userId != null && userId.isNotEmpty && token != null && token.isNotEmpty) {
          // Keep both token and userId
          newUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}?token=$token&userId=$userId';
        } else if (userId != null && userId.isNotEmpty) {
          // Only userId available
          newUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}?userId=$userId';
        } else if (token != null && token.isNotEmpty) {
          // Only token available
          newUrl = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}${uri.path}?token=$token';
        } else {
          // Just remove hash, keep existing query params
          newUrl = mainPart;
        }

        // Force update browser URL (this removes hash)
        html.window.history.replaceState(null, '', newUrl);

        // Also clear hash directly (double check)
        html.window.location.hash = '';
      } else {
        // No hash, but ensure hash is empty
        if (html.window.location.hash.isNotEmpty) {
          html.window.location.hash = '';
        }
      }
    } catch (e) {
      // Not web platform, ignore
      debugPrint('Error cleaning URL: $e');
    }
  }

  /// Handles the logic for confirming the registration.
  Future<void> _confirmRegistration() async {
    // Backend expects token (hash) for verification
    // Use saved token from initState (saved before URL was cleaned)
    String? token = _savedToken;
    debugPrint('🔑 Starting confirmation with saved token: ${token != null ? "***${token.substring(token.length > 10 ? token.length - 10 : 0)}" : "null"}');

    // Fallback: try widget token
    if (token == null || token.isEmpty) {
      token = widget.token;
      debugPrint('🔑 Using widget token: ${token != null ? "***${token.substring(token.length > 10 ? token.length - 10 : 0)}" : "null"}');
    }

    // Final fallback: try to get from current URL (might still be there)
    if (token == null || token.isEmpty) {
      try {
        final currentHref = html.window.location.href;
        debugPrint('🔑 Trying to get token from current URL: $currentHref');

        // Try main URL first
        final mainPart = currentHref.split('#').first;
        final mainUri = Uri.parse(mainPart);
        token = mainUri.queryParameters['token'];
        debugPrint('🔑 Token from current main URL: ${token != null ? "***${token.substring(token.length > 10 ? token.length - 10 : 0)}" : "null"}');

        // If still not found, try hash fragment
        if ((token == null || token.isEmpty) && currentHref.contains('#')) {
          final hashPart = currentHref.split('#').last;
          if (hashPart.contains('?')) {
            final hashUri = Uri.parse('?${hashPart.split('?').last}');
            token = hashUri.queryParameters['token'];
            debugPrint('🔑 Token from current hash: ${token != null ? "***${token.substring(token.length > 10 ? token.length - 10 : 0)}" : "null"}');
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting token from URL: $e');
      }
    }

    // If still no token, we can't proceed (backend requires token hash)
    if (token == null || token.isEmpty) {
      debugPrint('❌ No token found! Widget token: ${widget.token}, Saved token: $_savedToken');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid confirmation link. Token is missing. Please use the complete link from your email that includes the token.';
      });
      return;
    }

    // ----------------------------------------------------------------------
    // CRITICAL FIX: Restore encoded '+' characters
    // URL decoding turns '+' into space ' '. We must revert this for the backend.
    // ----------------------------------------------------------------------
    if (token.contains(' ')) {
      debugPrint('⚠️ Token contains spaces, replacing with +');
      token = token.replaceAll(' ', '+');
    }
    debugPrint('🔑 FIXED Token for Backend: $token');
    // ----------------------------------------------------------------------

    try {
      debugPrint('✅ Sending token to backend...');
      // Send token to backend (backend expects token field with hash)
      final result = await ref
          .read(authProvider.notifier)
          .confirmRegister(token); // Use the fixed token
      debugPrint('✅ Backend response: $result');

      if (mounted) {
        // Update state to show success
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        // Small delay to show success message, then navigate
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navigate to login page after successful confirmation
          // Use GoRouter to avoid hash routing issues
          try {
            debugPrint('🔵 Navigating to login page...');
            if (widget.userId != null && widget.userId!.isNotEmpty) {
              context.go('/login?userId=${widget.userId}');
            } else {
              context.go('/login');
            }
            debugPrint('✅ Navigation successful');
          } catch (e) {
            debugPrint('❌ GoRouter navigation error: $e');
            // Fallback: try window.location without hash
            try {
              final baseUrl = html.window.location.origin;
              final targetPath = widget.userId != null && widget.userId!.isNotEmpty
                  ? '/login?userId=${widget.userId}'
                  : '/login';
              final fullUrl = '$baseUrl$targetPath';

              debugPrint('🔵 Fallback: Navigating to: $fullUrl');
              html.window.location.href = fullUrl;
            } catch (e2) {
              debugPrint('❌ Window location navigation also failed: $e2');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error confirming registration: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = getUserFriendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading) ...[
                  // Loading state
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Confirming your registration...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ] else if (_isSuccess) ...[
                  // Success state - will auto-redirect
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Registration Confirmed!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account has been successfully confirmed! Redirecting to login...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ] else ...[
                  // Error state
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Registration Failed',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'An error occurred while confirming your registration. Please try again or contact support.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/signup'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
