import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../features/sales/data/order.dart';

/// Servicio para exportar datos a archivos Excel (.xlsx)
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  // ─── Colores reutilizables ────────────────────────────────────────────────
  static final ExcelColor _red = ExcelColor.fromHexString('#F05454');
  static final ExcelColor _dark = ExcelColor.fromHexString('#2C3E50');
  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');
  static final ExcelColor _gray = ExcelColor.fromHexString('#666666');
  static final ExcelColor _lightGray = ExcelColor.fromHexString('#888888');

  // ─── Estilos de celda ────────────────────────────────────────────────────

  CellStyle _headerStyle() => CellStyle(
        bold: true,
        fontColorHex: _white,
        backgroundColorHex: _red,
        horizontalAlign: HorizontalAlign.Center,
      );

  CellStyle _currencyStyle() =>
      CellStyle(horizontalAlign: HorizontalAlign.Right);

  CellStyle _centerStyle() =>
      CellStyle(horizontalAlign: HorizontalAlign.Center);

  void _setHeader(Sheet sheet, int row, List<String> headers) {
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle();
    }
  }

  // ─── Permiso de almacenamiento ───────────────────────────────────────────

  Future<void> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  // ─── Directorio de Descargas ─────────────────────────────────────────────

  Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download/ChazinFood');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      final chazinDir = Directory('${docDir.path}/ChazinFood');
      if (!await chazinDir.exists()) await chazinDir.create(recursive: true);
      return chazinDir;
    }
  }

  // ─── Guardar y notificar ─────────────────────────────────────────────────

  Future<String?> _saveAndNotify(
    Excel excel,
    String fileName,
    BuildContext context,
  ) async {
    try {
      await _requestStoragePermission();
      final dir = await _getDownloadsDir();
      final filePath = '${dir.path}/$fileName';
      final bytes = excel.save();
      if (bytes == null) throw Exception('No se pudo generar el archivo');
      await File(filePath).writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✅ Excel guardado en Descargas',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('ChazinFood/$fileName',
                    style: const TextStyle(fontSize: 11)),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Compartir',
              textColor: Colors.white,
              onPressed: () => Share.shareXFiles([XFile(filePath)],
                  subject: fileName),
            ),
          ),
        );
      }
      return filePath;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al exportar: $e'),
              backgroundColor: Colors.red),
        );
      }
      return null;
    }
  }

  // ─── Formato moneda COP ──────────────────────────────────────────────────

  String _cop(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  String _timestamp(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}'
      '_${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}';

  // ─── EXPORT HISTORIAL ────────────────────────────────────────────────────

  Future<void> exportHistorial(
    List<Order> orders,
    String periodo,
    BuildContext context,
  ) async {
    final excel = Excel.createExcel();
    const sheetName = 'Historial';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];
    final now = DateTime.now();

    // Fila 0: título
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Historial de Ventas — $periodo')
      ..cellStyle = CellStyle(bold: true, fontSize: 14, fontColorHex: _red);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: 0),
    );

    // Fila 1: fecha exportación
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue(
          'Exportado el ${now.day}/${now.month}/${now.year} '
          'a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}')
      ..cellStyle = CellStyle(italic: true, fontColorHex: _gray);

    // Fila 3: encabezados
    _setHeader(sheet, 3, [
      'ID Pedido', 'Cliente', 'Fecha', 'Hora Inicio', 'Hora Fin',
      'Método Pago', 'Tipo Entrega', 'Subtotal (COP)', 'Descuento (%)', 'Total (COP)',
    ]);

    // Anchos
    for (int c = 0; c < 10; c++) {
      sheet.setColumnWidth(c, [14.0, 22.0, 14.0, 13.0, 13.0, 16.0, 16.0, 16.0, 14.0, 14.0][c]);
    }

    int rowIdx = 4;
    for (final o in orders) {
      final pago = o.metodoPago == 'efectivo'
          ? 'Efectivo'
          : o.metodoPago == 'tarjeta'
              ? 'Tarjeta'
              : 'Transferencia';
      final entrega = o.tipoEntrega == 'mesa'
          ? 'En Mesa'
          : o.tipoEntrega == 'domicilio'
              ? 'Domicilio'
              : 'Para Recoger';

      final vals = [o.id, o.cliente, o.fecha, o.hora, o.horaFin, pago, entrega, o.subtotal, o.descuento, o.total];
      for (int c = 0; c < vals.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
        final v = vals[c];
        if (v is String) {
          cell.value = TextCellValue(v);
        } else if (v is double) {
          cell.value = DoubleCellValue(v);
          cell.cellStyle = (c == 7 || c == 9) ? _currencyStyle() : _centerStyle();
        }
      }
      rowIdx++;

      // Sub-fila con detalle de productos
      if (o.detalle.isNotEmpty) {
        final detail = o.detalle.map((d) => '${d.cantidad}x ${d.nombre}').join(' | ');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
          ..value = TextCellValue('📦 $detail')
          ..cellStyle = CellStyle(italic: true, fontColorHex: _gray, fontSize: 9);
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
          CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx),
        );
      }
      rowIdx++;
    }

    // Fila total
    rowIdx++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx))
      ..value = TextCellValue('TOTAL PERÍODO:')
      ..cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIdx))
      ..value = TextCellValue(_cop(orders.fold(0.0, (s, o) => s + o.total)))
      ..cellStyle = CellStyle(bold: true, fontColorHex: _red, horizontalAlign: HorizontalAlign.Right);

    await _saveAndNotify(excel, 'Chazin_Historial_${_timestamp(now)}.xlsx', context);
  }

  // ─── EXPORT REPORTES ─────────────────────────────────────────────────────

  Future<void> exportReportes(
    List<Order> orders,
    List<SalesSummaryDay> dailyData,
    List<BestSeller> bestSellers,
    String periodo,
    BuildContext context,
  ) async {
    final excel = Excel.createExcel();
    final now = DateTime.now();

    // ── HOJA 1: Ingresos por Día ─────────────────────────────────────────
    excel.rename('Sheet1', 'Ingresos por Día');
    final sh1 = excel['Ingresos por Día'];

    sh1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Análisis de Ventas — $periodo')
      ..cellStyle = CellStyle(bold: true, fontSize: 13, fontColorHex: _red);
    sh1.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0),
    );

    _setHeader(sh1, 2, ['Día', 'Ingresos (COP)', 'Nº Pedidos', 'Ticket Promedio (COP)']);
    for (int c = 0; c < 4; c++) {
      sh1.setColumnWidth(c, [12.0, 18.0, 14.0, 22.0][c]);
    }

    int r = 3;
    for (final d in dailyData) {
      final tp = d.pedidos > 0 ? d.ventas / d.pedidos : 0.0;
      _setRow(sh1, r, [d.dia, d.ventas, d.pedidos, tp]);
      r++;
    }
    r++;
    sh1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('TOTAL SEMANA');
    sh1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
      ..value = DoubleCellValue(dailyData.fold(0.0, (s, d) => s + d.ventas))
      ..cellStyle = CellStyle(bold: true, fontColorHex: _red, horizontalAlign: HorizontalAlign.Right);
    sh1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
      ..value = IntCellValue(dailyData.fold(0, (s, d) => s + d.pedidos))
      ..cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

    // ── HOJA 2: Productos Estrella ────────────────────────────────────────
    excel.copy('Ingresos por Día', 'Productos Estrella');
    final sh2 = excel['Productos Estrella'];
    sh2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Productos Más Vendidos — $periodo')
      ..cellStyle = CellStyle(bold: true, fontSize: 13, fontColorHex: _red);

    _setHeader(sh2, 2, ['#', 'Producto', 'Unidades Vendidas', '% del Total']);
    for (int c = 0; c < 4; c++) {
      sh2.setColumnWidth(c, [6.0, 30.0, 20.0, 16.0][c]);
    }

    final totalU = bestSellers.fold(0, (s, b) => s + b.cantidad);
    int bsr = 3;
    for (int i = 0; i < bestSellers.length; i++) {
      final b = bestSellers[i];
      final pct = totalU > 0 ? (b.cantidad / totalU) * 100 : 0.0;
      final rowVals = ['${i + 1}', b.nombre, '${b.cantidad}', '${pct.toStringAsFixed(1)}%'];
      for (int c = 0; c < 4; c++) {
        sh2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: bsr)).value = TextCellValue(rowVals[c]);
        if (c != 1) sh2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: bsr)).cellStyle = _centerStyle();
      }
      bsr++;
    }

    // ── HOJA 3: Resumen Ejecutivo ─────────────────────────────────────────
    excel.copy('Ingresos por Día', 'Resumen Ejecutivo');
    final sh3 = excel['Resumen Ejecutivo'];
    sh3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Resumen Ejecutivo — $periodo')
      ..cellStyle = CellStyle(bold: true, fontSize: 13, fontColorHex: _red);

    _setHeader(sh3, 2, ['Métrica', 'Valor']);
    sh3.setColumnWidth(0, 32);
    sh3.setColumnWidth(1, 22);

    final totalV = orders.fold(0.0, (s, o) => s + o.total);
    final totalP = orders.length;
    final tp = totalP > 0 ? totalV / totalP : 0.0;
    final totalD = orders.fold(0.0, (s, o) => s + (o.subtotal * (o.descuento / 100)));

    // Día tope
    final Map<String, double> dSales = {};
    for (final o in orders) { dSales[o.fecha] = (dSales[o.fecha] ?? 0) + o.total; }
    String topDia = 'N/A';
    if (dSales.isNotEmpty) {
      final top = dSales.entries.reduce((a, b) => a.value > b.value ? a : b);
      topDia = '${top.key} (${_cop(top.value)})';
    }

    // Producto estrella
    final Map<String, int> prodC = {};
    for (final o in orders) {
      for (final d in o.detalle) { prodC[d.nombre] = (prodC[d.nombre] ?? 0) + d.cantidad; }
    }
    String star = 'N/A';
    if (prodC.isNotEmpty) {
      final top = prodC.entries.reduce((a, b) => a.value > b.value ? a : b);
      star = '${top.key} (${top.value} und.)';
    }

    // Método de pago favorito
    final Map<String, int> payC = {};
    for (final o in orders) { payC[o.metodoPago] = (payC[o.metodoPago] ?? 0) + 1; }
    String favPay = 'N/A';
    if (payC.isNotEmpty) {
      final top = payC.entries.reduce((a, b) => a.value > b.value ? a : b);
      final pct = totalP > 0 ? (top.value / totalP) * 100 : 0.0;
      final lbl = top.key == 'efectivo' ? 'Efectivo' : top.key == 'tarjeta' ? 'Tarjeta' : 'Transferencia';
      favPay = '$lbl (${pct.toStringAsFixed(0)}%)';
    }

    final metrics = [
      ['Ingresos totales del período', _cop(totalV)],
      ['Total de pedidos procesados', '$totalP pedidos'],
      ['Ticket promedio por pedido', _cop(tp)],
      ['Total en descuentos aplicados', _cop(totalD)],
      ['Día con mayor facturación', topDia],
      ['Producto estrella', star],
      ['Método de pago preferido', favPay],
      ['Clientes únicos atendidos', '${orders.map((o) => o.cliente).toSet().length}'],
    ];

    int mr = 3;
    for (final m in metrics) {
      sh3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: mr)).value = TextCellValue(m[0]);
      sh3.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: mr))
        ..value = TextCellValue(m[1])
        ..cellStyle = CellStyle(bold: true, fontColorHex: _dark, horizontalAlign: HorizontalAlign.Right);
      mr++;
    }

    // Pie: fecha de exportación
    mr++;
    sh3.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: mr))
      ..value = TextCellValue(
          'Exportado el ${now.day}/${now.month}/${now.year} '
          'a las ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} — Chazin Food')
      ..cellStyle = CellStyle(italic: true, fontColorHex: _lightGray, fontSize: 9);
    sh3.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: mr),
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: mr),
    );

    await _saveAndNotify(excel, 'Chazin_Reportes_${_timestamp(now)}.xlsx', context);
  }

  // ─── Helper: set row values ──────────────────────────────────────────────

  void _setRow(Sheet sheet, int rowIdx, List<dynamic> vals) {
    for (int c = 0; c < vals.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
      final v = vals[c];
      if (v is String) {
        cell.value = TextCellValue(v);
        cell.cellStyle = _centerStyle();
      } else if (v is double) {
        cell.value = DoubleCellValue(v);
        cell.cellStyle = _currencyStyle();
      } else if (v is int) {
        cell.value = IntCellValue(v);
        cell.cellStyle = _centerStyle();
      }
    }
  }
}
