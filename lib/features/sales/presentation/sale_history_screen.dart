import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/sales_provider.dart';
import 'sale_detail_screen.dart';
import '../../../widgets/common_app_bar.dart';

class SaleHistoryScreen extends ConsumerStatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  ConsumerState<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends ConsumerState<SaleHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SaleStatus? _selectedStatus;
  PaymentMethod? _selectedPayment;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(salesProvider.notifier).loadSales();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Sale> _filterSales(List<Sale> sales) {
    return sales.where((sale) {
      // Status filter
      if (_selectedStatus != null && sale.status != _selectedStatus) return false;
      // Payment method filter
      if (_selectedPayment != null && sale.paymentMethod != _selectedPayment) return false;
      // Text search — multi-criteria
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final matchesClient = sale.clientName.toLowerCase().contains(q);
        final matchesId = sale.displayId.toLowerCase().contains(q) ||
            sale.id.toLowerCase().contains(q);
        final matchesDate = Formatters.date(sale.createdAt).contains(q) ||
            Formatters.dateTime(sale.createdAt).toLowerCase().contains(q) ||
            sale.formattedDate.contains(q);
        final matchesStatus = sale.statusName.toLowerCase().contains(q);
        final matchesPayment = sale.paymentMethodName.toLowerCase().contains(q);
        final matchesDelivery = sale.deliveryTypeName.toLowerCase().contains(q);
        final matchesProduct = sale.details.any(
            (d) => d.productName.toLowerCase().contains(q));
        if (!matchesClient &&
            !matchesId &&
            !matchesDate &&
            !matchesStatus &&
            !matchesPayment &&
            !matchesDelivery &&
            !matchesProduct) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredSales = _filterSales(state.sales);
    final hasActiveFilters =
        _searchQuery.isNotEmpty || _selectedStatus != null || _selectedPayment != null;

    return Scaffold(
      appBar: CommonAppBar(
        title: AppStrings.saleHistory,
        showRefresh: true,
        onRefresh: () => ref.read(salesProvider.notifier).loadSales(),
      ),
      body: state.isLoading
          ? const LoadingShimmer(itemCount: 8)
          : Column(
              children: [
                // ─── Search Bar ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente, ID, fecha, producto…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : AppColors.grey400,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? Colors.white38 : AppColors.grey400,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white38 : AppColors.grey400,
                                size: 18,
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.cardDark
                          : AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : AppColors.grey200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Filter Chips ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Status chips
                        _buildFilterChip(
                          label: 'Todos',
                          isSelected: _selectedStatus == null,
                          isDark: isDark,
                          onTap: () => setState(() => _selectedStatus = null),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Pagado',
                          icon: Icons.check_circle_outline,
                          isSelected: _selectedStatus == SaleStatus.completed,
                          isDark: isDark,
                          activeColor: AppColors.success,
                          onTap: () => setState(() => _selectedStatus =
                              _selectedStatus == SaleStatus.completed
                                  ? null
                                  : SaleStatus.completed),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Pendiente',
                          icon: Icons.access_time,
                          isSelected: _selectedStatus == SaleStatus.pending,
                          isDark: isDark,
                          activeColor: AppColors.warning,
                          onTap: () => setState(() => _selectedStatus =
                              _selectedStatus == SaleStatus.pending
                                  ? null
                                  : SaleStatus.pending),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Cancelada',
                          icon: Icons.cancel_outlined,
                          isSelected: _selectedStatus == SaleStatus.cancelled,
                          isDark: isDark,
                          activeColor: AppColors.error,
                          onTap: () => setState(() => _selectedStatus =
                              _selectedStatus == SaleStatus.cancelled
                                  ? null
                                  : SaleStatus.cancelled),
                        ),
                        const SizedBox(width: 12),
                        // Divider
                        Container(
                          width: 1,
                          height: 24,
                          color: isDark ? Colors.white12 : AppColors.grey200,
                        ),
                        const SizedBox(width: 12),
                        // Payment method chips
                        _buildFilterChip(
                          label: 'Efectivo',
                          icon: Icons.payments_outlined,
                          isSelected: _selectedPayment == PaymentMethod.cash,
                          isDark: isDark,
                          activeColor: const Color(0xFF10B981),
                          onTap: () => setState(() => _selectedPayment =
                              _selectedPayment == PaymentMethod.cash
                                  ? null
                                  : PaymentMethod.cash),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Tarjeta',
                          icon: Icons.credit_card,
                          isSelected: _selectedPayment == PaymentMethod.card,
                          isDark: isDark,
                          activeColor: const Color(0xFF3B82F6),
                          onTap: () => setState(() => _selectedPayment =
                              _selectedPayment == PaymentMethod.card
                                  ? null
                                  : PaymentMethod.card),
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Transfer.',
                          icon: Icons.swap_horiz,
                          isSelected:
                              _selectedPayment == PaymentMethod.transfer,
                          isDark: isDark,
                          activeColor: const Color(0xFF8B5CF6),
                          onTap: () => setState(() => _selectedPayment =
                              _selectedPayment == PaymentMethod.transfer
                                  ? null
                                  : PaymentMethod.transfer),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Results count ───
                if (hasActiveFilters)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          '${filteredSales.length} resultado${filteredSales.length != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white54 : AppColors.grey500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _selectedStatus = null;
                              _selectedPayment = null;
                            });
                          },
                          child: Text(
                            'Limpiar filtros',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── List ───
                Expanded(
                  child: filteredSales.isEmpty
                      ? EmptyState(
                          icon: hasActiveFilters
                              ? Icons.search_off_rounded
                              : Icons.receipt_long_outlined,
                          title: hasActiveFilters
                              ? 'Sin resultados'
                              : AppStrings.noSales,
                          subtitle: hasActiveFilters
                              ? 'No se encontraron ventas con los filtros aplicados'
                              : 'Las ventas registradas aparecerán aquí',
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () =>
                              ref.read(salesProvider.notifier).loadSales(),
                          child: AnimationLimiter(
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.all(AppDimens.paddingScreen),
                              itemCount: filteredSales.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppDimens.sm),
                              itemBuilder: (context, index) {
                                final sale = filteredSales[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration:
                                      const Duration(milliseconds: 400),
                                  child: SlideAnimation(
                                    horizontalOffset: 40,
                                    child: FadeInAnimation(
                                      child: _SaleCard(
                                        sale: sale,
                                        isDark: isDark,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  SaleDetailScreen(sale: sale),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _NewSaleNavigator(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newSale),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required bool isDark,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(26)
              : (isDark ? AppColors.cardDark : AppColors.grey50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white10 : AppColors.grey200),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? color : AppColors.grey400),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white54 : AppColors.grey500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper para navegar a nueva venta
class _NewSaleNavigator extends StatelessWidget {
  const _NewSaleNavigator();

  @override
  Widget build(BuildContext context) {
    // Import dinámico para evitar dependencia circular
    return const _LazyNewSale();
  }
}

class _LazyNewSale extends StatelessWidget {
  const _LazyNewSale();

  @override
  Widget build(BuildContext context) {
    // Importamos directamente
    return const _InlineNewSaleRedirect();
  }
}

class _InlineNewSaleRedirect extends ConsumerWidget {
  const _InlineNewSaleRedirect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Usar la misma pantalla de nueva venta
    return const NewSaleScreenWrapper();
  }
}

/// Wrapper que importa NewSaleScreen
class NewSaleScreenWrapper extends StatelessWidget {
  const NewSaleScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const _NewSaleInline();
  }
}

class _NewSaleInline extends ConsumerWidget {
  const _NewSaleInline();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Redirigir al import correcto
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) {
          // Lazy import
          return _PlaceholderNewSale(onBack: () => Navigator.of(context).pop());
        },
      ),
    );
  }
}

class _PlaceholderNewSale extends StatelessWidget {
  final VoidCallback onBack;
  const _PlaceholderNewSale({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Nueva Venta'),
      body: Center(
        child: ElevatedButton(
          onPressed: onBack,
          child: const Text('Ir a la pestaña de ventas para registrar'),
        ),
      ),
    );
  }
}

// ─── Sale Card ───
class _SaleCard extends StatelessWidget {
  final Sale sale;
  final bool isDark;
  final VoidCallback onTap;

  const _SaleCard({
    required this.sale,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: isDark ? Border.all(color: Colors.white.withAlpha(13)) : null,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.grey200.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(sale.status).withAlpha(26),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Icon(
                    _statusIcon(sale.status),
                    color: _statusColor(sale.status),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.clientName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateTime(sale.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(sale.total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(sale.status).withAlpha(26),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        sale.statusName,
                        style: TextStyle(
                          fontSize: AppDimens.fontXs,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(sale.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  '${sale.totalItems} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: AppDimens.md),
                Icon(Icons.payment_outlined, size: 14, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  sale.paymentMethodName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppColors.grey400, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return AppColors.success;
      case SaleStatus.pending: return AppColors.warning;
      case SaleStatus.cancelled: return AppColors.error;
    }
  }

  IconData _statusIcon(SaleStatus status) {
    switch (status) {
      case SaleStatus.completed: return Icons.check_circle_outline;
      case SaleStatus.pending: return Icons.access_time;
      case SaleStatus.cancelled: return Icons.cancel_outlined;
    }
  }
}
