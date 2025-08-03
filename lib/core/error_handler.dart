import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:seol_haru_check/constants/app_strings.dart';

/// Custom exception classes for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  AppException(this.message, {this.code, this.originalError, this.stackTrace, Map<String, dynamic>? context})
    : timestamp = DateTime.now(),
      context = context ?? {};

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}

class DataException extends AppException {
  DataException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}

class ServiceUnavailableException extends AppException {
  ServiceUnavailableException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}

/// Error handler utility class
class ErrorHandler {
  static const String _logTag = 'ErrorHandler';

  /// Handle and convert various error types to user-friendly messages
  static AppException handleError(
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userAction,
  }) {
    // Add user action to context if provided
    final errorContext = Map<String, dynamic>.from(context ?? {});
    if (userAction != null) {
      errorContext['userAction'] = userAction;
    }

    // Log the error for debugging
    _logError(error, stackTrace, errorContext);

    // Handle specific error types
    if (error is AppException) {
      return error;
    }

    if (error is FirebaseException) {
      return _handleFirebaseError(error, stackTrace, errorContext);
    }

    if (error is FirebaseAuthException) {
      return _handleAuthError(error, stackTrace, errorContext);
    }

    if (error is SocketException) {
      return NetworkException(
        AppStrings.connectionError,
        code: 'network_error',
        originalError: error,
        stackTrace: stackTrace,
        context: errorContext,
      );
    }

    if (error is HttpException) {
      return _handleHttpError(error, stackTrace, errorContext);
    }

    if (error is FormatException) {
      return DataException(
        AppStrings.dataCorruptedError,
        code: 'format_error',
        originalError: error,
        stackTrace: stackTrace,
        context: errorContext,
      );
    }

    if (error is TimeoutException) {
      return NetworkException(
        AppStrings.timeoutError,
        code: 'timeout_error',
        originalError: error,
        stackTrace: stackTrace,
        context: errorContext,
      );
    }

    // Handle string errors
    if (error is String) {
      return AppException(
        error.isNotEmpty ? error : AppStrings.unexpectedError,
        code: 'string_error',
        originalError: error,
        stackTrace: stackTrace,
        context: errorContext,
      );
    }

    // Default case for unknown errors
    return AppException(
      AppStrings.unexpectedError,
      code: 'unknown_error',
      originalError: error,
      stackTrace: stackTrace,
      context: errorContext,
    );
  }

  /// Handle Firebase-specific errors
  static AppException _handleFirebaseError(
    FirebaseException error,
    StackTrace? stackTrace,
    Map<String, dynamic> context,
  ) {
    String message;
    String code = error.code;

    switch (error.code) {
      case 'permission-denied':
        message = AppStrings.permissionError;
        break;
      case 'unavailable':
        message = AppStrings.serviceUnavailable;
        break;
      case 'deadline-exceeded':
        message = AppStrings.timeoutError;
        break;
      case 'resource-exhausted':
        message = AppStrings.quotaExceededError;
        break;
      case 'failed-precondition':
        message = AppStrings.dataValidationError;
        break;
      case 'aborted':
        message = AppStrings.serverError;
        break;
      case 'out-of-range':
        message = AppStrings.dataValidationError;
        break;
      case 'unimplemented':
        message = AppStrings.serviceUnavailable;
        break;
      case 'internal':
        message = AppStrings.serverError;
        break;
      case 'data-loss':
        message = AppStrings.dataCorruptedError;
        break;
      case 'unauthenticated':
        return AuthException(
          AppStrings.loginRequired,
          code: code,
          originalError: error,
          stackTrace: stackTrace,
          context: context,
        );
      default:
        message = error.message ?? AppStrings.errorLoadingData;
    }

    return DataException(message, code: code, originalError: error, stackTrace: stackTrace, context: context);
  }

  /// Handle Firebase Auth-specific errors
  static AuthException _handleAuthError(
    FirebaseAuthException error,
    StackTrace? stackTrace,
    Map<String, dynamic> context,
  ) {
    String message;
    String code = error.code;

    switch (error.code) {
      case 'user-not-found':
        message = '사용자를 찾을 수 없습니다.';
        break;
      case 'wrong-password':
        message = AppStrings.passwordIncorrect;
        break;
      case 'user-disabled':
        message = '계정이 비활성화되었습니다.';
        break;
      case 'too-many-requests':
        message = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
        break;
      case 'operation-not-allowed':
        message = '허용되지 않은 작업입니다.';
        break;
      case 'invalid-email':
        message = '올바르지 않은 이메일 형식입니다.';
        break;
      case 'email-already-in-use':
        message = '이미 사용 중인 이메일입니다.';
        break;
      case 'weak-password':
        message = '비밀번호가 너무 약합니다.';
        break;
      case 'network-request-failed':
        message = AppStrings.connectionError;
        break;
      default:
        message = error.message ?? AppStrings.authError;
    }

    return AuthException(message, code: code, originalError: error, stackTrace: stackTrace, context: context);
  }

  /// Handle HTTP-specific errors
  static NetworkException _handleHttpError(HttpException error, StackTrace? stackTrace, Map<String, dynamic> context) {
    String message;
    String code = 'http_error';

    if (error.message.contains('404')) {
      message = '요청한 데이터를 찾을 수 없습니다.';
      code = 'not_found';
    } else if (error.message.contains('500')) {
      message = AppStrings.serverError;
      code = 'server_error';
    } else if (error.message.contains('503')) {
      message = AppStrings.serviceUnavailable;
      code = 'service_unavailable';
    } else {
      message = AppStrings.networkError;
    }

    return NetworkException(message, code: code, originalError: error, stackTrace: stackTrace, context: context);
  }

  /// Log error for debugging purposes
  static void _logError(dynamic error, StackTrace? stackTrace, Map<String, dynamic> context) {
    final errorInfo = {
      'error': error.toString(),
      'type': error.runtimeType.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
    };

    if (kDebugMode) {
      log('Error occurred: ${error.toString()}', name: _logTag, error: error, stackTrace: stackTrace);
      log('Error context: $errorInfo', name: _logTag);
    }

    // In production, you might want to send this to a crash reporting service
    // like Firebase Crashlytics or Sentry
    if (kReleaseMode) {
      _reportErrorToService(error, stackTrace, errorInfo);
    }
  }

  /// Report error to external service (placeholder for crash reporting)
  static void _reportErrorToService(dynamic error, StackTrace? stackTrace, Map<String, dynamic> errorInfo) {
    // TODO: Implement crash reporting service integration
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    // Example: Sentry.captureException(error, stackTrace: stackTrace);

    // For now, just log to console in release mode
    log('Error reported: $errorInfo', name: _logTag);
  }

  /// Check if error is network-related
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.message?.contains('network') == true;
    }
    return false;
  }

  /// Check if error is authentication-related
  static bool isAuthError(dynamic error) {
    if (error is AuthException) return true;
    if (error is FirebaseAuthException) return true;
    if (error is FirebaseException && error.code == 'unauthenticated') return true;
    return false;
  }

  /// Check if error is retryable
  static bool isRetryableError(dynamic error) {
    if (isNetworkError(error)) return true;

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'resource-exhausted':
        case 'aborted':
        case 'internal':
          return true;
        default:
          return false;
      }
    }

    return false;
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }

    final handledException = handleError(error);
    return handledException.message;
  }

  /// Create error report for user feedback
  static Map<String, dynamic> createErrorReport(AppException error) {
    return {
      'message': error.message,
      'code': error.code,
      'timestamp': error.timestamp.toIso8601String(),
      'context': error.context,
      'stackTrace': error.stackTrace?.toString(),
      'originalError': error.originalError?.toString(),
    };
  }
}

/// Timeout exception class
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.originalError, super.stackTrace, super.context});
}
