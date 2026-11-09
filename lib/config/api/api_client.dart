import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/utils/security_sanitizer.dart';
import '../../services/storage_service.dart';

/// Provider global de ApiClient para Riverpod
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Configuración centralizada del cliente HTTP Dio para la App Móvil Chazin Food
/// Cumple con OWASP Mobile Top 10 y MASVS (MASVS-STORAGE / MASVS-NETWORK)
class ApiClient {
  /// IP local IPv4 de la máquina de desarrollo (para pruebas locales en debug)
  static const String localServerIp = '192.168.40.23';

  /// URL de producción desplegada en la nube (Render)
  static const String productionApiUrl = 'https://backend-web-chazin-food.onrender.com/api';

  /// Determina la URL base de la API de forma configurable y según el entorno de ejecución
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // En modo Release (producción / despliegue), conectar directamente al backend en Render
    if (kReleaseMode) {
      return productionApiUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
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
  final StorageService _storageService;
  String? _authToken;

  ApiClient({String? customBaseUrl, StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    final String url = customBaseUrl ?? defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
        },
      ),
    );

    // Cargar token previamente almacenado de forma segura
    _initStoredToken();

    // Interceptor centralizado para cabeceras de autorización Bearer y seguridad
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          // Cabeceras de seguridad
          options.headers['X-Content-Type-Options'] = 'nosniff';
          options.headers['X-Frame-Options'] = 'DENY';
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          debugPrint('ApiClient Error [${error.response?.statusCode}]: ${error.message}');
          if (error.response?.statusCode == 401) {
            // Token expirado o inválido: limpiar estado seguro
            clearAuthToken();
          }
          return handler.next(error);
        },
      ),
    );

    // Interceptor para logging seguro en desarrollo
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

  Future<void> _initStoredToken() async {
    try {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        _authToken = token;
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('Error leyendo token de almacenamiento seguro: $e');
    }
  }

  /// Obtiene el token JWT actual
  String? get token => _authToken;

  /// Establece el token JWT para las peticiones autenticadas y lo persiste en flutter_secure_storage
  void setAuthToken(String token, {bool persist = true}) {
    _authToken = token;
    dio.options.headers['Authorization'] = 'Bearer $token';
    if (persist) {
      _storageService.saveToken(token);
    }
  }

  /// Remueve el token de autenticación tanto de memoria como de almacenamiento seguro
  void clearAuthToken() {
    _authToken = null;
    dio.options.headers.remove('Authorization');
    _storageService.clearAll();
  }

  // ─── Sanitización y parametrización de peticiones ───

  /// Procesa la ruta para prevenir Path Traversal y extrae cualquier query concatenada
  String _prepareSafePath(String path, Map<String, dynamic>? queryParameters, Map<String, dynamic> outParams) {
    var cleanPath = SecuritySanitizer.sanitizePath(path);

    if (queryParameters != null) {
      outParams.addAll(queryParameters);
    }

    // Si la ruta contiene un signo '?', separar los parámetros para enviarlos de forma parametrizada
    if (cleanPath.contains('?')) {
      final parts = cleanPath.split('?');
      cleanPath = parts[0];
      if (parts.length > 1) {
        final uri = Uri.tryParse(path);
        if (uri != null) {
          outParams.addAll(uri.queryParameters);
        }
      }
    }

    return cleanPath;
  }

  // ─── Helper Methods para peticiones HTTP Parametrizadas ───

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final Map<String, dynamic> params = {};
    final safePath = _prepareSafePath(path, queryParameters, params);
    return await dio.get<T>(
      safePath,
      queryParameters: params.isNotEmpty ? params : null,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final Map<String, dynamic> params = {};
    final safePath = _prepareSafePath(path, queryParameters, params);
    return await dio.post<T>(
      safePath,
      data: data,
      queryParameters: params.isNotEmpty ? params : null,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final Map<String, dynamic> params = {};
    final safePath = _prepareSafePath(path, queryParameters, params);
    return await dio.put<T>(
      safePath,
      data: data,
      queryParameters: params.isNotEmpty ? params : null,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final Map<String, dynamic> params = {};
    final safePath = _prepareSafePath(path, queryParameters, params);
    return await dio.patch<T>(
      safePath,
      data: data,
      queryParameters: params.isNotEmpty ? params : null,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final Map<String, dynamic> params = {};
    final safePath = _prepareSafePath(path, queryParameters, params);
    return await dio.delete<T>(
      safePath,
      data: data,
      queryParameters: params.isNotEmpty ? params : null,
      options: options,
    );
  }
}
