class ApiException implements Exception {
  ApiException(this.message, this.code);

  final dynamic message;
  final dynamic code;

  @override
  String toString() => 'ApiException: $message (code: $code)';
}
