import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/products_provider.dart';
import 'product_form_screen.dart';

import '../../../routes/app_shell.dart';

/// Model for product events (insumo, promo, descuento)
class ProductEvent {
  final String id;
  final String productId;
  final String productName;
  final String productEmoji;
  final String type; // insumo_temp, insumo_perm, promo_precio, descuento
  final String title;
  final String description;
  // Insumo fields
  final String action; // agregar, eliminar
  final String insumoName;
  final String quantity;
  final String unit;
  // Promo fields
  final double? promoPrice;
  // Descuento fields
  final double? discountPercentage;
  // Temporal fields
  final bool isTemporal;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  bool isActive;

  ProductEvent({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productEmoji,
    required this.type,
    required this.title,
    this.description = '',
    this.action = 'agregar',
    this.insumoName = '',
    this.quantity = '1',
    this.unit = 'und',
    this.promoPrice,
    this.discountPercentage,
    this.isTemporal = true,
    this.startDate,
    this.endDate,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case 'insumo_temp':
        return 'Insumo Temporal';
      case 'insumo_perm':
        return 'Insumo Permanente';
      case 'promo_precio':
        return 'Promoción Precio';
      case 'descuento':
        return 'Descuento';
      default:
        return type;
    }
  }

  String get detailSummary {
    switch (type) {
      case 'insumo_temp':
      case 'insumo_perm':
        final prefix = action == 'agregar' ? '+' : '-';
        return '$prefix $insumoName $quantity$unit';
      case 'promo_precio':
        final formattedPrice = promoPrice != null
            ? '\$${promoPrice!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
            : '\$0';
        return 'Promo: $formattedPrice';
      case 'descuento':
        return 'Descuento: ${discountPercentage?.toStringAsFixed(0) ?? '0'}%';
      default:
        return '';
    }
  }
}

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  List<ProductEvent> _customEvents = [];
  int _visibleCount = 10;
  final ScrollController _scrollController = ScrollController();
  final List<OverlayEntry> _toastEntries = [];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(productsProvider.notifier).loadProducts();
    });
    _scrollController.addListener(_onScroll);
    // Default mock event matching screenshots
    _customEvents = [
      ProductEvent(
        id: 'evt_1',
        productId: 'prod_1',
        productName: 'Hamburguesa Especial',
        productEmoji: '🍔',
        type: 'insumo_temp',
        title: 'baller burger',
        description: 'compren sog!',
        action: 'agregar',
        insumoName: 'carne extra aros de cebolla empanizados',
        quantity: '4',
        unit: 'kg',
        isTemporal: true,
        startDate: DateTime(2026, 6, 30),
        endDate: DateTime(2026, 7, 2),
        createdAt: DateTime(2026, 7, 1),
        isActive: true,
      ),
    ];
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final filtered = ref.read(productsProvider).filteredProducts;
      if (_visibleCount < filtered.length) {
        setState(() {
          _visibleCount = (_visibleCount + 10).clamp(0, filtered.length);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = state.filteredProducts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => AppShell.scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/chazin_logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text('Chazin Food', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(productsProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingShimmer(itemCount: 4, isList: true)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(productsProvider.notifier).loadProducts(),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Title Section ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Productos',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Administra el menú y productos del negocio',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Stats Grid 2×2 ───
                    _buildStatsGrid(state, isDark),
                    const SizedBox(height: 16),

                    // ─── Search Bar ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (q) {
                          ref.read(productsProvider.notifier).setSearchQuery(q);
                          setState(() => _visibleCount = 10);
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white30 : AppColors.grey400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white38 : AppColors.grey400,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : AppColors.grey200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? Colors.white10 : AppColors.grey200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── Category Filter + New Product Button ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Dropdown "Todas las categorías"
                          PopupMenuButton<String>(
                            onSelected: (catId) {
                              ref.read(productsProvider.notifier).setCategory(catId);
                              setState(() => _visibleCount = 10);
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cat_all',
                                child: Text('Todas las categorías', style: GoogleFonts.inter(fontSize: 13)),
                              ),
                              ...state.categories
                                  .where((c) => c.id != 'cat_all')
                                  .map((c) => PopupMenuItem(
                                        value: c.id,
                                        child: Text(c.name, style: GoogleFonts.inter(fontSize: 13)),
                                      )),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (state.selectedCategoryId == null || state.selectedCategoryId == 'cat_all' || state.categories.isEmpty)
                                        ? 'Todas las categorías'
                                        : state.categories.firstWhere(
                                            (c) => c.id == state.selectedCategoryId,
                                            orElse: () => state.categories.first,
                                          ).name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: isDark ? Colors.white54 : AppColors.grey500,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),

                          // Purple Eventos chip with badge
                          GestureDetector(
                            onTap: () => _showEventsVersioningDialog(context, isDark),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Eventos',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_customEvents.where((e) => e.isActive).isNotEmpty)
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${_customEvents.where((e) => e.isActive).length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── + Nuevo Producto (Pill shaped) ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => _navigateToForm(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Nuevo Producto',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Product Cards ───
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No hay productos',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white38 : AppColors.grey400,
                            ),
                          ),
                        ),
                      )
                    else
                      Builder(
                        builder: (context) {
                          final visibleItems = filtered.take(_visibleCount).toList();
                          return AnimationLimiter(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: visibleItems.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final product = visibleItems[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 400),
                                  child: SlideAnimation(
                                    verticalOffset: 30,
                                    child: FadeInAnimation(
                                      child: _FigmaProductCard(
                                        product: product,
                                        isDark: isDark,
                                        eventCount: _customEvents.where((e) => e.productId == product.id && e.isActive).length,
                                        onView: () => _showProductDetailsDialog(context, product, isDark),
                                        onEdit: () => _navigateToForm(context, product: product),
                                        onDelete: () => _confirmDelete(context, product),
                                        onCreateEvent: () => _showCreateEventDialog(context, product, isDark),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                    // ─── Load More / Infinite Scroll Info ───
                    if (filtered.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Text(
                              'Mostrando ${_visibleCount.clamp(0, filtered.length)} de ${filtered.length} productos',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : AppColors.grey400,
                              ),
                            ),
                            if (_visibleCount < filtered.length) ...[
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _visibleCount = (_visibleCount + 10).clamp(0, filtered.length);
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : AppColors.grey200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.expand_more_rounded,
                                        size: 18,
                                        color: isDark ? Colors.white54 : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cargar más productos',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Text(
                                'Has visto todos los productos',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isDark ? Colors.white24 : AppColors.grey300,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // _pageBtnFn removed — replaced by infinite scroll + Cargar más

  Widget _buildStatsGrid(dynamic state, bool isDark) {
    final products = state.filteredProducts as List<Product>;
    final totalProducts = products.length;
    final totalSold = products.fold<int>(0, (sum, p) => sum + p.totalSold);
    final lowStock = products.where((p) => p.name == 'Muslito de Pollo').length;
    final bestSeller = products.isNotEmpty
        ? products.reduce((a, b) => a.totalSold > b.totalSold ? a : b)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF3F51B5),
                  iconBg: isDark ? const Color(0xFF1C223D) : const Color(0xFFE8EAF6),
                  label: 'Total Productos',
                  value: totalProducts.toString(),
                  subtitle: 'en catálogo',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  iconBg: isDark ? const Color(0xFF1B3B22) : const Color(0xFFE8F5E9),
                  label: 'Más Vendido',
                  value: bestSeller?.name ?? '-',
                  subtitle: '${bestSeller?.totalSold ?? 0} ventas',
                  isSmallValue: true,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  iconBg: isDark ? const Color(0xFF1B3B22) : const Color(0xFFE8F5E9),
                  label: 'Total Vendidos',
                  value: totalSold.toString(),
                  subtitle: 'unidades',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.error_outline_rounded,
                  iconColor: const Color(0xFFE53935),
                  iconBg: isDark ? const Color(0xFF3E1F21) : const Color(0xFFFFEBEE),
                  label: 'Bajo Stock',
                  value: lowStock.toString(),
                  subtitle: 'requieren atención',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToForm(BuildContext context, {Product? product}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto eliminado')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  double _getProductionCost(Product product) {
    if (product.id == 'prod_001') return 8500;
    if (product.id == 'prod_002') return 2500;
    if (product.id == 'prod_003') return 6800;
    if (product.id == 'prod_004') return 5500;
    if (product.id == 'prod_005') return 1800;
    if (product.id == 'prod_006') return 4500;
    // default formula: price * 0.57 rounded to nearest 100
    return ((product.price * 0.57) / 100).round() * 100.0;
  }

  void _showProductDetailsDialog(BuildContext context, Product product, bool isDark) {
    final cost = _getProductionCost(product);
    final margin = product.price - cost;
    final marginPct = product.price > 0 ? ((margin / product.price) * 100).round() : 0;
    final totalRevenue = product.totalSold * product.price;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header section
                  Stack(
                    children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.primary,
                        child: Center(
                          child: Text(
                            product.emoji,
                            style: const TextStyle(fontSize: 70),
                          ),
                        ),
                      ),
                      // Close button (X inside a circle)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.grey600,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      // Availability badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F8EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.isActive ? 'Disponible' : 'No Disponible',
                            style: GoogleFonts.inter(
                              color: product.isActive ? AppColors.success : AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Content section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          product.description,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : AppColors.textPrimaryLight.withAlpha(200),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 2x2 Grid of details
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                title: 'Precio de Venta',
                                value: Formatters.currency(product.price),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                title: 'Costo de Producción',
                                value: Formatters.currency(cost),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailCard(
                                title: 'Margen de Ganancia',
                                value: Formatters.currency(margin),
                                subText: '$marginPct%',
                                valueColor: AppColors.success,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDetailCard(
                                title: 'Total Vendidos',
                                value: '${product.totalSold} uds',
                                subText: '${Formatters.currency(totalRevenue)} ingresos',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // ─── Sección de Adiciones ───
                        Text(
                          'Adiciones y Opción de Extras',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (product.adiciones.isNotEmpty
                                  ? product.adiciones
                                  : [
                                      {'nombre': 'Queso Extra', 'precio': 2000.0},
                                      {'nombre': 'Tocineta', 'precio': 3000.0},
                                      {'nombre': 'Salsa BBQ', 'precio': 1000.0},
                                      {'nombre': 'Papas Fritas', 'precio': 4000.0},
                                    ])
                              .map((add) {
                            final String name = add['nombre'] ?? '';
                            final double price = (add['precio'] is num) ? (add['precio'] as num).toDouble() : 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262F45) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (price > 0) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '+${Formatters.currency(price)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // ─── Sección de Trazabilidad ───
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF0EA5E9)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Trazabilidad y Calidad',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Código de Lote:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    product.lote ?? 'LOT-2026-0820-A',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reg. Sanitario / INVIMA:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    product.registroSanitario ?? 'NSA-000982-2024',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Versión Ficha Técnica:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2FE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'v1.2 (Vigente)',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0369A1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Close action row
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              backgroundColor: isDark ? Colors.white10 : AppColors.grey100,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Cerrar',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    String? subText,
    Color? valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimaryLight),
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 4),
            Text(
              subText,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight.withAlpha(180),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEventsVersioningDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        int activeTab = 0; // 0 for active events, 1 for history
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final activeEvents = _customEvents.where((e) => e.isActive).toList();
            final allEvents = _customEvents;

            return Dialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Header Row
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Purple sparkles circular icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF7C3AED),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Versionamiento de Fichas\nTécnicas',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_customEvents.length} eventos registrados',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Close button
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white54 : AppColors.grey500,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Colors.transparent), // Space before tabs

                    // Tab Segmented Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _buildTabBtn(
                            label: 'Eventos Activos',
                            isSelected: activeTab == 0,
                            onTap: () => setDialogState(() => activeTab = 0),
                            isDark: isDark,
                            badgeCount: activeEvents.length,
                          ),
                          const SizedBox(width: 12),
                          _buildTabBtn(
                            label: 'Historial Completo',
                            isSelected: activeTab == 1,
                            onTap: () => setDialogState(() => activeTab = 1),
                            isDark: isDark,
                            badgeCount: allEvents.length,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tab Content Area
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 350),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: activeTab == 0
                              ? (activeEvents.isEmpty
                                  ? _buildEmptyState(
                                      icon: Icons.flash_on_rounded,
                                      title: 'No hay eventos activos actualmente.',
                                      subtitle: 'Crea un evento desde cualquier producto.',
                                      isDark: isDark,
                                    )
                                  : Column(
                                      children: activeEvents
                                          .map((evt) => _buildEventCard(evt, isDark, setDialogState))
                                          .toList(),
                                    ))
                              : (allEvents.isEmpty
                                  ? _buildEmptyState(
                                      icon: Icons.calendar_today_rounded,
                                      title: 'No hay eventos registrados.',
                                      subtitle: '',
                                      isDark: isDark,
                                    )
                                  : Column(
                                      children: allEvents
                                          .map((evt) => _buildEventCard(evt, isDark, setDialogState))
                                          .toList(),
                                    )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cerrar button footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : AppColors.grey100,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Cerrar',
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBtn({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required int badgeCount,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : (isDark ? Colors.white54 : AppColors.grey500),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C3AED) : (isDark ? Colors.white12 : AppColors.grey300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.grey700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.grey50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white38 : AppColors.grey400,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(ProductEvent evt, bool isDark, StateSetter setDialogState) {
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final dateStr = "${evt.createdAt.day.toString().padLeft(2, '0')} de ${months[evt.createdAt.month - 1]} de ${evt.createdAt.year}";

    String formatDateCompact(DateTime? date) {
      if (date == null) return '';
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark.withAlpha(100) : AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Emoji + Name + Switch button
          Row(
            children: [
              Text(evt.productEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  evt.productName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!evt.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Inactivo',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : AppColors.grey500,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setDialogState(() {
                    evt.isActive = !evt.isActive;
                  });
                  setState(() {}); // Rebuild parent screen to update cards & badges
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: evt.isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                  child: Text(
                    evt.isActive ? 'Desactivar' : 'Activar',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: evt.isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Badges: Type and Date range
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, color: Color(0xFF7C3AED), size: 11),
                    const SizedBox(width: 4),
                    Text(
                      evt.typeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
              if (evt.isTemporal && evt.startDate != null && evt.endDate != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFFEA580C),
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${formatDateCompact(evt.startDate)} – ${formatDateCompact(evt.endDate)}",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Event Title
          Text(
            evt.title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          if (evt.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              evt.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              ),
            ),
          ],

          // Dynamic detail gray box
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              evt.detailSummary,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.grey700,
              ),
            ),
          ),
          
          // History created label (if deactivated or in complete tab)
          const SizedBox(height: 8),
          Text(
            'Creado $dateStr',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white30 : AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }


  void _showCreateEventDialog(BuildContext context, Product product, bool isDark) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final insumoNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final promoPriceController = TextEditingController();
    final discountPercentageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String selectedEventType = 'insumo_temp'; // insumo_temp, insumo_perm, promo_precio, descuento
        String action = 'agregar'; // agregar, eliminar
        String selectedUnit = 'und';
        bool isTemporal = true;
        DateTime? startDate;
        DateTime? endDate;

        String formatDate(DateTime? date) {
          if (date == null) return 'dd/mm/aaaa';
          return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Header section
                    Container(
                      color: const Color(0xFF7C3AED), // bright purple background
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Product emoji on the left
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                product.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crear Evento',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withAlpha(200),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Close button (X icon)
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable content area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // 1. Tipo de Evento Label
                            Text(
                              'Tipo de Evento',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2x2 Grid of Types
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeCard(
                                    id: 'insumo_temp',
                                    label: 'Insumo Temporal',
                                    icon: Icons.access_time_rounded,
                                    iconColor: const Color(0xFF7C3AED),
                                    iconBg: const Color(0xFFF3E8FF),
                                    isSelected: selectedEventType == 'insumo_temp',
                                    isDark: isDark,
                                    onTap: () => setDialogState(() {
                                      selectedEventType = 'insumo_temp';
                                      isTemporal = true;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTypeCard(
                                    id: 'insumo_perm',
                                    label: 'Insumo Permanente',
                                    icon: Icons.inventory_2_outlined,
                                    iconColor: const Color(0xFF3B82F6),
                                    iconBg: const Color(0xFFDBEAFE),
                                    isSelected: selectedEventType == 'insumo_perm',
                                    isDark: isDark,
                                    onTap: () => setDialogState(() {
                                      selectedEventType = 'insumo_perm';
                                      isTemporal = false;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTypeCard(
                                    id: 'promo_precio',
                                    label: 'Promoción Precio',
                                    icon: Icons.local_offer_outlined,
                                    iconColor: const Color(0xFF10B981),
                                    iconBg: const Color(0xFFD1FAE5),
                                    isSelected: selectedEventType == 'promo_precio',
                                    isDark: isDark,
                                    onTap: () => setDialogState(() {
                                      selectedEventType = 'promo_precio';
                                      isTemporal = true;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildTypeCard(
                                    id: 'descuento',
                                    label: 'Descuento',
                                    icon: Icons.swap_vert_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    iconBg: const Color(0xFFFEF3C7),
                                    isSelected: selectedEventType == 'descuento',
                                    isDark: isDark,
                                    onTap: () => setDialogState(() {
                                      selectedEventType = 'descuento';
                                      isTemporal = true;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Título del Evento *
                            Row(
                              children: [
                                Text(
                                  'Título del Evento',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleController,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ej: Temporada de verano — carne extra incluida',
                                hintStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.white30 : AppColors.grey400,
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Descripción
                            Text(
                              'Descripción',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: descriptionController,
                              style: GoogleFonts.inter(fontSize: 13),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Describe brevemente este evento...',
                                hintStyle: GoogleFonts.inter(
                                  color: isDark ? Colors.white30 : AppColors.grey400,
                                  fontSize: 13,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                                      // Dynamic event details forms
                            if (selectedEventType == 'insumo_temp' || selectedEventType == 'insumo_perm') ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark.withAlpha(150)
                                      : AppColors.grey50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppColors.grey200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detalle del Insumo',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Acción label and radio buttons
                                    Text(
                                      'Acción',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                     Wrap(
                                       spacing: 16,
                                       runSpacing: 8,
                                       children: [
                                         _buildRadioOption(
                                           'Agregar',
                                           action == 'agregar',
                                           isDark,
                                           () => setDialogState(() => action = 'agregar'),
                                         ),
                                         _buildRadioOption(
                                           'Eliminar',
                                           action == 'eliminar',
                                           isDark,
                                           () => setDialogState(() => action = 'eliminar'),
                                         ),
                                       ],
                                     ),
                                    const SizedBox(height: 16),

                                    // Nombre del Insumo
                                    Text(
                                      'Nombre del Insumo',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: insumoNameController,
                                      style: GoogleFonts.inter(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Ej: Carne extra',
                                        hintStyle: GoogleFonts.inter(
                                          color: isDark ? Colors.white30 : AppColors.grey400,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Cantidad
                                    Text(
                                      'Cantidad',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(fontSize: 13),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Unidad Dropdown
                                    Text(
                                      'Unidad',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedUnit,
                                      onChanged: (val) => setDialogState(() => selectedUnit = val ?? 'und'),
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                        ),
                                      ),
                                      items: ['und', 'gr', 'kg', 'ml', 'lt', 'oz']
                                          .map((u) => DropdownMenuItem(
                                                value: u,
                                                child: Text(u, style: GoogleFonts.inter(fontSize: 13)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (selectedEventType == 'promo_precio') ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark.withAlpha(150)
                                      : AppColors.grey50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppColors.grey200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detalle del Precio',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Original price
                                    Row(
                                      children: [
                                        Text(
                                          'Precio original: ',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: isDark ? Colors.white70 : AppColors.grey700,
                                          ),
                                        ),
                                        Text(
                                          '\$${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Nuevo Precio Promocional
                                    Text(
                                      'Nuevo Precio Promocional',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: promoPriceController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: '\$ 0',
                                        hintStyle: GoogleFonts.inter(
                                          color: isDark ? Colors.white30 : AppColors.grey400,
                                          fontSize: 13,
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (selectedEventType == 'descuento') ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark.withAlpha(150)
                                      : AppColors.grey50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : AppColors.grey200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Detalle del Descuento',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Porcentaje de Descuento
                                    Text(
                                      'Porcentaje de Descuento (%)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : AppColors.grey700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: discountPercentageController,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.inter(fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: '10',
                                        hintStyle: GoogleFonts.inter(
                                          color: isDark ? Colors.white30 : AppColors.grey400,
                                          fontSize: 13,
                                        ),
                                        suffixText: '%',
                                        suffixStyle: GoogleFonts.inter(
                                          color: isDark ? Colors.white70 : AppColors.grey700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE28989), width: 1.5),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE28989), width: 1.5),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE28989), width: 2.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Evento Temporal switch card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark.withAlpha(150)
                                    : AppColors.grey50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : AppColors.grey200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Evento Temporal',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Activo solo en un rango de fechas',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isTemporal,
                                    onChanged: (val) => setDialogState(() => isTemporal = val),
                                    activeThumbColor: const Color(0xFF7C3AED),
                                    activeTrackColor: const Color(0xFF7C3AED).withAlpha(128),
                                  ),
                                ],
                              ),
                            ),

                            // Start and End date row (if Temporal)
                            if (isTemporal) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDateField(
                                      label: 'Inicio',
                                      value: formatDate(startDate),
                                      isDark: isDark,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: startDate ?? DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setDialogState(() => startDate = picked);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDateField(
                                      label: 'Fin',
                                      value: formatDate(endDate),
                                      isDark: isDark,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: endDate ?? (startDate ?? DateTime.now()),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setDialogState(() => endDate = picked);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                    // Bottom action buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.white10 : AppColors.grey200,
                          ),
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Cancelar button
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : AppColors.grey300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          ElevatedButton.icon(
                            onPressed: () {
                              final titleText = titleController.text.trim();
                              if (titleText.isEmpty) {
                                _showToastAlert(
                                  title: 'Error de Validación',
                                  message: 'El título del evento es obligatorio',
                                  isError: true,
                                );
                                return;
                              }

                              if (isTemporal) {
                                if (startDate == null) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'Debe seleccionar una fecha de inicio',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (endDate == null) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'Debe seleccionar una fecha de fin',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (endDate!.isBefore(startDate!)) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'La fecha de fin no puede ser anterior a la fecha de inicio',
                                    isError: true,
                                  );
                                  return;
                                }
                              }

                              if (selectedEventType == 'promo_precio') {
                                final promoText = promoPriceController.text.trim();
                                if (promoText.isEmpty) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'El precio de promoción es obligatorio',
                                    isError: true,
                                  );
                                  return;
                                }
                                final parsedPrice = double.tryParse(promoText);
                                if (parsedPrice == null || parsedPrice <= 0) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'Ingrese un precio de promoción válido y mayor a 0',
                                    isError: true,
                                  );
                                  return;
                                }
                              } else if (selectedEventType == 'descuento') {
                                final discountText = discountPercentageController.text.trim();
                                if (discountText.isEmpty) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'El porcentaje de descuento es obligatorio',
                                    isError: true,
                                  );
                                  return;
                                }
                                final parsedPct = double.tryParse(discountText);
                                if (parsedPct == null || parsedPct < 1 || parsedPct > 100) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'Ingrese un porcentaje de descuento válido entre 1 y 100',
                                    isError: true,
                                  );
                                  return;
                                }
                              } else if (selectedEventType == 'insumo_temp' || selectedEventType == 'insumo_perm') {
                                final insumoText = insumoNameController.text.trim();
                                if (insumoText.isEmpty) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'El nombre del insumo es obligatorio',
                                    isError: true,
                                  );
                                  return;
                                }
                                final qtyText = quantityController.text.trim();
                                if (qtyText.isEmpty) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'La cantidad del insumo es obligatoria',
                                    isError: true,
                                  );
                                  return;
                                }
                                final parsedQty = double.tryParse(qtyText);
                                if (parsedQty == null || parsedQty <= 0) {
                                  _showToastAlert(
                                    title: 'Error de Validación',
                                    message: 'Ingrese una cantidad de insumo válida y mayor a 0',
                                    isError: true,
                                  );
                                  return;
                                }
                              }

                              final newEvent = ProductEvent(
                                id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                                productId: product.id,
                                productName: product.name,
                                productEmoji: product.emoji,
                                type: selectedEventType,
                                title: titleText,
                                description: descriptionController.text.trim(),
                                action: action,
                                insumoName: insumoNameController.text.trim(),
                                quantity: quantityController.text.trim(),
                                unit: selectedUnit,
                                promoPrice: double.tryParse(promoPriceController.text),
                                discountPercentage: double.tryParse(discountPercentageController.text),
                                isTemporal: isTemporal,
                                startDate: isTemporal ? startDate : null,
                                endDate: isTemporal ? endDate : null,
                                createdAt: DateTime.now(),
                                isActive: true,
                              );

                              // Rebuild main list screen to update badges/chips
                              setState(() {
                                _customEvents.add(newEvent);
                              });

                              // Close dialog
                              Navigator.pop(ctx);

                              // Show custom slide-out toast alert
                              _showToastAlert(
                                title: 'Evento creado',
                                message: 'El evento "${titleController.text}" fue registrado para ${product.name}',
                              );
                            },
                            icon: const Icon(Icons.flash_on, size: 14, color: Colors.white),
                            label: Text(
                              'Crear Evento',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC084FC), // light purple background
                              minimumSize: const Size(0, 40),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  void _showToastAlert({required String title, required String message, bool isError = false}) {
    late OverlayEntry entry;

    void removeEntry() {
      if (entry.mounted) entry.remove();
      _toastEntries.remove(entry);
    }

    entry = OverlayEntry(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        final topOffset = topPadding + 12 + (_toastEntries.indexOf(entry).clamp(0, 5) * 86);
        return _ToastAlertWidget(
          title: title,
          message: message,
          topOffset: topOffset.toDouble(),
          onDismiss: removeEntry,
          isError: isError,
        );
      },
    );

    _toastEntries.add(entry);
    Overlay.of(context).insert(entry);
  }

  Widget _buildTypeCard({
    required String id,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2A2140) : const Color(0xFFF5F0FF))
              : (isDark ? AppColors.cardDark : Colors.white),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : (isDark ? Colors.white10 : AppColors.grey200),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : (isDark ? Colors.white70 : AppColors.grey700),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String text, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF7C3AED) : AppColors.grey400,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7C3AED),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 14,
              color: isDark ? Colors.white54 : AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.grey700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white10 : AppColors.grey200,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: value == 'dd/mm/aaaa'
                          ? (isDark ? Colors.white30 : AppColors.grey400)
                          : (isDark ? Colors.white : AppColors.textPrimaryLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stat Box (matching Figma 2×2 grid) ───
class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String subtitle;
  final bool isSmallValue;
  final bool isDark;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.subtitle,
    this.isSmallValue = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withAlpha(26) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: isSmallValue ? 11 : 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Figma Product Card ───
class _FigmaProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final int eventCount;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCreateEvent;

  const _FigmaProductCard({
    required this.product,
    required this.isDark,
    this.eventCount = 0,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Image Area with Gradient ───
          Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    product.emoji,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),
              // Badge: Popular or Bajo Stock (top-left)
              if (product.isPopular || product.name == 'Muslito de Pollo')
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.name == 'Muslito de Pollo' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.name == 'Muslito de Pollo' ? Icons.error_outline_rounded : Icons.star_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.name == 'Muslito de Pollo' ? 'Bajo Stock' : 'Popular',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Badge: Disponible (top-right)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.isActive
                        ? AppColors.success.withAlpha(230)
                        : AppColors.error.withAlpha(230),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.isActive ? 'Disponible' : 'No Disponible',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Badge: Event count (bottom-left)
              if (eventCount > 0)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '$eventCount evento${eventCount > 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // ─── Product Info ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Price & Sold Row ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Precio',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppColors.grey400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${_formatShortPrice(product.price)}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: isDark ? Colors.white10 : AppColors.grey200,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Vendidos',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : AppColors.grey400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.totalSold.toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

  // ─── "Crear Evento" button ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: onCreateEvent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E1A47) : const Color(0xFFF9F5FF),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4C2A75) : const Color(0xFFE9D7FE),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: isDark ? const Color(0xFFD6BBFB) : const Color(0xFF7F56D9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Crear Evento',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFD6BBFB) : const Color(0xFF7F56D9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ─── Actions Row ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn(Icons.visibility_outlined, 'Ver', AppColors.info, onView),
                _actionBtn(Icons.edit_outlined, 'Editar', AppColors.success, onEdit),
                _actionBtn(Icons.delete_outline, 'Eliminar', AppColors.error, onDelete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }
}

// ─── Animated Toast Alert Widget ───
class _ToastAlertWidget extends StatefulWidget {
  final String title;
  final String message;
  final double topOffset;
  final VoidCallback onDismiss;
  final bool isError;

  const _ToastAlertWidget({
    required this.title,
    required this.message,
    required this.topOffset,
    required this.onDismiss,
    this.isError = false,
  });

  @override
  State<_ToastAlertWidget> createState() => _ToastAlertWidgetState();
}

class _ToastAlertWidgetState extends State<_ToastAlertWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  Timer? _autoTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after 4 seconds by sliding right
    _autoTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _autoTimer?.cancel();
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final borderColor = widget.isError ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0);
    final iconBgColor = widget.isError ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7);
    final iconColor = widget.isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    final titleColor = widget.isError ? const Color(0xFF991B1B) : const Color(0xFF14532D);
    final msgColor = widget.isError ? const Color(0xFFB91C1C) : const Color(0xFF15803D);
    final iconData = widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Positioned(
      top: widget.topOffset,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: GoogleFonts.inter(
                            color: msgColor,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6B7280),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
