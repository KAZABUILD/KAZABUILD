/// Logging service for tracking errors and user actions.
///
/// This service provides structured logging that can help with
/// debugging and monitoring application behavior.
library;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
  );

  /// Logs an informational message.
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      _logger.i(message, error: data);
    }
  }

  /// Logs a warning message.
  static void warning(String message, [dynamic data]) {
    if (kDebugMode) {
      _logger.w(message, error: data);
    }
  }

  /// Logs an error with optional stack trace.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a debug message (only in debug mode).
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      _logger.d(message, error: data);
    }
  }

  /// Logs user authentication actions.
  static void logAuth(String action, {String? userId, bool success = true}) {
    info('Auth Action: $action', {
      'userId': userId,
      'success': success,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Logs API calls.
  static void logApiCall(String endpoint, String method, {int? statusCode, dynamic error}) {
    if (error != null) {
      warning('API Call Failed: $method $endpoint', {
        'statusCode': statusCode,
        'error': error.toString(),
      });
    } else {
      debug('API Call: $method $endpoint', {'statusCode': statusCode});
    }
  }
}