/// Centralized error handling utility for the application.
///
/// This file provides functions to parse backend error responses and convert
/// them into user-friendly messages that non-technical users can understand.
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A class that represents a standardized application error.
class AppError {
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final String? errorCode;

  const AppError({
    required this.message,
    this.technicalDetails,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;
}

/// Main error handler that converts various error types into user-friendly messages.
class ErrorHandler {
  /// Handles DioException (network errors) and returns an AppError.
  static AppError handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppError(
          message: 'Connection timeout. Please check your internet connection and try again.',
          technicalDetails: 'Network timeout error',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return const AppError(
          message: 'Request was cancelled. Please try again.',
          technicalDetails: 'Request cancelled',
        );

      case DioExceptionType.connectionError:
        return const AppError(
          message: 'Unable to connect to the server. Please check your internet connection.',
          technicalDetails: 'Connection error',
        );

      case DioExceptionType.badCertificate:
        return const AppError(
          message: 'Security certificate error. Please contact support.',
          technicalDetails: 'SSL certificate error',
        );

      default:
        return AppError(
          message: 'An unexpected error occurred. Please try again later.',
          technicalDetails: error.message ?? 'Unknown error',
        );
    }
  }

  /// Handles bad HTTP responses (4xx, 5xx status codes).
  static AppError _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Try to extract error message from backend response
    String? backendMessage;
    String? errorCode;

    if (responseData is Map<String, dynamic>) {
      backendMessage = responseData['message'] as String?;
      errorCode = responseData['code'] as String?;
      
      // Handle specific error codes from backend
      if (errorCode == 'UNVERIFIED') {
        return AppError(
          message: 'Your account is not verified. Please check your email for the verification link.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: backendMessage,
        );
      }
    }

    switch (statusCode) {
      case 400:
        return AppError(
          message: backendMessage ?? 'Invalid request. Please check your input and try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 401:
        return AppError(
          message: backendMessage ?? 'Invalid credentials. Please check your email/username and password.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 403:
        return AppError(
          message: backendMessage ?? 'You do not have permission to perform this action.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 404:
        return AppError(
          message: backendMessage ?? 'The requested resource was not found.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 409:
        return AppError(
          message: backendMessage ?? 'This information is already in use. Please try different values.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 429:
        return AppError(
          message: 'Too many requests. Please wait a moment and try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          message: 'Server error. Our team has been notified. Please try again later.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );

      default:
        return AppError(
          message: backendMessage ?? 'An error occurred. Please try again.',
          statusCode: statusCode,
          errorCode: errorCode,
          technicalDetails: responseData.toString(),
        );
    }
  }

  /// Handles generic exceptions.
  static AppError handleGenericError(Object error) {
    if (error is DioException) {
      return handleDioError(error);
    }

    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
    );
  }
}

/// Extension methods for displaying errors to users.
extension ErrorDisplay on AppError {
  /// Shows this error as a SnackBar in the given context.
  void showAsSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        action: technicalDetails != null
            ? SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error Details'),
                      content: SingleChildScrollView(
                        child: Text(technicalDetails!),
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
              )
            : null,
      ),
    );
  }
}