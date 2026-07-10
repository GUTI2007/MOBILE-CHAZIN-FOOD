import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../data/mock_products_repository.dart';

/// Provider del repositorio
final productsRepositoryProvider = Provider<MockProductsRepository>((ref) {
  return MockProductsRepository();
});

/// Estado de la lista de productos
class ProductsState {
  final List<Product> products;
  final List<ProductCategory> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedCategoryId;

  const ProductsState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategoryId,
  });

  ProductsState copyWith({
    List<Product>? products,
    List<ProductCategory>? categories,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  List<Product> get filteredProducts {
    var filtered = List<Product>.from(products);

    if (selectedCategoryId != null) {
      filtered = filtered.where((p) => p.categoryId == selectedCategoryId).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q)).toList();
    }

    return filtered;
  }
}

/// Notifier de productos
class ProductsNotifier extends StateNotifier<ProductsState> {
  final MockProductsRepository _repository;

  ProductsNotifier(this._repository) : super(const ProductsState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _repository.getProducts();
      final categories = await _repository.getCategories();
      state = state.copyWith(
        products: products,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? categoryId) {
    if (categoryId == state.selectedCategoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String categoryId,
    required String categoryName,
    String? imageUrl,
  }) async {
    await _repository.createProduct(
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
    );
    await loadProducts();
  }

  Future<void> updateProduct(String id, {
    String? name,
    String? description,
    double? price,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isActive,
  }) async {
    await _repository.updateProduct(id,
      name: name,
      description: description,
      price: price,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl,
      isActive: isActive,
    );
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await loadProducts();
  }
}

/// Provider global de productos
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final repository = ref.read(productsRepositoryProvider);
  return ProductsNotifier(repository);
});
