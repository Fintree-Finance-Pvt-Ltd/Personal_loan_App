class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, String>? fieldErrors;
  final bool retryable;
  final String? providerCode;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
    this.fieldErrors,
    this.retryable = false,
    this.providerCode,
  });

  @override
  String toString() => 'AppException(message: $message, code: $code, statusCode: $statusCode)';
}
