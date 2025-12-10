/// Centralized error handling utility for the application.
///
/// This file provides functions to parse backend error responses and convert
/// them into user-friendly messages that non-technical users can understand.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/utils/logger_service.dart';

/// Error severity levels for categorization
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error categories for better error handling
enum ErrorCategory {
  network,
  authentication,
  authorization,
  validation,
  server,
  unknown,
}

/// A class that represents a standardized application error.
class AppError {
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final String? errorCode;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final bool isRetryable;
  final String? context;
  final String? action;
  final DateTime timestamp;
  final List<String> suggestions;

  AppError({
    required this.message,
    this.technicalDetails,
    this.statusCode,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.category = ErrorCategory.unknown,
    this.isRetryable = false,
    this.context,
    this.action,
    DateTime? timestamp,
    this.suggestions = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an AppError with current timestamp
  factory AppError.create({
    required String message,
    String? technicalDetails,
    int? statusCode,
    String? errorCode,
    ErrorSeverity severity = ErrorSeverity.error,
    ErrorCategory category = ErrorCategory.unknown,
    bool isRetryable = false,
    String? context,
    String? action,
    List<String> suggestions = const [],
  }) {
    return AppError(
      message: message,
      technicalDetails: technicalDetails,
      statusCode: statusCode,
      errorCode: errorCode,
      severity: severity,
      category: category,
      isRetryable: isRetryable,
      context: context,
      action: action,
      timestamp: DateTime.now(),
      suggestions: suggestions,
    );
  }

  bool get isCritical => severity == ErrorSeverity.critical;
  bool get canRetry => isRetryable;

  /// Converts error to analytics map for reporting
  Map<String, dynamic> toAnalyticsMap() {
    return {
      'message': message,
      'errorCode': errorCode,
      'statusCode': statusCode,
      'severity': severity.name,
      'category': category.name,
      'context': context,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'isRetryable': isRetryable,
    };
  }

  @override
  String toString() => message;
}

/// Main error handler that converts various error types into user-friendly messages.
class ErrorHandler {
  /// Gets appropriate error message for localhost environment
  static String _getConnectionErrorMessage() {
    return 'Backend server is not responding. Please check if the server is running on localhost.';
  }

  static String _getTimeoutErrorMessage() {
    return 'Backend server is taking too long to respond. Please check if the server is running and accessible.';
  }

  /// Handles DioException (network errors) and returns an AppError.
  static AppError handleDioError(
    DioException error, {
    String? context,
    String? action,
  }) {
    AppError appError;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        appError = AppError.create(
          message: _getTimeoutErrorMessage(),
          technicalDetails: 'Network timeout error: ${error.type}',
          severity: ErrorSeverity.warning,
          category: ErrorCategory.network,
          isRetryable: true,
          context: context,
          action: action,
          suggestions: [
            'Verify the backend server is running',
            'Check if the server port is correct',
            'Try restarting the backend server',
          ],
        );
        break;

      case DioExceptionType.badResponse:
        appError = _handleBadResponse(error, context: context, action: action);
        break;

      case DioExceptionType.cancel:
        appError = AppError.create(
          message: 'Request was cancelled.',
          technicalDetails: 'Request cancelled',
          severity: ErrorSeverity.info,
          category: ErrorCategory.network,
          context: context,
          action: action,
        );
        break;

      case DioExceptionType.connectionError:
        appError = AppError.create(
          message: _getConnectionErrorMessage(),
          technicalDetails: 'Connection error: ${error.message}',
          severity: ErrorSeverity.error,
          category: ErrorCategory.network,
          isRetryable: true,
          context: context,
          action: action,
          suggestions: [
            'Ensure the backend server is running',
            'Check the API URL configuration',
            'Verify the server is accessible',
          ],
        );
        break;

      case DioExceptionType.badCertificate:
        appError = AppError.create(
          message: 'Security certificate error. Please contact support.',
          technicalDetails: 'SSL certificate error',
          severity: ErrorSeverity.error,
          category: ErrorCategory.network,
          context: context,
          action: action,
        );
        break;

      default:
        appError = AppError.create(
          message: 'An unexpected error occurred. Please try again later.',
          technicalDetails: error.message ?? 'Unknown error',
          severity: ErrorSeverity.error,
          category: ErrorCategory.unknown,
          context: context,
          action: action,
        );
    }

    // Log the error
    LoggerService.error(
      'API Error: ${appError.message}',
      error,
      StackTrace.current,
    );

    return appError;
  }

  /// Handles bad HTTP responses (4xx, 5xx status codes).
  static AppError _handleBadResponse(
    DioException error, {
    String? context,
    String? action,
  }) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Try to extract error message from backend response
    String? backendMessage;
    String? errorCode;
    Map<String, dynamic>? validationErrors;

    if (responseData is Map<String, dynamic>) {
      backendMessage = responseData['message'] as String?;
      errorCode = responseData['code'] as String?;
      
      // Check for validation errors
      if (responseData.containsKey('errors')) {
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          validationErrors = errors;
        }
      }
      
      // Handle specific error codes from backend
      if (errorCode == 'UNVERIFIED') {
        return AppError.create(
          message: 'Your account is not verified. Please check your email for the verification link.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
          severity: ErrorSeverity.warning,
          category: ErrorCategory.authentication,
          context: context,
          action: action,
          suggestions: [
            'Check your email inbox',
            'Check spam folder',
            'Request a new verification email',
          ],
        );
      }

      if (errorCode == 'EMAIL_EXISTS') {
        return AppError.create(
          message: 'This email is already registered. Please use a different email or try logging in.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
          severity: ErrorSeverity.warning,
          category: ErrorCategory.validation,
          context: context,
          action: action,
        );
      }

      if (errorCode == 'USERNAME_TAKEN') {
        return AppError.create(
          message: 'This username is already taken. Please choose a different username.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
          severity: ErrorSeverity.warning,
          category: ErrorCategory.validation,
          context: context,
          action: action,
        );
      }

      if (errorCode == 'INVALID_TOKEN' || errorCode == 'TOKEN_EXPIRED') {
        return AppError.create(
          message: 'Your session has expired. Please log in again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
          severity: ErrorSeverity.warning,
          category: ErrorCategory.authentication,
          isRetryable: true,
          context: context,
          action: action,
        );
      }

      if (errorCode == 'RATE_LIMIT_EXCEEDED') {
        final retryAfter = error.response?.headers.value('Retry-After');
        return AppError.create(
          message: retryAfter != null
              ? 'Too many requests. Please wait $retryAfter seconds before trying again.'
              : 'Too many requests. Please wait a moment and try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
          severity: ErrorSeverity.warning,
          category: ErrorCategory.server,
          isRetryable: true,
          context: context,
          action: action,
        );
      }
    }

