import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../events/providers/events_provider.dart';
import '../../products/providers/products_provider.dart';

/// Pantalla completa para crear una campaña/evento.
/// Diseñada para Flutter Web (CanvasKit) + Mobile.
/// Body: ListView directo (sin Column+Expanded) para evitar
/// problemas de constraints en CanvasKit.
class CreateEventScreen extends ConsumerStatefulWidget {
  final Product? linkedProduct;
  const CreateEventScreen({super.key, this.linkedProduct});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  int _step = 0;

  // Paso 1
  String _tipo = 'promo_2x1';
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  final _pct = TextEditingController();
  final _precio = TextEditingController();
  final _top = TextEditingController();

  // Paso 2
  final List<Product> _selProd = [];
  String _search = '';

  // Paso 3
  String? _banner;
  final _bannerCtrl = TextEditingController();
  bool _permanente = false;
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 30));

  bool _saving = false;

  static const _orange = Color(0xFFE65100);
  static const _green = Color(0xFF22C55E);
  static const _bg = Color(0xFF12121F);
  static const _card = Color(0xFF1C1C2E);
  static const _border = Color(0xFF2A2A45);

  static const _tipos = [
    {'id': 'promo_2x1', 'nombre': 'Promoción 2x1', 'emoji': '🏷️'},
    {'id': 'descuento', 'nombre': 'Descuento %', 'emoji': '💯'},
    {'id': 'precio_especial', 'nombre': 'Precio Especial', 'emoji': '💲'},
    {'id': 'topping_extra', 'nombre': 'Topping Extra', 'emoji': '➕'},
    {'id': 'edicion_especial', 'nombre': 'Edición Especial', 'emoji': '⭐'},
    {'id': 'oferta_relampago', 'nombre': 'Oferta Relámpago', 'emoji': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.linkedProduct != null) _selProd.add(widget.linkedProduct!);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    _pct.dispose();
    _precio.dispose();
    _top.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (_titulo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final ids = _selProd
        .map((p) => p.id.isNotEmpty ? int.tryParse(p.id) : null)
        .whereType<int>()
        .toList();
    final event = Event(
      nombre: _titulo.text.trim(),
      descripcion: _desc.text.trim(),
      tipoEvento: _tipo,
      descuento: _tipo == 'descuento' ? double.tryParse(_pct.text) : null,
      nuevoPrecio:
          _tipo == 'precio_especial' ? double.tryParse(_precio.text) : null,
      accionInsumo: _tipo == 'topping_extra' ? _top.text.trim() : null,
      isActive: true,
      estado: 'Activo',
      fechaInicio: _permanente ? null : _inicio.toIso8601String(),
      fechaFin: _permanente ? null : _fin.toIso8601String(),
      productosAsociados: ids.isEmpty ? null : ids,
      icono: _banner ??
          (_bannerCtrl.text.trim().isEmpty ? null : _bannerCtrl.text.trim()),
      isTemporal: !_permanente,
    );
    final ok = await ref.read(eventsProvider.notifier).createEvent(event);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Campaña publicada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al publicar. Inténtalo de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear Campaña o Promoción',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Aplica descuentos, 2×1 o beneficios',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
      // ── ListView como body directo ──────────────────────────────────────
      // Evita el problema de Column+Expanded+SingleChildScrollView en Flutter
      // Web CanvasKit que causa body negro.
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _stepBar(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _stepContent(),
          ),
          // Espacio extra al final para que el footer no tape el contenido
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: _footer(),
    );
  }

  // ─── BARRA DE PASOS ───────────────────────────────────────────────────────
  Widget _stepBar() {
    final steps = ['1. Dinámica', '2. Productos', '3. Banner'];
    return Container(
      color: _card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(steps.length, (i) {
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _step ? _orange : _border,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          done ? _green : (active ? _orange : _border),
                      child: done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: active ? Colors.white : Colors.white38,
                              ),
                            ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 8,
                        color: active ? _orange : Colors.white38,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (i == steps.length - 1) const SizedBox(width: 0),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── CONTENIDO POR PASO ───────────────────────────────────────────────────
  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── PASO 1: Tipo de dinámica ─────────────────────────────────────────────
  Widget _step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('¿QUÉ BENEFICIO OFRECERÁ LA CAMPAÑA?'),
        const SizedBox(height: 12),
        // Grid 2 columnas usando Row+Column para evitar GridView en web
        ..._buildTiposGrid(),
        const SizedBox(height: 16),
        _label('TÍTULO DE LA CAMPAÑA *'),
        const SizedBox(height: 6),
        _textInput(_titulo, 'Ej: Jueves 2×1 de Burger Artesanal'),
        if (_tipo == 'descuento') ...[
          const SizedBox(height: 12),
          _label('PORCENTAJE DE DESCUENTO *'),
          const SizedBox(height: 6),
          _textInput(_pct, 'Ej: 15', suffix: '%', kb: TextInputType.number),
        ],
        if (_tipo == 'precio_especial') ...[
          const SizedBox(height: 12),
          _label('NUEVO PRECIO ESPECIAL (COP) *'),
          const SizedBox(height: 6),
          _textInput(_precio, 'Ej: 15000',
              prefix: r'$', kb: TextInputType.number),
        ],
        if (_tipo == 'topping_extra') ...[
          const SizedBox(height: 12),
          _label('NOMBRE DEL TOPPING *'),
          const SizedBox(height: 6),
          _textInput(_top, 'Ej: Extra Tocineta Ahumada'),
        ],
        const SizedBox(height: 12),
        _label('DESCRIPCIÓN (OPCIONAL)'),
        const SizedBox(height: 6),
        _textInput(_desc, 'Breve descripción...', maxLines: 3),
      ],
    );
  }

  List<Widget> _buildTiposGrid() {
    final rows = <Widget>[];
    for (int i = 0; i < _tipos.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _tipoCard(_tipos[i])),
            const SizedBox(width: 8),
            Expanded(
              child: i + 1 < _tipos.length
                  ? _tipoCard(_tipos[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < _tipos.length) rows.add(const SizedBox(height: 8));
    }
    return rows;
  }

  Widget _tipoCard(Map<String, String> t) {
    final sel = _tipo == t['id'];
    return GestureDetector(
      onTap: () => setState(() => _tipo = t['id']!),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: sel ? _orange.withAlpha(40) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? _orange : _border,
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(t['emoji']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t['nombre']!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? _orange : Colors.white,
                ),
              ),
            ),
            if (sel) const Icon(Icons.check_circle, size: 16, color: _orange),
          ],
        ),
      ),
    );
  }

  // ─── PASO 2: Productos ────────────────────────────────────────────────────
  Widget _step2() {
    final allP = ref.read(productsProvider).products;
    final filtered = _search.isEmpty
        ? allP
        : allP
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_search.toLowerCase()) ||
                  p.categoryName
                      .toLowerCase()
                      .contains(_search.toLowerCase()),
            )
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel('SELECCIONA LOS PRODUCTOS'),
        const SizedBox(height: 4),
        Text(
          '${_selProd.length} producto(s) seleccionado(s)',
          style: GoogleFonts.inter(fontSize: 10, color: _orange),
        ),
        const SizedBox(height: 12),
        // Buscador
        TextField(
          onChanged: (v) => setState(() => _search = v),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: _orange),
            filled: true,
            fillColor: _card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _orange),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No se encontraron productos',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          ...filtered.map((p) {
            final sel = _selProd.any((s) => s.id == p.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _selProd.removeWhere((s) => s.id == p.id);
                } else {
                  _selProd.add(p);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel ? _orange.withAlpha(40) : _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? _orange : _border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      sel ? Icons.check_box : Icons.check_box_outline_blank,
                      color: sel ? _orange : Colors.white38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            p.categoryName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      r'$' + p.price.toStringAsFixed(0),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ─── PASO 3: Banner y Vigencia ────────────────────────────────────────────
  Widget _step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner
        _cardWidget(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionLabel('BANNER PROMOCIONAL'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final url =
                      await CloudinaryService.pickAndUploadImage(context);
                  if (mounted && url != null) setState(() => _banner = url);
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Subir imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (_banner != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_banner!, height: 80, fit: BoxFit.cover),
                ),
              const SizedBox(height: 8),
              _textInput(_bannerCtrl, 'O pegar URL del banner...'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Vigencia
        _cardWidget(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionLabel('VIGENCIA DE LA CAMPAÑA'),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text(
                  'Campaña Permanente',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Sin fecha de vencimiento',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                value: _permanente,
                onChanged: (v) => setState(() => _permanente = v),
                activeTrackColor: _orange,
                activeThumbColor: Colors.white,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_permanente) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dateTile('INICIO', _fmt(_inicio), () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _inicio,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _inicio = d);
                      }),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dateTile('FIN', _fmt(_fin), () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _fin,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (d != null) setState(() => _fin = d);
                      }),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Resumen
        _cardWidget(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionLabel('RESUMEN FINAL'),
              const Divider(color: _border, height: 16),
              _row('CAMPAÑA',
                  _titulo.text.isEmpty ? 'Sin título' : _titulo.text),
              _row('TIPO',
                  _tipos.firstWhere((t) => t['id'] == _tipo)['nombre']!),
              _row('PRODUCTOS', '${_selProd.length} seleccionados'),
              _row(
                'VIGENCIA',
                _permanente
                    ? 'Permanente'
                    : '${_fmt(_inicio)} → ${_fmt(_fin)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  Widget _footer() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _card,
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const Spacer(),
            if (_step > 0)
              TextButton.icon(
                onPressed: () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back_ios_new,
                    size: 12, color: _orange),
                label:
                    const Text('Anterior', style: TextStyle(color: _orange)),
              ),
            const SizedBox(width: 8),
            if (_step < 2)
              ElevatedButton(
                onPressed: () => setState(() => _step++),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Siguiente ›',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '⚡ Crear y Publicar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Widget _cardWidget(Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: child,
      );

  Widget _sectionLabel(String t) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
      );

  Widget _label(String t) => Text(
        t,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white60,
        ),
      );

  Widget _textInput(
    TextEditingController ctrl,
    String hint, {
    String? suffix,
    String? prefix,
    int maxLines = 1,
    TextInputType? kb,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: kb,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        suffixText: suffix,
        prefixText: prefix,
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _orange),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _dateTile(String label, String value, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.white38),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 11, color: _orange),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
