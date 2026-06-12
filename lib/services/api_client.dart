import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

  String _normalizePath(String path) {
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      dio.get<T>(_normalizePath(path), queryParameters: query);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      dio.post<T>(_normalizePath(path), data: data, options: options);

  Future<Response<T>> delete<T>(String path, {dynamic data}) =>
      dio.delete<T>(_normalizePath(path), data: data);

  Future<Response<T>> put<T>(String path, {dynamic data}) =>
      dio.put<T>(_normalizePath(path), data: data);
}
