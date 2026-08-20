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
  final bool isLoading;
  final String? error;

  DashboardState({
    DashboardStats? stats,
    this.ventasChart = const [],
    this.alertasStock = const [],
    this.productosPopulares = const [],
    this.isLoading = false,
    this.error,
  }) : stats = stats ?? DashboardStats.defaultStats();

  DashboardState copyWith({
    DashboardStats? stats,
    List<VentasChartData>? ventasChart,
    List<StockAlertItem>? alertasStock,
    List<PopularProductItem>? productosPopulares,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      ventasChart: ventasChart ?? this.ventasChart,
      alertasStock: alertasStock ?? this.alertasStock,
      productosPopulares: productosPopulares ?? this.productosPopulares,
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

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _repository.getStats();
      final chart = await _repository.getVentasChart();
      final alerts = await _repository.getAlertasStock();
      final popular = await _repository.getProductosPopulares();

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
final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repository);
});
