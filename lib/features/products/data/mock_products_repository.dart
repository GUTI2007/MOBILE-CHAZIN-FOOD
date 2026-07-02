import '../../../shared/models/product_model.dart';

/// Repositorio mock de productos — datos basados en mockups Figma
class MockProductsRepository {
  final List<Product> _products = List.from(_initialProducts);
  final List<ProductCategory> _categories = List.from(_initialCategories);

  // ─── Categories (Figma: Producción > Categoría Productos) ───
  static final List<ProductCategory> _initialCategories = [
    const ProductCategory(id: 'cat_all', name: 'Todas', icon: '📋'),
    const ProductCategory(id: 'cat_01', name: 'Hamburguesas', icon: '🍔'),
    const ProductCategory(id: 'cat_02', name: 'Acompañamientos', icon: '🍟'),
    const ProductCategory(id: 'cat_03', name: 'Bebidas', icon: '🥤'),
    const ProductCategory(id: 'cat_04', name: 'Postres', icon: '🍰'),
    const ProductCategory(id: 'cat_06', name: 'Salchipapas', icon: '🍟'),
    const ProductCategory(id: 'cat_07', name: 'Perros Calientes', icon: '🌭'),
  ];

  // ─── Products (matching Figma mockup data) ───
  static final List<Product> _initialProducts = [
    Product(
      id: 'prod_001',
      name: 'Hamburguesa Especial',
      description: 'Hamburguesa con doble carne, queso, lechuga, tomate y salsas especiales',
      price: 15000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🍔',
      isActive: true,
      isPopular: true,
      totalSold: 245,
      createdAt: DateTime(2026, 1, 15),
    ),
    Product(
      id: 'prod_002',
      name: 'Papas Fritas Medianas',
      description: 'Papas fritas crujientes con sal',
      price: 6000,
      categoryId: 'cat_02',
      categoryName: 'Acompañamientos',
      emoji: '🍟',
      isActive: true,
      isPopular: true,
      totalSold: 420,
      createdAt: DateTime(2026, 1, 15),
    ),
    Product(
      id: 'prod_003',
      name: 'Salchipapa Grande',
      description: 'Papas fritas con salchicha, salsas y queso gratinado',
      price: 12000,
      categoryId: 'cat_06',
      categoryName: 'Salchipapas',
      emoji: '🍟',
      isActive: true,
      isPopular: true,
      totalSold: 198,
      createdAt: DateTime(2026, 2, 1),
    ),
    Product(
      id: 'prod_004',
      name: 'Perro Caliente Especial',
      description: 'Hot dog con salchicha premium, salsas, papa chip y queso',
      price: 10000,
      categoryId: 'cat_07',
      categoryName: 'Perros Calientes',
      emoji: '🌭',
      isActive: true,
      isPopular: true,
      totalSold: 167,
      createdAt: DateTime(2026, 1, 20),
    ),
    Product(
      id: 'prod_005',
      name: 'Coca-Cola 400ml',
      description: 'Coca-Cola original en vaso bien fría',
      price: 5000,
      categoryId: 'cat_03',
      categoryName: 'Bebidas',
      emoji: '🥤',
      isActive: true,
      isPopular: false,
      totalSold: 114,
      createdAt: DateTime(2026, 2, 15),
    ),
    Product(
      id: 'prod_006',
      name: 'Muslito de Pollo',
      description: 'Pollo frito crujiente por fuera y jugoso por dentro',
      price: 8000,
      categoryId: 'cat_02',
      categoryName: 'Acompañamientos',
      emoji: '🍗',
      isActive: true,
      isPopular: false,
      totalSold: 9,
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

  /// Obtener todos los productos
  Future<List<Product>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_products);
  }

  /// Obtener productos activos
  Future<List<Product>> getActiveProducts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _products.where((p) => p.isActive).toList();
  }

  /// Obtener categorías
  Future<List<ProductCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_categories);
  }

  /// Buscar productos
  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q))
        .toList();
  }

  /// Crear producto
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required String categoryName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final product = Product(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      isActive: true,
      createdAt: DateTime.now(),
    );
    _products.add(product);
    return product;
  }

  /// Editar producto
  Future<Product> updateProduct(String id, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? categoryName,
    bool? isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) throw Exception('Producto no encontrado');

    final updated = _products[index].copyWith(
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      isActive: isActive,
    );
    _products[index] = updated;
    return updated;
  }

  /// Eliminar producto
  Future<void> deleteProduct(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _products.removeWhere((p) => p.id == id);
  }
}
