import 'dart:io';

import 'package:dio/dio.dart';
import 'dart:async';

import 'package:dio/io.dart';

import '../../../core/logger/app_logger.dart';

class ApiClient {
  late final Dio _dio;
  String? _token;

  ApiClient({required String baseUrl, String? token}) {
    _dio = Dio(BaseOptions(
      baseUrl: '$baseUrl/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _token = token;
    _primaryBaseUrl = '$baseUrl/api';
    _setupInterceptors();
  }

  /// 单飞刷新：并发 401 只触发一次 refresh，其余请求等待同一结果。
  Future<bool> _tryRefresh() async {
    final fn = onRefreshRequested;
    if (fn == null) return false;
    if (_refreshing != null) return _refreshing!.future;
    final c = Completer<bool>();
    _refreshing = c;
    try {
      final ok = await fn();
      c.complete(ok);
      return ok;
    } catch (_) {
      c.complete(false);
      return false;
    } finally {
      _refreshing = null;
    }
  }

  void updateToken(String? token) {
    _token = token;
  }

  void updateBaseUrl(String baseUrl) {
    _primaryBaseUrl = '$baseUrl/api';
    _dio.options.baseUrl = _primaryBaseUrl!;
  }

  /// 直连通道配置：开启后 GET/HEAD 优先走直连（自动带设备签名），
  /// 连接失败/超时自动回退到主地址（CF）。写请求仍走主地址。
  void configureDirect({
    required bool enabled,
    String? url,
    Future<Map<String, String>> Function(String method, String uri)? signer,
    HttpClient Function()? clientFactory,
  }) {
    _directEnabled = enabled;
    _directBaseUrl = (url != null && url.isNotEmpty) ? '$url/api' : null;
    _signer = signer;
    // 直连常用自签证书：用固定了指纹的 HttpClient 校验；主通道证书合法不受影响。
    if (enabled && clientFactory != null) {
      _dio.httpClientAdapter =
          IOHttpClientAdapter(createHttpClient: clientFactory);
    }
  }

  String? _primaryBaseUrl;
  String? _directBaseUrl;
  bool _directEnabled = false;
  Future<Map<String, String>> Function(String method, String uri)? _signer;

  /// 会话中令牌失效（401）回调：由 DI 层注入「清令牌 + 回登录页」。
  /// 登录类接口自身的 401（密码错误等）不触发。
  void Function()? onUnauthorized;

  static const _authPublicPaths = [
    '/auth/login',
    '/auth/verify-totp',
    '/auth/verify-backup',
    '/auth/refresh',
  ];

  /// 401 时尝试静默刷新 access（由 DI 注入，内部单飞）。
  Future<bool> Function()? onRefreshRequested;
  Completer<bool>? _refreshing;

  void _setupInterceptors() {
    // 请求详情日志（可选）：开关在「运行日志」页，开启后记录方法/URL/状态/耗时。
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['__t0'] = DateTime.now().microsecondsSinceEpoch;
        AppLogger.req('→ ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        final t0 = response.requestOptions.extra['__t0'] as int?;
        final cost = t0 == null
            ? ''
            : ' ${(DateTime.now().microsecondsSinceEpoch - t0) ~/ 1000}ms';
        AppLogger.req(
            '← ${response.statusCode} ${response.requestOptions.method} '
            '${response.requestOptions.uri}$cost');
        handler.next(response);
      },
      onError: (err, handler) {
        final t0 = err.requestOptions.extra['__t0'] as int?;
        final cost = t0 == null
            ? ''
            : ' ${(DateTime.now().microsecondsSinceEpoch - t0) ~/ 1000}ms';
        AppLogger.req('✗ ${err.requestOptions.method} '
            '${err.requestOptions.uri} ${err.type.name}$cost');
        handler.next(err);
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        final isSafe = options.method == 'GET' || options.method == 'HEAD';
        if (_directEnabled &&
            _directBaseUrl != null &&
            _signer != null &&
            isSafe) {
          options.extra['__primaryBase'] = _primaryBaseUrl;
          options.baseUrl = _directBaseUrl!;
          final uri = options.uri;
          final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
          try {
            final sig = await _signer!(options.method, path);
            options.headers.addAll(sig);
            options.extra['__direct'] = true;
          } catch (_) {
            options.baseUrl = _primaryBaseUrl!;
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 直连失败（连接/超时类）自动回退主地址重试一次，保证可用性
        final usedDirect = error.requestOptions.extra['__direct'] == true;
        final retryable = error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout;
        if (usedDirect && retryable) {
          final primary = error.requestOptions.extra['__primaryBase'] as String?;
          if (primary != null && primary.isNotEmpty) {
            final headers = Map<String, dynamic>.from(error.requestOptions.headers)
              ..removeWhere((k, _) => k.startsWith('X-Device'));
            try {
              final res = await _dio.fetch(error.requestOptions.copyWith(
                baseUrl: primary,
                headers: headers,
              ));
              handler.resolve(res);
              return;
            } catch (_) {
              // 回退也失败，按原错误上报
            }
          }
        }
        // 请求失败进运行日志：方法/路径/原因，便于现场排障
        AppLogger.w('请求失败 ${error.requestOptions.method} '
            '${error.requestOptions.path}: ${error.message}');
        // 会话中令牌失效：清除本地缓存并通知回登录页
        final path = error.requestOptions.path;
        final isAuthPublic = _authPublicPaths.any((p) => path.contains(p));
        if (error.response?.statusCode == 401 && !isAuthPublic) {
          if (await _tryRefresh()) {
            try {
              final res = await _dio.fetch(error.requestOptions.copyWith(
                headers: Map<String, dynamic>.from(error.requestOptions.headers)
                  ..['Authorization'] = 'Bearer $_token',
              ));
              handler.resolve(res);
              return;
            } catch (_) {}
          }
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get<Map<String, dynamic>>(path,
        queryParameters: queryParameters);
    return _unwrapResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? data}) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: data);
    return _unwrapResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? data}) async {
    final response = await _dio.put<Map<String, dynamic>>(path, data: data);
    return _unwrapResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.delete<Map<String, dynamic>>(path,
        queryParameters: queryParameters);
    return _unwrapResponse(response);
  }

  Future<List<dynamic>> getList(String path,
      {Map<String, dynamic>? queryParameters}) async {
    final response =
        await _dio.get<dynamic>(path, queryParameters: queryParameters);
    final body = response.data as Map<String, dynamic>;
    if (body['code'] != 0 && body['code'] != 200) {
      throw ApiException(body['message'] as String? ?? 'Unknown error',
          body['code'] as int? ?? -1);
    }
    final d = body['data'];
    if (d is List) return d;
    return [];
  }

  Future<Response> download(String path, String savePath,
      {Map<String, dynamic>? queryParameters,
      void Function(int, int)? onReceiveProgress}) {
    return _dio.download(path, savePath,
        queryParameters: queryParameters, onReceiveProgress: onReceiveProgress);
  }

  Future<Response> upload(String path, FormData formData,
      {void Function(int, int)? onSendProgress}) {
    return _dio.post(path, data: formData, onSendProgress: onSendProgress);
  }

  Map<String, dynamic> _unwrapResponse(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('Invalid response format', -1);
    }
    if (body['code'] != 0 && body['code'] != 200) {
      throw ApiException(body['message'] as String? ?? 'Unknown error',
          body['code'] as int? ?? -1);
    }
    final d = body['data'];
    if (d is Map<String, dynamic>) return d;
    if (d is List) return <String, dynamic>{'_items': d};
    return body;
  }
}

class ApiException implements Exception {
  final String message;
  final int code;
  ApiException(this.message, this.code);
  @override
  String toString() => 'ApiException($code): $message';
}
