/// Roles del sistema
enum UserRole { admin, employee, cashier, chef }

/// Modelo de usuario administrativo
class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final bool isActive;
  final String? token;
  
  // Campos administrativos extendidos para la Gestión de Usuarios
  final String tipoDocumento;
  final String documento;
  final String telefono;
  final String fechaRegistro;
  final String ultimoAcceso;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.isActive = true,
    this.token,
    this.tipoDocumento = 'C.C.',
    this.documento = '1.098.765.432',
    this.telefono = '+57 300 000 0000',
    this.fechaRegistro = '15/01/2024',
    this.ultimoAcceso = 'Hoy, 10:45 AM',
  });

  /// Parseo fromJson para homologar con la API del Backend
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
    } else if (rolStr.contains('cajer') || rolStr.contains('cashier')) {
      role = UserRole.cashier;
    } else if (rolStr.contains('cocin') || rolStr.contains('chef')) {
      role = UserRole.chef;
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
      tipoDocumento: json['tipoDocumento'] ?? 'C.C.',
      documento: json['documento'] ?? json['cedula'] ?? '1.098.765.432',
      telefono: json['telefono'] ?? '+57 300 000 0000',
      fechaRegistro: json['fechaRegistro'] ?? '15/01/2024',
      ultimoAcceso: json['ultimoAcceso'] ?? 'Hace un momento',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'rol': roleName,
      'isActive': isActive,
      'tipoDocumento': tipoDocumento,
      'documento': documento,
      'telefono': telefono,
      'fechaRegistro': fechaRegistro,
      'ultimoAcceso': ultimoAcceso,
      if (token != null) 'token': token,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    bool? isActive,
    String? token,
    String? tipoDocumento,
    String? documento,
    String? telefono,
    String? fechaRegistro,
    String? ultimoAcceso,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
      token: token ?? this.token,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      telefono: telefono ?? this.telefono,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      ultimoAcceso: ultimoAcceso ?? this.ultimoAcceso,
    );
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
      case UserRole.cashier:
        return 'Cajero';
      case UserRole.chef:
        return 'Cocinero';
    }
  }

  bool get isAdmin => role == UserRole.admin;
}
