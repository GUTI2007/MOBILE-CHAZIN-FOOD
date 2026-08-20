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
  final List<Map<String, dynamic>> adiciones;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.emoji = '🍽️',
    this.isActive = true,
    this.isPopular = false,
    this.totalSold = 0,
    required this.createdAt,
    this.lote,
    this.registroSanitario,
    this.trazabilidadInfo,
    this.adiciones = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['idProducto'] ?? json['id'] ?? json['_id'] ?? '';
    final rawCatId = json['idCategoriaProducto'] ?? json['categoriaId'] ?? '';
    final rawPrecio = json['precio'] ?? json['price'] ?? 0;
    final double priceVal = (rawPrecio is num)
        ? rawPrecio.toDouble()
        : double.tryParse(rawPrecio.toString()) ?? 0.0;

    final estado = json['estado'];
    final isActive = estado == null || estado == 1 || estado == 'Activo' || estado == true;

    final rawAdiciones = json['adiciones'];
    List<Map<String, dynamic>> parsedAdiciones = [];
    if (rawAdiciones is List) {
      parsedAdiciones = rawAdiciones.map((item) {
        if (item is Map<String, dynamic>) return item;
        return {'nombre': item.toString(), 'precio': 0.0};
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
      emoji: json['emoji'] ?? '🍽️',
      isActive: isActive,
      isPopular: json['isPopular'] ?? false,
      totalSold: json['totalSold'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lote: json['lote'],
      registroSanitario: json['registroSanitario'],
      trazabilidadInfo: json['trazabilidadInfo'],
      adiciones: parsedAdiciones,
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
      'estado': isActive ? 'Activo' : 'Inactivo',
      'lote': lote,
      'registroSanitario': registroSanitario,
      'trazabilidadInfo': trazabilidadInfo,
      'adiciones': adiciones,
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
    List<Map<String, dynamic>>? adiciones,
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
      adiciones: adiciones ?? this.adiciones,
    );
  }
}
