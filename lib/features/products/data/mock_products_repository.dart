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
    // ─── More products for infinite scroll testing ───
    Product(
      id: 'prod_007',
      name: 'Hamburguesa Clásica',
      description: 'Carne de res, queso americano, lechuga, tomate y ketchup',
      price: 12000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🍔',
      isActive: true,
      isPopular: true,
      totalSold: 310,
      createdAt: DateTime(2026, 1, 10),
    ),
    Product(
      id: 'prod_008',
      name: 'Hamburguesa BBQ',
      description: 'Carne, tocino, cebolla caramelizada y salsa BBQ',
      price: 16000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🍔',
      isActive: true,
      isPopular: true,
      totalSold: 189,
      createdAt: DateTime(2026, 2, 5),
    ),
    Product(
      id: 'prod_009',
      name: 'Limonada Natural',
      description: 'Limonada fresca hecha con limones naturales',
      price: 4000,
      categoryId: 'cat_03',
      categoryName: 'Bebidas',
      emoji: '🍋',
      isActive: true,
      isPopular: false,
      totalSold: 156,
      createdAt: DateTime(2026, 1, 25),
    ),
    Product(
      id: 'prod_010',
      name: 'Brownie con Helado',
      description: 'Brownie de chocolate caliente con helado de vainilla',
      price: 9000,
      categoryId: 'cat_04',
      categoryName: 'Postres',
      emoji: '🍫',
      isActive: true,
      isPopular: true,
      totalSold: 134,
      createdAt: DateTime(2026, 3, 10),
    ),
    Product(
      id: 'prod_011',
      name: 'Perro Caliente Sencillo',
      description: 'Hot dog con salchicha, salsas y papitas',
      price: 7000,
      categoryId: 'cat_07',
      categoryName: 'Perros Calientes',
      emoji: '🌭',
      isActive: true,
      isPopular: false,
      totalSold: 88,
      createdAt: DateTime(2026, 2, 10),
    ),
    Product(
      id: 'prod_012',
      name: 'Salchipapa Mediana',
      description: 'Papas fritas con salchicha y salsas variadas',
      price: 9000,
      categoryId: 'cat_06',
      categoryName: 'Salchipapas',
      emoji: '🍟',
      isActive: true,
      isPopular: false,
      totalSold: 143,
      createdAt: DateTime(2026, 2, 20),
    ),
    Product(
      id: 'prod_013',
      name: 'Jugo de Naranja',
      description: 'Jugo de naranja natural recién exprimido',
      price: 4500,
      categoryId: 'cat_03',
      categoryName: 'Bebidas',
      emoji: '🍊',
      isActive: true,
      isPopular: false,
      totalSold: 97,
      createdAt: DateTime(2026, 3, 5),
    ),
    Product(
      id: 'prod_014',
      name: 'Aros de Cebolla',
      description: 'Aros de cebolla empanizados crujientes con salsa ranch',
      price: 7000,
      categoryId: 'cat_02',
      categoryName: 'Acompañamientos',
      emoji: '🧅',
      isActive: true,
      isPopular: false,
      totalSold: 76,
      createdAt: DateTime(2026, 3, 15),
    ),
    Product(
      id: 'prod_015',
      name: 'Hamburguesa Doble Queso',
      description: 'Doble carne con doble queso cheddar derretido',
      price: 18000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🍔',
      isActive: true,
      isPopular: true,
      totalSold: 201,
      createdAt: DateTime(2026, 1, 18),
    ),
    Product(
      id: 'prod_016',
      name: 'Malteada de Chocolate',
      description: 'Malteada cremosa de chocolate con crema batida',
      price: 8000,
      categoryId: 'cat_03',
      categoryName: 'Bebidas',
      emoji: '🥛',
      isActive: true,
      isPopular: true,
      totalSold: 122,
      createdAt: DateTime(2026, 2, 28),
    ),
    Product(
      id: 'prod_017',
      name: 'Torta de Tres Leches',
      description: 'Porción de torta de tres leches con canela',
      price: 7000,
      categoryId: 'cat_04',
      categoryName: 'Postres',
      emoji: '🍰',
      isActive: true,
      isPopular: false,
      totalSold: 67,
      createdAt: DateTime(2026, 4, 1),
    ),
    Product(
      id: 'prod_018',
      name: 'Nuggets de Pollo x8',
      description: 'Ocho nuggets de pollo crujientes con salsa BBQ',
      price: 10000,
      categoryId: 'cat_02',
      categoryName: 'Acompañamientos',
      emoji: '🍗',
      isActive: true,
      isPopular: false,
      totalSold: 54,
      createdAt: DateTime(2026, 4, 10),
    ),
    Product(
      id: 'prod_019',
      name: 'Perro Caliente Ranchero',
      description: 'Hot dog con carne molida, frijoles, jalapeños y queso',
      price: 12000,
      categoryId: 'cat_07',
      categoryName: 'Perros Calientes',
      emoji: '🌭',
      isActive: true,
      isPopular: false,
      totalSold: 45,
      createdAt: DateTime(2026, 4, 15),
    ),
    Product(
      id: 'prod_020',
      name: 'Agua Saborizada',
      description: 'Agua con sabor a frutos rojos 500ml',
      price: 3000,
      categoryId: 'cat_03',
      categoryName: 'Bebidas',
      emoji: '💧',
      isActive: true,
      isPopular: false,
      totalSold: 210,
      createdAt: DateTime(2026, 1, 5),
    ),
    Product(
      id: 'prod_021',
      name: 'Salchipapa Súper',
      description: 'Salchipapa con queso gratinado, tocineta y huevo',
      price: 15000,
      categoryId: 'cat_06',
      categoryName: 'Salchipapas',
      emoji: '🍟',
      isActive: true,
      isPopular: true,
      totalSold: 178,
      createdAt: DateTime(2026, 3, 20),
    ),
    Product(
      id: 'prod_022',
      name: 'Hamburguesa Pollo Crispy',
      description: 'Pechuga de pollo empanizada con lechuga y mayo',
      price: 14000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🍔',
      isActive: true,
      isPopular: false,
      totalSold: 89,
      createdAt: DateTime(2026, 5, 1),
    ),
    Product(
      id: 'prod_023',
      name: 'Helado de Vainilla',
      description: 'Copa de helado de vainilla con chispas de chocolate',
      price: 5000,
      categoryId: 'cat_04',
      categoryName: 'Postres',
      emoji: '🍦',
      isActive: true,
      isPopular: false,
      totalSold: 92,
      createdAt: DateTime(2026, 5, 10),
    ),
    Product(
      id: 'prod_024',
      name: 'Papas Fritas Grandes',
      description: 'Porción grande de papas fritas crujientes con salsas',
      price: 8000,
      categoryId: 'cat_02',
      categoryName: 'Acompañamientos',
      emoji: '🍟',
      isActive: true,
      isPopular: true,
      totalSold: 332,
      createdAt: DateTime(2026, 1, 12),
    ),
    Product(
      id: 'prod_025',
      name: 'Combo Familiar',
      description: '4 hamburguesas + 2 papas grandes + 4 bebidas',
      price: 55000,
      categoryId: 'cat_01',
      categoryName: 'Hamburguesas',
      emoji: '🎉',
      isActive: true,
      isPopular: true,
      totalSold: 31,
      createdAt: DateTime(2026, 6, 1),
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
