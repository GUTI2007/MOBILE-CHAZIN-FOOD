/// Modelo para las Estadísticas / Métricas del Dashboard (homologado con Express /api/dashboard)
class DashboardStats {
  final double ventasTotal;
  final double ventasVariacion;
  final int pedidosTotal;
  final double pedidosVariacion;
  final int clientesTotal;
  final int clientesActivos;
  final double clientesVariacion;
  final int productosTotal;
  final int insumosBajoStock;

  const DashboardStats({
    required this.ventasTotal,
    required this.ventasVariacion,
    required this.pedidosTotal,
    required this.pedidosVariacion,
    required this.clientesTotal,
    required this.clientesActivos,
    required this.clientesVariacion,
    required this.productosTotal,
    required this.insumosBajoStock,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic val) => val is num ? val : num.tryParse(val?.toString() ?? '') ?? 0;

    return DashboardStats(
      ventasTotal: getNum(json['ventasTotal']).toDouble(),
      ventasVariacion: getNum(json['ventasVariacion']).toDouble(),
      pedidosTotal: getNum(json['pedidosTotal']).toInt(),
      pedidosVariacion: getNum(json['pedidosVariacion']).toDouble(),
      clientesTotal: getNum(json['clientesTotal']).toInt(),
      clientesActivos: getNum(json['clientesActivos']).toInt(),
      clientesVariacion: getNum(json['clientesVariacion']).toDouble(),
      productosTotal: getNum(json['productosTotal']).toInt(),
      insumosBajoStock: getNum(json['insumosBajoStock']).toInt(),
    );
  }

  /// Valores por defecto en caso de carga o fallback
  factory DashboardStats.defaultStats() {
    return const DashboardStats(
      ventasTotal: 28400000,
      ventasVariacion: 12.5,
      pedidosTotal: 1248,
      pedidosVariacion: 8.2,
      clientesTotal: 342,
      clientesActivos: 342,
      clientesVariacion: 15.3,
      productosTotal: 68,
      insumosBajoStock: 5,
    );
  }
}

/// Punto de datos para gráfico de ventas y compras por mes
class VentasChartData {
  final String mes;
  final double ventas;
  final double compras;

  const VentasChartData({
    required this.mes,
    required this.ventas,
    required this.compras,
  });

  factory VentasChartData.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic val) => val is num ? val : num.tryParse(val?.toString() ?? '') ?? 0;
    return VentasChartData(
      mes: json['mes']?.toString() ?? '',
      ventas: getNum(json['ventas']).toDouble(),
      compras: getNum(json['compras']).toDouble(),
    );
  }
}

/// Alerta de stock para insumos/productos
class StockAlertItem {
  final String id;
  final String nombre;
  final int stock;
  final int minimo;

  const StockAlertItem({
    required this.id,
    required this.nombre,
    required this.stock,
    required this.minimo,
  });

  factory StockAlertItem.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic val) => val is num ? val : num.tryParse(val?.toString() ?? '') ?? 0;
    return StockAlertItem(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      stock: getNum(json['stock']).toInt(),
      minimo: getNum(json['minimo']).toInt(),
    );
  }

  String get formattedQty => '$stock / $minimo unidades';
}

/// Producto popular para el gráfico horizontal
class PopularProductItem {
  final String id;
  final String nombre;
  final int ventas;

  const PopularProductItem({
    required this.id,
    required this.nombre,
    required this.ventas,
  });

  factory PopularProductItem.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic val) => val is num ? val : num.tryParse(val?.toString() ?? '') ?? 0;
    return PopularProductItem(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      ventas: getNum(json['ventas']).toInt(),
    );
  }
}
