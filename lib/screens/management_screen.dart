import 'package:flutter/material.dart';
import '../models/order.dart';
import '../widgets/custom_charts.dart';

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

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                          const Text(
                            'Gestión de Ventas',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Monitoreo de pedidos pagados y análisis comercial',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    // KPI Grid (Capture 1 Style - 2x2 grid layout, overflow-safe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: _buildKpis(totalVentas, ticketPromedio, totalDescuentos, filteredOrders.length),
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
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFF05454), // Active red indicator
                      labelColor: const Color(0xFFF05454),
                      unselectedLabelColor: Colors.grey[600],
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
              _buildPedidosTab(filteredOrders),

              // Tab 2: Historial
              _buildHistorialTab(),

              // Tab 3: Reportes
              _buildReportesTab(filteredOrders),
            ],
          ),
        ),
      ),
    );
  }

  // --- Capture 1 KPI 2x2 Layout ---
  Widget _buildKpis(double totalVentas, double ticketPromedio, double totalDescuentos, int totalPedidos) {
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
                const Color(0xFFE8F5E9),
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Pedidos Pagados',
                '$totalPedidos',
                Icons.check_circle_outline,
                const Color(0xFFE8EAF6),
                const Color(0xFF3F51B5),
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
                const Color(0xFFFFEBEE),
                const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Desc. Otorgados',
                formatVal(totalDescuentos),
                Icons.shopping_bag_outlined,
                const Color(0xFFFFFDE7),
                const Color(0xFFFBC02D),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2)),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPedidosTab(List<Order> filtered) {
    int itemCount = filtered.isEmpty ? 3 : filtered.length + 2;

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Filters options container (contains period select, search bar, and collapsible filters card)
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period selectors row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Período: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _periodButton('hoy', 'Hoy'),
                            _periodButton('semana', '7 días'),
                            _periodButton('mes', 'Este mes'),
                            _periodButton('ano', 'Este año'),
                            _periodButton('personalizado', 'Personalizado'),
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
                          ),
                          child: Text(_fechaDesde == null ? 'Desde' : _formatDate(_fechaDesde!)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
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
                          ),
                          child: Text(_fechaHasta == null ? 'Hasta' : _formatDate(_fechaHasta!)),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                            hintText: 'Buscar por cliente o ID...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.filter_list, size: 16, color: Color(0xFF374151)),
                            const SizedBox(width: 6),
                            const Text(
                              'Filtros',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: const Color(0xFF374151),
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha Label
                        const Text(
                          'Fecha',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fechaFiltro.isEmpty ? 'dd/mm/aaaa' : _fechaFiltro,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _fechaFiltro.isEmpty ? Colors.grey[400] : Colors.black,
                                  ),
                                ),
                                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Método de pago Label
                        const Text(
                          'Método de pago',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                        ),
                        const SizedBox(height: 6),
                        // Dropdown selector
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _metodoPagoFiltro,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              style: const TextStyle(fontSize: 13, color: Colors.black),
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
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
                    Icon(Icons.checklist_rtl, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('No se encontraron pedidos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          } else {
            final order = filtered[index - 2];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: _orderCard(order),
            );
          }
        }
      },
    );
  }

  Widget _periodButton(String value, String label) {
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
            color: isSelected ? const Color(0xFF30475E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  // --- Order card item in Pedidos tab (Capture 2 details) ---
  Widget _orderCard(Order order) {
    String paymentLabel = order.metodoPago == 'efectivo'
        ? '💵 Efectivo'
        : order.metodoPago == 'tarjeta'
            ? '💳 Tarjeta'
            : '📲 Transferencia';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
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
                style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),

          // Row 3: Date/Time range & Payment tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.fecha} ${order.hora} – ${order.horaFin}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              Text(
                paymentLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
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
              onTap: () => _showOrderDetail(order),
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
  Widget _buildHistorialTab() {
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
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
                icon: const Icon(Icons.download, size: 14, color: Color(0xFF374151)),
                label: const Text('Exportar', style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
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
                  child: Text('Historial vacío para el período', style: TextStyle(color: Colors.grey[500])),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: historical.length,
                  itemBuilder: (context, index) {
                    final order = historical[index];
                    return _historialCard(order);
                  },
                ),
        )
      ],
    );
  }

  // --- Historial item card (Capture 4 details) ---
  Widget _historialCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order.id,
                          style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          order.fecha,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${order.hora} – ${order.horaFin}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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
                      style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Colors.grey[400]),
                    ),
                  Row(
                    children: [
                      Text(
                        '\$${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937)),
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
                onTap: () => _showOrderDetail(order),
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
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${item.cantidad}x ${item.nombre}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Tab 3: Reportes Tab builder (Capture 5 & Executive Summary Table) ---
  Widget _buildReportesTab(List<Order> filtered) {
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
              const Text(
                'Análisis de Ventas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
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
                    icon: const Icon(Icons.download, size: 14, color: Color(0xFF374151)),
                    label: const Text('Exportar', style: TextStyle(color: Color(0xFF374151), fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
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
        _buildExecutiveSummary(filtered),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Executive Summary Card builder (Capture 4 style) ---
  Widget _buildExecutiveSummary(List<Order> filtered) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(2), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen ejecutivo del período',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 16),
          _summaryRow('Ingresos totales del período', formatVal(sumTotal)),
          const Divider(height: 20),
          _summaryRow('Total de pedidos procesados', '$countPedidos pedidos'),
          const Divider(height: 20),
          _summaryRow('Día con mayor facturación', topDayStr),
          const Divider(height: 20),
          _summaryRow('Producto estrella', starProduct),
          const Divider(height: 20),
          _summaryRow('Método de pago preferido', favPayment),
          const Divider(height: 20),
          _summaryRow('Ticket promedio', formatVal(avgTicket)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }

  // --- Detail bottom sheet receipt modal (Capture 3 style) ---
  void _showOrderDetail(Order order) {
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
                        _detailMetaCard('Fecha', order.fecha),
                        _detailMetaCard('Horario', '${order.hora} – ${order.horaFin}'),
                        _detailMetaCard('Método de pago', paymentText),
                        _detailMetaCard('Tipo de entrega', deliveryText),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 10),

                    // Purchased items list (e.g. Combo Familiar)
                    ...order.detalle.map((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.cantidad} x \$${item.precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${(item.precio * item.cantidad).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Totals breakdown matching Capture 3
                    _breakdownRow('Subtotal', '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, false),
                    if (order.descuento > 0) ...[
                      const SizedBox(height: 6),
                      _breakdownRow(
                          'Descuento (${order.descuento.toStringAsFixed(0)}%)',
                          '-\$${discountAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          true,
                          false),
                    ],
                    const SizedBox(height: 6),
                    _breakdownRow('IVA (19%)', '\$${ivaVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, false),
                    const Divider(height: 24),
                    _breakdownRow('Total', '\$${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', false, true),
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

  Widget _detailMetaCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, bool isDiscount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF1F2937) : Colors.grey[600],
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
                    : const Color(0xFF1F2937),
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
