import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    options.headers['X-Request-ID'] = DateTime.now().millisecondsSinceEpoch.toString();

    final token = await _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Session expired handling
    }
    return handler.next(err);
  }
}
