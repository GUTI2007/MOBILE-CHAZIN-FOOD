/// Modelo de Evento promocional/asociado
class Event {
  final int? id;
  final String nombre;
  final String descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final String estado; // 'Activo' | 'Inactivo'
  final dynamic idProducto;
  final String? tipoEvento;
  final double? descuento;
  final double? nuevoPrecio;
  final String? accionInsumo;
  final List<dynamic>? insumosAsociados;
  final bool isTemporal;

  const Event({
    this.id,
    required this.nombre,
    this.descripcion = '',
    this.fechaInicio,
    this.fechaFin,
    this.estado = 'Activo',
    this.idProducto,
    this.tipoEvento,
    this.descuento,
    this.nuevoPrecio,
    this.accionInsumo,
    this.insumosAsociados,
    this.isTemporal = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] is int ? json['id'] : (json['idEvento'] is int ? json['idEvento'] : int.tryParse(json['id']?.toString() ?? '')),
      nombre: json['nombre']?.toString() ?? json['nombreEvento']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      fechaInicio: json['fechaInicio']?.toString(),
      fechaFin: json['fechaFin']?.toString(),
      estado: json['estado'] == 1 || json['estado'] == 'Activo' ? 'Activo' : 'Inactivo',
      idProducto: json['idProducto'] ?? json['productoId'],
      tipoEvento: json['tipoEvento']?.toString(),
      descuento: json['descuento'] != null ? double.tryParse(json['descuento'].toString()) : null,
      nuevoPrecio: json['nuevoPrecio'] != null ? double.tryParse(json['nuevoPrecio'].toString()) : null,
      accionInsumo: json['accionInsumo']?.toString() ?? json['accion']?.toString(),
      insumosAsociados: json['insumosAsociados'] is List ? json['insumosAsociados'] : null,
      isTemporal: json['fechaInicio'] != null && json['fechaInicio'].toString().isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'nombreEvento': nombre,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estado': estado,
      'productoId': idProducto,
      'idProducto': idProducto,
      'tipoEvento': tipoEvento,
      'descuento': descuento,
      'nuevoPrecio': nuevoPrecio,
      'accion': accionInsumo,
      'insumos': insumosAsociados,
      'isTemporal': isTemporal,
    };
  }
}
