import 'dart:convert';

/// Modelo de Evento promocional (Mapeado de la tabla `evento` de MySQL)
class Event {
  final int? id;
  final String nombre;
  final String descripcion;
  final String? fechaInicio;
  final String? fechaFin;
  final bool isActive;
  final String estado; // 'Activo' | 'Inactivo'
  final int? idProducto;
  final String? tipoEvento;
  final double? descuento;
  final double? nuevoPrecio;
  final String? accionInsumo;
  final List<dynamic>? insumosAsociados;
  final List<dynamic>? productosAsociados;
  final String? icono;
  final bool isTemporal;

  const Event({
    this.id,
    required this.nombre,
    this.descripcion = '',
    this.fechaInicio,
    this.fechaFin,
    this.isActive = true,
    this.estado = 'Activo',
    this.idProducto,
    this.tipoEvento,
    this.descuento,
    this.nuevoPrecio,
    this.accionInsumo,
    this.insumosAsociados,
    this.productosAsociados,
    this.icono,
    this.isTemporal = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final rawId = json['idEvento'] ?? json['id'];
    final int? parsedId = rawId is int
        ? rawId
        : (rawId != null ? int.tryParse(rawId.toString()) : null);

    final rawIdProd = json['idProducto'] ?? json['productoId'];
    final int? parsedIdProd = rawIdProd is int
        ? rawIdProd
        : (rawIdProd != null ? int.tryParse(rawIdProd.toString()) : null);

    final rawEstado = json['estado'];
    final bool active = rawEstado == null ||
        rawEstado == 1 ||
        rawEstado == '1' ||
        rawEstado == 'Activo' ||
        rawEstado == true;

    final rawDesc = json['descuento'];
    final double? parsedDesc = rawDesc is num
        ? rawDesc.toDouble()
        : (rawDesc != null ? double.tryParse(rawDesc.toString()) : null);

    final rawPrecio = json['nuevoPrecio'];
    final double? parsedPrecio = rawPrecio is num
        ? rawPrecio.toDouble()
        : (rawPrecio != null ? double.tryParse(rawPrecio.toString()) : null);

    List<dynamic>? parseJsonList(dynamic input) {
      if (input is List) return input;
      if (input is String && input.isNotEmpty) {
        try {
          final decoded = jsonDecode(input);
          if (decoded is List) return decoded;
        } catch (_) {}
      }
      return null;
    }

    return Event(
      id: parsedId,
      nombre: json['nombreEvento']?.toString() ?? json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      fechaInicio: json['fechaInicio']?.toString(),
      fechaFin: json['fechaFin']?.toString(),
      isActive: active,
      estado: active ? 'Activo' : 'Inactivo',
      idProducto: parsedIdProd,
      tipoEvento: json['tipoEvento']?.toString(),
      descuento: parsedDesc,
      nuevoPrecio: parsedPrecio,
      accionInsumo: json['accionInsumo']?.toString() ?? json['accion']?.toString(),
      insumosAsociados: parseJsonList(json['insumosAsociados'] ?? json['insumos']),
      productosAsociados: parseJsonList(json['productosAsociados'] ?? json['productos']),
      icono: json['icono']?.toString() ?? json['imagen']?.toString(),
      isTemporal: json['fechaInicio'] != null && json['fechaInicio'].toString().isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'idEvento': id,
      'nombreEvento': nombre,
      'nombre': nombre,
      'descripcion': descripcion,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estado': isActive ? 1 : 0,
      'idProducto': idProducto,
      'tipoEvento': tipoEvento,
      'descuento': descuento,
      'nuevoPrecio': nuevoPrecio,
      'accionInsumo': accionInsumo,
      'insumosAsociados': insumosAsociados != null ? jsonEncode(insumosAsociados) : null,
      'productosAsociados': productosAsociados != null ? jsonEncode(productosAsociados) : null,
      'icono': icono,
    };
  }
}

