import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late final Dio _dio;

  // Private constructor for Singleton pattern
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Axios-like Interceptors (Request, Response, Error)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // You can dynamically add Bearer tokens here:
          // String? token = getStoredToken();
          // if (token != null) options.headers['Authorization'] = 'Bearer $token';
          print('🌐 [API Request] ${options.method} -> ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ [API Response] Status: ${response.statusCode} for ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print('❌ [API Error] Msg: ${e.message} for ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );
  }

  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  // Axios-like get() helper
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Axios-like post() helper
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Uniform error handling
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "连接服务器超时，请检查网络！";
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return "服务器响应异常 ($status)";
      case DioExceptionType.connectionError:
        return "网络未连接，请检查网络设置！";
      default:
        return "发生未知错误: ${error.message}";
    }
  }
}
