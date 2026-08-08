import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../../app/router.dart';
import 'package:flutter/foundation.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers['Content-Type'] == null && options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }
    options.headers['Accept'] = 'application/json';
    if (!kIsWeb) {
      options.headers['X-Request-ID'] = DateTime.now().millisecondsSinceEpoch.toString();
      options.headers['x-api-key'] = 'Fintree@2026';
    }

    final token = await _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storageService.clearSession();
      appRouter.go('/login');
    }
    return handler.next(err);
  }
}
