import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_shell.dart';
import '../data/order.dart';
import 'widgets/custom_charts.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _fechaFiltro = '';
  String _metodoPagoFiltro = 'todos';
  bool _showFilters = false;
  String _periodoFiltro = 'mes'; // default matching Capture 2
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper date formatter
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Filter ranges
  Map<String, String> _getRangoFecha() {
    const hoyStr = '2026-06-23'; // baseline mock date from GestionVentas.tsx
    final DateTime hoy = DateTime.parse(hoyStr);

    if (_periodoFiltro == 'hoy') {
      return {'desde': hoyStr, 'hasta': hoyStr};
    } else if (_periodoFiltro == 'semana') {
      final desde = hoy.subtract(const Duration(days: 7));
      return {'desde': _formatDate(desde), 'hasta': hoyStr};
    } else if (_periodoFiltro == 'mes') {
      final desde = DateTime(hoy.year, hoy.month, 1);
      return {'desde': _formatDate(desde), 'hasta': hoyStr};
    } else if (_periodoFiltro == 'ano') {
      final desde = DateTime(hoy.year, 1, 1);
      return {'desde': _formatDate(desde), 'hasta': hoyStr};
    } else {
      return {
        'desde': _fechaDesde != null ? _formatDate(_fechaDesde!) : '',
        'hasta': _fechaHasta != null ? _formatDate(_fechaHasta!) : '',
      };
    }
  }

  List<Order> _getFilteredOrders() {
    final rango = _getRangoFecha();
    return pedidosMock.where((p) {
      final matchSearch = p.cliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchFecha = _fechaFiltro.isEmpty || p.fecha == _fechaFiltro;
      final matchMetodo = _metodoPagoFiltro == 'todos' || p.metodoPago == _metodoPagoFiltro;

      bool matchPeriodo = true;
      if (rango['desde']!.isNotEmpty) {
        matchPeriodo = matchPeriodo && p.fecha.compareTo(rango['desde']!) >= 0;
      }
      if (rango['hasta']!.isNotEmpty) {
        matchPeriodo = matchPeriodo && p.fecha.compareTo(rango['hasta']!) <= 0;
      }

      return matchSearch && matchFecha && matchMetodo && matchPeriodo;
    }).toList();
  }

  String get _periodoLabel {
    if (_periodoFiltro == 'hoy') return 'Hoy';
    if (_periodoFiltro == 'semana') return '7 días';
    if (_periodoFiltro == 'mes') return 'Este mes';
    if (_periodoFiltro == 'ano') return 'Este año';
    return 'Personalizado';
  }

  // --- Dynamic calculations helpers for Reportes ---
  List<SalesSummaryDay> _getDailyRevenueData(List<Order> filtered) {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    Map<String, double> revenues = {for (var d in days) d: 0.0};
    Map<String, int> ordersCount = {for (var d in days) d: 0};

    for (var o in filtered) {
      DateTime dt;
      try {
        dt = DateTime.parse(o.fecha);
      } catch (_) {
        dt = DateTime.now();
      }
      int weekday = dt.weekday; // 1 = Monday, 7 = Sunday
      String dayKey = days[weekday - 1];
      revenues[dayKey] = (revenues[dayKey] ?? 0.0) + o.total;
      ordersCount[dayKey] = (ordersCount[dayKey] ?? 0) + 1;
    }

    return days.map((d) => SalesSummaryDay(dia: d, ventas: revenues[d]!, pedidos: ordersCount[d]!)).toList();
  }

  List<BestSeller> _getBestSellersData(List<Order> filtered) {
    Map<String, int> counts = {};
    for (var o in filtered) {
      for (var d in o.detalle) {
        counts[d.nombre] = (counts[d.nombre] ?? 0) + d.cantidad;
      }
    }
    if (counts.isEmpty) {
      return [
        BestSeller(nombre: 'Ninguno', cantidad: 0),
      ];
    }
    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => BestSeller(nombre: e.key, cantidad: e.value)).toList();
  }

  List<PaymentMethodShare> _getPaymentMethodsData(List<Order> filtered) {
    Map<String, double> totals = {'Efectivo': 0.0, 'Tarjeta': 0.0};
    double totalAll = 0.0;
    for (var o in filtered) {
      String key = o.metodoPago == 'efectivo' ? 'Efectivo' : 'Tarjeta';
      totals[key] = (totals[key] ?? 0.0) + o.total;
      totalAll += o.total;
    }
    if (totalAll == 0.0) {
      return [
        PaymentMethodShare(metodo: 'Efectivo', porcentaje: 50.0),
        PaymentMethodShare(metodo: 'Tarjeta', porcentaje: 50.0),
      ];
    }
    return totals.entries.map((e) => PaymentMethodShare(metodo: e.key, porcentaje: (e.value / totalAll) * 100)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();

    // Calculable statistics from active mock orders
    double totalVentas = filteredOrders.fold(0.0, (sum, item) => sum + item.total);
    double ticketPromedio = filteredOrders.isEmpty ? 0.0 : totalVentas / filteredOrders.length;
    double totalDescuentos = filteredOrders.fold(0.0, (sum, item) => sum + (item.subtotal * (item.descuento / 100)));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : Colors.grey[50]!;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937);
    final textSecondary = isDark ? AppColors.textSecondaryDark : Colors.grey[500]!;
    final borderColor = isDark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: backgroundColor,
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
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Dashboard header & 2x2 KPIs (Collapses/scrolls away to save vertical space)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Ventas',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monitoreo de pedidos pagados y análisis comercial',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // KPI Grid (Capture 1 Style - 2x2 grid layout, overflow-safe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: _buildKpis(totalVentas, ticketPromedio, totalDescuentos, filteredOrders.length, cardColor, textPrimary, textSecondary, borderColor, isDark),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Pinned tab bar header (stays at the top when scrolling)
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarHeaderDelegate(
                  child: Container(
                    color: surfaceColor,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFF05454), // Active red indicator
                      labelColor: const Color(0xFFF05454),
                      unselectedLabelColor: isDark ? Colors.white38 : Colors.grey[600],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(icon: Icon(Icons.check_circle_outline, size: 20), text: 'Pedidos'),
                        Tab(icon: Icon(Icons.access_time, size: 20), text: 'Historial'),
                        Tab(icon: Icon(Icons.bar_chart_outlined, size: 20), text: 'Reportes'),
                      ],
                    ),
                  ),
                ),
              )
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Pedidos Pagados
              _buildPedidosTab(filteredOrders, surfaceColor, textPrimary, textSecondary, borderColor, isDark, cardColor, backgroundColor),

              // Tab 2: Historial
              _buildHistorialTab(cardColor, textPrimary, textSecondary, borderColor, isDark),

              // Tab 3: Reportes
              _buildReportesTab(filteredOrders, cardColor, textPrimary, textSecondary, borderColor, isDark, surfaceColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- Capture 1 KPI 2x2 Layout ---
  Widget _buildKpis(double totalVentas, double ticketPromedio, double totalDescuentos, int totalPedidos, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    String formatVal(double val) => '\$${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Total Ventas',
                formatVal(totalVentas),
                Icons.attach_money,
                isDark ? const Color(0xFF1B3B22) : const Color(0xFFE8F5E9),
                const Color(0xFF4CAF50),
                cardColor,
                textPrimary,
                textSecondary,
                borderColor,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Pedidos Pagados',
                '$totalPedidos',
                Icons.check_circle_outline,
                isDark ? const Color(0xFF1C223D) : const Color(0xFFE8EAF6),
                const Color(0xFF3F51B5),
                cardColor,
                textPrimary,
                textSecondary,
                borderColor,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Ticket Promedio',
                formatVal(ticketPromedio),
                Icons.trending_up,
                isDark ? const Color(0xFF3E1F21) : const Color(0xFFFFEBEE),
                const Color(0xFFE53935),
                cardColor,
                textPrimary,
                textSecondary,
                borderColor,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Desc. Otorgados',
                formatVal(totalDescuentos),
                Icons.shopping_bag_outlined,
                isDark ? const Color(0xFF3B3A1C) : const Color(0xFFFFFDE7),
                const Color(0xFFFBC02D),
                cardColor,
                textPrimary,
                textSecondary,
                borderColor,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color bgColor, Color iconColor, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosTab(List<Order> filtered, Color surfaceColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark, Color cardColor, Color backgroundColor) {
    int itemCount = filtered.isEmpty ? 3 : filtered.length + 2;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Filters options container (contains period select, search bar, and collapsible filters card)
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selectors row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Período: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _periodButton('hoy', 'Hoy', isDark),
                            _periodButton('semana', '7 días', isDark),
                            _periodButton('mes', 'Este mes', isDark),
                            _periodButton('ano', 'Este año', isDark),
                            _periodButton('personalizado', 'Personalizado', isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Date pickers if custom
                if (_periodoFiltro == 'personalizado') ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (selected != null) {
                              setState(() {
                                _fechaDesde = selected;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 11),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Text(_fechaDesde == null ? 'Desde' : _formatDate(_fechaDesde!), style: TextStyle(color: textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 14, color: textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (selected != null) {
                              setState(() {
                                _fechaHasta = selected;
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            textStyle: const TextStyle(fontSize: 11),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Text(_fechaHasta == null ? 'Hasta' : _formatDate(_fechaHasta!), style: TextStyle(color: textPrimary)),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // Search bar and Collapsible toggle button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: TextStyle(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, size: 18, color: textSecondary),
                            hintText: 'Buscar por cliente o ID...',
                            hintStyle: TextStyle(color: textSecondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Collapsible toggle card (Capture 2 design style)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, size: 16, color: textPrimary),
                            const SizedBox(width: 6),
                            Text(
                              'Filtros',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: textPrimary,
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),

                // Collapsible filter panel card (Capture 2 details)
                if (_showFilters) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha Label
                        Text(
                          'Fecha',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        // Date selector display input card
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setState(() {
                                _fechaFiltro = _formatDate(date);
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                    _fechaFiltro.isEmpty ? 'dd/mm/aaaa' : _fechaFiltro,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _fechaFiltro.isEmpty ? textSecondary : textPrimary,
                                    ),
                                  ),
                                  Icon(Icons.calendar_today_outlined, size: 16, color: textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Método de pago Label
                        Text(
                          'Método de pago',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        // Dropdown selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _metodoPagoFiltro,
                              isExpanded: true,
                              dropdownColor: surfaceColor,
                              icon: Icon(Icons.keyboard_arrow_down, color: textSecondary),
                              style: TextStyle(fontSize: 13, color: textPrimary),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                                DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _metodoPagoFiltro = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Underlined Limpiar red link
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _fechaFiltro = '';
                              _metodoPagoFiltro = 'todos';
                              _searchQuery = '';
                            });
                          },
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFC92C2C),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        } else if (index == 1) {
          // Count header
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '${filtered.length} pedido(s) encontrado(s)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
            ),
          );
        } else {
          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.checklist_rtl, size: 56, color: isDark ? Colors.white24 : Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No se encontraron pedidos', style: TextStyle(fontWeight: FontWeight.bold, color: textSecondary)),
                  ],
                ),
              ),
            );
          } else {
            final order = filtered[index - 2];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: _orderCard(order, cardColor, textPrimary, textSecondary, borderColor, isDark),
            );
          }
        }
      },
    );
  }

  Widget _periodButton(String value, String label, bool isDark) {
    bool isSelected = _periodoFiltro == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _periodoFiltro = value;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF30475E) : (isDark ? Colors.white.withAlpha(15) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  }

  // --- Order card item in Pedidos tab (Capture 2 details) ---
  Widget _orderCard(Order order, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    String paymentLabel = order.metodoPago == 'efectivo'
        ? '💵 Efectivo'
        : order.metodoPago == 'tarjeta'
            ? '💳 Tarjeta'
            : '📲 Transferencia';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 10, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text(
                      'Pagado',
                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Customer name
          Text(
            order.cliente,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
          ),
          const SizedBox(height: 8),

          // Row 3: Date/Time range & Payment tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.fecha} ${order.hora} – ${order.horaFin}',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
              Text(
                paymentLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 4: Delivery Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.tipoEntrega == 'mesa'
                  ? '🍽️ En Mesa'
                  : order.tipoEntrega == 'domicilio'
                      ? '🛵 Domicilio'
                      : '🏪 Recoger',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ),

          const Divider(height: 24),

          // Action Detail Button Trigger
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => _showOrderDetail(order, cardColor, textPrimary, textSecondary, borderColor, isDark),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, size: 14, color: Color(0xFFF05454)),
                  SizedBox(width: 4),
                  Text(
                    'Ver detalle',
                    style: TextStyle(color: Color(0xFFF05454), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Tab 2: Historial Tab builder (Capture 4 Style, horizontal-overflow safe Wrap) ---
  Widget _buildHistorialTab(Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    final rango = _getRangoFecha();
    final historical = [...pedidosMock].where((p) {
      bool matchPeriodo = true;
      if (rango['desde']!.isNotEmpty) {
        matchPeriodo = matchPeriodo && p.fecha.compareTo(rango['desde']!) >= 0;
      }
      if (rango['hasta']!.isNotEmpty) {
        matchPeriodo = matchPeriodo && p.fecha.compareTo(rango['hasta']!) <= 0;
      }
      return matchPeriodo;
    }).toList();

    // Sort newest first
    historical.sort((a, b) {
      int dateComp = b.fecha.compareTo(a.fecha);
      if (dateComp != 0) return dateComp;
      return b.hora.compareTo(a.hora);
    });

    return Column(
      children: [
        // Historial Title and Export Button Header (Horizontal Wrap layout to avoid clipping)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Historial — $_periodoLabel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Historial exportado correctamente!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: Icon(Icons.download, size: 14, color: textPrimary),
                label: Text('Exportar', style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ),

        // History lists
        Expanded(
          child: historical.isEmpty
              ? Center(
                  child: Text('Historial vacío para el período', style: TextStyle(color: textSecondary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: historical.length,
                  itemBuilder: (context, index) {
                    final order = historical[index];
                    return _historialCard(order, cardColor, textPrimary, textSecondary, borderColor, isDark);
                  },
                ),
        )
      ],
    );
  }

  // --- Historial item card (Capture 4 details) ---
  Widget _historialCard(Order order, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Initial circle avatar, Name & metadata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF05454),
                child: Text(
                  order.cliente.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.cliente,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.id,
                          style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          order.fecha,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_outlined, size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${order.hora} – ${order.horaFin}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Price & Detalle inline eye link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.descuento > 0)
                    Text(
                      '\$${order.subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: textSecondary),
                    ),
                  Row(
                    children: [
                      Text(
                        '\$${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textPrimary),
                      ),
                      if (order.descuento > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '-${order.descuento.toStringAsFixed(0)}% desc.',
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        )
                      ]
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showOrderDetail(order, cardColor, textPrimary, textSecondary, borderColor, isDark),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, size: 14, color: Color(0xFFF05454)),
                    SizedBox(width: 4),
                    Text(
                      'Detalle',
                      style: TextStyle(color: Color(0xFFF05454), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Row 3: Horizontal item pill tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: order.detalle.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.grey[50],
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${item.cantidad}x ${item.nombre}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Reportes Tab builder (Capture 5 & Executive Summary Table) ---
  Widget _buildReportesTab(List<Order> filtered, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark, Color surfaceColor) {
    // Dynamic calculations for charts
    final dailyRevenue = _getDailyRevenueData(filtered);
    final bestSellers = _getBestSellersData(filtered);
    final paymentMethods = _getPaymentMethodsData(filtered);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Report Header with Export button and period indicator (Wrap to avoid horizontal overflows)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Análisis de Ventas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Reportes exportados correctamente!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: Icon(Icons.download, size: 14, color: textPrimary),
                    label: Text('Exportar', style: TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _periodoLabel,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF05454)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 1. Revenues daily bars (Interactive tooltips on tap)
        DailyRevenueChart(data: dailyRevenue),
        const SizedBox(height: 12),

        // 2. Orders line points (Interactive tooltips on tap)
        DailyOrdersChart(data: dailyRevenue),
        const SizedBox(height: 12),

        // 3. Best selling products (Interactive tooltips on tap)
        TopProductsChart(data: bestSellers),
        const SizedBox(height: 12),

        // 4. Payment methods donut chart (Interactive center percent display)
        PaymentMethodsChart(data: paymentMethods),
        const SizedBox(height: 12),

        // 5. Executive Summary Table (Capture 4 style)
        _buildExecutiveSummary(filtered, cardColor, textPrimary, textSecondary, borderColor, isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Executive Summary Card builder (Capture 4 style) ---
  Widget _buildExecutiveSummary(List<Order> filtered, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    double sumTotal = filtered.fold(0.0, (sum, item) => sum + item.total);
    int countPedidos = filtered.length;
    double avgTicket = countPedidos == 0 ? 0.0 : sumTotal / countPedidos;

    // Map date strings to day of week names
    final daysFull = {
      '2026-06-23': 'Martes',
      '2026-06-22': 'Lunes',
      '2026-06-21': 'Domingo',
      '2026-06-20': 'Sábado',
      '2026-06-19': 'Viernes',
      '2026-06-18': 'Jueves',
      '2026-06-17': 'Miércoles',
      '2026-06-09': 'Martes',
      '2026-06-08': 'Lunes',
      '2026-06-07': 'Domingo',
      '2026-06-06': 'Sábado',
      '2026-06-05': 'Viernes',
    };

    // Calculate top day sales
    Map<String, double> daySales = {};
    for (var o in filtered) {
      daySales[o.fecha] = (daySales[o.fecha] ?? 0.0) + o.total;
    }
    String topDayStr = 'N/A';
    if (daySales.isNotEmpty) {
      var topDayEntry = daySales.entries.reduce((a, b) => a.value > b.value ? a : b);
      String dayLabel = daysFull[topDayEntry.key] ?? topDayEntry.key;
      topDayStr = '$dayLabel — \$${topDayEntry.value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    // Calculate star product sold
    Map<String, int> productCounts = {};
    for (var o in filtered) {
      for (var d in o.detalle) {
        productCounts[d.nombre] = (productCounts[d.nombre] ?? 0) + d.cantidad;
      }
    }
    String starProduct = 'N/A';
    if (productCounts.isNotEmpty) {
      var topProductEntry = productCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      starProduct = '${topProductEntry.key} (${topProductEntry.value} und.)';
    }

    // Calculate favorite payment method
    Map<String, int> paymentCounts = {};
    for (var o in filtered) {
      paymentCounts[o.metodoPago] = (paymentCounts[o.metodoPago] ?? 0) + 1;
    }
    String favPayment = 'N/A';
    if (paymentCounts.isNotEmpty) {
      var topPaymentEntry = paymentCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      double pct = (topPaymentEntry.value / countPedidos) * 100;
      String methodLabel = topPaymentEntry.key == 'efectivo'
          ? 'Efectivo'
          : topPaymentEntry.key == 'tarjeta'
              ? 'Tarjeta'
              : 'Transferencia';
      favPayment = '$methodLabel (${pct.toStringAsFixed(0)}%)';
    }

    String formatVal(double val) => '\$${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen ejecutivo del período',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 16),
          _summaryRow('Ingresos totales del período', formatVal(sumTotal), textPrimary, textSecondary),
          const Divider(height: 20),
          _summaryRow('Total de pedidos procesados', '$countPedidos pedidos', textPrimary, textSecondary),
          const Divider(height: 20),
          _summaryRow('Día con mayor facturación', topDayStr, textPrimary, textSecondary),
          const Divider(height: 20),
          _summaryRow('Producto estrella', starProduct, textPrimary, textSecondary),
          const Divider(height: 20),
          _summaryRow('Método de pago preferido', favPayment, textPrimary, textSecondary),
          const Divider(height: 20),
          _summaryRow('Ticket promedio', formatVal(avgTicket), textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
        ),
      ],
    );
  }

  // --- Detail bottom sheet receipt modal (Capture 3 style) ---
  void _showOrderDetail(Order order, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        double subtotal = order.subtotal;
        double discountAmount = subtotal * (order.descuento / 100);
        double baseVal = subtotal - discountAmount;
        double ivaVal = (baseVal * 0.19).roundToDouble();

        String deliveryText = order.tipoEntrega == 'mesa'
            ? '🍽️ En Mesa'
            : order.tipoEntrega == 'domicilio'
                ? '🛵 Domicilio'
                : '🏪 Recoger';

        String paymentText = order.metodoPago == 'efectivo'
            ? '💵 Efectivo'
            : order.metodoPago == 'tarjeta'
                ? '💳 Tarjeta'
                : '📲 Transferencia';

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            children: [
              // Header card (Slate dark blue container, titles, close button)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF34495E),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.id,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            order.cliente,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  ],
                ),
              ),

              // Scrollable receipt body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 2x2 Metadata Cards Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _detailMetaCard('Fecha', order.fecha, textPrimary, textSecondary, borderColor, isDark),
                        _detailMetaCard('Horario', '${order.hora} – ${order.horaFin}', textPrimary, textSecondary, borderColor, isDark),
                        _detailMetaCard('Método de pago', paymentText, textPrimary, textSecondary, borderColor, isDark),
                        _detailMetaCard('Tipo de entrega', deliveryText, textPrimary, textSecondary, borderColor, isDark),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Green Pagado Banner
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Pagado',
                            style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Products header
                    Text(
                      'Productos del pedido (${order.detalle.length})',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(height: 10),

                    // Purchased items list (e.g. Combo Familiar)
                    ...order.detalle.map((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.cantidad} x \$${item.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${(item.precio * item.cantidad).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Totals breakdown matching Capture 3
                    _breakdownRow('Subtotal', '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, false, textPrimary, textSecondary),
                    if (order.descuento > 0) ...[
                      const SizedBox(height: 6),
                      _breakdownRow(
                          'Descuento (${order.descuento.toStringAsFixed(0)}%)',
                          '-\$${discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          true,
                          false,
                          textPrimary,
                          textSecondary),
                    ],
                    const SizedBox(height: 6),
                    _breakdownRow('IVA (19%)', '\$${ivaVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, false, textPrimary, textSecondary),
                    const Divider(height: 24),
                    _breakdownRow('Total', '\$${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, true, textPrimary, textSecondary),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailMetaCard(String label, String value, Color textPrimary, Color textSecondary, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, bool isDiscount, bool isTotal, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? textPrimary : textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 12,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? const Color(0xFFF05454) // Red total matching Capture 3
                : isDiscount
                    ? Colors.green
                    : textPrimary,
          ),
        ),
      ],
    );
  }
}

// --- Custom TabBar Header Delegate for NestedScrollView ---
class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _TabBarHeaderDelegate({required this.child});

  @override
  double get minExtent => 48.0;

  @override
  double get maxExtent => 48.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
