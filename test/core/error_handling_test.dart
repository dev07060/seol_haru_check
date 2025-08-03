import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/core/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('handleError', () {
      test('should handle FirebaseException correctly', () {
        // Arrange
        final firebaseError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        );

        // Act
        final result = ErrorHandler.handleError(firebaseError);

        // Assert
        expect(result, isA<DataException>());
        expect(result.message, AppStrings.permissionError);
        expect(result.code, 'permission-denied');
        expect(result.originalError, firebaseError);
      });

      test('should handle FirebaseAuthException correctly', () {
        // Arrange
        final authError = FirebaseAuthException(code: 'user-not-found', message: 'User not found');

        // Act
        final result = ErrorHandler.handleError(authError);

        // Assert
        expect(result, isA<DataException>());
        expect(result.message, 'User not found');
        expect(result.code, 'user-not-found');
        expect(result.originalError, authError);
      });

      test('should handle SocketException correctly', () {
        // Arrange
        final socketError = const SocketException('Network unreachable');

        // Act
        final result = ErrorHandler.handleError(socketError);

        // Assert
        expect(result, isA<NetworkException>());
        expect(result.message, AppStrings.connectionError);
        expect(result.code, 'network_error');
        expect(result.originalError, socketError);
      });

      test('should handle HttpException correctly', () {
        // Arrange
        final httpError = const HttpException('404 Not Found');

        // Act
        final result = ErrorHandler.handleError(httpError);

        // Assert
        expect(result, isA<NetworkException>());
        expect(result.message, '요청한 데이터를 찾을 수 없습니다.');
        expect(result.code, 'not_found');
        expect(result.originalError, httpError);
      });

      test('should handle FormatException correctly', () {
        // Arrange
        final formatError = const FormatException('Invalid format');

        // Act
        final result = ErrorHandler.handleError(formatError);

        // Assert
        expect(result, isA<DataException>());
        expect(result.message, AppStrings.dataCorruptedError);
        expect(result.code, 'format_error');
        expect(result.originalError, formatError);
      });

      test('should handle TimeoutException correctly', () {
        // Arrange
        final timeoutError = TimeoutException('Request timeout');

        // Act
        final result = ErrorHandler.handleError(timeoutError);

        // Assert
        expect(result, isA<AppException>());
        expect(result.message, 'Request timeout');
        expect(result.code, isNull);
        expect(result.originalError, timeoutError);
      });

      test('should handle string errors correctly', () {
        // Arrange
        const stringError = 'Custom error message';

        // Act
        final result = ErrorHandler.handleError(stringError);

        // Assert
        expect(result, isA<AppException>());
        expect(result.message, 'Custom error message');
        expect(result.code, 'string_error');
        expect(result.originalError, stringError);
      });

      test('should handle empty string errors correctly', () {
        // Arrange
        const stringError = '';

        // Act
        final result = ErrorHandler.handleError(stringError);

        // Assert
        expect(result, isA<AppException>());
        expect(result.message, AppStrings.unexpectedError);
        expect(result.code, 'string_error');
        expect(result.originalError, stringError);
      });

      test('should handle unknown errors correctly', () {
        // Arrange
        final unknownError = Exception('Unknown error');

        // Act
        final result = ErrorHandler.handleError(unknownError);

        // Assert
        expect(result, isA<AppException>());
        expect(result.message, AppStrings.unexpectedError);
        expect(result.code, 'unknown_error');
        expect(result.originalError, unknownError);
      });

      test('should return existing AppException unchanged', () {
        // Arrange
        final appException = AppException('Test error', code: 'test_code');

        // Act
        final result = ErrorHandler.handleError(appException);

        // Assert
        expect(result, same(appException));
      });

      test('should include context and user action', () {
        // Arrange
        final error = Exception('Test error');
        final context = {'userId': '123', 'action': 'test'};
        const userAction = 'Testing error handling';

        // Act
        final result = ErrorHandler.handleError(error, context: context, userAction: userAction);

        // Assert
        expect(result.context!['userId'], '123');
        expect(result.context!['action'], 'test');
        expect(result.context!['userAction'], userAction);
      });
    });

    group('Firebase error handling', () {
      test('should handle various Firebase error codes', () {
        final testCases = [
          ('unavailable', AppStrings.serviceUnavailable),
          ('deadline-exceeded', AppStrings.timeoutError),
          ('resource-exhausted', AppStrings.quotaExceededError),
          ('failed-precondition', AppStrings.dataValidationError),
          ('aborted', AppStrings.serverError),
          ('out-of-range', AppStrings.dataValidationError),
          ('unimplemented', AppStrings.serviceUnavailable),
          ('internal', AppStrings.serverError),
          ('data-loss', AppStrings.dataCorruptedError),
        ];

        for (final testCase in testCases) {
          final error = FirebaseException(plugin: 'test', code: testCase.$1, message: 'Test message');

          final result = ErrorHandler.handleError(error);

          expect(result.message, testCase.$2, reason: 'Failed for code: ${testCase.$1}');
          expect(result.code, testCase.$1);
        }
      });

      test('should handle unauthenticated Firebase error as AuthException', () {
        // Arrange
        final error = FirebaseException(plugin: 'test', code: 'unauthenticated', message: 'User not authenticated');

        // Act
        final result = ErrorHandler.handleError(error);

        // Assert
        expect(result, isA<AuthException>());
        expect(result.message, AppStrings.loginRequired);
        expect(result.code, 'unauthenticated');
      });
    });

    group('Firebase Auth error handling', () {
      test('should handle various Firebase Auth error codes', () {
        final testCases = [
          ('wrong-password', AppStrings.passwordIncorrect),
          ('user-disabled', '계정이 비활성화되었습니다.'),
          ('too-many-requests', '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.'),
          ('operation-not-allowed', '허용되지 않은 작업입니다.'),
          ('invalid-email', '올바르지 않은 이메일 형식입니다.'),
          ('email-already-in-use', '이미 사용 중인 이메일입니다.'),
          ('weak-password', '비밀번호가 너무 약합니다.'),
          ('network-request-failed', AppStrings.connectionError),
        ];

        for (final testCase in testCases) {
          final error = FirebaseAuthException(code: testCase.$1, message: 'Test message');

          final result = ErrorHandler.handleError(error);

          expect(result, isA<DataException>());
          expect(result.message, 'Test message', reason: 'Failed for code: ${testCase.$1}');
          expect(result.code, testCase.$1);
        }
      });
    });

    group('HTTP error handling', () {
      test('should handle various HTTP error codes', () {
        final testCases = [
          ('404 Not Found', '요청한 데이터를 찾을 수 없습니다.', 'not_found'),
          ('500 Internal Server Error', AppStrings.serverError, 'server_error'),
          ('503 Service Unavailable', AppStrings.serviceUnavailable, 'service_unavailable'),
          ('400 Bad Request', AppStrings.networkError, 'http_error'),
        ];

        for (final testCase in testCases) {
          final error = HttpException(testCase.$1);

          final result = ErrorHandler.handleError(error);

          expect(result, isA<NetworkException>());
          expect(result.message, testCase.$2, reason: 'Failed for message: ${testCase.$1}');
          expect(result.code, testCase.$3);
        }
      });
    });

    group('Error classification', () {
      test('should correctly identify network errors', () {
        final networkErrors = [
          NetworkException('Network error'),
          const SocketException('Connection failed'),
          const HttpException('HTTP error'),
          FirebaseException(plugin: 'test', code: 'unavailable'),
          FirebaseException(plugin: 'test', code: 'deadline-exceeded'),
          FirebaseException(plugin: 'test', message: 'network timeout'),
        ];

        for (final error in networkErrors) {
          expect(ErrorHandler.isNetworkError(error), true, reason: 'Failed for: ${error.runtimeType}');
        }
      });

      test('should correctly identify non-network errors', () {
        final nonNetworkErrors = [
          AuthException('Auth error'),
          DataException('Data error'),
          ValidationException('Validation error'),
          FirebaseException(plugin: 'test', code: 'permission-denied'),
        ];

        for (final error in nonNetworkErrors) {
          expect(ErrorHandler.isNetworkError(error), false, reason: 'Failed for: ${error.runtimeType}');
        }
      });

      test('should correctly identify auth errors', () {
        final authErrors = [
          AuthException('Auth error'),
          FirebaseAuthException(code: 'user-not-found'),
          FirebaseException(plugin: 'test', code: 'unauthenticated'),
        ];

        for (final error in authErrors) {
          expect(ErrorHandler.isAuthError(error), true, reason: 'Failed for: ${error.runtimeType}');
        }
      });

      test('should correctly identify retryable errors', () {
        final retryableErrors = [
          NetworkException('Network error'),
          const SocketException('Connection failed'),
          FirebaseException(plugin: 'test', code: 'unavailable'),
          FirebaseException(plugin: 'test', code: 'deadline-exceeded'),
          FirebaseException(plugin: 'test', code: 'resource-exhausted'),
          FirebaseException(plugin: 'test', code: 'aborted'),
          FirebaseException(plugin: 'test', code: 'internal'),
        ];

        for (final error in retryableErrors) {
          expect(ErrorHandler.isRetryableError(error), true, reason: 'Failed for: ${error.runtimeType}');
        }
      });

      test('should correctly identify non-retryable errors', () {
        final nonRetryableErrors = [
          AuthException('Auth error'),
          ValidationException('Validation error'),
          FirebaseException(plugin: 'test', code: 'permission-denied'),
          FirebaseException(plugin: 'test', code: 'not-found'),
        ];

        for (final error in nonRetryableErrors) {
          expect(ErrorHandler.isRetryableError(error), false, reason: 'Failed for: ${error.runtimeType}');
        }
      });
    });

    group('getUserFriendlyMessage', () {
      test('should return message from AppException', () {
        // Arrange
        final appException = AppException('Test error message');

        // Act
        final message = ErrorHandler.getUserFriendlyMessage(appException);

        // Assert
        expect(message, 'Test error message');
      });

      test('should handle and return message from other errors', () {
        // Arrange
        final error = Exception('Raw error');

        // Act
        final message = ErrorHandler.getUserFriendlyMessage(error);

        // Assert
        expect(message, AppStrings.unexpectedError);
      });
    });

    group('createErrorReport', () {
      test('should create comprehensive error report', () {
        // Arrange
        final context = {'userId': '123', 'action': 'test'};
        final originalError = Exception('Original error');
        final appException = AppException(
          'Test error',
          code: 'test_code',
          originalError: originalError,
          context: context,
        );

        // Act
        final report = ErrorHandler.createErrorReport(appException);

        // Assert
        expect(report['message'], 'Test error');
        expect(report['code'], 'test_code');
        expect(report['timestamp'], isA<String>());
        expect(report['context'], context);
        expect(report['originalError'], originalError.toString());
        expect(report['stackTrace'], isA<String?>());
      });
    });
  });

  group('Custom Exception Classes', () {
    test('should create NetworkException correctly', () {
      // Arrange & Act
      final exception = NetworkException(
        'Network error',
        code: 'network_code',
        originalError: Exception('Original'),
        context: {'test': 'value'},
      );

      // Assert
      expect(exception.message, 'Network error');
      expect(exception.code, 'network_code');
      expect(exception.originalError, isA<Exception>());
      expect(exception.context!['test'], 'value');
      expect(exception.timestamp, isA<DateTime>());
    });

    test('should create AuthException correctly', () {
      // Arrange & Act
      final exception = AuthException(
        'Auth error',
        code: 'auth_code',
        originalError: Exception('Original'),
        context: {'user': 'test'},
      );

      // Assert
      expect(exception.message, 'Auth error');
      expect(exception.code, 'auth_code');
      expect(exception.originalError, isA<Exception>());
      expect(exception.context!['user'], 'test');
      expect(exception.timestamp, isA<DateTime>());
    });

    test('should create DataException correctly', () {
      // Arrange & Act
      final exception = DataException(
        'Data error',
        code: 'data_code',
        originalError: Exception('Original'),
        context: {'data': 'invalid'},
      );

      // Assert
      expect(exception.message, 'Data error');
      expect(exception.code, 'data_code');
      expect(exception.originalError, isA<Exception>());
      expect(exception.context!['data'], 'invalid');
      expect(exception.timestamp, isA<DateTime>());
    });

    test('should create ValidationException correctly', () {
      // Arrange & Act
      final exception = ValidationException(
        'Validation error',
        code: 'validation_code',
        originalError: Exception('Original'),
        context: {'field': 'email'},
      );

      // Assert
      expect(exception.message, 'Validation error');
      expect(exception.code, 'validation_code');
      expect(exception.originalError, isA<Exception>());
      expect(exception.context!['field'], 'email');
      expect(exception.timestamp, isA<DateTime>());
    });

    test('should create ServiceUnavailableException correctly', () {
      // Arrange & Act
      final exception = ServiceUnavailableException(
        'Service unavailable',
        code: 'service_code',
        originalError: Exception('Original'),
        context: {'service': 'api'},
      );

      // Assert
      expect(exception.message, 'Service unavailable');
      expect(exception.code, 'service_code');
      expect(exception.originalError, isA<Exception>());
      expect(exception.context!['service'], 'api');
      expect(exception.timestamp, isA<DateTime>());
    });

    test('should have meaningful toString', () {
      // Arrange
      final exception = AppException('Test error', code: 'test_code');

      // Act
      final string = exception.toString();

      // Assert
      expect(string, 'AppException: Test error (Code: test_code)');
    });

    test('should handle null context correctly', () {
      // Arrange & Act
      final exception = AppException('Test error');

      // Assert
      expect(exception.context, isA<Map<String, dynamic>>());
      expect(exception.context, isEmpty);
    });
  });
}
