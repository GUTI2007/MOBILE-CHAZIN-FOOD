import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/cloudinary_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Plain StatefulWidget dialog — NO ConsumerStatefulWidget inside a dialog
// (Riverpod data is loaded OUTSIDE and passed as constructor parameters, which
// is the only approach that is 100% stable on all Flutter versions/devices.)
// ─────────────────────────────────────────────────────────────────────────────
class CreateGlobalEventDialog extends StatefulWidget {
  final Product? linkedProduct;
  final List<Product> allProducts;
  final List<ProductCategory> allCategories;
  /// Callback to persist the event; returns true on success.
  final Future<bool> Function(Event event) onSave;

  const CreateGlobalEventDialog({
    super.key,
    this.linkedProduct,
    required this.allProducts,
    required this.allCategories,
    required this.onSave,
  });

  @override
  State<CreateGlobalEventDialog> createState() =>
      _CreateGlobalEventDialogState();
}

class _CreateGlobalEventDialogState extends State<CreateGlobalEventDialog> {
  // ─── Wizard ─────────────────────────────────────────────────────────────
  int _step = 0;
  bool _modoNuevoProducto = false;

  // ─── Step 1 ─────────────────────────────────────────────────────────────
  String _dinamica = 'promo_2x1';
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _descuentoCtrl = TextEditingController();
  final _precioEspecialCtrl = TextEditingController();
  final _toppingCtrl = TextEditingController();

  // ─── Step 2 ─────────────────────────────────────────────────────────────
  List<Product> _selectedProducts = [];
  String _productSearch = '';
  String? _selectedCategoryFilter;

