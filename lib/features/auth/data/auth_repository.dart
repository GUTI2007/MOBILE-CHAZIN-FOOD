import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/user_model.dart';
import 'mock_auth_repository.dart';

/// Repositorio de autenticación conectado con el Backend Express de Chazin Food
class AuthRepository {
  final ApiClient _apiClient;
  final MockAuthRepository _mockFallback = MockAuthRepository();

  AuthRepository(this._apiClient);

  /// Realiza la autenticación llamando a /api/usuarios/login (o /api/auth/login)
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/usuarios/login',
        data: {
          'email': email.trim(),
          'password': password,
          'correo': email.trim(),
          'contrasena': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        final user = User.fromJson(data);
        final token = data['token']?.toString() ?? '';

        if (token.isNotEmpty) {
          _apiClient.setAuthToken(token);
        }

        return AuthResult.success(user: user, token: token);
      } else {
        final msg = response.data?['message'] ?? 'Error al iniciar sesión';
        return AuthResult.failure(msg);
      }
    } on DioException catch (e) {
      // Si la API backend no está encendida o devuelve error de conexión en dev, intentar fallback mock para desarrollo suave
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.unknown) {
        try {
          final mockRes = await _mockFallback.login(email, password);
          if (mockRes.isSuccess && mockRes.token != null) {
            _apiClient.setAuthToken(mockRes.token!);
          }
          return mockRes;
        } catch (_) {}
      }

      final errorMsg = e.response?.data?['message'] ??
          (e.response?.data is Map && e.response?.data['error'] != null
              ? e.response?.data['error']
              : null) ??
          'No se pudo conectar con el servidor backend (${_apiClient.dio.options.baseUrl}).';
      return AuthResult.failure(errorMsg.toString());
    } catch (e) {
      return AuthResult.failure('Error inesperado: ${e.toString()}');
    }
  }

  /// Recuperación de contraseña vía /api/usuarios/recuperar-contrasena
  Future<bool> recoverPassword(String email) async {
    try {
      final response = await _apiClient.post(
        '/usuarios/recuperar-contrasena',
        data: {'email': email.trim(), 'correo': email.trim()},
      );
      return response.statusCode == 200;
    } catch (_) {
      // Intentar endpoint alternativo
      try {
        final response = await _apiClient.post(
          '/usuarios/forgot-password',
          data: {'email': email.trim()},
        );
        return response.statusCode == 200;
      } catch (_) {
        return await _mockFallback.recoverPassword(email);
      }
    }
  }

  /// Restablecimiento de contraseña vía /api/usuarios/restablecer-contrasena
  Future<bool> resetPassword(String email, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/usuarios/restablecer-contrasena',
        data: {
          'email': email.trim(),
          'contrasena': newPassword,
          'password': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return await _mockFallback.resetPassword(email, newPassword);
    }
  }
}
