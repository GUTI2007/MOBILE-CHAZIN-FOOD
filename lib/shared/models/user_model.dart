/// Roles del sistema
enum UserRole { admin, employee }

/// Modelo de usuario
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final String? token;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.token,
  });

  /// Parseo fromJson para homologar con la API del Backend (Express)
  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['idUsuario'] ?? json['id'] ?? json['_id'] ?? '';
    final rawNombre = json['nombre'] ?? json['name'] ?? '';
    final rawApellidos = json['apellidos'] ?? json['apellido'] ?? '';
    final fullName = '$rawNombre $rawApellidos'.trim();
    final emailStr = json['email'] ?? json['correo'] ?? '';
    final rolStr = (json['rol'] ?? json['role'] ?? '').toString().toLowerCase();

    UserRole role = UserRole.employee;
    if (rolStr.contains('admin')) {
      role = UserRole.admin;
    }

    final estado = json['estado'];
    final isActive = estado == null || estado == 'ACTIVO' || estado == 1 || estado == true || estado == 'Activo';

    return User(
      id: rawId.toString(),
      name: fullName.isEmpty ? 'Usuario' : fullName,
      email: emailStr,
      role: role,
      avatarUrl: json['avatarUrl'] ?? json['imagen'],
      isActive: isActive,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'rol': roleName,
      'isActive': isActive,
      if (token != null) 'token': token,
    };
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  String get roleName {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.employee:
        return 'Empleado';
    }
  }

  bool get isAdmin => role == UserRole.admin;
}
