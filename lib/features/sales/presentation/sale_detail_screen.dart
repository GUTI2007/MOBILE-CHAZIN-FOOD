import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/sale_model.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;

  const SaleDetailScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Venta #${sale.id.replaceAll('sale_', '').substring(0, 3)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingScreen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(77),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: AppDimens.sm),
                  Text(
                    Formatters.currency(sale.total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      sale.statusName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.lg),

            // ─── Client Info ───
            _buildSection(
              context,
              'Información del Cliente',
              Icons.person_rounded,
              [
                _infoTile(context, 'Nombre', sale.clientName, isDark),
                _infoTile(context, 'Fecha', Formatters.dateTime(sale.createdAt), isDark),
                _infoTile(context, 'Método de pago', sale.paymentMethodName, isDark),
              ],
              isDark,
            ),
            const SizedBox(height: AppDimens.md),

            // ─── Products ───
            _buildSection(
              context,
              'Productos',
              Icons.shopping_bag_rounded,
              sale.details
                  .map((d) => _productTile(context, d, isDark))
                  .toList(),
              isDark,
            ),
            const SizedBox(height: AppDimens.md),

            // ─── Totals ───
            Container(
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
                  _totalRow(context, AppStrings.subtotal, sale.subtotal),
                  if (sale.discount > 0)
                    _totalRow(context, AppStrings.discount, -sale.discount, isDiscount: true),
                  const Divider(height: AppDimens.lg),
                  _totalRow(context, AppStrings.total, sale.total, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.md),

            // ─── Production Order ───
            Container(
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(26),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.info.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.factory_rounded, color: AppColors.info),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden de Producción',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.info),
                        ),
                        Text(
                          'Generada automáticamente',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children, bool isDark) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppDimens.sm),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: AppDimens.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _productTile(BuildContext context, SaleDetail detail, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Center(
              child: Text(
                'x${detail.quantity}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.productName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text('${Formatters.currency(detail.unitPrice)} c/u', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            Formatters.currency(detail.subtotal),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(BuildContext context, String label, double amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyLarge),
          Text(
            '${isDiscount ? '-' : ''}${Formatters.currency(amount.abs())}',
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
                : isDiscount
                    ? const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)
                    : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
