import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../events/providers/events_provider.dart';
import '../../products/providers/products_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateEventScreen — Pantalla completa con Scaffold propio.
// Navigator.push evita cualquier problema de mouse_tracker/overlay en web/mobile.
// AppBar usa PreferredSize+Container (garantizado en Flutter Web y Mobile).
// Body usa ListView simple — sin Column+Expanded que causa constraints vacíos.
// ─────────────────────────────────────────────────────────────────────────────
class CreateEventScreen extends ConsumerStatefulWidget {
  final Product? linkedProduct;
  const CreateEventScreen({super.key, this.linkedProduct});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  static const _kOrange  = Color(0xFFE65100);
  static const _kOrange2 = Color(0xFFF97316);
  static const _kGreen   = Color(0xFF22C55E);

  // ─── Wizard state ─────────────────────────────────────────────────────────
  int    _step    = 0;
  String _dinamica = 'promo_2x1';

  final _tituloCtrl         = TextEditingController();
  final _descCtrl           = TextEditingController();
  final _descuentoCtrl      = TextEditingController();
  final _precioEspecialCtrl = TextEditingController();
  final _toppingCtrl        = TextEditingController();

  List<Product> _selectedProducts    = [];
  String        _productSearch       = '';
  String?       _selectedCategoryFilter;

  String?  _bannerUrl;
  bool     _subiendoBanner  = false;
  final    _bannerUrlCtrl   = TextEditingController();
  bool     _campanaPermanente = false;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin    = DateTime.now().add(const Duration(days: 30));

  bool _guardando = false;

