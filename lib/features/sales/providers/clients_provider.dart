import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/client_model.dart';

final clientsListProvider = FutureProvider<List<Client>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/clientes');
    if (response.statusCode == 200 && response.data is List) {
      final List list = response.data;
      return list.map((item) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(item);
        return Client(
          id: json['id_cliente']?.toString() ?? json['id']?.toString() ?? '',
          name: json['nombre']?.toString() ?? json['name']?.toString() ?? 'Cliente',
          email: json['email']?.toString() ?? json['correo']?.toString(),
          phone: json['telefono']?.toString() ?? json['phone']?.toString(),
          loyaltyPoints: json['puntos_fidelidad'] is int ? json['puntos_fidelidad'] : 0,
          isActive: json['estado'] == 1 || json['estado'] == 'Activo' || json['estado'] == true,
        );
      }).toList();
    }
    return [];
  } catch (_) {
    return [];
  }
});
