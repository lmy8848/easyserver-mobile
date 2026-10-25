import 'package:dio/dio.dart';

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
    _setupInterceptors();
  }

  void updateToken(String? token) {
    _token = token;
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = '$baseUrl/api';
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
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
