class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic rawData)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true || json['status'] == 'SUCCESS' || json['status'] == true,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
    );
  }
}
