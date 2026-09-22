/// Cliente
class Client {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final int loyaltyPoints;
  final double totalSpent;
  final bool isActive;

  const Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.loyaltyPoints = 0,
    this.totalSpent = 0.0,
    this.isActive = true,
  });

  String get initials {
    if (name.isEmpty) return 'CL';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
