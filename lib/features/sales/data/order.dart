class DetallePedido {
  final String nombre;
  final int cantidad;
  final double precio;
  final List<String> adiciones;

  DetallePedido({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    this.adiciones = const [],
  });
}

class Order {
  final String id;
  final String cliente;
  final String fecha;
  final String hora;
  final String horaFin;
  final String estado; // 'pagado', 'pendiente', 'en_proceso'
  final String metodoPago; // 'efectivo', 'tarjeta', 'transferencia'
  final String tipoEntrega; // 'mesa', 'domicilio', 'recoger'
  final double subtotal;
  final double descuento; // in percentage
  final double total;
  final List<DetallePedido> detalle;

  Order({
    required this.id,
    required this.cliente,
    required this.fecha,
    required this.hora,
    required this.horaFin,
    required this.estado,
    required this.metodoPago,
    required this.tipoEntrega,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.detalle,
  });
}

final List<Order> pedidosMock = [
  Order(
    id: 'PED-001',
    cliente: 'Juan García',
    fecha: '2026-06-09',
    hora: '12:30',
    horaFin: '12:45',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'domicilio',
    subtotal: 28000,
    descuento: 0,
    total: 28000,
    detalle: [
      DetallePedido(nombre: 'Hamburguesa Especial', cantidad: 1, precio: 15000, adiciones: ['Queso Extra', 'Salsa BBQ']),
      DetallePedido(nombre: 'Coca Cola', cantidad: 1, precio: 3000),
      DetallePedido(nombre: 'Papas Fritas', cantidad: 2, precio: 6000),
    ],
  ),
  Order(
    id: 'PED-002',
    cliente: 'María López',
    fecha: '2026-06-09',
    hora: '13:05',
    horaFin: '13:20',
    estado: 'pagado',
    metodoPago: 'tarjeta',
    tipoEntrega: 'mesa',
    subtotal: 45000,
    descuento: 10,
    total: 40500,
    detalle: [
      DetallePedido(nombre: 'Combo Familiar', cantidad: 1, precio: 45000),
    ],
  ),
  Order(
    id: 'PED-003',
    cliente: 'Carlos Pérez',
    fecha: '2026-06-09',
    hora: '13:45',
    horaFin: '14:00',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'recoger',
    subtotal: 22000,
    descuento: 0,
    total: 22000,
    detalle: [
      DetallePedido(nombre: 'Pollo Broaster', cantidad: 1, precio: 18000, adiciones: ['Salsa Picante']),
      DetallePedido(nombre: 'Sprite', cantidad: 1, precio: 3000),
    ],
  ),
  Order(
    id: 'PED-004',
    cliente: 'Ana Martínez',
    fecha: '2026-06-08',
    hora: '11:20',
    horaFin: '11:35',
    estado: 'pagado',
    metodoPago: 'tarjeta',
    tipoEntrega: 'domicilio',
    subtotal: 20000,
    descuento: 5,
    total: 19000,
    detalle: [
      DetallePedido(nombre: 'Perro Caliente', cantidad: 1, precio: 10000, adiciones: ['Salsa de Ajo']),
      DetallePedido(nombre: 'Salchipapa Grande', cantidad: 1, precio: 12000),
    ],
  ),
  Order(
    id: 'PED-005',
    cliente: 'Luis Rodríguez',
    fecha: '2026-06-08',
    hora: '14:15',
    horaFin: '14:30',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'mesa',
    subtotal: 36000,
    descuento: 0,
    total: 36000,
    detalle: [
      DetallePedido(nombre: 'Hamburguesa Especial', cantidad: 2, precio: 15000),
      DetallePedido(nombre: 'Jugo de Naranja', cantidad: 1, precio: 4000),
    ],
  ),
  Order(
    id: 'PED-006',
    cliente: 'Sofia Gómez',
    fecha: '2026-06-07',
    hora: '12:00',
    horaFin: '12:15',
    estado: 'pagado',
    metodoPago: 'transferencia',
    tipoEntrega: 'recoger',
    subtotal: 15000,
    descuento: 0,
    total: 15000,
    detalle: [
      DetallePedido(nombre: 'Hamburguesa Especial', cantidad: 1, precio: 15000, adiciones: ['Tocineta']),
    ],
  ),
  Order(
    id: 'PED-007',
    cliente: 'Pedro Vargas',
    fecha: '2026-06-07',
    hora: '19:30',
    horaFin: '19:45',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'domicilio',
    subtotal: 54000,
    descuento: 15,
    total: 45900,
    detalle: [
      DetallePedido(nombre: 'Combo Familiar', cantidad: 1, precio: 45000),
      DetallePedido(nombre: 'Arepa con Queso', cantidad: 1, precio: 8000),
    ],
  ),
  Order(
    id: 'PED-008',
    cliente: 'Cliente General',
    fecha: '2026-06-06',
    hora: '13:00',
    horaFin: '13:15',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'mesa',
    subtotal: 12000,
    descuento: 0,
    total: 12000,
    detalle: [
      DetallePedido(nombre: 'Salchipapa Grande', cantidad: 1, precio: 12000),
    ],
  ),
  Order(
    id: 'PED-009',
    cliente: 'Diana Torres',
    fecha: '2026-06-06',
    hora: '17:45',
    horaFin: '18:00',
    estado: 'pagado',
    metodoPago: 'tarjeta',
    tipoEntrega: 'domicilio',
    subtotal: 30000,
    descuento: 0,
    total: 30000,
    detalle: [
      DetallePedido(nombre: 'Pollo Broaster', cantidad: 1, precio: 18000),
      DetallePedido(nombre: 'Coca Cola', cantidad: 2, precio: 3000),
      DetallePedido(nombre: 'Papas Fritas', cantidad: 1, precio: 6000),
    ],
  ),
  Order(
    id: 'PED-010',
    cliente: 'Andrés Cano',
    fecha: '2026-06-05',
    hora: '20:10',
    horaFin: '20:25',
    estado: 'pagado',
    metodoPago: 'efectivo',
    tipoEntrega: 'recoger',
    subtotal: 48000,
    descuento: 0,
    total: 48000,
    detalle: [
      DetallePedido(nombre: 'Combo Familiar', cantidad: 1, precio: 45000),
      DetallePedido(nombre: 'Sprite', cantidad: 1, precio: 3000),
    ],
  ),
];

