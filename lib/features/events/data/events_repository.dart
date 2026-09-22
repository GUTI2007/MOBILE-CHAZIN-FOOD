import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/event_model.dart';

/// Repositorio de Eventos conectado directamente al backend /api/eventos
class EventsRepository {
  final ApiClient _apiClient;

  EventsRepository(this._apiClient);

  /// Obtener listado de eventos desde /api/eventos
  Future<List<Event>> getEvents() async {
    try {
      final response = await _apiClient.get('/eventos');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list
            .map((item) => Event.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error al cargar eventos de la API.',
      );
    } catch (e) {
      throw Exception('Error inesperado al cargar eventos: $e');
    }
  }

  /// Crear un nuevo evento en /api/eventos
  Future<Event> createEvent(Event event) async {
    try {
      final response = await _apiClient.post(
        '/eventos',
        data: event.toJson(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return Event.fromJson(Map<String, dynamic>.from(response.data));
      }
      throw Exception('Respuesta inválida del servidor al crear el evento.');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          (e.response?.data is Map ? e.response?.data['error'] : null) ??
          'Error al conectar con la API al crear el evento.';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error inesperado al crear el evento: $e');
    }
  }

  /// Actualizar evento existente
  Future<Event> updateEvent(int id, Event event) async {
    try {
      final response = await _apiClient.put(
        '/eventos/$id',
        data: event.toJson(),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Event.fromJson(Map<String, dynamic>.from(response.data));
      }
      throw Exception('No se pudo actualizar el evento en la API.');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error al actualizar evento.',
      );
    } catch (e) {
      throw Exception('Error al actualizar el evento: $e');
    }
  }

  /// Eliminar un evento
  Future<bool> deleteEvent(int id) async {
    try {
      final response = await _apiClient.delete('/eventos/$id');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
