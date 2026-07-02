/// Cliente
class Client {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final int loyaltyPoints;
  final bool isActive;

  const Client({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.loyaltyPoints = 0,
    this.isActive = true,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}
