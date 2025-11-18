/// Utility functions for handling and displaying user-friendly error messages
library;

/// Converts technical error messages to user-friendly messages
/// 
/// This function hides technical details and provides simplified,
/// user-readable error messages.
String getUserFriendlyError(dynamic error) {
  if (error == null) {
    return 'An unexpected error occurred. Please try again.';
  }

  final errorString = error.toString().toLowerCase();

  // Network/Connection errors
  if (errorString.contains('socketexception') ||
      errorString.contains('connection') ||
      errorString.contains('network') ||
      errorString.contains('timeout') ||
      errorString.contains('failed host lookup')) {
    return 'Unable to connect to the server. Please check your internet connection and try again.';
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

