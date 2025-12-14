/// Input validation utilities that match backend validation rules.
///
/// These validators ensure that user input meets the requirements
/// defined in the backend DTOs before submission.
library;

class Validators {
  /// Validates email format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates username/login (min 8 chars, max 50 chars).
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    if (value.length < 8) {
      return 'Username must be at least 8 characters long';
    }

    if (value.length > 50) {
      return 'Username cannot be longer than 50 characters';
    }

    return null;
  }

  /// Validates display name (min 8 chars, max 50 chars).
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required';
    }

    if (value.length < 8) {
      return 'Display name must be at least 8 characters long';
    }

    if (value.length > 50) {
      return 'Display name cannot be longer than 50 characters';
    }

    return null;
  }

  /// Validates password (min 8 chars).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    return null;
  }

  /// Validates phone number format.
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone number is optional
    }

    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validates description (max 1000 chars).
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }

    if (value.length > 1000) {
      return 'Description cannot be longer than 1000 characters';
    }

    return null;
  }

  /// Validates that a field is not empty.
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates minimum length.
  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < min) {
      return '$fieldName must be at least $min characters long';
    }

    return null;
  }

  /// Validates maximum length.
  static String? maxLength(String? value, int max, String fieldName) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > max) {
      return '$fieldName cannot be longer than $max characters';
    }

    return null;
  }

  /// Validates password confirmation match.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
