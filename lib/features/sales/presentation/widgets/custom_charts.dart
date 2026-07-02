import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/order.dart';

// --- Daily Revenue Bar Chart with Interactive Tooltip ---
class DailyRevenueChart extends StatefulWidget {
  final List<SalesSummaryDay> data;

  const DailyRevenueChart({super.key, required this.data});

  @override
  State<DailyRevenueChart> createState() => _DailyRevenueChartState();
}

class _DailyRevenueChartState extends State<DailyRevenueChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    double maxRevenue = widget.data.fold(1.0, (maxVal, item) => max(maxVal, item.ventas));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937);
    final textSecondary = isDark ? AppColors.textSecondaryDark : Colors.grey;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(20);

    return LayoutBuilder(
      builder: (context, constraints) {
        double columnWidth = constraints.maxWidth / widget.data.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresos diarios (COP)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Grid / Highlight Backgrounds
                    Row(
                      children: widget.data.asMap().entries.map((entry) {
                        int index = entry.key;
                        bool isSelected = _selectedIndex == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = (_selectedIndex == index) ? null : index;
                              });
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              color: isSelected ? Colors.grey.withAlpha(25) : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // The Bars and Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: widget.data.asMap().entries.map((entry) {
                        var item = entry.value;
                        double heightPercent = item.ventas / maxRevenue;

                        return Expanded(
                          child: IgnorePointer(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '\$${(item.ventas / 1000).toStringAsFixed(0)}k',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textPrimary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: max(6.0, heightPercent * 90),
                                  width: 14,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF05454), Color(0xFFC92C2C)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.dia,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Floating Tooltip Popup
                    if (_selectedIndex != null) ...[
                      _buildTooltip(columnWidth, constraints.maxWidth, isDark, textPrimary),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(double columnWidth, double maxWidth, bool isDark, Color textPrimary) {
    int index = _selectedIndex!;
    var item = widget.data[index];

    double tooltipWidth = 140;
    double leftOffset = (index * columnWidth) + (columnWidth / 2) - (tooltipWidth / 2);
    leftOffset = leftOffset.clamp(4.0, maxWidth - tooltipWidth - 4.0);

    return Positioned(
      top: 15,
      left: leftOffset,
      child: Container(
        width: tooltipWidth,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getFullDayName(item.dia),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Ingresos : \$${item.ventas.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC92C2C)),
            ),
          ],
        ),
      ),
    );
  }

  String _getFullDayName(String short) {
    switch (short) {
      case 'Lun': return 'Lunes';
      case 'Mar': return 'Martes';
      case 'Mié': return 'Miércoles';
      case 'Jue': return 'Jueves';
      case 'Vie': return 'Viernes';
      case 'Sáb': return 'Sábado';
      default: return 'Domingo';
    }
  }
}

// --- Daily Orders Line Chart with Click Tooltip ---
class DailyOrdersChart extends StatefulWidget {
  final List<SalesSummaryDay> data;

  const DailyOrdersChart({super.key, required this.data});

  @override
  State<DailyOrdersChart> createState() => _DailyOrdersChartState();
}

