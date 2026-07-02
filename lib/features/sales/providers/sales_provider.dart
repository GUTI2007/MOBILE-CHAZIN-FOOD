import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/models/client_model.dart';
import '../../../shared/models/product_model.dart';
import '../data/mock_sales_repository.dart';

/// Provider del repositorio
final salesRepositoryProvider = Provider<MockSalesRepository>((ref) {
  return MockSalesRepository();
});

// ════════════════════════════════════════════
// SALES LIST STATE
// ════════════════════════════════════════════

class SalesState {
  final List<Sale> sales;
  final bool isLoading;
  final String? error;

  const SalesState({
    this.sales = const [],
    this.isLoading = false,
    this.error,
  });

  SalesState copyWith({
    List<Sale>? sales,
    bool? isLoading,
    String? error,
  }) {
    return SalesState(
      sales: sales ?? this.sales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SalesNotifier extends StateNotifier<SalesState> {
  final MockSalesRepository _repository;

  SalesNotifier(this._repository) : super(const SalesState());

  Future<void> loadSales() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sales = await _repository.getSales();
      state = state.copyWith(sales: sales, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final salesProvider = StateNotifierProvider<SalesNotifier, SalesState>((ref) {
  final repository = ref.read(salesRepositoryProvider);
  return SalesNotifier(repository);
});

// ════════════════════════════════════════════
// CART / NEW SALE STATE
// ════════════════════════════════════════════

class NewSaleState {
  final int currentStep;
  final Client? selectedClient;
  final List<CartItem> cartItems;
  final double subtotal;
  final double discount;
  final double total;
  final PaymentMethod? paymentMethod;
  final bool isProcessing;
  final bool isCompleted;
  final String? error;

  const NewSaleState({
    this.currentStep = 0,
    this.selectedClient,
    this.cartItems = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.total = 0,
    this.paymentMethod,
    this.isProcessing = false,
    this.isCompleted = false,
    this.error,
  });

  NewSaleState copyWith({
    int? currentStep,
    Client? selectedClient,
    List<CartItem>? cartItems,
    double? subtotal,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    bool? isProcessing,
    bool? isCompleted,
    String? error,
    bool clearClient = false,
    bool clearPayment = false,
  }) {
    return NewSaleState(
      currentStep: currentStep ?? this.currentStep,
      selectedClient: clearClient ? null : (selectedClient ?? this.selectedClient),
      cartItems: cartItems ?? this.cartItems,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
      isProcessing: isProcessing ?? this.isProcessing,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return selectedClient != null;
      case 1:
        return cartItems.isNotEmpty;
      case 2:
        return true; // Total siempre calculado
      case 3:
        return true; // Fidelización opcional
      case 4:
        return paymentMethod != null;
      default:
        return false;
    }
  }
}

class NewSaleNotifier extends StateNotifier<NewSaleState> {
  final MockSalesRepository _repository;

  NewSaleNotifier(this._repository) : super(const NewSaleState());

  void selectClient(Client client) {
    state = state.copyWith(selectedClient: client);
  }

  void addProduct(Product product) {
    final items = List<CartItem>.from(state.cartItems);
    final existingIndex = items.indexWhere((i) => i.product.id == product.id);

    if (existingIndex >= 0) {
      items[existingIndex].quantity++;
    } else {
      items.add(CartItem(product: product));
    }

    _recalculate(items);
  }

  void removeProduct(String productId) {
    final items = List<CartItem>.from(state.cartItems);
    items.removeWhere((i) => i.product.id == productId);
    _recalculate(items);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final items = List<CartItem>.from(state.cartItems);
    final index = items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      items[index].quantity = quantity;
    }
    _recalculate(items);
  }

  void _recalculate(List<CartItem> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    // Descuento de fidelización: si el cliente tiene >200 puntos, 5% descuento
    final loyaltyDiscount = (state.selectedClient?.loyaltyPoints ?? 0) > 200
        ? subtotal * 0.05
        : 0.0;
    final total = subtotal - loyaltyDiscount;

    state = state.copyWith(
      cartItems: items,
      subtotal: subtotal,
      discount: loyaltyDiscount,
      total: total,
    );
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<bool> confirmSale() async {
    if (state.selectedClient == null || state.cartItems.isEmpty || state.paymentMethod == null) {
      return false;
    }

    state = state.copyWith(isProcessing: true, error: null);

    try {
      final details = state.cartItems.map((item) => SaleDetail(
        id: 'sd_${DateTime.now().millisecondsSinceEpoch}_${item.product.id}',
        productId: item.product.id,
        productName: item.product.name,
        unitPrice: item.product.price,
        quantity: item.quantity,
        subtotal: item.subtotal,
      )).toList();

      await _repository.createSale(
        clientId: state.selectedClient!.id,
        clientName: state.selectedClient!.name,
        details: details,
        subtotal: state.subtotal,
        discount: state.discount,
        total: state.total,
        paymentMethod: state.paymentMethod!,
      );

      state = state.copyWith(isProcessing: false, isCompleted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const NewSaleState();
  }
}

final newSaleProvider = StateNotifierProvider<NewSaleNotifier, NewSaleState>((ref) {
  final repository = ref.read(salesRepositoryProvider);
  return NewSaleNotifier(repository);
});

/// Provider de clientes
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final repository = ref.read(salesRepositoryProvider);
  return repository.getClients();
});

/// Provider de stats del dashboard
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(salesRepositoryProvider);
  return repository.getDashboardStats();
});
