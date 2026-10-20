import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order.dart';
import '../data/sales_repository.dart';
import '../../../config/api/api_client.dart';

/// Provider del repositorio de ventas
final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SalesRepository(apiClient);
});

/// Estado de los pedidos
class OrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final bool usingMock;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.usingMock = false,
  });

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    bool? usingMock,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      usingMock: usingMock ?? this.usingMock,
    );
  }
}

/// Notifier para manejar los pedidos desde la API real
class OrdersNotifier extends StateNotifier<OrdersState> {
  final SalesRepository _repository;

  OrdersNotifier(this._repository) : super(const OrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sales = await _repository.getSales();

      if (sales.isEmpty) {
        // Si la API no retorna datos, usar mock
        state = state.copyWith(
          orders: pedidosMock,
          isLoading: false,
          usingMock: true,
        );
        return;
      }

      // Mapear Sale → Order
      final orders = sales.map((sale) {
        final detalles = sale.details.map((d) {
          return DetallePedido(
            nombre: d.productName,
            cantidad: d.quantity,
            precio: d.unitPrice,
            adiciones: d.addOns,
          );
        }).toList();

        String metodoPago;
        switch (sale.paymentMethod.name) {
          case 'card':
            metodoPago = 'tarjeta';
            break;
          case 'transfer':
            metodoPago = 'transferencia';
            break;
          default:
            metodoPago = 'efectivo';
        }

        String tipoEntrega;
        switch (sale.deliveryType.name) {
          case 'delivery':
            tipoEntrega = 'domicilio';
            break;
          case 'takeout':
            tipoEntrega = 'recoger';
            break;
          default:
            tipoEntrega = 'mesa';
        }

        final hora = '${sale.createdAt.hour.toString().padLeft(2, '0')}:${sale.createdAt.minute.toString().padLeft(2, '0')}';
        final horaFin = sale.endAt != null
            ? '${sale.endAt!.hour.toString().padLeft(2, '0')}:${sale.endAt!.minute.toString().padLeft(2, '0')}'
            : hora;

        final num = sale.id.replaceAll(RegExp(r'[^0-9]'), '');
        final displayId = 'PED-${num.padLeft(3, '0')}';

        return Order(
          id: displayId,
          cliente: sale.clientName,
          fecha: sale.formattedDate,
          hora: hora,
          horaFin: horaFin,
          estado: sale.statusName == 'Pagado' ? 'pagado' : 'pendiente',
          metodoPago: metodoPago,
          tipoEntrega: tipoEntrega,
          subtotal: sale.subtotal,
          descuento: sale.discount,
          total: sale.total,
          detalle: detalles,
        );
      }).toList();

      // Ordenar por fecha descendente
      orders.sort((a, b) {
        int dateComp = b.fecha.compareTo(a.fecha);
        if (dateComp != 0) return dateComp;
        return b.hora.compareTo(a.hora);
      });

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        usingMock: false,
      );
    } catch (e) {
      // Fallback a datos mock si la API falla (sin Internet, dev offline, etc.)
      state = state.copyWith(
        orders: pedidosMock,
        isLoading: false,
        error: e.toString(),
        usingMock: true,
      );
    }
  }

  /// Fuerza una recarga desde la API
  Future<void> refresh() => loadOrders();
}

/// Provider global de pedidos
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final repository = ref.watch(salesRepositoryProvider);
  return OrdersNotifier(repository);
});
