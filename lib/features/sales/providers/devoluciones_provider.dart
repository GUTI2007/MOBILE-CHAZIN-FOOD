// lib/features/sales/providers/devoluciones_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/devolucion_model.dart';
import '../data/devoluciones_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────
class DevolucionesState {
  final List<Devolucion> devoluciones;
  final bool isLoading;
  final String? error;

  const DevolucionesState({
    this.devoluciones = const [],
    this.isLoading = false,
    this.error,
  });

  DevolucionesState copyWith({
    List<Devolucion>? devoluciones,
    bool? isLoading,
    String? error,
  }) =>
      DevolucionesState(
        devoluciones: devoluciones ?? this.devoluciones,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  List<Devolucion> get pendientes =>
      devoluciones.where((d) => d.isPendiente).toList();
}

// ── Notifier ───────────────────────────────────────────────────────────────
class DevolucionesNotifier extends StateNotifier<DevolucionesState> {
  final DevolucionesRepository _repo;

  DevolucionesNotifier(this._repo) : super(const DevolucionesState());

  Future<void> loadDevoluciones() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getDevoluciones();
      state = state.copyWith(devoluciones: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Provider ───────────────────────────────────────────────────────────────
final devolucionesProvider =
    StateNotifierProvider<DevolucionesNotifier, DevolucionesState>((ref) {
  final client = ref.read(apiClientProvider);
  return DevolucionesNotifier(DevolucionesRepository(client));
});
