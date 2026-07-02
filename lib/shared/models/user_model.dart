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

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
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
