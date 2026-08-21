import 'package:dio/dio.dart';
import '../../app/env.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  ApiClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: currentEnvironment.apiBaseUrl,
        connectTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
        receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutSeconds),
        sendTimeout: const Duration(seconds: AppConstants.connectTimeoutSeconds),
      ),
    );

    _dio.interceptors.add(AuthInterceptor(_storageService));

    if (currentEnvironment.isDevelopment) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) {
            final str = object.toString();
            // Sanitize sensitive strings before logging
            final sanitized = str
                .replaceAll(RegExp(r'"otp"\s*:\s*"[^"]*"'), '"otp":"******"')
                .replaceAll(RegExp(r'"panNumber"\s*:\s*"[^"]*"'), '"panNumber":"******"')
                .replaceAll(RegExp(r'"accountNumber"\s*:\s*"[^"]*"'), '"accountNumber":"******"');
            // Print sanitized log in dev mode
            // ignore: avoid_print
            print('[API LOG] $sanitized');
          },
        ),
      );
    }
  }

  Dio get dio => _dio;

  AppException handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const AppException(
            message: 'Network connection error or timeout. Please check your internet connection.',
            retryable: true,
          );

        case DioExceptionType.badResponse:
          final response = error.response;
          final statusCode = response?.statusCode;
          final data = response?.data;

          String message = 'An unexpected server error occurred.';
          Map<String, String>? fieldErrors;
          String? code;

          if (data is Map<String, dynamic>) {
            if (data['error'] is Map<String, dynamic>) {
              final errMap = data['error'] as Map<String, dynamic>;
              if (errMap['message'] != null) {
                message = errMap['message'].toString();
              }
              if (errMap['code'] != null) {
                code = errMap['code'].toString();
              }
            } else if (data['error'] is String) {
              message = data['error'] as String;
            }

            if (data['message'] is String) {
              message = data['message'] as String;
            } else if (data['message'] is List) {
              message = (data['message'] as List).join(', ');
            }

            if (data['code'] is String) {
              code = data['code'] as String;
            }

            if (data['errors'] is Map<String, dynamic>) {
              fieldErrors = (data['errors'] as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v.toString()),
              );
            }
          }

          return AppException(
            message: message,
            statusCode: statusCode,
            code: code,
            fieldErrors: fieldErrors,
            retryable: statusCode != null && statusCode >= 500,
          );

        default:
          return AppException(
            message: error.message ?? 'An unknown error occurred.',
          );
      }
    }
    if (error is AppException) return error;
    return AppException(message: error.toString());
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } catch (e) {
      throw handleError(e);
    }
  }
}
