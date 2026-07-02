import '../../../shared/models/sale_model.dart';
import '../../../shared/models/client_model.dart';

/// Repositorio mock de ventas y clientes
class MockSalesRepository {
  final List<Sale> _sales = List.from(_initialSales);
  final List<Client> _clients = List.from(_initialClients);

  // ─── Clientes ───
  static final List<Client> _initialClients = [
    const Client(id: 'cli_01', name: 'Juan García', email: 'juan@email.com', phone: '3001234567', loyaltyPoints: 150),
    const Client(id: 'cli_02', name: 'María López', email: 'maria@email.com', phone: '3009876543', loyaltyPoints: 320),
    const Client(id: 'cli_03', name: 'Carlos Díaz', email: 'carlos@email.com', phone: '3005551234', loyaltyPoints: 80),
    const Client(id: 'cli_04', name: 'Laura Torres', email: 'laura@email.com', phone: '3007778899', loyaltyPoints: 500),
    const Client(id: 'cli_05', name: 'Diego Morales', email: 'diego@email.com', phone: '3003334455', loyaltyPoints: 45),
    const Client(id: 'cli_06', name: 'Sofía Hernández', email: 'sofia@email.com', phone: '3006667788', loyaltyPoints: 210),
    const Client(id: 'cli_07', name: 'Andrés Castro', email: 'andres@email.com', phone: '3002223344', loyaltyPoints: 90),
    const Client(id: 'cli_08', name: 'Valentina Ruiz', email: 'vale@email.com', phone: '3008889900', loyaltyPoints: 175),
  ];