class _DailyOrdersChartState extends State<DailyOrdersChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    List<double> points = widget.data.map<double>((e) => e.pedidos.toDouble()).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937);
    final textSecondary = isDark ? AppColors.textSecondaryDark : Colors.grey;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(20);

    return LayoutBuilder(
      builder: (context, constraints) {
        double widthStep = constraints.maxWidth / (widget.data.isEmpty ? 1 : widget.data.length - 1);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Número de pedidos por día',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Canvas chart painter with gesture trigger
                    GestureDetector(
                      onTapUp: (details) {
                        double tappedX = details.localPosition.dx;
                        int idx = (tappedX / widthStep).round();
                        idx = idx.clamp(0, widget.data.length - 1);
                        setState(() {
                          _selectedIndex = (_selectedIndex == idx) ? null : idx;
                        });
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 140),
                        painter: LineChartPainter(
                          points: points,
                          days: widget.data.map((e) => e.dia).toList(),
                          selectedIndex: _selectedIndex,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    // Hover Tooltip Popup (Capture 3 style)
                    if (_selectedIndex != null) ...[
                      _buildTooltip(widthStep, constraints.maxWidth, isDark, textPrimary),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(double widthStep, double maxWidth, bool isDark, Color textPrimary) {
    int index = _selectedIndex!;
    var item = widget.data[index];

    double tooltipWidth = 120;
    double leftOffset = (index * widthStep) - (tooltipWidth / 2);
    leftOffset = leftOffset.clamp(4.0, maxWidth - tooltipWidth - 4.0);

    return Positioned(
      top: 15,
      left: leftOffset,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.dia == 'Lun' ? 'Lunes' :
                item.dia == 'Mar' ? 'Martes' :
                item.dia == 'Mié' ? 'Miércoles' :
                item.dia == 'Jue' ? 'Jueves' :
                item.dia == 'Vie' ? 'Viernes' :
                item.dia == 'Sáb' ? 'Sábado' : 'Domingo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Pedidos : ${item.pedidos}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF30475E)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> points;
  final List<String> days;
  final int? selectedIndex;
  final bool isDark;

  LineChartPainter({required this.points, required this.days, this.selectedIndex, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFF30475E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF30475E)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(15)
      ..strokeWidth = 0.8;

    double maxVal = points.reduce(max);
    double minVal = 0;
    double range = maxVal - minVal;
    if (range == 0) range = 1;

    double widthStep = size.width / (points.length - 1);

    // Draw horizontal grid lines
    int gridCount = 3;
    for (int i = 0; i <= gridCount; i++) {
      double y = size.height - (i * (size.height - 20) / gridCount) - 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final path = Path();
    List<Offset> coordinates = [];

    for (int i = 0; i < points.length; i++) {
      double x = i * widthStep;
      double ratio = (points[i] - minVal) / range;
      double y = size.height - 25 - (ratio * (size.height - 45));
      Offset pt = Offset(x, y);
      coordinates.add(pt);

      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Draw lines
    canvas.drawPath(path, paintLine);

    // If a point is selected, draw a vertical marker line and point halo highlight
    if (selectedIndex != null && selectedIndex! < coordinates.length) {
      Offset selectedPt = coordinates[selectedIndex!];

      // Vertical dotted/marker line
      final paintMarker = Paint()
        ..color = isDark ? Colors.white24 : Colors.grey[400]!
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(selectedPt.dx, selectedPt.dy), Offset(selectedPt.dx, size.height - 20), paintMarker);

      // Selected outer glow ring
      final paintGlow = Paint()
        ..color = const Color(0xFF30475E).withAlpha(40)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPt, 8.0, paintGlow);
    }

    // Draw points & labels
    for (int i = 0; i < coordinates.length; i++) {
      Offset pt = coordinates[i];
      canvas.drawCircle(pt, 4.0, paintDot);

      // Draw active values only if not selected or overlay tooltip shows it
      if (selectedIndex != i) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: points[i].toInt().toString(),
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : const Color(0xFF30475E)),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, pt.dy - 14));
      }

      // Day label
      final dayPainter = TextPainter(
        text: TextSpan(
          text: days[i],
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppColors.textSecondaryDark : Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      );
      dayPainter.layout();
      dayPainter.paint(canvas, Offset(pt.dx - dayPainter.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}

// --- Top Products Chart with Row highlight and popups ---
class TopProductsChart extends StatefulWidget {
  final List<BestSeller> data;

  const TopProductsChart({super.key, required this.data});

  @override
  State<TopProductsChart> createState() => _TopProductsChartState();
}

class _TopProductsChartState extends State<TopProductsChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    int maxQty = widget.data.fold(1, (maxVal, item) => max(maxVal, item.cantidad));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937);
    final textSecondary = isDark ? AppColors.textSecondaryDark : Colors.grey;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(20);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productos más vendidos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
              ),
              const SizedBox(height: 12),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: widget.data.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      double percent = item.cantidad / maxQty;
                      bool isSelected = _selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                           setState(() {
                             _selectedIndex = (_selectedIndex == index) ? null : index;
                           });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: isSelected ? (isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(20)) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  item.nombre,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(15),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      width: (constraints.maxWidth - 130) * percent,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFF05454) : (isDark ? AppColors.primaryLight : const Color(0xFF30475E)),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 22,
                                child: Text(
                                  '${item.cantidad}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Floating Tooltip above the selected product row
                  if (_selectedIndex != null) ...[
                    _buildRowTooltip(constraints.maxWidth, isDark, textPrimary),
                  ]
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRowTooltip(double maxWidth, bool isDark, Color textPrimary) {
    int index = _selectedIndex!;
    var item = widget.data[index];

    double tooltipWidth = 160;
    // Position vertically center of tapped row. Row height is 22 (padding/margins make it approx 32px height)
    double topOffset = (index * 34.0) - 26;
    double leftOffset = (maxWidth / 2) - (tooltipWidth / 2);

    return Positioned(
      top: topOffset,
      left: leftOffset,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.nombre,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Vendidos: ${item.cantidad} und.',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC92C2C)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Payment Methods Donut Chart with interactive Center displays ---
class PaymentMethodsChart extends StatefulWidget {
  final List<PaymentMethodShare> data;

  const PaymentMethodsChart({super.key, required this.data});

  @override
  State<PaymentMethodsChart> createState() => _PaymentMethodsChartState();
}

class _PaymentMethodsChartState extends State<PaymentMethodsChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937);
    final textSecondary = isDark ? AppColors.textSecondaryDark : Colors.grey;
    final borderColor = isDark ? Colors.white.withAlpha(20) : Colors.grey.withAlpha(20);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métodos de pago',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textSecondary),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              bool useVertical = constraints.maxWidth < 260;

              Widget donut = GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedIndex == null) {
                      _selectedIndex = 0;
                    } else if (_selectedIndex == 0) {
                      _selectedIndex = 1;
                    } else {
                      _selectedIndex = null;
                    }
                  });
                },
                child: SizedBox(
                  height: 90,
                  width: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(90, 90),
                        painter: DonutPainter(shares: widget.data, selectedIndex: _selectedIndex),
                      ),
                      // Center Circle overlay showing active details
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedIndex == null
                                  ? 'Todos'
                                  : widget.data[_selectedIndex!].metodo,
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _selectedIndex == null
                                  ? '100%'
                                  : '${widget.data[_selectedIndex!].porcentaje.toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textPrimary),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );

              Widget legend = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.data.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  Color color = index == 0 ? const Color(0xFF30475E) : const Color(0xFFF05454);
                  bool isSelected = _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = (_selectedIndex == index) ? null : index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(20)) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.metodo} (${item.porcentaje.toStringAsFixed(0)}%)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );

              return useVertical
                  ? Column(
                      children: [
                        Center(child: donut),
                        const SizedBox(height: 16),
                        legend,
                      ],
                    )
                  : Row(
                      children: [
                        const SizedBox(width: 8),
                        donut,
                        const SizedBox(width: 24),
                        Expanded(child: legend),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  final List<PaymentMethodShare> shares;
  final int? selectedIndex;

  DonutPainter({required this.shares, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    double total = shares.fold(0.0, (sum, item) => sum + item.porcentaje);
    if (total == 0) return;

    double startAngle = -pi / 2;
    Rect rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2 - 8);

    for (int i = 0; i < shares.length; i++) {
      double sweepAngle = (shares[i].porcentaje / total) * 2 * pi;
      bool isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = i == 0 ? const Color(0xFF30475E) : const Color(0xFFF05454)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 18.0 : 13.0; // thicken slice when selected

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => true;
}
