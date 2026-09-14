import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your network and server.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final response = error.response;
        if (response != null && response.data != null) {
          if (response.data is Map<String, dynamic>) {
            final map = response.data as Map<String, dynamic>;
            final message = map['message'] ?? map['detail'] ?? map['error'] ?? 'Server error';
            return ApiException(
              message: message.toString(),
              statusCode: response.statusCode,
              data: response.data,
            );
          }
        }
        return ApiException(
          message: 'Received invalid server response (${response?.statusCode}).',
          statusCode: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'Unable to connect to Student OS backend server. Please verify backend is running.',
          statusCode: 503,
        );
      default:
        return ApiException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}
