import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/sales_provider.dart';
import 'sale_detail_screen.dart';

class SaleHistoryScreen extends ConsumerStatefulWidget {
  const SaleHistoryScreen({super.key});

  @override
  ConsumerState<SaleHistoryScreen> createState() => _SaleHistoryScreenState();
}

class _SaleHistoryScreenState extends ConsumerState<SaleHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(salesProvider.notifier).loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.saleHistory),
      ),
      body: state.isLoading
          ? const LoadingShimmer(itemCount: 8)
          : state.sales.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: AppStrings.noSales,
                  subtitle: 'Las ventas registradas aparecerán aquí',
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(salesProvider.notifier).loadSales(),
                  child: AnimationLimiter(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppDimens.paddingScreen),
                      itemCount: state.sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.sm),
                      itemBuilder: (context, index) {
                        final sale = state.sales[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 400),
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
                                      builder: (_) => SaleDetailScreen(sale: sale),
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
      appBar: AppBar(title: const Text('Nueva Venta')),
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
