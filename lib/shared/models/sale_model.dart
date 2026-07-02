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
}
