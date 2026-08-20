import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/dashboard_stats_model.dart';

/// Repositorio de Estadísticas y Métricas del Dashboard (/api/dashboard/*)
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  /// Obtener métricas resumidas desde /api/dashboard/stats
  Future<DashboardStats> getStats() async {
    try {
      final response = await _apiClient.get('/dashboard/stats');
      if (response.statusCode == 200 && response.data is Map) {
        return DashboardStats.fromJson(Map<String, dynamic>.from(response.data));
      }
      return DashboardStats.defaultStats();
    } on DioException catch (_) {
      return DashboardStats.defaultStats();
    } catch (_) {
      return DashboardStats.defaultStats();
    }
  }

  /// Obtener datos para gráfico de ventas y compras desde /api/dashboard/ventas-chart
  Future<List<VentasChartData>> getVentasChart() async {
    try {
      final response = await _apiClient.get('/dashboard/ventas-chart');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) => VentasChartData.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return _defaultVentasChart();
    } catch (_) {
      return _defaultVentasChart();
    }
  }

  /// Obtener alertas de stock desde /api/dashboard/alertas-stock
  Future<List<StockAlertItem>> getAlertasStock() async {
    try {
      final response = await _apiClient.get('/dashboard/alertas-stock');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) => StockAlertItem.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return _defaultAlertasStock();
    } catch (_) {
      return _defaultAlertasStock();
    }
  }

  /// Obtener productos populares desde /api/dashboard/productos-populares
  Future<List<PopularProductItem>> getProductosPopulares() async {
    try {
      final response = await _apiClient.get('/dashboard/productos-populares');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) => PopularProductItem.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return _defaultProductosPopulares();
    } catch (_) {
      return _defaultProductosPopulares();
    }
  }

  // Fallbacks estáticos si el servidor no está corriendo durante desarrollo UI
  List<VentasChartData> _defaultVentasChart() {
    return const [
      VentasChartData(mes: 'Ene', ventas: 12000, compras: 7500),
      VentasChartData(mes: 'Feb', ventas: 15200, compras: 9500),
      VentasChartData(mes: 'Mar', ventas: 19000, compras: 11000),
      VentasChartData(mes: 'Abr', ventas: 22000, compras: 13500),
      VentasChartData(mes: 'May', ventas: 26000, compras: 15000),
      VentasChartData(mes: 'Jun', ventas: 28000, compras: 16500),
    ];
  }

  List<StockAlertItem> _defaultAlertasStock() {
    return const [
      StockAlertItem(id: '1', nombre: 'Pan de Hamburguesa', stock: 15, minimo: 50),
      StockAlertItem(id: '2', nombre: 'Salchicha Premium', stock: 8, minimo: 30),
      StockAlertItem(id: '3', nombre: 'Papas Congeladas', stock: 12, minimo: 40),
      StockAlertItem(id: '4', nombre: 'Queso Mozzarella', stock: 6, minimo: 20),
      StockAlertItem(id: '5', nombre: 'Tomate', stock: 9, minimo: 25),
    ];
  }

  List<PopularProductItem> _defaultProductosPopulares() {
    return const [
      PopularProductItem(id: '1', nombre: 'Hamburguesa Especial', ventas: 240),
      PopularProductItem(id: '2', nombre: 'Salchipapa Grande', ventas: 195),
      PopularProductItem(id: '3', nombre: 'Perro Caliente', ventas: 80),
      PopularProductItem(id: '4', nombre: 'Pollo Broaster', ventas: 80),
      PopularProductItem(id: '5', nombre: 'Papas Fritas', ventas: 120),
    ];
  }
}
