/// Categoría de producto
class ProductCategory {
  final String id;
  final String name;
  final String? icon;
  final bool isActive;

  const ProductCategory({
    required this.id,
    required this.name,
    this.icon,
    this.isActive = true,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final rawId = json['idCategoriaProducto'] ?? json['id'] ?? '';
    final estado = json['estado'];
    final isActive = estado == null || estado == 1 || estado == 'Activo' || estado == true;

    return ProductCategory(
      id: rawId.toString(),
      name: json['nombre'] ?? json['name'] ?? '',
      icon: json['icon'] ?? json['icono'],
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idCategoriaProducto': id,
      'nombre': name,
      'icon': icon,
      'estado': isActive ? 'Activo' : 'Inactivo',
    };
  }
}

/// Producto
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final String emoji;
  final bool isActive;
  final bool isPopular;
  final int totalSold;
  final DateTime createdAt;

  final String? lote;
  final String? registroSanitario;
  final String? trazabilidadInfo;
  final String? vidaUtil;
  final double costoEstimado;
  final double margenGanancia;
  final String statusString; // 'Disponible' | 'Agotado' | 'Inactivo'
  final List<Map<String, dynamic>> adiciones;
  final List<Map<String, dynamic>> insumos;
  final List<Map<String, dynamic>> variantes;
  final List<Map<String, dynamic>> resenas;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.emoji = '',
    this.isActive = true,
    this.isPopular = false,
    this.totalSold = 0,
    required this.createdAt,
    this.lote,
    this.registroSanitario,
    this.trazabilidadInfo,
    this.vidaUtil,
    this.costoEstimado = 0.0,
    this.margenGanancia = 0.0,
    this.statusString = 'Disponible',
    this.adiciones = const [],
    this.insumos = const [],
    this.variantes = const [],
    this.resenas = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['idProducto'] ?? json['id'] ?? json['_id'] ?? '';
    final rawCatId = json['idCategoriaProducto'] ?? json['categoriaId'] ?? '';
    final rawPrecio = json['precio'] ?? json['price'] ?? 0;
    final double priceVal = (rawPrecio is num)
        ? rawPrecio.toDouble()
        : double.tryParse(rawPrecio.toString()) ?? 0.0;

    final rawCosto = json['costoEstimado'] ?? json['costo'] ?? 0;
    final double costoVal = (rawCosto is num)
        ? rawCosto.toDouble()
        : double.tryParse(rawCosto.toString()) ?? (priceVal * 0.54);

    final rawMargen = json['margenGanancia'] ?? json['margen'] ?? 0;
    final double margenVal = (rawMargen is num)
        ? rawMargen.toDouble()
        : priceVal > 0 ? (((priceVal - costoVal) / priceVal) * 100).roundToDouble() : 0.0;

    final estado = json['estado'] ?? json['statusString'];
    final bool isActive = estado == null || estado == 1 || estado == 'Activo' || estado == 'Disponible' || estado == true;
    final String statusStr = (estado is String && estado.isNotEmpty)
        ? estado
        : (isActive ? 'Disponible' : 'Inactivo');

    final rawAdiciones = json['adiciones'];
    List<Map<String, dynamic>> parsedAdiciones = [];
    if (rawAdiciones is List) {
      parsedAdiciones = rawAdiciones.map((item) {
        if (item is Map<String, dynamic>) return item;
        return {'nombre': item.toString(), 'precio': 0.0};
      }).toList();
    }

    final rawInsumos = json['insumos'];
    List<Map<String, dynamic>> parsedInsumos = [];
    if (rawInsumos is List) {
      parsedInsumos = rawInsumos.map((item) {
        if (item is Map<String, dynamic>) return item;
        return {'nombre': item.toString(), 'cantidad': '1 und'};
      }).toList();
    }

    final rawVariantes = json['variantes'];
    List<Map<String, dynamic>> parsedVariantes = [];
    if (rawVariantes is List) {
      parsedVariantes = rawVariantes.map((item) {
        if (item is Map<String, dynamic>) return item;
        return {'nombre': item.toString(), 'precio': priceVal};
      }).toList();
    }

    final rawResenas = json['resenas'];
    List<Map<String, dynamic>> parsedResenas = [];
    if (rawResenas is List) {
      parsedResenas = rawResenas.map((item) {
        if (item is Map<String, dynamic>) return item;
        return {'usuario': 'Cliente', 'comentario': item.toString(), 'calificacion': 5.0};
      }).toList();
    }

    return Product(
      id: rawId.toString(),
      name: json['nombre'] ?? json['name'] ?? '',
      description: json['descripcion'] ?? json['description'] ?? '',
      price: priceVal,
      categoryId: rawCatId.toString(),
      categoryName: json['categoria'] ?? json['categoryName'] ?? '',
      imageUrl: json['imagen'] ?? json['imageUrl'],
      emoji: json['emoji'] ?? '',
      isActive: isActive,
      isPopular: json['isPopular'] ?? false,
      totalSold: json['totalSold'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lote: json['lote'],
      registroSanitario: json['registroSanitario'],
      trazabilidadInfo: json['trazabilidadInfo'],
      vidaUtil: json['vidaUtil'],
      costoEstimado: costoVal,
      margenGanancia: margenVal,
      statusString: statusStr,
      adiciones: parsedAdiciones,
      insumos: parsedInsumos,
      variantes: parsedVariantes,
      resenas: parsedResenas,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idProducto': id,
      'nombre': name,
      'descripcion': description,
      'precio': price,
      'idCategoriaProducto': categoryId,
      'categoria': categoryName,
      'imagen': imageUrl,
      'estado': statusString,
      'lote': lote,
      'registroSanitario': registroSanitario,
      'trazabilidadInfo': trazabilidadInfo,
      'vidaUtil': vidaUtil,
      'costoEstimado': costoEstimado,
      'margenGanancia': margenGanancia,
      'adiciones': adiciones,
      'insumos': insumos,
      'variantes': variantes,
      'resenas': resenas,
    };
  }

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    String? emoji,
    bool? isActive,
    bool? isPopular,
    int? totalSold,
    String? lote,
    String? registroSanitario,
    String? trazabilidadInfo,
    String? vidaUtil,
    double? costoEstimado,
    double? margenGanancia,
    String? statusString,
    List<Map<String, dynamic>>? adiciones,
    List<Map<String, dynamic>>? insumos,
    List<Map<String, dynamic>>? variantes,
    List<Map<String, dynamic>>? resenas,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      emoji: emoji ?? this.emoji,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      totalSold: totalSold ?? this.totalSold,
      createdAt: createdAt,
      lote: lote ?? this.lote,
      registroSanitario: registroSanitario ?? this.registroSanitario,
      trazabilidadInfo: trazabilidadInfo ?? this.trazabilidadInfo,
      vidaUtil: vidaUtil ?? this.vidaUtil,
      costoEstimado: costoEstimado ?? this.costoEstimado,
      margenGanancia: margenGanancia ?? this.margenGanancia,
      statusString: statusString ?? this.statusString,
      adiciones: adiciones ?? this.adiciones,
      insumos: insumos ?? this.insumos,
      variantes: variantes ?? this.variantes,
      resenas: resenas ?? this.resenas,
    );
  }
}
