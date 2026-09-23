import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

/// Provider global de ApiClient para Riverpod
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Configuración centralizada del cliente HTTP Dio para la App Móvil Chazin Food
class ApiClient {
  /// IP local IPv4 de la máquina de desarrollo (para celular físico APK)
  static const String localServerIp = '192.168.40.23';

  /// Determina la URL base de la API de forma configurable y según el entorno de ejecución
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      // Si se especifica --dart-define=USE_EMULATOR=true usa la IP especial del emulador (10.0.2.2)
      // Por defecto para APK / dispositivo físico usa la IP local de la PC (http://192.168.40.23:5000/api)
      const useEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
      if (useEmulator) {
        return 'http://10.0.2.2:5000/api';
      }
      return 'http://$localServerIp:5000/api';
    }
    // Desktop / iOS por defecto
    return 'http://$localServerIp:5000/api';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  late final Dio dio;
  String? _authToken;

  ApiClient({String? customBaseUrl}) {
    final String url = customBaseUrl ?? defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para agregar Token JWT automáticamente si existe
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint('ApiClient Error [${error.response?.statusCode}]: ${error.message}');
          return handler.next(error);
        },
      ),
    );

    // Interceptor para logging en desarrollo
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[HTTP] $obj'),
        ),
      );
    }
  }

  /// Obtiene el token JWT actual
  String? get token => _authToken;

  /// Establece el token JWT para las peticiones autenticadas
  void setAuthToken(String token) {
    _authToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remueve el token de autenticación
  void clearAuthToken() {
    _authToken = null;
    dio.options.headers.remove('Authorization');
  }

  // ─── Helper Methods para peticiones HTTP ───

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }
}
