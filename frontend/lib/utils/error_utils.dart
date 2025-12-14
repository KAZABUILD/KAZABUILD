/// Utility functions for handling and displaying user-friendly error messages
library;

import 'package:dio/dio.dart';

/// Converts technical error messages to user-friendly messages
/// 
/// This function hides technical details and provides simplified,
/// user-readable error messages. It handles DioException specifically
/// for better connection error detection.
String getUserFriendlyError(dynamic error) {
  if (error == null) {
    return 'An unexpected error occurred. Please try again.';
  }

  // Handle DioException specifically for connection errors
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The internal servers are experiencing issues. Please try to reconnect later.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return 'You do not have permission to perform this action.';
        } else if (statusCode == 404) {
          return 'The requested item could not be found.';
        } else if (statusCode == 400) {
          return 'Invalid request. Please check your input and try again.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'The server encountered an error. Please try again later.';
        }
        return 'An error occurred. Please try again.';
      
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        // Check if it's a connection-related error
        final errorMessage = error.message?.toLowerCase() ?? '';
        if (errorMessage.contains('socketexception') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('network') ||
            errorMessage.contains('failed host lookup') ||
            errorMessage.contains('no internet') ||
            errorMessage.contains('network is unreachable')) {
          return 'The internal servers are experiencing issues. Please try to reconnect later.';
        }
        return 'An error occurred. Please try again.';
      
      default:
        return 'An error occurred. Please try again.';
    }
  }

  final errorString = error.toString().toLowerCase();

  // Network/Connection errors
  if (errorString.contains('socketexception') ||
      errorString.contains('connection') ||
      errorString.contains('network') ||
      errorString.contains('timeout') ||
      errorString.contains('failed host lookup') ||
      errorString.contains('no internet') ||
      errorString.contains('network is unreachable')) {
    return 'The internal servers are experiencing issues. Please try to reconnect later.';
  }

  // Authentication errors
  if (errorString.contains('unauthorized') ||
      errorString.contains('401') ||
      errorString.contains('forbidden') ||
      errorString.contains('403')) {
    return 'You do not have permission to perform this action.';
  }

  // Not found errors
  if (errorString.contains('not found') ||
      errorString.contains('404')) {
    return 'The requested item could not be found.';
  }

  // Server errors
  if (errorString.contains('500') ||
      errorString.contains('502') ||
      errorString.contains('503') ||
      errorString.contains('internal server error')) {
    return 'The server encountered an error. Please try again later.';
  }

  // Validation errors
  if (errorString.contains('validation') ||
      errorString.contains('invalid') ||
      errorString.contains('required')) {
    return 'Please check your input and try again.';
  }

  // Bad request errors
  if (errorString.contains('400') ||
      errorString.contains('bad request')) {
    return 'Invalid request. Please check your input and try again.';
  }

  // Generic error - don't show technical details
  return 'An error occurred. Please try again.';
}

/// Gets a simplified error message for specific operations
String getOperationError(String operation) {
  return 'Failed to $operation. Please try again.';
}

