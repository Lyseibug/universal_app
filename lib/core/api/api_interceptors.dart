import 'package:dio/dio.dart';

import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'api_exceptions.dart';

/// Interceptor to handle HTTP→HTTPS 301/302 redirects for POST/PUT requests.
/// Dio's built-in followRedirects only works for GET. For POST requests that
/// receive a 301 from nginx (http→https), we must manually re-issue the request
/// to the Location header URL, preserving method and body.
class RedirectInterceptor extends Interceptor {
  final Dio _dio;

  RedirectInterceptor({required Dio dio}) : _dio = dio;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final statusCode = response.statusCode ?? 0;

    // Handle 301/302/307/308 redirects that Dio didn't follow (POST requests)
    if (statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 307 ||
        statusCode == 308) {
      final location = response.headers.value('location');

      if (location != null && location.isNotEmpty) {
        AppLogger.info(
          'Redirect $statusCode → $location (re-issuing ${response.requestOptions.method})',
          tag: 'RedirectInterceptor',
        );

        // Resolve the redirect URL (could be relative or absolute)
        final redirectUri = Uri.parse(location);
        final originalUri = response.requestOptions.uri;
        final resolvedUri = redirectUri.isAbsolute
            ? redirectUri
            : originalUri.resolveUri(redirectUri);

        try {
          // Re-issue the same request to the redirect URL
          final newResponse = await _dio.request(
            resolvedUri.toString(),
            data: response.requestOptions.data,
            options: Options(
              method: response.requestOptions.method,
              headers: response.requestOptions.headers,
              contentType: response.requestOptions.contentType,
              followRedirects: true,
              maxRedirects: 5,
            ),
          );
          handler.resolve(newResponse);
          return;
        } on DioException catch (e) {
          handler.reject(e);
          return;
        }
      }
    }

    handler.next(response);
  }
}

/// Interceptor for managing ERPNext session cookies.
/// Frappe uses cookie-based authentication (sid, system_user, etc.)
class CookieInterceptor extends Interceptor {
  final StorageService _storageService;

  CookieInterceptor({required StorageService storageService})
    : _storageService = storageService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Attach saved session cookies to every request
    final cookies = await _storageService.getSessionCookies();
    if (cookies != null && cookies.isNotEmpty) {
      options.headers['Cookie'] = cookies;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Extract and persist Set-Cookie headers from response
    final setCookies = response.headers.map['set-cookie'];
    if (setCookies != null && setCookies.isNotEmpty) {
      final cookieString = _parseCookies(setCookies);
      if (cookieString.isNotEmpty) {
        await _storageService.saveSessionCookies(cookieString);
        AppLogger.debug('Session cookies saved', tag: 'CookieInterceptor');
      }
    }
    handler.next(response);
  }

  /// Parse Set-Cookie headers into a single Cookie header string.
  String _parseCookies(List<String> setCookieHeaders) {
    final cookies = <String, String>{};
    for (final header in setCookieHeaders) {
      final parts = header.split(';');
      if (parts.isNotEmpty) {
        final nameValue = parts[0].trim();
        final eqIndex = nameValue.indexOf('=');
        if (eqIndex > 0) {
          final name = nameValue.substring(0, eqIndex).trim();
          final value = nameValue.substring(eqIndex + 1).trim();
          cookies[name] = value;
        }
      }
    }
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}

/// Interceptor for logging requests and responses.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('→ ${options.method} ${options.uri}', tag: 'HTTP');
    if (options.data != null) {
      AppLogger.debug('  Body: ${options.data}', tag: 'HTTP');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      tag: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '✖ ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.uri}',
      error: err.message,
      tag: 'HTTP',
    );
    handler.next(err);
  }
}

/// Interceptor for centralized error handling.
class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode ?? 0;

    // Handle client errors (4xx) received as responses
    if (statusCode >= 400 && statusCode < 500) {
      final data = response.data;
      String message;

      if (data is Map) {
        message =
            (data['message'] as String?) ??
            (data['_server_messages'] as String?) ??
            _defaultMessageForStatus(statusCode);
      } else if (data is String && data.isNotEmpty) {
        message = data;
      } else {
        message = _defaultMessageForStatus(statusCode);
      }

      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: ApiException(
            message: message,
            statusCode: statusCode,
            data: data,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ApiException(
              message: 'Connection timed out. Please try again.',
              statusCode: err.response?.statusCode,
            ),
            type: err.type,
            response: err.response,
          ),
        );
        return;
      case DioExceptionType.connectionError:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NoInternetException('Unable to connect to server.'),
            type: err.type,
            response: err.response,
          ),
        );
        return;
      default:
        handler.next(err);
    }
  }

  String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Invalid credentials. Please try again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
