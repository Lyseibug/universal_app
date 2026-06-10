import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../constants/app_constants.dart';
import '../services/connectivity_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';
import 'api_exceptions.dart';
import 'api_interceptors.dart';

/// Centralized API client built on Dio for ERPNext/Frappe backend.
/// Uses cookie-based session management (Frappe standard).
/// Handles HTTP→HTTPS redirects for POST requests (nginx 301).
class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;
  final ConnectivityService _connectivityService;

  ApiClient({
    required StorageService storageService,
    required ConnectivityService connectivityService,
  }) : _storageService = storageService,
       _connectivityService = connectivityService {
    _dio = Dio(_baseOptions);
    _configureDio();
    _setupInterceptors();
  }

  /// Expose Dio instance for cookie-aware operations.
  Dio get dio => _dio;

  /// Base Dio options with timeouts.
  /// followRedirects handles GET redirects automatically.
  /// For POST redirects (301/302), we handle manually in the interceptor.
  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: _storageService.getErpUrl(),
    connectTimeout: const Duration(seconds: AppConstants.connectionTimeout),
    receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
    followRedirects: true,
    maxRedirects: 5,
    validateStatus: (status) => status != null && status < 500,
    headers: {'Accept': 'application/json'},
  );

  /// Configure Dio to accept self-signed certificates (common for internal ERPNext).
  void _configureDio() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
  }

  /// Setup interceptors for redirect handling, cookies, logging, and errors.
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      RedirectInterceptor(dio: _dio),
      CookieInterceptor(storageService: _storageService),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  /// Update the base URL when settings change.
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
    AppLogger.info('API base URL updated to: $newUrl', tag: 'ApiClient');
  }

  /// Generic GET request with retry mechanism.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();
    return _retryRequest(
      () =>
          _dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  /// Generic POST request with retry mechanism.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();
    return _retryRequest(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Generic PUT request with retry mechanism.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();
    return _retryRequest(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Generic DELETE request with retry mechanism.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    await _checkConnectivity();
    return _retryRequest(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  /// Check internet connectivity before making a request.
  Future<void> _checkConnectivity() async {
    final hasConnection = await _connectivityService.hasInternetConnection();
    if (!hasConnection) {
      throw NoInternetException();
    }
  }

  /// Retry mechanism for failed requests.
  Future<Response<T>> _retryRequest<T>(
    Future<Response<T>> Function() request, {
    int maxRetries = AppConstants.maxRetries,
  }) async {
    int retryCount = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        retryCount++;
        if (retryCount >= maxRetries ||
            (e.type != DioExceptionType.connectionTimeout &&
                e.type != DioExceptionType.receiveTimeout &&
                e.type != DioExceptionType.connectionError)) {
          rethrow;
        }
        AppLogger.warning(
          'Request failed, retrying ($retryCount/$maxRetries)...',
          tag: 'ApiClient',
        );
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
  }
}
