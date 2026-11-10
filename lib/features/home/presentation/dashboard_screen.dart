import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/navigation_provider.dart';
import '../../sales/providers/dashboard_provider.dart';
import '../../sales/providers/orders_provider.dart';
import '../../../shared/models/dashboard_stats_model.dart';
import '../../../widgets/common_app_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Tooltip product bar chart state
  String? _activeTooltipProduct;
  int? _activeTooltipCount;
  int? _selectedMonthIndex;

  // Período seleccionado para filtro histórico
  String _periodoSeleccionado = 'Mes Actual';
  bool _showKpiDash = true;

  static const List<String> _periodos = [
    'Hoy',
    '7 Días',
    'Mes Actual',
    'Mes Anterior',
    'Últimos 3 Meses',
    'Últimos 6 Meses',
    'Año Actual',
    'Año Anterior',
    'Histórico',
    '2026',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats;

    return Scaffold(
      appBar: const CommonAppBar(
        showBrandHeader: true,
        showDrawerMenu: true,
        showDarkModeToggle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).loadDashboardData(periodo: _periodoSeleccionado);
            await ref.read(ordersProvider.notifier).loadOrders();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: AnimationLimiter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 450),
                  childAnimationBuilder: (w) => SlideAnimation(
                    verticalOffset: 30,
                    child: FadeInAnimation(child: w),
                  ),
                  children: [
                    // ─── Header title ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel de Control',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                _periodoSeleccionado,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón toggle KPIs
                        GestureDetector(
                          onTap: () => setState(() => _showKpiDash = !_showKpiDash),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _showKpiDash
                                  ? AppColors.primary.withAlpha(20)
                                  : (isDark ? Colors.white10 : AppColors.grey100),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _showKpiDash ? AppColors.primary : (isDark ? Colors.white24 : AppColors.grey300),
                              ),
                            ),
                            child: Icon(
                              _showKpiDash ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              size: 16,
                              color: _showKpiDash ? AppColors.primary : (isDark ? Colors.white54 : AppColors.grey500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón dedicado de filtro período
                        GestureDetector(
                          onTap: () => _showPeriodPicker(context, isDark),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : AppColors.grey50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white24 : AppColors.grey300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 15,
                                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: isDark ? Colors.white54 : AppColors.grey500,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Metric Cards (2x2 Grid) — condicional al toggle ───
                    if (_showKpiDash) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.attach_money_rounded,
                              iconColor: const Color(0xFF10B981),
                              iconBg: const Color(0xFFD1FAE5),
                              label: _periodoSeleccionado == 'Mes Actual'
                                  ? 'Ventas del Mes'
                                  : 'Ventas del Período',
                              value: Formatters.currency(stats.ventasTotal),
                              trendText: '${stats.ventasVariacion >= 0 ? '↗ +' : '↘ '}${stats.ventasVariacion.toStringAsFixed(1)}%',
                              trendColor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.shopping_cart_outlined,
                              iconColor: const Color(0xFF3B82F6),
                              iconBg: const Color(0xFFDBEAFE),
                              label: 'Total Pedidos',
                              value: '${stats.pedidosTotal}',
                              trendText: '${stats.pedidosVariacion >= 0 ? '↗ +' : '↘ '}${stats.pedidosVariacion.toStringAsFixed(1)}%',
                              trendColor: const Color(0xFF3B82F6),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.people_outline_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              iconBg: const Color(0xFFEDE9FE),
                              label: 'Clientes Activos',
                              value: '${stats.clientesActivos}',
                              trendText: '${stats.clientesVariacion >= 0 ? '↗ +' : '↘ '}${stats.clientesVariacion.toStringAsFixed(1)}%',
                              trendColor: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.inventory_2_outlined,
                              iconColor: const Color(0xFFEF4444),
                              iconBg: const Color(0xFFFEE2E2),
                              label: 'Stock Crítico',
                              value: '${dashboardState.alertasStock.where((a) => a.stock < 10).length}',
                              trendText: 'Insumos < 10 uds',
                              trendColor: const Color(0xFFEF4444),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],


                    // ─── Ventas y Compras Chart ───
                    _buildVentasComprasChart(isDark, dashboardState.ventasChart),
                    const SizedBox(height: 24),

                    // ─── Productos Más Vendidos Chart ───
                    _buildProductosMasVendidos(isDark, dashboardState.productosPopulares),
                    const SizedBox(height: 24),

                    // ─── Alertas de Stock ───
                    _buildAlertasDeStock(isDark, dashboardState.alertasStock),
                    const SizedBox(height: 24),

                    // ─── Ventas Pendientes ───
                    _buildVentasPendientes(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  void _showPeriodPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrar por período',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _periodos.map((p) {
                        final isSelected = p == _periodoSeleccionado;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withAlpha(20) : (isDark ? Colors.white10 : AppColors.grey50),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : AppColors.grey500),
                            ),
                          ),
                          title: Text(
                            p,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18)
                              : null,
                          onTap: () {
                            setState(() => _periodoSeleccionado = p);
                            ref.read(dashboardProvider.notifier).loadDashboardData(periodo: p);
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String trendText,
    required Color trendColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDark
            ? Border.all(color: Colors.white12)
            : Border.all(color: const Color(0xFFF1F3F5)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: icon + trend badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withAlpha(38) : iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: trendColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      trendText,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Value & label compactos y bien centrados
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 1.5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Custom Line Chart for "Ventas y Compras"
  Widget _buildVentasComprasChart(bool isDark, List<VentasChartData> chartData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas y Compras',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          // Chart Graphic
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final list = chartData.isNotEmpty
                  ? chartData
                  : const [
                      VentasChartData(mes: 'Sem 1-7', ventas: 0, compras: 0),
                      VentasChartData(mes: 'Sem 8-14', ventas: 0, compras: 0),
                      VentasChartData(mes: 'Sem 15-21', ventas: 0, compras: 0),
                      VentasChartData(mes: 'Sem 22-fin', ventas: 0, compras: 0),
                    ];
              final int count = list.length;
              final double stepX = count > 1 ? (width - 48) / (count - 1) : (width - 48);
              final double selectedX = _selectedMonthIndex != null
                  ? 36 + _selectedMonthIndex! * stepX
                  : 0.0;

              final currentMonth = (_selectedMonthIndex != null && _selectedMonthIndex! < count)
                  ? list[_selectedMonthIndex!].mes
                  : '';
              final currentIngreso = (_selectedMonthIndex != null && _selectedMonthIndex! < count)
                  ? Formatters.currency(list[_selectedMonthIndex!].ventas)
                  : '';
              final currentEgreso = (_selectedMonthIndex != null && _selectedMonthIndex! < count)
                  ? Formatters.currency(list[_selectedMonthIndex!].compras)
                  : '';

              return GestureDetector(
                onTapDown: (details) {
                  final double localX = details.localPosition.dx;
                  final double relativeX = localX - 36;
                  int idx = (relativeX + (stepX / 2)) ~/ stepX;
                  if (idx >= 0 && idx < count) {
                    setState(() {
                      _selectedMonthIndex = (_selectedMonthIndex == idx) ? null : idx;
                    });
                  } else {
                    setState(() {
                      _selectedMonthIndex = null;
                    });
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _LineChartPainter(
                          data: list,
                          isDark: isDark,
                          selectedIndex: _selectedMonthIndex,
                        ),
                      ),
                    ),
                    // Floating popover tooltip in line chart matching Capture 3
                    if (_selectedMonthIndex != null && _selectedMonthIndex! < count)
                      Positioned(
                        top: 10,
                        left: (selectedX - 70).clamp(10, width - 150),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentMonth,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ventas : $currentIngreso',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Compras : $currentEgreso',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegendItem('Compras', const Color(0xFF10B981)),
              const SizedBox(width: 24),
              _chartLegendItem('Ventas', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7E818C),
          ),
        ),
      ],
    );
  }

  // Horizonal Bar Chart for "Productos Más Vendidos"
  Widget _buildProductosMasVendidos(bool isDark, List<PopularProductItem> popularItems) {
    final products = popularItems.isNotEmpty
        ? popularItems.map((p) => {'name': p.nombre, 'val': p.ventas}).toList()
        : [
            {'name': 'Hamburguesa Especial', 'val': 240},
            {'name': 'Salchipapa Grande', 'val': 195},
            {'name': 'Perro Caliente', 'val': 80},
            {'name': 'Pollo Broaster', 'val': 80},
            {'name': 'Papas Fritas', 'val': 120},
          ];
    final int maxVal = products.map((e) => e['val'] as int).fold(1, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Productos Más Vendidos',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: products.map((p) {
                  final name = p['name'] as String;
                  final val = p['val'] as int;
                  final isSelected = name == _activeTooltipProduct;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_activeTooltipProduct == name) {
                          _activeTooltipProduct = null;
                          _activeTooltipCount = null;
                        } else {
                          _activeTooltipProduct = name;
                          _activeTooltipCount = val + 4;
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                // Background Bar track
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                // Fill Bar green
                                FractionallySizedBox(
                                  widthFactor: (val / maxVal).clamp(0.04, 1.0),
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF86EFAC)
                                          : const Color(0xFF10B981).withAlpha(160),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              // Floating popover tooltip in chart
              if (_activeTooltipProduct != null && _activeTooltipCount != null)
                Positioned(
                  top: products.indexWhere((p) => p['name'] == _activeTooltipProduct) * 32.0 + 8,
                  right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeTooltipProduct!,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ventas : $_activeTooltipCount',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Chart Bottom Axis Numbers
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 98.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                Text('65', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                Text('130', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                Text('195', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                Text('260', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stock alerts — solo insumos con stock < 10 unidades (regla estricta de stock crítico)
  Widget _buildAlertasDeStock(bool isDark, List<StockAlertItem> stockAlerts) {
    // Filtrar: solo los que tengan stock estrictamente menor a 10
    final criticos = stockAlerts.where((a) => a.stock < 10).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock Crítico (< 10 unidades)',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: criticos.isEmpty ? (isDark ? Colors.white10 : const Color(0xFFF0FDF4)) : (isDark ? const Color(0xFF3E1F21) : const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${criticos.length} alertas',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: criticos.isEmpty ? (isDark ? Colors.white38 : const Color(0xFF16A34A)) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (criticos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Inventario al día — sin alertas críticas',
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF166534)),
                  ),
                ],
              ),
            )
          else
            Column(
              children: criticos.map((a) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3E1F21) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF5A2A2D) : const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.nombre,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D),
                              ),
                            ),
                            Text(
                              '${a.stock} uds disponibles (mín. ${a.minimo})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF5A2A2D) : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          '⚠ Crítico',
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Ventas Pendientes — solo las órdenes con estado 'pendiente' del backend, con hora exacta
  Widget _buildVentasPendientes(bool isDark) {
    final ordersState = ref.watch(ordersProvider);

    // Filtrar SOLO las órdenes con estado pendiente, ordenadas por hora desc
    final pendientes = ordersState.orders
        .where((o) => o.estado == 'pendiente')
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ventas Pendientes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(appShellIndexProvider.notifier).state = 2;
                },
                child: Text(
                  'Ver todo ›',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (ordersState.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ))
          else if (pendientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Sin ventas pendientes en este momento',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: pendientes.map((o) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                o.id,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Pendiente',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // hora exacta del timestamp del backend (HH:mm)
                            '${o.cliente} • ${o.hora}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        Formatters.currency(o.total),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Custom Line Chart Painter ───
class _LineChartPainter extends CustomPainter {
  final List<VentasChartData> data;
  final bool isDark;
  final int? selectedIndex;

  _LineChartPainter({
    required this.data,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final axisTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    if (data.isEmpty) {
      final y = size.height / 2;
      canvas.drawLine(Offset(32, y), Offset(size.width, y), gridPaint);
      return;
    }

    // Determine maxVal dynamically with comfortable headroom
    double maxVal = 0;
    for (var d in data) {
      if (d.ventas > maxVal) maxVal = d.ventas;
      if (d.compras > maxVal) maxVal = d.compras;
    }
    if (maxVal <= 0) maxVal = 50000;
    maxVal = maxVal * 1.15; // 15% top headroom

    // Draw horizontal dashed lines
    final double stepY = size.height / 4;
    for (int i = 0; i <= 4; i++) {
      final double y = i * stepY;
      canvas.drawLine(Offset(32, y), Offset(size.width, y), gridPaint);

      final val = (4 - i) * (maxVal / 4);
      String labelVal;
      if (val >= 1000000) {
        labelVal = '${(val / 1000000).toStringAsFixed(1)}M';
      } else if (val >= 1000) {
        labelVal = '${(val / 1000).toStringAsFixed(0)}k';
      } else {
        labelVal = val.toStringAsFixed(0);
      }

      axisTextPainter.text = TextSpan(
        text: labelVal,
        style: GoogleFonts.inter(fontSize: 8, color: Colors.grey),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(0, y - 6));
    }

    final int count = data.length;
    final double stepX = count > 1 ? (size.width - 48) / (count - 1) : (size.width - 48);

    // X-Axis labels & guides
    for (int i = 0; i < count; i++) {
      final double x = 36 + i * stepX;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      axisTextPainter.text = TextSpan(
        text: data[i].mes,
        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(x - (axisTextPainter.width / 2), size.height + 4));
    }

    // Points
    final List<Offset> ingresosPoints = [];
    final List<Offset> egresosPoints = [];

    for (int i = 0; i < count; i++) {
      final double x = 36 + i * stepX;
      final double yIng = size.height - (data[i].ventas / maxVal).clamp(0.0, 1.0) * size.height;
      final double yEgr = size.height - (data[i].compras / maxVal).clamp(0.0, 1.0) * size.height;
      ingresosPoints.add(Offset(x, yIng));
      egresosPoints.add(Offset(x, yEgr));
    }

    final paintLineIngresos = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintLineEgresos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (ingresosPoints.isNotEmpty) {
      final pathIngresos = Path()..moveTo(ingresosPoints[0].dx, ingresosPoints[0].dy);
      for (var pt in ingresosPoints) {
        pathIngresos.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(pathIngresos, paintLineIngresos);

      final pathEgresos = Path()..moveTo(egresosPoints[0].dx, egresosPoints[0].dy);
      for (var pt in egresosPoints) {
        pathEgresos.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(pathEgresos, paintLineEgresos);

      // Area fill ingresos
      final fillPathIngresos = Path()
        ..moveTo(ingresosPoints[0].dx, size.height)
        ..lineTo(ingresosPoints[0].dx, ingresosPoints[0].dy);
      for (var pt in ingresosPoints) {
        fillPathIngresos.lineTo(pt.dx, pt.dy);
      }
      fillPathIngresos.lineTo(ingresosPoints.last.dx, size.height);
      fillPathIngresos.close();
      canvas.drawPath(fillPathIngresos, Paint()..color = const Color(0xFF10B981).withAlpha(20)..style = PaintingStyle.fill);

      // Area fill egresos
      final fillPathEgresos = Path()
        ..moveTo(egresosPoints[0].dx, size.height)
        ..lineTo(egresosPoints[0].dx, egresosPoints[0].dy);
      for (var pt in egresosPoints) {
        fillPathEgresos.lineTo(pt.dx, pt.dy);
      }
      fillPathEgresos.lineTo(egresosPoints.last.dx, size.height);
      fillPathEgresos.close();
      canvas.drawPath(fillPathEgresos, Paint()..color = const Color(0xFFEF4444).withAlpha(16)..style = PaintingStyle.fill);
    }

    // Selection guide & highlight dots
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < count) {
      final double selX = 36 + selectedIndex! * stepX;
      canvas.drawLine(
        Offset(selX, 0),
        Offset(selX, size.height),
        Paint()
          ..color = isDark ? Colors.white24 : const Color(0xFFCBD5E1)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      final double ingresosY = ingresosPoints[selectedIndex!].dy;
      final double egresosY = egresosPoints[selectedIndex!].dy;

      canvas.drawCircle(Offset(selX, ingresosY), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(selX, ingresosY), 3.5, Paint()..color = const Color(0xFF10B981));

      canvas.drawCircle(Offset(selX, egresosY), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(selX, egresosY), 3.5, Paint()..color = const Color(0xFFEF4444));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
