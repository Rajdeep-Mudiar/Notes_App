import 'package:dio/dio.dart';
import 'package:frontend/core/constants/api_endpoints.dart';
import 'package:frontend/core/storage/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final StorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Dynamically synchronize current baseUrl from user config or runtime setting
    if (!options.path.startsWith('http://') && !options.path.startsWith('https://')) {
      options.baseUrl = ApiEndpoints.baseUrl;
    }
    final token = _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token is expired or invalid
      // In advanced phases, auto-refresh token flow is triggered here.
    }
    handler.next(err);
  }
}
