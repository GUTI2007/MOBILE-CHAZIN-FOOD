import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/models/client_model.dart';

/// Repositorio de Ventas conectado a la API /api/ventas
class SalesRepository {
  final ApiClient _apiClient;

  SalesRepository(this._apiClient);

  /// Obtener ventas desde /api/ventas
  Future<List<Sale>> getSales() async {
    try {
      final response = await _apiClient.get('/ventas');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) => Sale.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Crear venta en /api/ventas
  Future<Sale?> createSale({
    required String clientId,
    required String clientName,
    required List<SaleDetail> details,
    required double subtotal,
    required double discount,
    required double total,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ventas',
        data: {
          'idCliente': clientId,
          'cliente': clientName,
          'detalles': details.map((d) => d.toJson()).toList(),
          'subtotal': subtotal,
          'descuento': discount,
          'total': total,
          'metodoPago': paymentMethod.name,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return Sale.fromJson(Map<String, dynamic>.from(response.data));
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al registrar venta.');
    } catch (e) {
      throw Exception('Error al registrar venta: $e');
    }
  }

  /// Obtener clientes desde /api/clientes
  Future<List<Client>> getClients() async {
    try {
      final response = await _apiClient.get('/clientes');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item);
          return Client(
            id: m['id_cliente']?.toString() ?? m['id']?.toString() ?? '',
            name: m['nombre']?.toString() ?? m['name']?.toString() ?? 'Cliente',
            email: m['email']?.toString() ?? m['correo']?.toString(),
            phone: m['telefono']?.toString() ?? m['phone']?.toString(),
            loyaltyPoints: m['puntos_fidelidad'] is int ? m['puntos_fidelidad'] : 0,
            isActive: m['estado'] == 1 || m['estado'] == 'Activo' || m['estado'] == true,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Obtener estadísticas de dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/dashboard/stats');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