    // Handle validation errors
    if (validationErrors != null && validationErrors.isNotEmpty) {
      final firstError = validationErrors.values.first;
      String validationMessage;
      if (firstError is List && firstError.isNotEmpty) {
        validationMessage = firstError.first.toString();
      } else if (firstError is String) {
        validationMessage = firstError;
      } else {
        validationMessage = backendMessage ?? 'Validation error. Please check your input.';
      }

      return AppError.create(
        message: validationMessage,
        statusCode: statusCode,
        errorCode: errorCode ?? 'VALIDATION_ERROR',
        technicalDetails: validationErrors.toString(),
        severity: ErrorSeverity.warning,
        category: ErrorCategory.validation,
        context: context,
        action: action,
        suggestions: ['Check all required fields', 'Verify input format'],
      );
    }

    // Handle status codes
    switch (statusCode) {
      case 400:
        return AppError.create(
          message: backendMessage ?? 'Invalid request. Please check your input and try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.validation,
          context: context,
          action: action,
        );

      case 401:
        return AppError.create(
          message: backendMessage ?? 'Invalid credentials. Please check your email/username and password.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.authentication,
          isRetryable: true,
          context: context,
          action: action,
          suggestions: ['Check your email/username', 'Verify your password', 'Try resetting your password'],
        );

      case 403:
        return AppError.create(
          message: backendMessage ?? 'You do not have permission to perform this action.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.error,
          category: ErrorCategory.authorization,
          context: context,
          action: action,
        );

      case 404:
        return AppError.create(
          message: backendMessage ?? 'The requested resource was not found.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.server,
          context: context,
          action: action,
        );

      case 409:
        return AppError.create(
          message: backendMessage ?? 'This information is already in use. Please try different values.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.validation,
          context: context,
          action: action,
        );

      case 429:
        final retryAfter = error.response?.headers.value('Retry-After');
        return AppError.create(
          message: retryAfter != null
              ? 'Too many requests. Please wait $retryAfter seconds before trying again.'
              : 'Too many requests. Please wait a moment and try again.',
          statusCode: statusCode,
          errorCode: errorCode ?? 'RATE_LIMIT',
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.server,
          isRetryable: true,
          context: context,
          action: action,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError.create(
          message: backendMessage ?? 'Backend server error. Please check the server logs and ensure all services are running correctly.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.critical,
          category: ErrorCategory.server,
          isRetryable: true,
          context: context,
          action: action,
          suggestions: [
            'Check backend server logs',
            'Verify database connection',
            'Restart the backend server',
          ],
        );

      default:
        return AppError.create(
          message: backendMessage ?? 'An error occurred. Please try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
          severity: ErrorSeverity.error,
          category: _categorizeError(statusCode),
          context: context,
          action: action,
        );
    }
  }