  // ─── Step 3 ─────────────────────────────────────────────────────────────
  String? _bannerUrl;
  bool _subiendoBanner = false;
  final _bannerUrlCtrl = TextEditingController();
  bool _campanaPermanente = false;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 30));

  // ─── Save ────────────────────────────────────────────────────────────────
  bool _guardando = false;

  // ─── Opciones de dinámica ────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _dinamicaOpts = [
    {
      'id': 'promo_2x1',
      'label': 'Promoción 2x1',
      'icon': Icons.local_offer_rounded,
      'desc': 'Lleva 2 unidades al precio de 1',
      'color': Color(0xFFEF4444),
    },
    {
      'id': 'descuento',
      'label': 'Descuento %',
      'icon': Icons.percent_rounded,
      'desc': 'Rebaja porcentual sobre el precio de carta',
      'color': Color(0xFF22C55E),
    },
    {
      'id': 'precio_especial',
      'label': 'Precio Especial',
      'icon': Icons.price_change_rounded,
      'desc': 'Precio promocional fijo y rebajado',
      'color': Color(0xFFF97316),
    },
    {
      'id': 'topping_extra',
      'label': 'Topping Extra',
      'icon': Icons.add_circle_rounded,
      'desc': 'Topping o ingrediente de cortesía sin costo',
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'edicion_especial',
      'label': 'Edición Especial',
      'icon': Icons.emoji_events_rounded,
      'desc': 'Campaña gastronómica o temporada exclusiva',
      'color': Color(0xFFEAB308),
    },
    {
      'id': 'oferta_relampago',
      'label': 'Oferta Relámpago',
      'icon': Icons.flash_on_rounded,
      'desc': 'Promoción express por tiempo limitado',
      'color': Color(0xFFF59E0B),
    },
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
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _descuentoCtrl.dispose();
    _precioEspecialCtrl.dispose();
    _toppingCtrl.dispose();
    _bannerUrlCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    var list = List<Product>.from(widget.allProducts);
    if (_selectedCategoryFilter != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
    }
    if (_productSearch.isNotEmpty) {
      final q = _productSearch.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  String get _dinamicaLabel => (_dinamicaOpts.firstWhere(
        (o) => o['id'] == _dinamica,
        orElse: () => _dinamicaOpts.first,
      )['label'] as String);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _fechaInicio = picked;
        if (_fechaFin.isBefore(picked)) {
          _fechaFin = picked.add(const Duration(days: 1));
        }
      } else {
        _fechaFin = picked;
      }
    });
  }

  Future<void> _guardar() async {
    if (_tituloCtrl.text.trim().isEmpty) {
      _snack('El título de la campaña es obligatorio');
      return;
    }
    setState(() => _guardando = true);

    final productIds = _selectedProducts
        .map((p) => p.id.isNotEmpty ? int.tryParse(p.id) : null)
        .whereType<int>()
        .toList();

    final event = Event(
      nombre: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      tipoEvento: _dinamica,
      descuento: _dinamica == 'descuento'
          ? double.tryParse(_descuentoCtrl.text)
          : null,
      nuevoPrecio: _dinamica == 'precio_especial'
          ? double.tryParse(_precioEspecialCtrl.text)
          : null,
      accionInsumo:
          _dinamica == 'topping_extra' ? _toppingCtrl.text.trim() : null,
      isActive: true,
      estado: 'Activo',
      fechaInicio: _campanaPermanente ? null : _fechaInicio.toIso8601String(),
      fechaFin: _campanaPermanente ? null : _fechaFin.toIso8601String(),
      productosAsociados: productIds.isEmpty ? null : productIds,
      icono: _bannerUrl ?? (_bannerUrlCtrl.text.trim().isEmpty ? null : _bannerUrlCtrl.text.trim()),
      isTemporal: !_campanaPermanente,
    );

    final ok = await widget.onSave(event);
    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      Navigator.of(context).pop();
      _snack('✅ Campaña publicada exitosamente', isError: false);
    } else {
      _snack('No se pudo publicar la campaña. Inténtalo de nuevo.');
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;
    final dialogH = (screenH * 0.88).clamp(420.0, 760.0);

    // Retorna el contenido limpio del wizard sin Dialog/AlertDialog wrapper.
    // El caller (showDialog en product_list_screen) provee el Material + Center + SizedBox.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: SizedBox(
          height: dialogH,
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildTabSwitcher(isDark),
              _buildStepIndicator(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildStepContent(isDark),
                ),
              ),
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFF97316)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Campaña o Promoción',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Aplica descuentos, 2x1 o beneficios a platillos de tu menú.',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ─── Tab switcher ─────────────────────────────────────────────────────────
  Widget _buildTabSwitcher(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          Expanded(child: _tab(isDark, false, Icons.local_offer_rounded,
              'MENÚ EXISTENTE', '2x1, % OFF o Toppings en platillos actuales')),
          const SizedBox(width: 8),
          Expanded(child: _tab(isDark, true, Icons.auto_awesome_rounded,
              'NUEVO PLATILLO', 'Crear producto con Ficha Técnica desde cero')),
        ],
      ),
    );
  }

  Widget _tab(bool isDark, bool isNuevo, IconData icon, String title, String subtitle) {
    final selected = _modoNuevoProducto == isNuevo;
    return GestureDetector(
      onTap: () => setState(() { _modoNuevoProducto = isNuevo; _step = 0; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0))
              : (isDark ? Colors.white.withAlpha(8) : AppColors.grey100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFE65100) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16,
              color: selected ? const Color(0xFFE65100) : (isDark ? Colors.white38 : AppColors.grey400)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFFE65100) : (isDark ? Colors.white54 : AppColors.grey500))),
                  Text(subtitle,
                    style: GoogleFonts.inter(fontSize: 8,
                      color: isDark ? Colors.white38 : AppColors.grey400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step indicator ───────────────────────────────────────────────────────
  Widget _buildStepIndicator(bool isDark) {
    final labels = [
      '1. Dinámica',
      '2. Productos (${_selectedProducts.length})',
      '3. Banner & Fecha',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1,
                  color: i <= _step
                      ? const Color(0xFFE65100)
                      : (isDark ? Colors.white12 : AppColors.grey200),
                ),
              ),
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i < _step
                        ? const Color(0xFF22C55E)
                        : (i == _step ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: i < _step
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : Text('${i + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: i == _step ? Colors.white : (isDark ? Colors.white38 : AppColors.grey400),
                            )),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: i == _step ? FontWeight.w700 : FontWeight.w400,
                    color: i == _step
                        ? const Color(0xFFE65100)
                        : (isDark ? Colors.white38 : AppColors.grey400),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step router ──────────────────────────────────────────────────────────
  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 0:  return _buildStep1(isDark);
      case 1:  return _buildStep2(isDark);
      case 2:  return _buildStep3(isDark);
      default: return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: Dinámica & Beneficio ────────────────────────────────────────
  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('¿QUÉ BENEFICIO OFRECERÁ LA CAMPAÑA? *',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white60 : AppColors.grey500)),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _dinamicaOpts.length,
          itemBuilder: (ctx, i) {
            final opt = _dinamicaOpts[i];
            final sel = _dinamica == opt['id'];
            final color = opt['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _dinamica = opt['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel ? color.withAlpha(isDark ? 50 : 25) : (isDark ? Colors.white.withAlpha(8) : AppColors.grey50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? color : (isDark ? Colors.white12 : AppColors.grey200), width: sel ? 2 : 1),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(7)),
                          child: Icon(opt['icon'] as IconData, size: 14, color: color),
                        ),
                        if (sel) Icon(Icons.check_circle, size: 14, color: color),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(opt['label'] as String,
                      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
                        color: sel ? color : (isDark ? Colors.white70 : AppColors.textPrimaryLight))),
                    const SizedBox(height: 2),
                    Text(opt['desc'] as String,
                      style: GoogleFonts.inter(fontSize: 7.5, color: isDark ? Colors.white38 : AppColors.grey400, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _label(isDark, 'TÍTULO DE LA CAMPAÑA *'),
        const SizedBox(height: 6),
        _textField(isDark, _tituloCtrl, hint: 'Ej: Jueves 2×1 de Burger Artesanal'),
        if (_dinamica == 'descuento') ...[
          const SizedBox(height: 10),
          _label(isDark, 'PORCENTAJE DE DESCUENTO *'),
          const SizedBox(height: 6),
          _textField(isDark, _descuentoCtrl, hint: 'Ej: 15', suffix: '%', keyboardType: TextInputType.number),
        ],
        if (_dinamica == 'precio_especial') ...[
          const SizedBox(height: 10),
          _label(isDark, 'NUEVO PRECIO ESPECIAL (COP) *'),
          const SizedBox(height: 6),
          _textField(isDark, _precioEspecialCtrl, hint: 'Ej: 15000', prefix: '\$', keyboardType: TextInputType.number),
        ],
        if (_dinamica == 'topping_extra') ...[
          const SizedBox(height: 10),
          _label(isDark, 'NOMBRE DEL TOPPING EXTRA *'),
          const SizedBox(height: 6),
          _textField(isDark, _toppingCtrl, hint: 'Ej: Extra Tocineta Ahumada'),
        ],
        const SizedBox(height: 10),
        _label(isDark, 'DESCRIPCIÓN (OPCIONAL)'),
        const SizedBox(height: 6),
        _textField(isDark, _descCtrl, hint: 'Breve descripción...', maxLines: 2),
      ],
    );
  }

  // ─── STEP 2: Productos ────────────────────────────────────────────────────
  Widget _buildStep2(bool isDark) {
    final filtered = _filteredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('PLATILLOS QUE PARTICIPAN EN LA CAMPAÑA',
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
        const SizedBox(height: 4),
        Text('Agrega o retira platillos del catálogo.',
          style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : AppColors.grey400)),
        const SizedBox(height: 10),
        if (widget.allCategories.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.allCategories.map((cat) {
                final sel = _selectedCategoryFilter == cat.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategoryFilter = sel ? null : cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white.withAlpha(13) : AppColors.grey100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200)),
                      ),
                      child: Text('+ ${cat.name}',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : (isDark ? Colors.white60 : AppColors.grey600))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _productSearch = v),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: 'Buscar producto...',
            hintStyle: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white30 : AppColors.grey400),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFE65100)),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFFE65100))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu_outlined, size: 32, color: isDark ? Colors.white24 : AppColors.grey300),
                  const SizedBox(height: 6),
                  Text('No hay productos', style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.grey400)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final p = filtered[i];
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
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE65100).withAlpha(isDark ? 40 : 20) : (isDark ? Colors.white.withAlpha(8) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFFE65100) : Colors.transparent,
                          border: Border.all(color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white30 : AppColors.grey300)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: sel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                            Text(p.categoryName, style: GoogleFonts.inter(fontSize: 10,
                              color: isDark ? Colors.white38 : AppColors.grey400)),
                          ],
                        ),
                      ),
                      Text('\$${p.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFE65100))),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ─── STEP 3: Banner & Vigencia ────────────────────────────────────────────
  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.image_rounded, size: 14, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Text('BANNER PROMOCIONAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 70, height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(13) : AppColors.grey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _bannerUrl != null && _bannerUrl!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(8),
                            child: Image.network(_bannerUrl!, fit: BoxFit.cover))
                        : Center(child: Icon(Icons.image_outlined, size: 20,
                            color: isDark ? Colors.white24 : AppColors.grey300)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _subiendoBanner ? null : () async {
                            setState(() => _subiendoBanner = true);
                            final url = await CloudinaryService.pickAndUploadImage(context);
                            if (mounted) setState(() { _bannerUrl = url; _subiendoBanner = false; });
                          },
                          icon: _subiendoBanner
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined, size: 14),
                          label: Text('Subir Banner', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _bannerUrlCtrl,
                          onChanged: (v) => setState(() => _bannerUrl = v.trim().isEmpty ? null : v.trim()),
                          style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                          decoration: InputDecoration(
                            hintText: 'O pegar URL del banner...',
                            hintStyle: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white30 : AppColors.grey400),
                            filled: true,
                            fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFFE65100))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Vigencia
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop_rounded, size: 14, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CAMPAÑA PERMANENTE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                        Text('Sin fecha de vencimiento', style: GoogleFonts.inter(fontSize: 9,
                          color: isDark ? Colors.white38 : AppColors.grey400)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _campanaPermanente,
                    onChanged: (v) => setState(() => _campanaPermanente = v),
                    activeThumbColor: const Color(0xFFE65100),
                    activeTrackColor: const Color(0xFFE65100).withAlpha(100),
                  ),
                ],
              ),
              if (!_campanaPermanente) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _datePicker(isDark, 'INICIO', _fmtDate(_fechaInicio), () => _pickDate(true))),
                    const SizedBox(width: 10),
                    Expanded(child: _datePicker(isDark, 'FIN', _fmtDate(_fechaFin), () => _pickDate(false))),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Resumen
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 6),
                Text('RESUMEN DE PUBLICACIÓN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(10)),
                  child: Text('LISTO', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 8),
              _summaryRow(isDark, 'CAMPAÑA', _tituloCtrl.text.isEmpty ? 'Sin título' : _tituloCtrl.text),
              Divider(color: isDark ? Colors.white12 : AppColors.grey100, height: 10),
              _summaryRow(isDark, 'DINÁMICA', _dinamicaLabel),
              Divider(color: isDark ? Colors.white12 : AppColors.grey100, height: 10),
              _summaryRow(isDark, 'PRODUCTOS', '${_selectedProducts.length} platillos asignados'),
              Divider(color: isDark ? Colors.white12 : AppColors.grey100, height: 10),
              _summaryRow(isDark, 'VIGENCIA',
                _campanaPermanente ? 'Permanente' : '${_fmtDate(_fechaInicio)} → ${_fmtDate(_fechaFin)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _datePicker(bool isDark, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(13) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white38 : AppColors.grey400)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFFE65100)),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight)),
          ]),
        ]),
      ),
    );
  }

  Widget _summaryRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white38 : AppColors.grey400)),
          Flexible(child: Text(value, textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimaryLight),
            overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: isDark ? Colors.white54 : AppColors.grey400)),
          ),
          const Spacer(),
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 12),
              label: Text('Anterior', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFE65100))),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE65100)),
            ),
          if (_step > 0) const SizedBox(width: 8),
          if (_step < 2)
            ElevatedButton(
              onPressed: () => setState(() => _step++),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Siguiente', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12),
              ]),
            )
          else
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome, size: 14),
                      const SizedBox(width: 6),
                      Text('Crear y Publicar', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
            ),
        ],
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────
  Widget _label(bool isDark, String text) => Text(text,
    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
      color: isDark ? Colors.white60 : AppColors.grey500));

  Widget _textField(bool isDark, TextEditingController ctrl,
      {required String hint, String? suffix, String? prefix, int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
        suffixText: suffix,
        prefixText: prefix,
        filled: true,
        fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide(color: Color(0xFFE65100))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
