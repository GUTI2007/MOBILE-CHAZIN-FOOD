import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/dark_mode_provider.dart';
import '../../../providers/navigation_provider.dart';

import '../../../routes/app_shell.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () {
              ref.read(darkModeProvider.notifier).state = !isDark;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
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
                    Text(
                      'Panel de Control',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Bienvenido a Chazin Food',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Acceso Rápido ───
                    Text(
                      'Acceso Rápido',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(isDark),
                    const SizedBox(height: 20),

                    // ─── Metric Cards (Scroll Vertical exact style) ───
                    _buildMetricCard(
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFD1FAE5),
                      label: 'Ventas del Mes',
                      value: '\$28.4M',
                      trendText: '↗ +12.5%',
                      trendColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      icon: Icons.shopping_cart_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      iconBg: const Color(0xFFDBEAFE),
                      label: 'Total Pedidos',
                      value: '1,248',
                      trendText: '↗ +8.2%',
                      trendColor: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      icon: Icons.people_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBg: const Color(0xFFEDE9FE),
                      label: 'Clientes Activos',
                      value: '342',
                      trendText: '↗ +15.3%',
                      trendColor: const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      icon: Icons.inventory_2_outlined,
                      iconColor: const Color(0xFFEF4444),
                      iconBg: const Color(0xFFFEE2E2),
                      label: 'Productos',
                      value: '68',
                      trendText: '⚠ 5 bajo stock',
                      trendColor: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // ─── Ventas y Compras Chart ───
                    _buildVentasComprasChart(isDark),
                    const SizedBox(height: 24),

                    // ─── Productos Más Vendidos Chart ───
                    _buildProductosMasVendidos(isDark),
                    const SizedBox(height: 24),

                    // ─── Alertas de Stock ───
                    _buildAlertasDeStock(isDark),
                    const SizedBox(height: 24),

                    // ─── Ventas Recientes ───
                    _buildVentasRecientes(isDark),
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

  // Quick Action Grid 2x2
  Widget _buildQuickActionsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      children: [
        _quickActionItem(
          icon: Icons.shopping_cart_rounded,
          iconColor: const Color(0xFF1E3A8A),
          iconBg: const Color(0xFFEFF6FF),
          title: 'Compras',
          subtitle: 'Gestión de insumos',
          isDark: isDark,
        ),
        _quickActionItem(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBg: const Color(0xFFFEF2F2),
          title: 'Ventas',
          subtitle: 'Punto de venta',
          isDark: isDark,
        ),
        _quickActionItem(
          icon: Icons.people_rounded,
          iconColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFFF5F3FF),
          title: 'Usuarios',
          subtitle: 'Administrar accesos',
          isDark: isDark,
        ),
        _quickActionItem(
          icon: Icons.settings_rounded,
          iconColor: const Color(0xFF475569),
          iconBg: const Color(0xFFF1F5F9),
          title: 'Configuración',
          subtitle: 'Roles y permisos',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _quickActionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withAlpha(38) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Custom Metric Card Horizontal Row
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withAlpha(38) : iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: trendColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trendText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Line Chart for "Ventas y Compras"
  Widget _buildVentasComprasChart(bool isDark) {
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
              final double stepX = (width - 36) / 5;
              final double selectedX = _selectedMonthIndex != null
                  ? 32 + _selectedMonthIndex! * stepX
                  : 0.0;

              final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
              final ingresos = [12000, 15200, 19000, 22000, 26000, 28000];
              final egresos = [7500, 9500, 11000, 13500, 15000, 16500];

              final currentMonth = _selectedMonthIndex != null ? months[_selectedMonthIndex!] : '';
              final currentIngreso = _selectedMonthIndex != null ? ingresos[_selectedMonthIndex!] : 0;
              final currentEgreso = _selectedMonthIndex != null ? egresos[_selectedMonthIndex!] : 0;

              return GestureDetector(
                onTapDown: (details) {
                  final double localX = details.localPosition.dx;
                  final double relativeX = localX - 32;
                  int idx = (relativeX + (stepX / 2)) ~/ stepX;
                  if (idx >= 0 && idx < 6) {
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
                          isDark: isDark,
                          selectedIndex: _selectedMonthIndex,
                        ),
                      ),
                    ),
                    // Floating popover tooltip in line chart matching Capture 3
                    if (_selectedMonthIndex != null)
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
                                    'Ingresos : $currentIngreso',
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
                                    'Egresos : $currentEgreso',
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
              _chartLegendItem('Ingresos', const Color(0xFF10B981)),
              const SizedBox(width: 24),
              _chartLegendItem('Egresos', const Color(0xFFEF4444)),
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
  Widget _buildProductosMasVendidos(bool isDark) {
    final products = [
      {'name': 'Hamburguesa Especial', 'val': 240},
      {'name': 'Salchipapa Grande', 'val': 195},
      {'name': 'Perro Caliente', 'val': 80},
      {'name': 'Pollo Broaster', 'val': 80},
      {'name': 'Papas Fritas', 'val': 120},
    ];

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
                                  widthFactor: val / 260.0,
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

  // Stock alerts with exact button actions
  Widget _buildAlertasDeStock(bool isDark) {
    final alerts = [
      {'name': 'Pan de Hamburguesa', 'qty': '15 / 50 unidades'},
      {'name': 'Salchicha Premium', 'qty': '8 / 30 unidades'},
      {'name': 'Papas Congeladas', 'qty': '12 / 40 unidades'},
      {'name': 'Queso Mozzarella', 'qty': '6 / 20 unidades'},
      {'name': 'Tomate', 'qty': '9 / 25 unidades'},
    ];

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
                'Alertas de Stock',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                'Ver todo ›',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: alerts.map((a) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
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
                            a['name']!,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFF7F1D1D),
                            ),
                          ),
                          Text(
                            a['qty']!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _showReabastecerDialog(context, a, isDark);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE25858),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reabastecer',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
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

  // Recent Sales Widget
  Widget _buildVentasRecientes(bool isDark) {
    final recentSales = [
      {'id': '#0042', 'status': 'Completado', 'client': 'Juan Pérez', 'time': '10:30 AM', 'val': 45000, 'color': const Color(0xFFD1FAE5), 'txtColor': const Color(0xFF065F46)},
      {'id': '#0041', 'status': 'En proceso', 'client': 'María García', 'time': '10:15 AM', 'val': 32500, 'color': const Color(0xFFFEF3C7), 'txtColor': const Color(0xFF92400E)},
    ];

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
                'Ventas Recientes',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              GestureDetector(
                onTap: () {
                  ref.read(appShellIndexProvider.notifier).state = 2; // Ventas index
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
          Column(
            children: recentSales.map((s) {
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
                              s['id'] as String,
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
                                color: s['color'] as Color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s['status'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: s['txtColor'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${s['client']} • ${s['time']}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '\$${_formatPrice((s['val'] as int).toDouble())}',
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

  String _formatPrice(double val) {
    final str = val.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  void _showReabastecerDialog(BuildContext context, Map<String, String> alert, bool isDark) {
    final qtyParts = alert['qty']!.split('/');
    final currentStock = qtyParts.isNotEmpty ? qtyParts[0].trim() : '0';
    final minStock = qtyParts.length > 1 ? qtyParts[1].trim() : '0';

    showDialog(
      context: context,
      builder: (context) {
        final dialogBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
        final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subtitleColor = isDark ? Colors.white70 : const Color(0xFF334155);
        final detailColor = isDark ? Colors.white54 : const Color(0xFF64748B);
        final btnCancelBg = isDark ? Colors.transparent : Colors.white;
        final btnCancelText = isDark ? Colors.white70 : const Color(0xFF334155);
        final btnCancelBorder = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

        return Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon in light red circle container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Reabastecer Insumo',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                // Subtitle
                Text(
                  alert['name']!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                // Stock details
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: detailColor,
                    ),
                    children: [
                      const TextSpan(text: 'Stock actual: '),
                      TextSpan(
                        text: currentStock,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' / Mínimo: $minStock'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: btnCancelBg,
                          side: BorderSide(color: btnCancelBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: btnCancelText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Close dialog
                          Navigator.pop(context);
                          // Redirect to Compras tab (index 1)
                          ref.read(appShellIndexProvider.notifier).state = 1;
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE25858),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Ir a Compras',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Custom Line Chart Painter ───
class _LineChartPainter extends CustomPainter {
  final bool isDark;
  final int? selectedIndex;
  _LineChartPainter({required this.isDark, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : const Color(0xFFE2E8F0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final axisTextPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal dashed lines
    final double stepY = size.height / 4;
    for (int i = 0; i <= 4; i++) {
      final double y = i * stepY;
      canvas.drawLine(Offset(32, y), Offset(size.width, y), gridPaint);
      
      // Axis Labels (0, 7500, 15000, 22500, 30000)
      final val = (4 - i) * 7500;
      axisTextPainter.text = TextSpan(
        text: val.toString(),
        style: GoogleFonts.inter(fontSize: 8, color: Colors.grey),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(0, y - 6));
    }

    // Points mapping for Months (Ene, Feb, Mar, Abr, May, Jun)
    final double stepX = (size.width - 36) / 5;
    final List<String> months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
    for (int i = 0; i < 6; i++) {
      final double x = 32 + i * stepX;
      
      // Draw vertical dotted guides
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      // Label
      axisTextPainter.text = TextSpan(
        text: months[i],
        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(x - 8, size.height + 4));
    }

    // Draw Ingresos Line (Green)
    final ingresosPoints = [
      Offset(32, size.height - (12000 / 30000.0) * size.height),
      Offset(32 + stepX, size.height - (15000 / 30000.0) * size.height),
      Offset(32 + 2 * stepX, size.height - (19000 / 30000.0) * size.height),
      Offset(32 + 3 * stepX, size.height - (22000 / 30000.0) * size.height),
      Offset(32 + 4 * stepX, size.height - (26000 / 30000.0) * size.height),
      Offset(32 + 5 * stepX, size.height - (28000 / 30000.0) * size.height),
    ];

    final egresosPoints = [
      Offset(32, size.height - (7500 / 30000.0) * size.height),
      Offset(32 + stepX, size.height - (9000 / 30000.0) * size.height),
      Offset(32 + 2 * stepX, size.height - (11000 / 30000.0) * size.height),
      Offset(32 + 3 * stepX, size.height - (13500 / 30000.0) * size.height),
      Offset(32 + 4 * stepX, size.height - (15000 / 30000.0) * size.height),
      Offset(32 + 5 * stepX, size.height - (16500 / 30000.0) * size.height),
    ];

    final paintLineIngresos = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintLineEgresos = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw paths
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

    // Draw Gradient Areas below lines
    final paintFillIngresos = Paint()
      ..color = const Color(0xFF10B981).withAlpha(20)
      ..style = PaintingStyle.fill;
    
    final fillPathIngresos = Path()
      ..moveTo(ingresosPoints[0].dx, size.height)
      ..lineTo(ingresosPoints[0].dx, ingresosPoints[0].dy);
    for (var pt in ingresosPoints) {
      fillPathIngresos.lineTo(pt.dx, pt.dy);
    }
    fillPathIngresos.lineTo(ingresosPoints.last.dx, size.height);
    fillPathIngresos.close();
    canvas.drawPath(fillPathIngresos, paintFillIngresos);

    final paintFillEgresos = Paint()
      ..color = const Color(0xFFEF4444).withAlpha(16)
      ..style = PaintingStyle.fill;
    
    final fillPathEgresos = Path()
      ..moveTo(egresosPoints[0].dx, size.height)
      ..lineTo(egresosPoints[0].dx, egresosPoints[0].dy);
    for (var pt in egresosPoints) {
      fillPathEgresos.lineTo(pt.dx, pt.dy);
    }
    fillPathEgresos.lineTo(egresosPoints.last.dx, size.height);
    fillPathEgresos.close();
    canvas.drawPath(fillPathEgresos, paintFillEgresos);

    // Draw selection vertical guide & intersection dots if clicked
    if (selectedIndex != null) {
      final double selX = 32 + selectedIndex! * stepX;
      canvas.drawLine(
        Offset(selX, 0),
        Offset(selX, size.height),
        Paint()
          ..color = isDark ? Colors.white24 : const Color(0xFFCBD5E1)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );

      final List<double> ingresos = [12000, 15200, 19000, 22000, 26000, 28000];
      final List<double> egresos = [7500, 9500, 11000, 13500, 15000, 16500];

      final double ingresosY = size.height - (ingresos[selectedIndex!] / 30000.0) * size.height;
      final double egresosY = size.height - (egresos[selectedIndex!] / 30000.0) * size.height;

      // Ingresos Highlight Dot (Green)
      canvas.drawCircle(Offset(selX, ingresosY), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(selX, ingresosY), 3.5, Paint()..color = const Color(0xFF10B981));

      // Egresos Highlight Dot (Red)
      canvas.drawCircle(Offset(selX, egresosY), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(selX, egresosY), 3.5, Paint()..color = const Color(0xFFEF4444));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
