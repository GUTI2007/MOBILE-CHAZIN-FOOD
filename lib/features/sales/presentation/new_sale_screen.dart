import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/sale_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../products/providers/products_provider.dart';
import '../providers/sales_provider.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(newSaleProvider.notifier).reset();
      ref.read(productsProvider.notifier).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleState = ref.watch(newSaleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (saleState.isCompleted) {
      return _SuccessScreen(
        onDone: () {
          ref.read(newSaleProvider.notifier).reset();
          ref.read(salesProvider.notifier).loadSales();
          Navigator.pop(context);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newSale),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(newSaleProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // ─── Step Indicator ───
          _StepIndicator(currentStep: saleState.currentStep),

          // ─── Step Content ───
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(saleState, isDark),
            ),
          ),

          // ─── Bottom Buttons ───
          Container(
            padding: const EdgeInsets.all(AppDimens.paddingScreen),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (saleState.currentStep > 0)
                  Expanded(
                    child: AppButton(
                      text: AppStrings.previous,
                      onPressed: () => ref.read(newSaleProvider.notifier).previousStep(),
                      isOutlined: true,
                    ),
                  ),
                if (saleState.currentStep > 0) const SizedBox(width: AppDimens.md),
                Expanded(
                  flex: saleState.currentStep == 0 ? 1 : 1,
                  child: saleState.currentStep == 5
                      ? AppButton(
                          text: AppStrings.confirmSale,
                          onPressed: saleState.isProcessing
                              ? null
                              : () => ref.read(newSaleProvider.notifier).confirmSale(),
                          isLoading: saleState.isProcessing,
                          icon: Icons.check_circle_rounded,
                        )
                      : AppButton(
                          text: AppStrings.next,
                          onPressed: saleState.canProceed
                              ? () => ref.read(newSaleProvider.notifier).nextStep()
                              : null,
                          icon: Icons.arrow_forward_rounded,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(NewSaleState state, bool isDark) {
    switch (state.currentStep) {
      case 0:
        return _ClientSelectionStep(key: const ValueKey(0));
      case 1:
        return _ProductSelectionStep(key: const ValueKey(1));
      case 2:
        return _TotalStep(state: state, isDark: isDark, key: const ValueKey(2));
      case 3:
        return _LoyaltyStep(state: state, isDark: isDark, key: const ValueKey(3));
      case 4:
        return _PaymentStep(state: state, isDark: isDark, key: const ValueKey(4));
      case 5:
        return _ConfirmationStep(state: state, isDark: isDark, key: const ValueKey(5));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ════════════════════════════════════════════
// STEP INDICATOR
// ════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const _steps = ['Cliente', 'Productos', 'Total', 'Fidelización', 'Pago', 'Confirmar'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.primary
                    : AppColors.grey300,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == currentStep;
          final isDone = stepIndex < currentStep;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primary
                      : isActive
                          ? AppColors.primary.withAlpha(26)
                          : AppColors.grey200,
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.primary : AppColors.grey500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[stepIndex],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.primary : AppColors.grey500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════
// STEP 0: CLIENT SELECTION
// ════════════════════════════════════════════

class _ClientSelectionStep extends ConsumerWidget {
  const _ClientSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    final selectedClient = ref.watch(newSaleProvider).selectedClient;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return clients.when(
      data: (clientList) => ListView.separated(
        padding: const EdgeInsets.all(AppDimens.paddingScreen),
        itemCount: clientList.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppDimens.sm),
        itemBuilder: (_, index) {
          final client = clientList[index];
          final isSelected = selectedClient?.id == client.id;

          return GestureDetector(
            onTap: () => ref.read(newSaleProvider.notifier).selectClient(client),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppDimens.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(26)
                    : isDark
                        ? AppColors.cardDark
                        : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.grey200.withAlpha(64),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accent.withAlpha(51),
                    child: Text(
                      client.initials,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentDark),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(client.phone ?? '', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text('${client.loyaltyPoints} pts'),
                    backgroundColor: AppColors.accent.withAlpha(26),
                    labelStyle: const TextStyle(fontSize: 11, color: AppColors.accentDark),
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.check_circle, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error cargando clientes')),
    );
  }
}

// ════════════════════════════════════════════
// STEP 1: PRODUCT SELECTION
// ════════════════════════════════════════════

class _ProductSelectionStep extends ConsumerWidget {
  const _ProductSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);
    final cartItems = ref.watch(newSaleProvider).cartItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeProducts = productsState.products.where((p) => p.isActive).toList();

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.paddingScreen),
      itemCount: activeProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.sm),
      itemBuilder: (_, index) {
        final product = activeProducts[index];
        final inCart = cartItems.where((i) => i.product.id == product.id);
        final qty = inCart.isNotEmpty ? inCart.first.quantity : 0;

        return Container(
          padding: const EdgeInsets.all(AppDimens.md),
          decoration: BoxDecoration(
            color: qty > 0
                ? AppColors.primary.withAlpha(13)
                : isDark
                    ? AppColors.cardDark
                    : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: qty > 0
                ? Border.all(color: AppColors.primary.withAlpha(64))
                : isDark
                    ? Border.all(color: Colors.white.withAlpha(13))
                    : null,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.grey200.withAlpha(64),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.currency(product.price),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (qty == 0)
                IconButton(
                  onPressed: () => ref.read(newSaleProvider.notifier).addProduct(product),
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 32),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                      onPressed: () => ref.read(newSaleProvider.notifier).updateQuantity(product.id, qty - 1),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.center,
                      child: Text(
                        '$qty',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () => ref.read(newSaleProvider.notifier).updateQuantity(product.id, qty + 1),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════
// STEP 2: TOTAL
// ════════════════════════════════════════════

class _TotalStep extends StatelessWidget {
  final NewSaleState state;
  final bool isDark;

  const _TotalStep({super.key, required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del pedido', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimens.md),
          ...state.cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimens.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.product.name} x${item.quantity}',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Text(Formatters.currency(item.subtotal),
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              )),
          const Divider(height: AppDimens.xl),
          _totalRow(context, AppStrings.subtotal, state.subtotal),
          if (state.discount > 0) _totalRow(context, AppStrings.discount, -state.discount, isDiscount: true),
          const Divider(height: AppDimens.lg),
          _totalRow(context, AppStrings.total, state.total, isTotal: true),
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
          Text(
            label,
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            Formatters.currency(amount.abs()),
            style: isTotal
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    )
                : isDiscount
                    ? TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)
                    : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// STEP 3: LOYALTY
// ════════════════════════════════════════════

class _LoyaltyStep extends StatelessWidget {
  final NewSaleState state;
  final bool isDark;

  const _LoyaltyStep({super.key, required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final points = state.selectedClient?.loyaltyPoints ?? 0;
    final hasDiscount = points > 200;

    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingScreen),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasDiscount ? Icons.loyalty_rounded : Icons.card_giftcard_rounded,
            size: 64,
            color: hasDiscount ? AppColors.accent : AppColors.grey400,
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            '${state.selectedClient?.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppDimens.sm),
          Text(
            '$points puntos de fidelización',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                ),
          ),
          const SizedBox(height: AppDimens.lg),
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              color: hasDiscount
                  ? AppColors.success.withAlpha(26)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  hasDiscount ? Icons.check_circle : Icons.info_outline,
                  color: hasDiscount ? AppColors.success : AppColors.grey500,
                ),
                const SizedBox(width: AppDimens.md),
                Expanded(
                  child: Text(
                    hasDiscount
                        ? '¡Descuento del 5% aplicado automáticamente! (-${Formatters.currency(state.discount)})'
                        : 'Se necesitan más de 200 puntos para obtener un descuento del 5%.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// STEP 4: PAYMENT
// ════════════════════════════════════════════

class _PaymentStep extends ConsumerWidget {
  final NewSaleState state;
  final bool isDark;

  const _PaymentStep({super.key, required this.state, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.paddingScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.paymentMethod, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimens.lg),
          _paymentOption(context, ref, PaymentMethod.cash, Icons.money_rounded, AppStrings.cash, AppColors.success),
          const SizedBox(height: AppDimens.md),
          _paymentOption(context, ref, PaymentMethod.card, Icons.credit_card_rounded, AppStrings.card, AppColors.info),
          const SizedBox(height: AppDimens.md),
          _paymentOption(context, ref, PaymentMethod.transfer, Icons.account_balance_rounded, AppStrings.transfer, AppColors.accent),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(AppDimens.md),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a pagar', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  Formatters.currency(state.total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(BuildContext context, WidgetRef ref, PaymentMethod method, IconData icon, String label, Color color) {
    final isSelected = state.paymentMethod == method;

    return GestureDetector(
      onTap: () => ref.read(newSaleProvider.notifier).setPaymentMethod(method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimens.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(26) : isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: AppDimens.md),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: color),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
// STEP 5: CONFIRMATION
// ════════════════════════════════════════════

class _ConfirmationStep extends StatelessWidget {
  final NewSaleState state;
  final bool isDark;

  const _ConfirmationStep({super.key, required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingScreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirmación', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppDimens.md),

          _infoRow(context, 'Cliente', state.selectedClient?.name ?? ''),
          _infoRow(context, 'Items', '${state.cartItems.length} productos'),
          _infoRow(context, 'Subtotal', Formatters.currency(state.subtotal)),
          if (state.discount > 0) _infoRow(context, 'Descuento', '-${Formatters.currency(state.discount)}'),
          _infoRow(context, 'Método de pago', state.paymentMethod == PaymentMethod.cash
              ? AppStrings.cash
              : state.paymentMethod == PaymentMethod.card
                  ? AppStrings.card
                  : AppStrings.transfer),
          const Divider(height: AppDimens.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: Theme.of(context).textTheme.headlineMedium),
              Text(
                Formatters.currency(state.total),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
// SUCCESS SCREEN
// ════════════════════════════════════════════

class _SuccessScreen extends StatelessWidget {
  final VoidCallback onDone;

  const _SuccessScreen({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.xl),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppDimens.xl),
              Text(
                AppStrings.saleConfirmed,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.sm),
              Text(
                'La orden de producción ha sido generada automáticamente.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.xxl),
              AppButton(
                text: 'Volver al inicio',
                onPressed: onDone,
                icon: Icons.home_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
