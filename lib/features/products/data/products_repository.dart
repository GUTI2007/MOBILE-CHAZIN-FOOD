import 'package:dio/dio.dart';
import '../../../config/api/api_client.dart';
import '../../../shared/models/product_model.dart';
import 'mock_products_repository.dart';

/// Repositorio de productos y categorías conectado con el Backend Express (/api/productos, /api/categorias)
class ProductsRepository {
  final ApiClient _apiClient;
  final MockProductsRepository _mockFallback = MockProductsRepository();

  ProductsRepository(this._apiClient);

  /// Obtiene la lista de productos desde /api/productos
  Future<List<Product>> getProducts() async {
    try {
      final response = await _apiClient.get('/productos');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        return list.map((item) => Product.fromJson(Map<String, dynamic>.from(item))).toList();
      }
      return await _mockFallback.getProducts();
    } on DioException catch (_) {
      return await _mockFallback.getProducts();
    } catch (_) {
      return await _mockFallback.getProducts();
    }
  }

  /// Obtiene la lista de categorías desde /api/categorias (o /api/categorias-producto)
  Future<List<ProductCategory>> getCategories() async {
    try {
      final response = await _apiClient.get('/categorias');
      if (response.statusCode == 200 && response.data is List) {
        final List list = response.data;
        final categories = list.map((item) => ProductCategory.fromJson(Map<String, dynamic>.from(item))).toList();
        // Insertar opción "Todas" al inicio si no viene del backend
        if (!categories.any((c) => c.id == 'cat_all' || c.name.toLowerCase() == 'todas')) {
          categories.insert(
            0,
            const ProductCategory(id: 'cat_all', name: 'Todas', icon: '📋'),
          );
        }
        return categories;
      }
      return await _mockFallback.getCategories();
    } on DioException catch (_) {
      return await _mockFallback.getCategories();
    } catch (_) {
      return await _mockFallback.getCategories();
    }
  }

  /// Buscar productos localmente o por query
  Future<List<Product>> searchProducts(String query) async {
    final allProducts = await getProducts();
    if (query.isEmpty) return allProducts;
    final q = query.toLowerCase();
    return allProducts.where((p) =>
      p.name.toLowerCase().contains(q) ||
      p.description.toLowerCase().contains(q) ||
      p.categoryName.toLowerCase().contains(q)
    ).toList();
  }

  /// Crear un producto en /api/productos
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required String categoryName,
    String? imageUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/productos',
        data: {
          'nombre': name,
          'descripcion': description,
          'precio': price,
          'idCategoriaProducto': int.tryParse(categoryId) ?? categoryId,
          'categoria': categoryName,
          'imagen': imageUrl ?? '',
          'estado': 1,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(Map<String, dynamic>.from(response.data));
      }
      return await _mockFallback.createProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        categoryName: categoryName,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return await _mockFallback.createProduct(
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        categoryName: categoryName,
        imageUrl: imageUrl,
      );
    }
  }

  /// Actualizar un producto en /api/productos/:id
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (name != null) updateData['nombre'] = name;
      if (description != null) updateData['descripcion'] = description;
      if (price != null) updateData['precio'] = price;
      if (categoryId != null) updateData['idCategoriaProducto'] = int.tryParse(categoryId) ?? categoryId;
      if (categoryName != null) updateData['categoria'] = categoryName;
      if (imageUrl != null) updateData['imagen'] = imageUrl;
      if (isActive != null) updateData['estado'] = isActive ? 1 : 0;

      final response = await _apiClient.put('/productos/$id', data: updateData);
      if (response.statusCode == 200) {
        return Product.fromJson(Map<String, dynamic>.from(response.data));
      }
      return await _mockFallback.updateProduct(id,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        categoryName: categoryName,
        imageUrl: imageUrl,
        isActive: isActive,
      );
    } catch (_) {
      return await _mockFallback.updateProduct(id,
        name: name,
        description: description,
        price: price,
        categoryId: categoryId,
        categoryName: categoryName,
        imageUrl: imageUrl,
        isActive: isActive,
      );
    }
  }

  /// Eliminar un producto en /api/productos/:id
  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.delete('/productos/$id');
    } catch (_) {
      await _mockFallback.deleteProduct(id);
    }
  }
}
