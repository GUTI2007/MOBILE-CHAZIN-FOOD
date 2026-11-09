import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/user_model.dart';

/// Resultado de la verificación previa de existencia del correo
class EmailCheckResult {
  final bool exists;
  final bool isConnectionError;
  final String message;

  const EmailCheckResult({
    required this.exists,
    this.isConnectionError = false,
    required this.message,
  });
}

/// Repositorio de autenticación conectado directamente con la API REST Backend
class AuthRepository {
  final ApiClient _apiClient;

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

  /// Verifica si el correo electrónico existe en la base de datos o backend antes de enviar instrucciones
  Future<EmailCheckResult> verifyEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return const EmailCheckResult(
        exists: false,
        message: 'Por favor ingresa un correo electrónico válido.',
      );
    }

    // 1. Intentar endpoint dedicado /usuarios/verificar-correo
    try {
      final response = await _apiClient.post(
        '/usuarios/verificar-correo',
        data: {'email': cleanEmail, 'correo': cleanEmail},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final bool exists = data['exists'] == true || data['registered'] == true;
        final String msg = data['message']?.toString() ??
            (exists
                ? 'El correo se encuentra registrado.'
                : 'El correo ingresado no se encuentra registrado en el sistema.');
        return EmailCheckResult(exists: exists, message: msg);
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404 &&
          dioErr.response?.data is Map &&
          dioErr.response?.data['message'] != null) {
        return EmailCheckResult(
          exists: false,
          message: dioErr.response!.data['message'].toString(),
        );
      }
    } catch (_) {}

    // 2. Intentar endpoint dedicado /auth/verificar-correo
    try {
      final response = await _apiClient.post(
        '/auth/verificar-correo',
        data: {'email': cleanEmail, 'correo': cleanEmail},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final bool exists = data['exists'] == true || data['registered'] == true;
        final String msg = data['message']?.toString() ??
            (exists
                ? 'El correo se encuentra registrado.'
                : 'El correo ingresado no se encuentra registrado en el sistema.');
        return EmailCheckResult(exists: exists, message: msg);
      }
    } on DioException catch (dioErr) {
      if (dioErr.response?.statusCode == 404 &&
          dioErr.response?.data is Map &&
          dioErr.response?.data['message'] != null) {
        return EmailCheckResult(
          exists: false,
          message: dioErr.response!.data['message'].toString(),
        );
      }
    } catch (_) {}

    // 3. Fallback: Consulta directa del listado de usuarios de la base de datos (/usuarios)
    try {
      final response = await _apiClient.get('/usuarios');
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        final bool exists = list.any((u) {
          if (u is Map) {
            final uEmail = (u['email'] ?? u['correo'])?.toString().trim().toLowerCase();
            return uEmail == cleanEmail;
          }
          return false;
        });

        return EmailCheckResult(
          exists: exists,
          message: exists
              ? 'El correo se encuentra registrado.'
              : 'El correo ingresado no se encuentra registrado en el sistema.',
        );
      }
    } catch (_) {}

    return const EmailCheckResult(
      exists: false,
      isConnectionError: true,
      message: 'No fue posible validar el correo con el servidor. Verifica tu conexión a internet.',
    );
  }

  /// Recuperación de contraseña vía /api/usuarios/recuperar-contrasena
  Future<bool> recoverPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final response = await _apiClient.post(
        '/usuarios/recuperar-contrasena',
        data: {'email': cleanEmail, 'correo': cleanEmail},
      );
      return response.statusCode == 200;
    } catch (_) {
      try {
        final response = await _apiClient.post(
          '/auth/recuperar-contrasena',
          data: {'email': cleanEmail, 'correo': cleanEmail},
        );
        return response.statusCode == 200;
      } catch (_) {
        try {
          final response = await _apiClient.post(
            '/usuarios/forgot-password',
            data: {'email': cleanEmail},
          );
          return response.statusCode == 200;
        } catch (_) {
          return false;
        }
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
      return false;
    }
  }
}
