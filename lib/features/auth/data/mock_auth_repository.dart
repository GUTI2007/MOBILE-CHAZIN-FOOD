import '../../../shared/models/user_model.dart';

/// Repositorio mock de autenticación
class MockAuthRepository {
  // Usuarios mock del sistema
  static final List<_MockUser> _users = [
    _MockUser(
      user: const User(
        id: 'usr_001',
        name: 'Carlos Martínez',
        email: 'admin@chazin.com',
        role: UserRole.admin,
      ),
      password: 'admin123',
    ),
    _MockUser(
      user: const User(
        id: 'usr_002',
        name: 'María López',
        email: 'cajero@chazin.com',
        role: UserRole.employee,
      ),
      password: 'cajero123',
    ),
  ];

  /// Simula login con delay de red
  Future<AuthResult> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final match = _users.where(
      (u) => u.user.email == email.trim().toLowerCase() && u.password == password,
    );

    if (match.isEmpty) {
      return AuthResult.failure('Credenciales inválidas. Intenta de nuevo.');
    }

    return AuthResult.success(
      user: match.first.user,
      token: 'mock_jwt_token_${match.first.user.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Simula recuperación de contraseña
  Future<bool> recoverPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return _users.any((u) => u.user.email == email.trim().toLowerCase());
  }

  /// Simula restablecimiento de contraseña
  Future<bool> resetPassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final cleanEmail = email.trim().toLowerCase();
    final match = _users.where((u) => u.user.email == cleanEmail);
    if (match.isNotEmpty) {
      match.first.password = newPassword;
      return true;
    }
    return false;
  }
}

/// Resultado de autenticación
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.token,
    this.errorMessage,
  });

  factory AuthResult.success({required User user, required String token}) {
    return AuthResult._(isSuccess: true, user: user, token: token);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}

class _MockUser {
  final User user;
  String password;
  _MockUser({required this.user, required this.password});
}
