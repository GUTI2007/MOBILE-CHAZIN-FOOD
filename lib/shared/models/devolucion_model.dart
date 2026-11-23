// lib/shared/models/devolucion_model.dart

class Devolucion {
  final String idDevolucion;
  final String idVenta;
  final String cliente;
  final String motivo;
  final String estado;
  final double monto;
  final String fecha;
  final String producto;

  const Devolucion({
    required this.idDevolucion,
    required this.idVenta,
    required this.cliente,
    required this.motivo,
    required this.estado,
    required this.monto,
    required this.fecha,
    required this.producto,
  });

  factory Devolucion.fromJson(Map<String, dynamic> json) {
    return Devolucion(
      idDevolucion: json['idDevolucion']?.toString() ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      idVenta: json['idVenta']?.toString() ?? json['venta']?.toString() ?? '',
      cliente: json['clienteNombre']?.toString() ??
          json['cliente']?.toString() ??
          json['venta']?['cliente']?['nombre']?.toString() ??
          'Cliente',
      motivo: json['motivo']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      monto: (json['monto'] ?? json['total'] ?? json['montoDevolucion'] ?? 0)
          .toDouble(),
      fecha: json['fecha']?.toString() ??
          json['createdAt']?.toString() ??
          json['fechaCreacion']?.toString() ??
          '',
      producto: json['producto']?.toString() ??
          json['descripcion']?.toString() ??
          '',
    );
  }

  bool get isPendiente =>
      estado.toLowerCase() == 'pendiente' ||
      estado.toLowerCase() == 'pendiente por revisión' ||
      estado.toLowerCase() == 'pendiente por revision' ||
      estado.toLowerCase() == 'en revision' ||
      estado.toLowerCase() == 'en revisión';
}
