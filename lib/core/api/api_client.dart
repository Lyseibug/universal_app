import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../auth/token_store.dart';
import '../services/connectivity_service.dart';
import '../utils/logger.dart';
import 'api_exceptions.dart';

/// Centralized API client built on Dio for the WMS/PDT application.
///
/// Handles:
///  • Token authentication (Authorization: token <token>)
///  • Self-signed HTTPS certificate bypass
///  • Frappe response envelope unwrapping (success: msg['data'], failure: msg['error'])
///  • Device connectivity pre-checks and retry mechanism
///  • Centrally intercepts "UNAUTHENTICATED" errors to trigger logout
class ApiClient {
  final Dio _dio;
  final TokenStore _tokens;
  final ConnectivityService _connectivityService;
  final void Function()? onUnauthenticated;

  ApiClient(
    this._tokens, {
    required String baseUrl,
    required ConnectivityService connectivityService,
    this.onUnauthenticated,
  })  : _connectivityService = connectivityService,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          contentType: 'application/json',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status != null && status < 500,
        )) {
    _configureDio();
    _setupInterceptors();
  }

  /// Expose Dio options to update baseUrl dynamically (e.g. from Settings screen)
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    AppLogger.info('API base URL updated to: $newUrl', tag: 'ApiClient');
  }

  /// Configure bad certificate callback (accept self-signed certs)
  void _configureDio() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  /// Setup token authorization and global error handler interceptor
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        AppLogger.info('→ ${options.method} ${options.uri}', tag: 'HTTP');
        final t = await _tokens.read();
        if (t != null) {
          options.headers['Authorization'] = 'token $t';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info('← ${response.statusCode} ${response.requestOptions.uri}', tag: 'HTTP');
        handler.next(response);
      },
      onError: (err, handler) {
        AppLogger.error('✖ ${err.response?.statusCode ?? 'N/A'} ${err.requestOptions.uri}', tag: 'HTTP');
        handler.next(err);
      },
    ));
  }

  /// Call a `universal_mobile_api` method.
  ///
  /// Automatically checks connectivity and retries on transient connection issues.
  /// Unwraps the Frappe response envelope (returns `message.data` or throws `ApiException`).
  Future<dynamic> call(String method, {Map<String, dynamic>? body}) async {
    await _checkConnectivity();

    final Response res = await _retryRequest(
      () => _dio.post(
        '/api/method/universal_mobile_api.api.$method',
        data: body ?? const {},
      ),
    );

    final root = res.data;
    final msg = (root is Map && root['message'] is Map)
        ? root['message'] as Map
        : null;

    if (msg == null) {
      throw const ApiException('PROTOCOL', 'Unexpected server response');
    }

    if (msg['error'] == true) {
      final code = (msg['code'] ?? 'UNKNOWN').toString();
      final message = (msg['message'] ?? 'Error').toString();
      
      final apiException = ApiException(code, message);

      if (apiException.isAuth) {
        AppLogger.warning('Received UNAUTHENTICATED error. Triggering global logout.', tag: 'ApiClient');
        onUnauthenticated?.call();
      }

      throw apiException;
    }

    return msg['data'];
  }

  /// Check internet connectivity before making a request.
  Future<void> _checkConnectivity() async {
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      throw NoInternetException();
    }
  }

  /// Retry mechanism for transient connection/timeout failures.
  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request, {
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        retryCount++;
        // Retry only for timeouts or connection errors (status code is null)
        if (retryCount >= maxRetries ||
            (e.type != DioExceptionType.connectionTimeout &&
                e.type != DioExceptionType.receiveTimeout &&
                e.type != DioExceptionType.connectionError)) {
          rethrow;
        }
        AppLogger.warning(
          'Request failed, retrying ($retryCount/$maxRetries) in ${retryCount * 2}s...',
          tag: 'ApiClient',
        );
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }
}
