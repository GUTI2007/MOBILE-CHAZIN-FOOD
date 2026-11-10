import 'product_model.dart';

/// Método de pago
enum PaymentMethod { cash, card, transfer }

/// Estado de la venta
enum SaleStatus { pending, completed, cancelled }

/// Tipo de entrega
enum DeliveryType { dineIn, delivery, takeout }

/// Item del carrito
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;
}

/// Detalle de venta
class SaleDetail {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final List<String> addOns;

  const SaleDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.addOns = const [],
  });

  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      id: (json['id'] ?? json['idDetalleVenta'] ?? json['idVariante'] ?? json['_id'])?.toString() ?? '',
      productId: (json['idVariante'] ?? json['productId'] ?? json['productoId'] ?? json['producto'])?.toString() ?? '',
      productName: json['nombre']?.toString() ?? json['productName']?.toString() ?? json['nombreProducto']?.toString() ?? json['productoNombre']?.toString() ?? '',
      unitPrice: (json['precioUnitario'] ?? json['unitPrice'] ?? json['precio'] ?? 0).toDouble(),
      quantity: (json['cantidad'] ?? json['quantity'] ?? 1).toInt(),
      subtotal: (json['total'] ?? json['subtotal'] ?? 0).toDouble(),
      addOns: (json['adiciones'] as List<dynamic>?)?.map((a) {
        if (a is Map) return a['nombre']?.toString() ?? '';
        return a.toString();
      }).where((s) => s.isNotEmpty).toList() ?? (json['addOns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'addOns': addOns,
    };
  }
}

/// Venta
class Sale {
  final String id;
  final String clientId;
  final String clientName;
  final List<SaleDetail> details;
  final double subtotal;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final DateTime createdAt;
  final DateTime? endAt;
  final DeliveryType deliveryType;
  final String? notes;

  const Sale({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.details,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.endAt,
    this.deliveryType = DeliveryType.dineIn,
    this.notes,
  });

  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
    }
  }

  String get deliveryTypeName {
    switch (deliveryType) {
      case DeliveryType.dineIn:
        return 'En Mesa';
      case DeliveryType.delivery:
        return 'Domicilio';
      case DeliveryType.takeout:
        return 'Para llevar';
    }
  }

  String get statusName {
    switch (status) {
      case SaleStatus.pending:
        return 'Pendiente';
      case SaleStatus.completed:
        return 'Pagado';
      case SaleStatus.cancelled:
        return 'Cancelada';
    }
  }

  int get totalItems => details.fold(0, (sum, d) => sum + d.quantity);

  /// Display ID in PED-001 format
  String get displayId {
    final num = id.replaceAll(RegExp(r'[^0-9]'), '');
    return 'PED-${num.padLeft(3, '0')}';
  }

  /// Formatted date string
  String get formattedDate {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// Formatted time range
  String get formattedTimeRange {
    final start = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    if (endAt != null) {
      final end = '${endAt!.hour.toString().padLeft(2, '0')}:${endAt!.minute.toString().padLeft(2, '0')}';
      return '$start – $end';
    }
    return start;
  }

  /// Subtotal with IVA calculation
  double get iva => subtotal * 0.19;
  double get totalWithIva => subtotal + iva;

  factory Sale.fromJson(Map<String, dynamic> json) {
    PaymentMethod parsePaymentMethod(String? pm) {
      if (pm == null) return PaymentMethod.cash;
      switch (pm.toLowerCase()) {
        case 'card':
        case 'tarjeta':
          return PaymentMethod.card;
        case 'transfer':
        case 'transferencia':
          return PaymentMethod.transfer;
        default:
          return PaymentMethod.cash;
      }
    }

    SaleStatus parseStatus(String? st) {
      if (st == null) return SaleStatus.completed;
      switch (st.toLowerCase()) {
        case 'pending':
        case 'pendiente':
          return SaleStatus.pending;
        case 'cancelled':
        case 'cancelada':
        case 'cancelado':
        case 'anulada':
        case 'anulado':
          return SaleStatus.cancelled;
        // Backend states: 'Completada', 'Listo', 'En Preparación', 'En Cocina',
        // 'ENTREGADO', 'LISTO', 'PREPARANDO', 'pagado', etc. → completed
        default:
          return SaleStatus.completed;
      }
    }

    DeliveryType parseDelivery(String? dt) {
      if (dt == null) return DeliveryType.dineIn;
      switch (dt.toLowerCase()) {
        case 'delivery':
        case 'domicilio':
          return DeliveryType.delivery;
        case 'takeout':
        case 'parallevar':
        case 'para llevar':
          return DeliveryType.takeout;
        default:
          return DeliveryType.dineIn;
      }
    }

    // Backend returns 'productos' array; also check legacy field names
    final rawDetails = json['productos'] ?? json['details'] ?? json['detalles'] ?? json['items'] ?? [];
    List<SaleDetail> detailsList = [];
    if (rawDetails is List) {
      detailsList = rawDetails
          .whereType<Map<String, dynamic>>()
          .map((d) => SaleDetail.fromJson(d))
          .toList();
    }

    // Map backend date: 'fechaVenta' (ISO string) or 'fecha' or 'createdAt'
    DateTime parseDate(Map<String, dynamic> j) {
      final raw = j['fechaVenta'] ?? j['createdAt'] ?? j['fecha'];
      if (raw == null) return DateTime.now();
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    return Sale(
      id: (json['id'] ?? json['idVenta'] ?? json['_id'])?.toString() ?? '',
      clientId: (json['idCliente'] ?? json['clientId'] ?? json['clienteId'])?.toString() ?? '',
      clientName: json['clienteNombre']?.toString() ?? json['cliente']?.toString() ?? json['clientName']?.toString() ?? json['nombreCliente']?.toString() ?? 'Cliente General',
      details: detailsList,
      subtotal: (json['subtotal'] ?? json['montoTotal'] ?? 0).toDouble(),
      discount: (json['descuentoAplicado'] ?? json['montoDescuento'] ?? json['discount'] ?? json['descuento'] ?? 0).toDouble(),
      total: (json['total'] ?? json['montoTotal'] ?? json['totalVenta'] ?? 0).toDouble(),
      paymentMethod: parsePaymentMethod(json['metodoPago']?.toString() ?? json['paymentMethod']?.toString()),
      status: parseStatus(json['estado']?.toString() ?? json['estadoEntrega']?.toString() ?? json['status']?.toString()),
      createdAt: parseDate(json),
      endAt: null,
      deliveryType: parseDelivery(json['tipoEntrega']?.toString() ?? json['deliveryType']?.toString()),
      notes: json['especificaciones']?.toString() ?? json['observaciones']?.toString() ?? json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'details': details.map((d) => d.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'deliveryType': deliveryType.name,
      'notes': notes,
    };
  }
}