  static const List<Map<String, dynamic>> _dinamicaOpts = [
    {'id': 'promo_2x1',       'label': 'Promoción 2x1',    'icon': Icons.local_offer_rounded,    'desc': 'Lleva 2 unidades al precio de 1',              'color': Color(0xFFEF4444)},
    {'id': 'descuento',       'label': 'Descuento %',       'icon': Icons.percent_rounded,         'desc': 'Rebaja porcentual sobre el precio de carta',   'color': Color(0xFF22C55E)},
    {'id': 'precio_especial', 'label': 'Precio Especial',   'icon': Icons.price_change_rounded,    'desc': 'Precio promocional fijo y rebajado',           'color': Color(0xFFF97316)},
    {'id': 'topping_extra',   'label': 'Topping Extra',     'icon': Icons.add_circle_rounded,      'desc': 'Topping o ingrediente de cortesía sin costo',  'color': Color(0xFF8B5CF6)},
    {'id': 'edicion_especial','label': 'Edición Especial',  'icon': Icons.emoji_events_rounded,    'desc': 'Campaña gastronómica o temporada exclusiva',   'color': Color(0xFFEAB308)},
    {'id': 'oferta_relampago','label': 'Oferta Relámpago',  'icon': Icons.flash_on_rounded,        'desc': 'Promoción express por tiempo limitado',        'color': Color(0xFFF59E0B)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.linkedProduct != null) {
      _selectedProducts = [widget.linkedProduct!];
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose(); _descCtrl.dispose(); _descuentoCtrl.dispose();
    _precioEspecialCtrl.dispose(); _toppingCtrl.dispose(); _bannerUrlCtrl.dispose();
    super.dispose();
  }

  // ─── Computed ─────────────────────────────────────────────────────────────
  String get _dinamicaLabel => (_dinamicaOpts.firstWhere(
        (o) => o['id'] == _dinamica, orElse: () => _dinamicaOpts.first)['label'] as String);

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  List<Product> get _filteredProducts {
    var list = List<Product>.from(ref.read(productsProvider).products);
    if (_selectedCategoryFilter != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
    }
    if (_productSearch.isNotEmpty) {
      final q = _productSearch.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<ProductCategory> get _categories => ref.read(productsProvider).categories
      .where((c) => c.id != 'cat_all' && c.id != '0' && c.isActive).toList();

  // ─── Actions ──────────────────────────────────────────────────────────────
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2024), lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _fechaInicio = picked;
        if (_fechaFin.isBefore(picked)) _fechaFin = picked.add(const Duration(days: 1));
      } else {
        _fechaFin = picked;
      }
    });
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) { _snack('El título es obligatorio'); return; }
    setState(() => _guardando = true);
    final productIds = _selectedProducts
        .map((p) => p.id.isNotEmpty ? int.tryParse(p.id) : null)
        .whereType<int>().toList();
    final event = Event(
      nombre:        _tituloCtrl.text.trim(),
      descripcion:   _descCtrl.text.trim(),
      tipoEvento:    _dinamica,
      descuento:     _dinamica == 'descuento'       ? double.tryParse(_descuentoCtrl.text)      : null,
      nuevoPrecio:   _dinamica == 'precio_especial' ? double.tryParse(_precioEspecialCtrl.text) : null,
      accionInsumo:  _dinamica == 'topping_extra'   ? _toppingCtrl.text.trim()                 : null,
      isActive:      true,
      estado:        'Activo',
      fechaInicio:   _campanaPermanente ? null : _fechaInicio.toIso8601String(),
      fechaFin:      _campanaPermanente ? null : _fechaFin.toIso8601String(),
      productosAsociados: productIds.isEmpty ? null : productIds,
      icono: _bannerUrl ?? (_bannerUrlCtrl.text.trim().isEmpty ? null : _bannerUrlCtrl.text.trim()),
      isTemporal: !_campanaPermanente,
    );
    final ok = await ref.read(eventsProvider.notifier).createEvent(event);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (ok) {
      _snack('✅ Campaña publicada exitosamente', isError: false);
      Navigator.of(context).pop(true);
    } else {
      _snack('No se pudo publicar. Inténtalo de nuevo.');
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark     = brightness == Brightness.dark;

    // High-contrast color tokens — work correctly in both light & dark mode
    final Color scaffoldBg  = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5);
    final Color cardBg      = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0E0);
    final Color txtMain     = isDark ? Colors.white            : const Color(0xFF111827);
    final Color txtSub      = isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: scaffoldBg,
      // ── AppBar con PreferredSize+Container (funciona en web Y mobile)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kOrange, _kOrange2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crear Campaña o Promoción',
                        style: GoogleFonts.outfit(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Aplica descuentos, 2x1 o beneficios a tu menú.',
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      // ── Body: ListView directo — sin Column+Expanded
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          _buildTabs(isDark, cardBg, borderColor, txtMain, txtSub),
          const SizedBox(height: 14),
          _buildStepBar(isDark, txtSub),
          const SizedBox(height: 18),
          _buildStepContent(isDark, cardBg, borderColor, txtMain, txtSub),
          const SizedBox(height: 100), // espacio para el footer fijo
        ],
      ),
      // ── Footer fijo
      bottomNavigationBar: _buildFooter(isDark, cardBg, borderColor, txtSub),
    );
  }

  // ─── TABS ─────────────────────────────────────────────────────────────────
  Widget _buildTabs(bool isDark, Color card, Color border, Color txtMain, Color txtSub) {
    return Row(children: [
      Expanded(child: _tab(false, Icons.local_offer_rounded,
          'MENÚ EXISTENTE', '2x1, % OFF o Toppings', card, border, txtMain, txtSub)),
      const SizedBox(width: 8),
      Expanded(child: _tab(true, Icons.auto_awesome_rounded,
          'NUEVO PLATILLO', 'Ficha Técnica desde cero', card, border, txtMain, txtSub)),
    ]);
  }

  Widget _tab(bool isNuevo, IconData icon, String title, String sub,
      Color card, Color border, Color txtMain, Color txtSub) {
    // "Menú Existente" (isNuevo=false) siempre activo por ahora
    final sel = !isNuevo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: sel ? _kOrange.withAlpha(30) : card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sel ? _kOrange : border, width: sel ? 1.5 : 1),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: sel ? _kOrange : txtSub),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
              color: sel ? _kOrange : txtSub)),
          Text(sub,
            style: GoogleFonts.inter(fontSize: 8, color: txtSub)),
        ])),
      ]),
    );
  }

  // ─── STEP BAR ─────────────────────────────────────────────────────────────
  Widget _buildStepBar(bool isDark, Color txtSub) {
    final inactiveCircle = isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0E0);
    final inactiveLine   = isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0E0);
    final labels = [
      '1. Dinámica',
      '2. Productos (${_selectedProducts.length})',
      '3. Banner & Fecha',
    ];
    return Row(children: [
      for (int i = 0; i < 3; i++) ...[
        if (i > 0)
          Expanded(child: Container(height: 2,
            color: i <= _step ? _kOrange : inactiveLine)),
        Column(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _step ? _kGreen : (i == _step ? _kOrange : inactiveCircle),
            ),
            child: Center(
              child: i < _step
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : Text('${i + 1}',
                      style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: i == _step ? Colors.white : txtSub)),
            ),
          ),
          const SizedBox(height: 4),
          Text(labels[i],
            style: GoogleFonts.inter(fontSize: 9,
              fontWeight: i == _step ? FontWeight.w700 : FontWeight.w400,
              color: i == _step ? _kOrange : txtSub)),
        ]),
      ],
    ]);
  }

  // ─── STEP ROUTER ──────────────────────────────────────────────────────────
  Widget _buildStepContent(bool isDark, Color card, Color border,
      Color txtMain, Color txtSub) {
    switch (_step) {
      case 0:  return _buildStep1(isDark, card, border, txtMain, txtSub);
      case 1:  return _buildStep2(isDark, card, border, txtMain, txtSub);
      case 2:  return _buildStep3(isDark, card, border, txtMain, txtSub);
      default: return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: Dinámica & Beneficio ─────────────────────────────────────────
  Widget _buildStep1(bool isDark, Color card, Color border,
      Color txtMain, Color txtSub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('¿QUÉ BENEFICIO OFRECERÁ LA CAMPAÑA? *',
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: txtSub)),
      const SizedBox(height: 12),
      // Grid 3×2 con shrinkWrap dentro de ListView
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: _dinamicaOpts.map((opt) {
          final id    = opt['id'] as String;
          final sel   = _dinamica == id;
          final color = opt['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _dinamica = id),
            child: Container(
              decoration: BoxDecoration(
                color: sel ? color.withAlpha(isDark ? 60 : 30) : card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? color : border, width: sel ? 2 : 1),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withAlpha(35),
                      borderRadius: BorderRadius.circular(7)),
                    child: Icon(opt['icon'] as IconData, size: 14, color: color),
                  ),
                  if (sel) Icon(Icons.check_circle, size: 14, color: color),
                ]),
                const SizedBox(height: 5),
                Text(opt['label'] as String,
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                    color: sel ? color : txtMain)),
                const SizedBox(height: 2),
                Text(opt['desc'] as String,
                  style: GoogleFonts.inter(fontSize: 7.5, color: txtSub, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      _lbl('TÍTULO DE LA CAMPAÑA *', txtSub),
      const SizedBox(height: 6),
      _field(_tituloCtrl, 'Ej: Jueves 2×1 de Burger Artesanal', card, border, txtMain, txtSub),
      if (_dinamica == 'descuento') ...[
        const SizedBox(height: 12),
        _lbl('PORCENTAJE DE DESCUENTO *', txtSub), const SizedBox(height: 6),
        _field(_descuentoCtrl, 'Ej: 15', card, border, txtMain, txtSub,
            suffix: '%', kb: TextInputType.number),
      ],
      if (_dinamica == 'precio_especial') ...[
        const SizedBox(height: 12),
        _lbl('NUEVO PRECIO ESPECIAL (COP) *', txtSub), const SizedBox(height: 6),
        _field(_precioEspecialCtrl, 'Ej: 15000', card, border, txtMain, txtSub,
            prefix: r'$', kb: TextInputType.number),
      ],
      if (_dinamica == 'topping_extra') ...[
        const SizedBox(height: 12),
        _lbl('NOMBRE DEL TOPPING EXTRA *', txtSub), const SizedBox(height: 6),
        _field(_toppingCtrl, 'Ej: Extra Tocineta Ahumada', card, border, txtMain, txtSub),
      ],
      const SizedBox(height: 12),
      _lbl('DESCRIPCIÓN (OPCIONAL)', txtSub), const SizedBox(height: 6),
      _field(_descCtrl, 'Breve descripción de la campaña...', card, border, txtMain, txtSub,
          maxLines: 2),
    ]);
  }

  // ─── STEP 2: Productos ────────────────────────────────────────────────────
  Widget _buildStep2(bool isDark, Color card, Color border,
      Color txtMain, Color txtSub) {
    final cats     = _categories;
    final filtered = _filteredProducts;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('PLATILLOS QUE PARTICIPAN EN LA CAMPAÑA',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: txtMain)),
      const SizedBox(height: 4),
      Text('Agrega o retira platillos del catálogo.',
        style: GoogleFonts.inter(fontSize: 10, color: txtSub)),
      const SizedBox(height: 12),
      if (cats.isNotEmpty) ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: cats.map((cat) {
            final sel = _selectedCategoryFilter == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() =>
                    _selectedCategoryFilter = sel ? null : cat.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _kOrange : card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _kOrange : border),
                  ),
                  child: Text('+ ${cat.name}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : txtSub)),
                ),
              ),
            );
          }).toList()),
        ),
        const SizedBox(height: 10),
      ],
      TextField(
        onChanged: (v) => setState(() => _productSearch = v),
        style: GoogleFonts.inter(fontSize: 13, color: txtMain),
        decoration: InputDecoration(
          hintText: 'Buscar producto por nombre o categoría...',
          hintStyle: GoogleFonts.inter(fontSize: 12, color: txtSub),
          prefixIcon: const Icon(Icons.search, size: 20, color: _kOrange),
          filled: true, fillColor: card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kOrange)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Column(children: [
            Icon(Icons.restaurant_menu_outlined, size: 36, color: txtSub),
            const SizedBox(height: 8),
            Text('No hay productos seleccionados todavía',
              style: GoogleFonts.inter(fontSize: 13, color: txtSub)),
          ])),
        )
      else
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final p   = filtered[i];
            final sel = _selectedProducts.any((s) => s.id == p.id);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _selectedProducts.removeWhere((s) => s.id == p.id);
                } else {
                  _selectedProducts.add(p);
                }
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _kOrange.withAlpha(isDark ? 50 : 25) : card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _kOrange : border),
                ),
                child: Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: sel ? _kOrange : Colors.transparent,
                      border: Border.all(color: sel ? _kOrange : border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: sel
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name,
                      style: GoogleFonts.inter(fontSize: 13,
                          fontWeight: FontWeight.w600, color: txtMain)),
                    Text(p.categoryName,
                      style: GoogleFonts.inter(fontSize: 11, color: txtSub)),
                  ])),
                  Text('\$${p.price.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 14,
                        fontWeight: FontWeight.w700, color: _kOrange)),
                ]),
              ),
            );
          },
        ),
    ]);
  }

  // ─── STEP 3: Banner & Vigencia ────────────────────────────────────────────
  Widget _buildStep3(bool isDark, Color card, Color border,
      Color txtMain, Color txtSub) {
    final innerBg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F5F5);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Banner card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.image_rounded, size: 15, color: _kOrange),
            const SizedBox(width: 6),
            Text('BANNER PROMOCIONAL',
              style: GoogleFonts.inter(fontSize: 10,
                  fontWeight: FontWeight.w700, color: txtMain)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 80, height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(10)),
              child: _bannerUrl != null && _bannerUrl!.isNotEmpty
                  ? ClipRRect(borderRadius: BorderRadius.circular(10),
                      child: Image.network(_bannerUrl!, fit: BoxFit.cover))
                  : Center(child: Icon(Icons.image_outlined, size: 24, color: txtSub)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ElevatedButton.icon(
                onPressed: _subiendoBanner ? null : () async {
                  setState(() => _subiendoBanner = true);
                  final url = await CloudinaryService.pickAndUploadImage(context);
                  if (mounted) setState(() { _bannerUrl = url; _subiendoBanner = false; });
                },
                icon: _subiendoBanner
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload_outlined, size: 15),
                label: Text('Subir Banner',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bannerUrlCtrl,
                onChanged: (v) => setState(() =>
                    _bannerUrl = v.trim().isEmpty ? null : v.trim()),
                style: GoogleFonts.inter(fontSize: 12, color: txtMain),
                decoration: InputDecoration(
                  hintText: 'O pegar URL del banner...',
                  hintStyle: GoogleFonts.inter(fontSize: 11, color: txtSub),
                  filled: true, fillColor: innerBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kOrange)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ])),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      // Vigencia card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border)),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.loop_rounded, size: 15, color: _kOrange),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CAMPAÑA PERMANENTE',
                style: GoogleFonts.inter(fontSize: 11,
                    fontWeight: FontWeight.w700, color: txtMain)),
              Text('Sin fecha de vencimiento',
                style: GoogleFonts.inter(fontSize: 10, color: txtSub)),
            ])),
            Switch(
              value: _campanaPermanente,
              onChanged: (v) => setState(() => _campanaPermanente = v),
              activeThumbColor: _kOrange,
              activeTrackColor: _kOrange.withAlpha(100),
            ),
          ]),
          if (!_campanaPermanente) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _datePicker('INICIO', _fmt(_fechaInicio),
                  () => _pickDate(true), card, border, txtMain, txtSub)),
              const SizedBox(width: 12),
              Expanded(child: _datePicker('FIN', _fmt(_fechaFin),
                  () => _pickDate(false), card, border, txtMain, txtSub)),
            ]),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      // Resumen card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.check_circle_outline_rounded, size: 15, color: _kGreen),
            const SizedBox(width: 6),
            Text('RESUMEN DE PUBLICACIÓN',
              style: GoogleFonts.inter(fontSize: 10,
                  fontWeight: FontWeight.w700, color: txtMain)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
              child: Text('LISTO',
                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 10),
          _summaryRow('CAMPAÑA',
              _tituloCtrl.text.isEmpty ? 'Sin título' : _tituloCtrl.text, txtMain, txtSub),
          Divider(color: border, height: 12),
          _summaryRow('DINÁMICA', _dinamicaLabel, txtMain, txtSub),
          Divider(color: border, height: 12),
          _summaryRow('PRODUCTOS', '${_selectedProducts.length} platillos asignados', txtMain, txtSub),
          Divider(color: border, height: 12),
          _summaryRow('VIGENCIA',
            _campanaPermanente ? 'Permanente' : '${_fmt(_fechaInicio)} → ${_fmt(_fechaFin)}',
            txtMain, txtSub),
        ]),
      ),
    ]);
  }

  // ─── FOOTER ───────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark, Color card, Color border, Color txtSub) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16,
          MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: card,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar',
            style: GoogleFonts.inter(color: txtSub)),
        ),
        const Spacer(),
        if (_step > 0) ...[
          TextButton.icon(
            onPressed: () => setState(() => _step--),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 13),
            label: Text('Anterior',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _kOrange)),
            style: TextButton.styleFrom(foregroundColor: _kOrange),
          ),
          const SizedBox(width: 8),
        ],
        if (_step < 2)
          ElevatedButton(
            onPressed: () => setState(() => _step++),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Siguiente', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 13),
            ]),
          )
        else
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _guardando
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome, size: 15),
                    const SizedBox(width: 6),
                    Text('Crear y Publicar Campaña',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
          ),
      ]),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  Widget _datePicker(String label, String value, VoidCallback onTap,
      Color card, Color border, Color txtMain, Color txtSub) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: card, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9,
              fontWeight: FontWeight.w700, color: txtSub)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 12, color: _kOrange),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 12,
                fontWeight: FontWeight.w600, color: txtMain)),
          ]),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color txtMain, Color txtSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9,
            fontWeight: FontWeight.w700, color: txtSub)),
        Flexible(child: Text(value, textAlign: TextAlign.end,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: txtMain),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _lbl(String text, Color txtSub) => Text(text,
    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: txtSub));

  Widget _field(TextEditingController ctrl, String hint,
      Color card, Color border, Color txtMain, Color txtSub,
      {String? suffix, String? prefix, int maxLines = 1, TextInputType? kb}) {
    return TextField(
      controller: ctrl, maxLines: maxLines, keyboardType: kb,
      style: GoogleFonts.inter(fontSize: 14, color: txtMain),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: txtSub),
        suffixText: suffix, prefixText: prefix,
        filled: true, fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kOrange)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
