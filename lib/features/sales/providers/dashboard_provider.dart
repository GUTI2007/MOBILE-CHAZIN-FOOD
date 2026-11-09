import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/dashboard_stats_model.dart';
import '../data/dashboard_repository.dart';

/// Provider del repositorio de Dashboard
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

/// Estado del Dashboard
class DashboardState {
  final DashboardStats stats;
  final List<VentasChartData> ventasChart;
  final List<StockAlertItem> alertasStock;
  final List<PopularProductItem> productosPopulares;
  final String currentPeriodo;
  final bool isLoading;
  final String? error;

  DashboardState({
    DashboardStats? stats,
    this.ventasChart = const [],
    this.alertasStock = const [],
    this.productosPopulares = const [],
    this.currentPeriodo = 'Mes Actual',
    this.isLoading = false,
    this.error,
  }) : stats = stats ?? DashboardStats.defaultStats();

  DashboardState copyWith({
    DashboardStats? stats,
    List<VentasChartData>? ventasChart,
    List<StockAlertItem>? alertasStock,
    List<PopularProductItem>? productosPopulares,
    String? currentPeriodo,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      ventasChart: ventasChart ?? this.ventasChart,
      alertasStock: alertasStock ?? this.alertasStock,
      productosPopulares: productosPopulares ?? this.productosPopulares,
      currentPeriodo: currentPeriodo ?? this.currentPeriodo,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para el Dashboard
class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(DashboardState()) {
    loadDashboardData();
  }

  String _mapPeriodToBackend(String? periodo) {
    if (periodo == null) return 'mes_actual';
    final p = periodo.trim().toLowerCase();
    // Períodos simples primero
    if (p == 'hoy') return 'hoy';
    if (p == '2026') return '2026';
    if (p.contains('histor')) return 'historico';
    // 7 días
    if (p.contains('7') && (p.contains('d') || p.contains('sem'))) return '7_dias';
    // Mes
    if (p.contains('3') && p.contains('mes')) return 'ultimos_3_meses';
    if (p.contains('6') && p.contains('mes')) return 'ultimos_6_meses';
    if (p.contains('anterior') && p.contains('mes')) return 'mes_anterior';
    if (p.contains('mes')) return 'mes_actual';
    // Año — verificar con 'año' o 'ano', no con 'a' genérico
    if (p.contains('anterior') && (p.contains('año') || p.contains('ano'))) return 'ano_anterior';
    if (p.contains('año') || p.contains('ano')) return 'ano_actual';
    return 'mes_actual';
  }

  Future<void> loadDashboardData({String? periodo}) async {
    final selectedLabel = periodo ?? state.currentPeriodo;
    final backendPeriod = _mapPeriodToBackend(selectedLabel);
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPeriodo: selectedLabel,
    );
    try {
      final stats = await _repository.getStats(periodo: backendPeriod);
      final chart = await _repository.getVentasChart(periodo: backendPeriod);
      final alerts = await _repository.getAlertasStock();
      final popular = await _repository.getProductosPopulares(
        periodo: backendPeriod,
      );

      state = state.copyWith(
        stats: stats,
        ventasChart: chart,
        alertasStock: alerts,
        productosPopulares: popular,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider global del Dashboard
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final repository = ref.watch(dashboardRepositoryProvider);
      return DashboardNotifier(repository);
    });