  /// Categorizes error based on status code
  static ErrorCategory _categorizeError(int? statusCode) {
    if (statusCode == null) return ErrorCategory.unknown;
    if (statusCode >= 500) return ErrorCategory.server;
    if (statusCode == 401) return ErrorCategory.authentication;
    if (statusCode == 403) return ErrorCategory.authorization;
    if (statusCode == 400 || statusCode == 422) return ErrorCategory.validation;
    return ErrorCategory.unknown;
  }

  /// Handles generic exceptions.
  static AppError handleGenericError(
    Object error, {
    String? context,
    String? action,
  }) {
    if (error is DioException) {
      return handleDioError(error, context: context, action: action);
    }

    final appError = AppError.create(
      message: 'An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
      severity: ErrorSeverity.error,
      category: ErrorCategory.unknown,
      context: context,
      action: action,
    );

    // Log the error
    LoggerService.error(
      'Generic Error: ${appError.message}',
      error,
      StackTrace.current,
    );

    return appError;
  }

  /// Checks if error is a network-related error
  static bool isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.connectionError ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.sendTimeout;
  }

  /// Parses validation errors from response
  static AppError? parseValidationErrors(
    Map<String, dynamic> responseData, {
    String? context,
    String? action,
  }) {
    if (responseData.containsKey('errors')) {
      final errors = responseData['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        String validationMessage;
        if (firstError is List && firstError.isNotEmpty) {
          validationMessage = firstError.first.toString();
        } else if (firstError is String) {
          validationMessage = firstError;
        } else {
          validationMessage = 'Validation error. Please check your input.';
        }

        return AppError.create(
          message: validationMessage,
          errorCode: 'VALIDATION_ERROR',
          technicalDetails: errors.toString(),
          severity: ErrorSeverity.warning,
          category: ErrorCategory.validation,
          context: context,
          action: action,
          suggestions: ['Check all required fields', 'Verify input format'],
        );
      }
    }
    return null;
  }
}

/// Extension methods for displaying errors to users.
extension ErrorDisplay on AppError {
  /// Shows this error as a SnackBar in the given context.
  void showAsSnackBar(BuildContext context, {VoidCallback? onRetry}) {
    final backgroundColor = _getErrorColor();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...suggestions.take(2).map((suggestion) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '• $suggestion',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
            ],
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isCritical ? 6 : 4),
        action: _buildSnackBarAction(context, onRetry: onRetry),
      ),
    );
  }

  /// Shows this error as a dialog in the given context.
  void showAsDialog(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getErrorIcon(),
              color: _getErrorColor(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getErrorTitle(),
                style: TextStyle(color: _getErrorColor()),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Suggestions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $suggestion'),
                    )),
              ],
              if (technicalDetails != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Technical Details'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(
                        technicalDetails!,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (canRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Gets appropriate error color based on severity
  Color _getErrorColor() {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue.shade700;
      case ErrorSeverity.warning:
        return Colors.orange.shade700;
      case ErrorSeverity.error:
        return Colors.red.shade700;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  /// Gets appropriate error icon based on severity
  IconData _getErrorIcon() {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_outlined;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.error;
    }
  }

  /// Gets appropriate error title based on severity
  String _getErrorTitle() {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  /// Builds SnackBar action widget
  SnackBarAction? _buildSnackBarAction(BuildContext context, {VoidCallback? onRetry}) {
    if (canRetry && onRetry != null) {
      return SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      );
    }
    
    if (technicalDetails != null) {
      return SnackBarAction(
        label: 'Details',
        textColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error Details'),
              content: SingleChildScrollView(
                child: SelectableText(
                  technicalDetails!,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      );
    }
    
    return null;
  }
}