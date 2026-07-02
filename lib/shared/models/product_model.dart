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
  });

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
    );
  }
}