class SalesSummaryDay {
  final String dia;
  final double ventas;
  final int pedidos;

  SalesSummaryDay({
    required this.dia,
    required this.ventas,
    required this.pedidos,
  });
}

final List<SalesSummaryDay> ventasPorDia = [
  SalesSummaryDay(dia: 'Lun', ventas: 185000, pedidos: 6),
  SalesSummaryDay(dia: 'Mar', ventas: 210000, pedidos: 7),
  SalesSummaryDay(dia: 'Mié', ventas: 160000, pedidos: 5),
  SalesSummaryDay(dia: 'Jue', ventas: 295000, pedidos: 9),
  SalesSummaryDay(dia: 'Vie', ventas: 340000, pedidos: 11),
  SalesSummaryDay(dia: 'Sáb', ventas: 420000, pedidos: 14),
  SalesSummaryDay(dia: 'Dom', ventas: 380000, pedidos: 12),
];

class BestSeller {
  final String nombre;
  final int cantidad;

  BestSeller({
    required this.nombre,
    required this.cantidad,
  });
}

final List<BestSeller> productosMasVendidos = [
  BestSeller(nombre: 'Hamburguesa Esp.', cantidad: 38),
  BestSeller(nombre: 'Combo Familiar', cantidad: 24),
  BestSeller(nombre: 'Pollo Broaster', cantidad: 21),
  BestSeller(nombre: 'Salchipapa', cantidad: 19),
  BestSeller(nombre: 'Perro Caliente', cantidad: 15),
];

class PaymentMethodShare {
  final String metodo;
  final double porcentaje;

  PaymentMethodShare({
    required this.metodo,
    required this.porcentaje,
  });
}

final List<PaymentMethodShare> metodoPagoData = [
  PaymentMethodShare(metodo: 'Efectivo', porcentaje: 62),
  PaymentMethodShare(metodo: 'Tarjeta', porcentaje: 38),
];
