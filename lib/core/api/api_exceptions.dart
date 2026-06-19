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
///
/// [code] carries the PDT error code from the server envelope (e.g. `BIN_FULL`).
class ApiException implements Exception {
  final String code;
  final String message;

  const ApiException(this.code, this.message);

  /// Helper to check if this is an authentication/session expiry error.
  bool get isAuth => code == 'UNAUTHENTICATED';

  @override
  String toString() => 'ApiException($code): $message';
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
