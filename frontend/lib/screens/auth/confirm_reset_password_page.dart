/// This file defines the UI for the "Confirm Reset Password" screen.
///
/// This page is accessed via a link sent to the user's email. It allows
/// the user to enter and confirm a new password. The page extracts the
/// reset token from the URL query parameters to authorize the change.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';
import 'dart:html' as html;
import 'dart:async';
import 'package:frontend/utils/error_utils.dart';

/// A widget that allows a user to set a new password.
///
/// It requires a `token` from the password reset email to function.
class ConfirmResetPasswordPage extends ConsumerStatefulWidget {
  /// The password reset token from the URL.
  final String? token;
  /// The user ID from the URL (optional).
  final String? userId;

  const ConfirmResetPasswordPage({super.key, this.token, this.userId});

  @override
  ConsumerState<ConfirmResetPasswordPage> createState() =>
      _ConfirmResetPasswordPageState();
}

class _ConfirmResetPasswordPageState
    extends ConsumerState<ConfirmResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _savedToken; // Store token before URL is cleaned
  String? _savedUserId; // Store userId before URL is cleaned

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Save token and userId from URL BEFORE cleaning it
    // Email URL format: ?token=xxx&userId=yyy
    _savedToken = widget.token;
    _savedUserId = widget.userId;
    debugPrint('🔑 Token from widget: $_savedToken');
    debugPrint('🔑 UserId from widget: $_savedUserId');
    
    if (_savedToken == null || _savedToken!.isEmpty) {
      try {
        // Get token from current URL (before cleaning)
        final currentHref = html.window.location.href;
        
        // Check main URL first (before hash)
        final mainPart = currentHref.split('#').first;
        
        // Use Uri.parse but get raw query string to preserve token encoding
        try {
          final uri = Uri.parse(mainPart);
          // Get token from query parameters (Uri automatically decodes, but we need raw)
          _savedToken = uri.queryParameters['token'];
          _savedUserId = uri.queryParameters['userId'];
          
          // If token has spaces, it means + was decoded to space - restore it
          if (_savedToken != null && _savedToken!.contains(' ')) {
            _savedToken = _savedToken!.replaceAll(' ', '+');
          }
        } catch (e) {
          // Fallback to manual parsing
          if (mainPart.contains('token=')) {
            final tokenStart = mainPart.indexOf('token=') + 6;
            var tokenEnd = mainPart.indexOf('&', tokenStart);
            if (tokenEnd == -1) tokenEnd = mainPart.length;
            _savedToken = mainPart.substring(tokenStart, tokenEnd);
          }
          
          if (mainPart.contains('userId=')) {
            final userIdStart = mainPart.indexOf('userId=') + 7;
            var userIdEnd = mainPart.indexOf('&', userIdStart);
            if (userIdEnd == -1) userIdEnd = mainPart.length;
            _savedUserId = mainPart.substring(userIdStart, userIdEnd);
          }
        }
        
        // If not found in main URL, check hash fragment
        if ((_savedToken == null || _savedToken!.isEmpty) && currentHref.contains('#')) {
          final hashPart = currentHref.split('#').last;
          
          try {
            final hashUri = Uri.parse('https://example.com?$hashPart');
            _savedToken = hashUri.queryParameters['token'];
            _savedUserId = hashUri.queryParameters['userId'];
            
            if (_savedToken != null && _savedToken!.contains(' ')) {
              _savedToken = _savedToken!.replaceAll(' ', '+');
            }
          } catch (e) {
            // Fallback to manual parsing
            if (hashPart.contains('token=')) {
              final tokenStart = hashPart.indexOf('token=') + 6;
              var tokenEnd = hashPart.indexOf('&', tokenStart);
              if (tokenEnd == -1) tokenEnd = hashPart.length;
              _savedToken = hashPart.substring(tokenStart, tokenEnd);
            }
            
            if (hashPart.contains('userId=')) {
              final userIdStart = hashPart.indexOf('userId=') + 7;
              var userIdEnd = hashPart.indexOf('&', userIdStart);
              if (userIdEnd == -1) userIdEnd = hashPart.length;
              _savedUserId = hashPart.substring(userIdStart, userIdEnd);
            }
          }
        }
      } catch (e) {
        // Fallback to Uri.parse if manual parsing fails
        try {
          final currentHref = html.window.location.href;
          final mainPart = currentHref.split('#').first;
          final mainUri = Uri.parse(mainPart);
          _savedToken = mainUri.queryParameters['token'];
          _savedUserId = mainUri.queryParameters['userId'];
        } catch (e2) {
          // Ignore
        }
      }
    }
    
    // ----------------------------------------------------------------------
    // CRITICAL FIX: Restore encoded '+' characters in token
    // URL decoding turns '+' into space ' '. We must revert this for the backend.
    // ----------------------------------------------------------------------
    if (_savedToken != null && _savedToken!.isNotEmpty) {
      // Replace spaces with + (URL decoding issue)
      if (_savedToken!.contains(' ')) {
        _savedToken = _savedToken!.replaceAll(' ', '+');
      }
    }
    // ----------------------------------------------------------------------
    
    debugPrint('🔑 Final saved token: $_savedToken');
    debugPrint('🔑 Final saved userId: $_savedUserId');
    
    // Wait a bit before cleaning URL to ensure token is saved
    Future.microtask(() async {
      // Small delay to let router settle
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Clean URL hash
      _cleanAndRebuildUrlImmediately();
    });
    
    // Small delay to ensure router has finished redirecting
    Future.microtask(() {
      // Clean again after router finishes
      _cleanAndRebuildUrlImmediately();
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
        currentHref = currentHref.split('#').first;
        
        // Parse URL to get userId and token (from cleaned URL without hash)
        final uri = Uri.parse(currentHref);
        final userId = uri.queryParameters['userId'] ?? _savedUserId;
        final token = uri.queryParameters['token'] ?? _savedToken;
        
        // Update saved values if found in URL
        if (token != null && token.isNotEmpty) {
          _savedToken = token;
        }
        if (userId != null && userId.isNotEmpty) {
          _savedUserId = userId;
        }
        
        // Build new URL with userId and token (keep both, remove hash)
        String newUrl;
        if (userId != null && userId.isNotEmpty && token != null && token.isNotEmpty) {
          // Keep both token and userId
          newUrl = '${uri.scheme}://${uri.host}:${uri.port}${uri.path}?token=$token&userId=$userId';
        } else if (userId != null && userId.isNotEmpty) {
          // Only userId available
          newUrl = '${uri.scheme}://${uri.host}:${uri.port}${uri.path}?userId=$userId';
        } else if (token != null && token.isNotEmpty) {
          // Only token available
          newUrl = '${uri.scheme}://${uri.host}:${uri.port}${uri.path}?token=$token';
        } else {
          // Just remove hash, keep existing query params
          newUrl = currentHref;
        }
        
        // Update browser URL without hash
        html.window.history.replaceState(null, '', newUrl);
        debugPrint('🧹 Cleaned URL: $newUrl');
      }
    } catch (e) {
      // Not web platform or error occurred, ignore
      debugPrint('⚠️ Error cleaning URL (non-web or other): $e');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Set New Password',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please enter your new password below. Make sure it\'s secure.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (_savedUserId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Information:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User ID: $_savedUserId',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (_savedToken != null && _savedToken!.isNotEmpty)
                            Text(
                              'Token: ${_savedToken!.substring(0, _savedToken!.length > 8 ? 8 : _savedToken!.length)}...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'New Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm New Password',
                    icon: Icons.lock_person_outlined,
                    isPassword: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: _isLoading ? 'Resetting...' : 'Reset Password',
                    icon: null,
                    onPressed: _isLoading ? null : _resetPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the logic for confirming the password reset.
  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if we have a valid token - try to get it from current URL as fallback
    String? token = _savedToken;
    
    if (token == null || token.isEmpty) {
      // Try to get from widget
      token = widget.token;
    }
    
    if (token == null || token.isEmpty) {
      // Final fallback: try to get from current URL
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

    // If still no token, show error and redirect
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Invalid or missing reset token. The reset link may have expired or is invalid. Please request a new password reset link.',
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        // Redirect to forgot password page after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            GoRouter.of(context).go('/forgot-password');
          }
        });
      }
      return;
    }

    // ----------------------------------------------------------------------
    // CRITICAL FIX: Restore encoded '+' characters
    // URL decoding turns '+' into space ' '. We must revert this for the backend.
    // ----------------------------------------------------------------------
    if (token.contains(' ')) {
      token = token.replaceAll(' ', '+');
    }
    // ----------------------------------------------------------------------

    setState(() => _isLoading = true);

    try {
      debugPrint('✅ Sending token to backend for password reset...');
      final successMessage = await ref
          .read(authProvider.notifier)
          .confirmPasswordReset(token, _passwordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(successMessage)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate to login page and clear the navigation stack.
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          GoRouter.of(context).go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(getUserFriendlyError(e))),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