  // ─── Ventas mock ───
  // All within June 2026 (the current month from the mockup context)
  // Total: $296,400  |  Discounts: $13,600
  static final List<Sale> _initialSales = [
    // PED-001 — Juan García — Domicilio — Efectivo — $28,000
    Sale(
      id: 'sale_001', clientId: 'cli_01', clientName: 'Juan García',
      details: const [
        SaleDetail(id: 'sd_001a', productId: 'prod_001', productName: 'Hamburguesa Especial', unitPrice: 15000, quantity: 1, subtotal: 15000, addOns: ['Queso Extra', 'Salsa BBQ']),
        SaleDetail(id: 'sd_001b', productId: 'prod_008', productName: 'Coca Cola', unitPrice: 3000, quantity: 1, subtotal: 3000),
        SaleDetail(id: 'sd_001c', productId: 'prod_010', productName: 'Papas Fritas', unitPrice: 6000, quantity: 2, subtotal: 12000),
      ],
      subtotal: 28000, discount: 0, total: 28000,
      paymentMethod: PaymentMethod.cash, status: SaleStatus.completed,
      deliveryType: DeliveryType.delivery,
      createdAt: DateTime(2026, 6, 9, 12, 30),
      endAt: DateTime(2026, 6, 9, 12, 45),
    ),

    // PED-002 — María López — En Mesa — Tarjeta — $40,500
    Sale(
      id: 'sale_002', clientId: 'cli_02', clientName: 'María López',
      details: const [
        SaleDetail(id: 'sd_002a', productId: 'prod_005', productName: 'Combo Familiar', unitPrice: 45000, quantity: 1, subtotal: 45000),
      ],
      subtotal: 45000, discount: 4500, total: 40500,
      paymentMethod: PaymentMethod.card, status: SaleStatus.completed,
      deliveryType: DeliveryType.dineIn,
      createdAt: DateTime(2026, 6, 9, 13, 5),
      endAt: DateTime(2026, 6, 9, 13, 20),
    ),

    // PED-003 — Carlos Pérez — Para llevar — Efectivo — $22,000
    Sale(
      id: 'sale_003', clientId: 'cli_03', clientName: 'Carlos Pérez',
      details: const [
        SaleDetail(id: 'sd_003a', productId: 'prod_001', productName: 'Pollo Broaster', unitPrice: 18000, quantity: 1, subtotal: 18000),
        SaleDetail(id: 'sd_003b', productId: 'prod_002', productName: 'Sprite', unitPrice: 4000, quantity: 1, subtotal: 4000),
      ],
      subtotal: 22000, discount: 0, total: 22000,
      paymentMethod: PaymentMethod.cash, status: SaleStatus.completed,
      deliveryType: DeliveryType.takeout,
      createdAt: DateTime(2026, 6, 9, 13, 45),
      endAt: DateTime(2026, 6, 9, 14, 0),
    ),

    // PED-004 — Diego Morales — En Mesa — Tarjeta — $18,000
    Sale(
      id: 'sale_004', clientId: 'cli_05', clientName: 'Diego Morales',
      details: const [
        SaleDetail(id: 'sd_004a', productId: 'prod_009', productName: 'Malteada de Chocolate', unitPrice: 12000, quantity: 1, subtotal: 12000),
        SaleDetail(id: 'sd_004b', productId: 'prod_010', productName: 'Papas Fritas', unitPrice: 6000, quantity: 1, subtotal: 6000),
      ],
      subtotal: 18000, discount: 0, total: 18000,
      paymentMethod: PaymentMethod.card, status: SaleStatus.completed,
      deliveryType: DeliveryType.dineIn,
      createdAt: DateTime(2026, 6, 15, 13, 0),
      endAt: DateTime(2026, 6, 15, 13, 25),
    ),

    // PED-005 — Laura Torres — Domicilio — Efectivo — $54,000
    Sale(
      id: 'sale_005', clientId: 'cli_04', clientName: 'Laura Torres',
      details: const [
        SaleDetail(id: 'sd_005a', productId: 'prod_014', productName: 'Combo Pizza Familiar', unitPrice: 59000, quantity: 1, subtotal: 59000),
      ],
      subtotal: 59000, discount: 5000, total: 54000,
      paymentMethod: PaymentMethod.cash, status: SaleStatus.completed,
      deliveryType: DeliveryType.delivery,
      createdAt: DateTime(2026, 6, 18, 19, 30),
      endAt: DateTime(2026, 6, 18, 19, 55),
    ),

    // PED-006 — Andrés Castro — En Mesa — Tarjeta — $25,000
    Sale(
      id: 'sale_006', clientId: 'cli_07', clientName: 'Andrés Castro',
      details: const [
        SaleDetail(id: 'sd_006a', productId: 'prod_004', productName: 'Pizza Margarita', unitPrice: 25000, quantity: 1, subtotal: 25000),
      ],
      subtotal: 25000, discount: 0, total: 25000,
      paymentMethod: PaymentMethod.card, status: SaleStatus.completed,
      deliveryType: DeliveryType.dineIn,
      createdAt: DateTime(2026, 6, 20, 12, 0),
      endAt: DateTime(2026, 6, 20, 12, 30),
    ),

    // PED-007 — Sofía Hernández — Para llevar — Efectivo — $30,000
    Sale(
      id: 'sale_007', clientId: 'cli_06', clientName: 'Sofía Hernández',
      details: const [
        SaleDetail(id: 'sd_007a', productId: 'prod_006', productName: 'Pizza Hawaiana', unitPrice: 30000, quantity: 1, subtotal: 30000, addOns: ['Borde relleno']),
      ],
      subtotal: 33600, discount: 3600, total: 30000,
      paymentMethod: PaymentMethod.cash, status: SaleStatus.completed,
      deliveryType: DeliveryType.takeout,
      createdAt: DateTime(2026, 6, 22, 20, 15),
      endAt: DateTime(2026, 6, 22, 20, 30),
    ),

    // PED-008 — Valentina Ruiz — Domicilio — Tarjeta — $22,000
    Sale(
      id: 'sale_008', clientId: 'cli_08', clientName: 'Valentina Ruiz',
      details: const [
        SaleDetail(id: 'sd_008a', productId: 'prod_003', productName: 'Hamburguesa Pollo Crispy', unitPrice: 22000, quantity: 1, subtotal: 22000),
      ],
      subtotal: 22500, discount: 500, total: 22000,
      paymentMethod: PaymentMethod.card, status: SaleStatus.completed,
      deliveryType: DeliveryType.delivery,
      createdAt: DateTime(2026, 6, 25, 10, 0),
      endAt: DateTime(2026, 6, 25, 10, 20),
    ),

    // PED-009 — Juan García — En Mesa — Efectivo — $27,400
    Sale(
      id: 'sale_009', clientId: 'cli_01', clientName: 'Juan García',
      details: const [
        SaleDetail(id: 'sd_009a', productId: 'prod_008', productName: 'Limonada Natural', unitPrice: 6850, quantity: 4, subtotal: 27400),
      ],
      subtotal: 27400, discount: 0, total: 27400,
      paymentMethod: PaymentMethod.cash, status: SaleStatus.completed,
      deliveryType: DeliveryType.dineIn,
      createdAt: DateTime(2026, 6, 27, 15, 45),
      endAt: DateTime(2026, 6, 27, 16, 0),
    ),

    // PED-010 — Ana García — Para llevar — Tarjeta — $29,500
    Sale(
      id: 'sale_010', clientId: 'cli_02', clientName: 'Ana García',
      details: const [
        SaleDetail(id: 'sd_010a', productId: 'prod_011', productName: 'Cheesecake de Frutos Rojos', unitPrice: 15000, quantity: 1, subtotal: 15000),
        SaleDetail(id: 'sd_010b', productId: 'prod_001', productName: 'Hamburguesa Especial', unitPrice: 14500, quantity: 1, subtotal: 14500),
      ],
      subtotal: 29500, discount: 0, total: 29500,
      paymentMethod: PaymentMethod.card, status: SaleStatus.completed,
      deliveryType: DeliveryType.takeout,
      createdAt: DateTime(2026, 6, 28, 11, 20),
      endAt: DateTime(2026, 6, 28, 11, 35),
    ),
  ];

  // ─── Operaciones ───

  Future<List<Sale>> getSales() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.from(_sales)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Sale?> getSaleById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sales.cast<Sale?>().firstWhere((s) => s!.id == id, orElse: () => null);
  }

  Future<void> addSale(Sale sale) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _sales.add(sale);
  }

  Future<void> createSale({
    required String clientId,
    required String clientName,
    required List<SaleDetail> details,
    required double subtotal,
    required double discount,
    required double total,
    required PaymentMethod paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newSale = Sale(
      id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      clientName: clientName,
      details: details,
      subtotal: subtotal,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      status: SaleStatus.completed,
      createdAt: DateTime.now(),
      deliveryType: DeliveryType.dineIn,
    );
    _sales.add(newSale);
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final totalVentas = _sales.fold<double>(0, (sum, s) => sum + s.total);
    final totalOrders = _sales.length;
    final totalDiscounts = _sales.fold<double>(0, (sum, s) => sum + s.discount);
    final ticketAverage = totalOrders > 0 ? totalVentas / totalOrders : 0.0;

    return {
      'totalSales': totalVentas,
      'ordersCount': totalOrders,
      'discountsCount': totalDiscounts,
      'ticketAverage': ticketAverage,
    };
  }

  Future<List<Client>> getClients() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_clients);
  }
}
