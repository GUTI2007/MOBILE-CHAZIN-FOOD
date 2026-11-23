// lib/features/sales/data/devoluciones_repository.dart

import '../../../config/api/api_client.dart';
import '../../../shared/models/devolucion_model.dart';

class DevolucionesRepository {
  final ApiClient _client;

  DevolucionesRepository(this._client);

  Future<List<Devolucion>> getDevoluciones() async {
    try {
      final resp = await _client.get('/devoluciones');
      final data = resp.data;
      List rawList = [];

      if (data is List) {
        rawList = data;
      } else if (data is Map) {
        if (data['devoluciones'] is List) {
          rawList = data['devoluciones'] as List;
        } else if (data['data'] is List) {
          rawList = data['data'] as List;
        } else if (data['result'] is List) {
          rawList = data['result'] as List;
        }
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((j) => Devolucion.fromJson(j))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
