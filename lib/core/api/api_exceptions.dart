/// Custom exception for no internet connectivity.
class NoInternetException implements Exception {
  final String message;
  NoInternetException([
    this.message = 'No internet connection. Please check your network.',
  ]);

  @override
  String toString() => message;
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Custom exception for unauthorized access (401).
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([
    this.message = 'Session expired. Please login again.',
  ]);

  @override
  String toString() => message;
}

/// Custom exception for server errors (5xx).
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error. Please try again later.']);

  @override
  String toString() => message;
}
