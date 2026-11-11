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
// Top-level helper — called from ProductListScreen
// ─────────────────────────────────────────────────────────────────────────────
void showCreateGlobalEventDialog(
  BuildContext context, {
  Product? linkedProduct,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateGlobalEventDialog(linkedProduct: linkedProduct),
    );
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal widget — 3-step wizard that matches the web "Crear Campaña o Promoción"
// ─────────────────────────────────────────────────────────────────────────────
class CreateGlobalEventDialog extends ConsumerStatefulWidget {
  final Product? linkedProduct;
  const CreateGlobalEventDialog({super.key, this.linkedProduct});

  @override
  ConsumerState<CreateGlobalEventDialog> createState() =>
      _CreateGlobalEventDialogState();
}

class _CreateGlobalEventDialogState
    extends ConsumerState<CreateGlobalEventDialog> {
  // ─── Wizard state ───────────────────────────────────────────────────────
  int _step = 0; // 0 = Dinámica, 1 = Productos, 2 = Banner & Vigencia
  bool _modoNuevoProducto = false; // false = Promoción Menú Existente

  // ─── Step 1 ─────────────────────────────────────────────────────────────
  String _dinamica = 'promo_2x1';
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _descuentoCtrl = TextEditingController();
  final _precioEspecialCtrl = TextEditingController();
  final _toppingCtrl = TextEditingController();

  // ─── Step 2 ─────────────────────────────────────────────────────────────
  List<Product> _allProducts = [];
  List<ProductCategory> _allCategories = [];
  List<Product> _selectedProducts = [];
  String _productSearch = '';
  String? _selectedCategoryFilter;
  bool _loadingProducts = false;

  // ─── Step 3 ─────────────────────────────────────────────────────────────
  String? _bannerUrl;
  bool _subiendoBanner = false;
  final _bannerUrlCtrl = TextEditingController();
  bool _campanaPermanente = false;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 30));

  // ─── Save ────────────────────────────────────────────────────────────────
  bool _guardando = false;

  // ─── Dynamic types config ────────────────────────────────────────────────
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
    Future.microtask(_loadProductsAndCategories);
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

  Future<void> _loadProductsAndCategories() async {
    if (!mounted) return;
    setState(() => _loadingProducts = true);
    final state = ref.read(productsProvider);
    if (mounted) {
      setState(() {
        _allProducts = state.products;
        _allCategories = state.categories
            .where((c) =>
                c.id != 'cat_all' &&
                c.id != '0' &&
                c.name != '__SISTEMA_VARIANTE_CERO__' &&
                c.isActive)
            .toList();
        _loadingProducts = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    var list = List<Product>.from(_allProducts);
    if (_selectedCategoryFilter != null) {
      list =
          list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
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

  String get _dinamicaLabel {
    final opt = _dinamicaOpts.firstWhere((o) => o['id'] == _dinamica,
        orElse: () => _dinamicaOpts.first);
    return opt['label'] as String;
  }

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
      icono: _bannerUrl ?? _bannerUrlCtrl.text.trim(),
      isTemporal: !_campanaPermanente,
    );

    final ok = await ref.read(eventsProvider.notifier).createEvent(event);
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
    // Compute available height so the dialog never exceeds the screen.
    final screenHeight = MediaQuery.of(context).size.height;
    final maxH = (screenHeight * 0.88).clamp(400.0, 720.0);
    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
        child: Column(
          // mainAxisSize MUST be max when Column has Expanded children,
          // otherwise Flutter throws a RenderFlex assertion.
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildHeader(isDark),
            _buildTabSwitcher(isDark),
            _buildStepIndicator(isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildStepContent(isDark),
              ),
            ),
            _buildFooter(isDark),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Crear Campaña o Promoción',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'PRODUCTOS EXISTENTES',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Aplica descuentos, 2x1 o beneficios a platillos de tu menú.',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(child: _tab(isDark, false, Icons.local_offer_rounded,
              'PROMOCIÓN PARA MENÚ EXISTENTE', '2x1, % OFF o Toppings en platillos actuales')),
          const SizedBox(width: 10),
          Expanded(child: _tab(isDark, true, Icons.auto_awesome_rounded,
              'NUEVO PLATILLO DE FESTIVAL', 'Crear producto con Ficha Técnica desde cero')),
        ],
      ),
    );
  }

  Widget _tab(bool isDark, bool isNuevo, IconData icon, String title, String subtitle) {
    final selected = _modoNuevoProducto == isNuevo;
    return GestureDetector(
      onTap: () => setState(() {
        _modoNuevoProducto = isNuevo;
        _step = 0;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0))
              : (isDark ? Colors.white.withAlpha(8) : AppColors.grey100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE65100) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? const Color(0xFFE65100) : (isDark ? Colors.white38 : AppColors.grey400),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFFE65100)
                          : (isDark ? Colors.white54 : AppColors.grey500),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: isDark ? Colors.white38 : AppColors.grey400,
                    ),
                  ),
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
    final steps = [
      '1. Dinámica & Beneficio',
      '2. Productos (${_selectedProducts.length})',
      '3. Banner & Vigencia',
    ];
    final subtitles = [
      'Tipo de oferta y título',
      'Platillos participantes',
      'Fechas y vista previa',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 1,
                color: i ~/ 2 < _step
                    ? const Color(0xFFE65100)
                    : (isDark ? Colors.white12 : AppColors.grey200),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _step;
          final active = idx == _step;
          return Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF22C55E)
                      : (active ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : (isDark ? Colors.white38 : AppColors.grey400),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active
                      ? const Color(0xFFE65100)
                      : (isDark ? Colors.white38 : AppColors.grey400),
                ),
              ),
              Text(
                subtitles[idx],
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: isDark ? Colors.white24 : AppColors.grey300,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Step content router ──────────────────────────────────────────────────
  Widget _buildStepContent(bool isDark) {
    switch (_step) {
      case 0:
        return _buildStep1(isDark);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── STEP 1: Dinámica & Beneficio ────────────────────────────────────────
  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          '¿QUÉ BENEFICIO O DINÁMICA OFRECERÁ LA CAMPAÑA? *',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white60 : AppColors.grey500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        // 3×2 grid of dynamic options
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.15,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _dinamicaOpts.length,
          itemBuilder: (ctx, i) {
            final opt = _dinamicaOpts[i];
            final selected = _dinamica == opt['id'];
            final color = opt['color'] as Color;
            return GestureDetector(
              onTap: () => setState(() => _dinamica = opt['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withAlpha(isDark ? 50 : 25)
                      : (isDark ? Colors.white.withAlpha(8) : AppColors.grey50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : (isDark ? Colors.white12 : AppColors.grey200),
                    width: selected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(opt['icon'] as IconData, size: 16, color: color),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, size: 16, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected ? color : (isDark ? Colors.white70 : AppColors.textPrimaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['desc'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        color: isDark ? Colors.white38 : AppColors.grey400,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Título de la campaña
        Text(
          'TÍTULO DE LA CAMPAÑA *',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white60 : AppColors.grey500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _tituloCtrl,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Ej: Jueves 2×1 de Burger Artesanal',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE65100)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        // Conditional extra field
        if (_dinamica == 'descuento') ...[
          Text('PORCENTAJE DE DESCUENTO *', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.grey500)),
          const SizedBox(height: 6),
          TextField(
            controller: _descuentoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            decoration: _inputDeco(isDark, hint: 'Ej: 15', suffix: '%'),
          ),
          const SizedBox(height: 10),
        ],
        if (_dinamica == 'precio_especial') ...[
          Text('NUEVO PRECIO ESPECIAL (COP) *', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.grey500)),
          const SizedBox(height: 6),
          TextField(
            controller: _precioEspecialCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            decoration: _inputDeco(isDark, hint: 'Ej: 15000', prefix: '\$'),
          ),
          const SizedBox(height: 10),
        ],
        if (_dinamica == 'topping_extra') ...[
          Text('NOMBRE DEL TOPPING EXTRA *', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.grey500)),
          const SizedBox(height: 6),
          TextField(
            controller: _toppingCtrl,
            style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            decoration: _inputDeco(isDark, hint: 'Ej: Extra Tocineta Ahumada'),
          ),
          const SizedBox(height: 10),
        ],

        // Description
        Text('DESCRIPCIÓN (OPCIONAL)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.grey500)),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          decoration: _inputDeco(isDark, hint: 'Breve descripción de la campaña...'),
        ),

        // Live preview card
        const SizedBox(height: 16),
        _buildLivePreview(isDark),
      ],
    );
  }

  Widget _buildLivePreview(bool isDark) {
    final opt = _dinamicaOpts.firstWhere((o) => o['id'] == _dinamica, orElse: () => _dinamicaOpts.first);
    final color = opt['color'] as Color;
    final badgeLabel = {
      'promo_2x1': '2X1',
      'descuento': '${_descuentoCtrl.text.isEmpty ? '?' : _descuentoCtrl.text}% OFF',
      'precio_especial': 'PRECIO',
      'topping_extra': 'GRATIS',
      'edicion_especial': 'ESPECIAL',
      'oferta_relampago': 'FLASH',
    }[_dinamica] ?? '?';
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFFE65100)),
              const SizedBox(width: 6),
              Text('VISTA PREVIA EN VIVO', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFE65100))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(10)),
                child: Text('CAMPAÑA ACTIVA', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(13) : AppColors.grey200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: _bannerUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(_bannerUrl!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 20, color: isDark ? Colors.white24 : AppColors.grey300),
                        Text('Sin banner de campaña', style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white24 : AppColors.grey300)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withAlpha(220), borderRadius: BorderRadius.circular(8)),
            child: Text(badgeLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Text(
            _tituloCtrl.text.isEmpty ? 'TÍTULO DE LA CAMPAÑA' : _tituloCtrl.text,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          ),
          Text(
            _descCtrl.text.isEmpty ? 'Platillos seleccionados' : _descCtrl.text,
            style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white54 : AppColors.grey400),
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: Productos Participantes ─────────────────────────────────────
  Widget _buildStep2(bool isDark) {
    final filtered = _filteredProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 16, color: const Color(0xFFE65100)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLATILLOS QUE PARTICIPAN EN LA CAMPAÑA',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
                  Text('Agrega o retira platillos del catálogo que tendrán esta promoción activa.',
                      style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : AppColors.grey400)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category filter chips
        if (_allCategories.isNotEmpty) ...[
          Row(
            children: [
              Text('AÑADIR CATEGORÍA:', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : AppColors.grey400)),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _allCategories.map((cat) {
                      final sel = _selectedCategoryFilter == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryFilter = sel ? null : cat.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white.withAlpha(13) : AppColors.grey100),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sel ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200)),
                            ),
                            child: Text(
                              '+ ${cat.name}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : (isDark ? Colors.white60 : AppColors.grey600),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // Search bar
        TextField(
          onChanged: (v) => setState(() => _productSearch = v),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: 'Buscar producto por nombre o categoría para agregarlo...',
            hintStyle: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white30 : AppColors.grey400),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFE65100)),
            filled: true,
            fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE65100))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        // Product list (lazy)
        if (_loadingProducts)
          const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu_outlined, size: 36, color: isDark ? Colors.white24 : AppColors.grey300),
                  const SizedBox(height: 8),
                  Text('No hay productos seleccionados todavía',
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white38 : AppColors.grey400)),
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
              final selected = _selectedProducts.any((s) => s.id == p.id);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedProducts.removeWhere((s) => s.id == p.id);
                    } else {
                      _selectedProducts.add(p);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE65100).withAlpha(isDark ? 40 : 20)
                        : (isDark ? Colors.white.withAlpha(8) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? const Color(0xFFE65100) : (isDark ? Colors.white12 : AppColors.grey200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE65100) : Colors.transparent,
                          border: Border.all(color: selected ? const Color(0xFFE65100) : (isDark ? Colors.white30 : AppColors.grey300)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                            Text(p.categoryName, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400)),
                          ],
                        ),
                      ),
                      Text(
                        '\$${p.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFE65100)),
                      ),
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

        // Banner section
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Icon(Icons.image_rounded, size: 14, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Text('BANNER PROMOCIONAL DE LA CAMPAÑA', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
                  const Spacer(),
                  Text('Panorámico (carrusel & catálogo)', style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : AppColors.grey400)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(13) : AppColors.grey200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _bannerUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_bannerUrl!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Icon(Icons.image_outlined, size: 20, color: isDark ? Colors.white24 : AppColors.grey300),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _subiendoBanner
                              ? null
                              : () async {
                                  setState(() => _subiendoBanner = true);
                                  final url = await CloudinaryService.pickAndUploadImage(context);
                                  if (mounted) {
                                    setState(() {
                                      _bannerUrl = url;
                                      _subiendoBanner = false;
                                    });
                                  }
                                },
                          icon: _subiendoBanner
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined, size: 16),
                          label: Text('Subir Banner desde PC', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Ingresar URL del Banner', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                content: TextField(
                                  controller: _bannerUrlCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'https://res.cloudinary.com/...',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => _bannerUrl = _bannerUrlCtrl.text.trim());
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Aplicar'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('O ingresar URL...', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFE65100), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Campaña Permanente toggle
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Icon(Icons.loop_rounded, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CAMPAÑA PERMANENTE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                        Text('Permanecerá activa de forma continua hasta que la desactives', style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : AppColors.grey400)),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _datePicker(isDark, 'FECHA INICIO', _fmtDate(_fechaInicio), () => _pickDate(true))),
                    const SizedBox(width: 10),
                    Expanded(child: _datePicker(isDark, 'FECHA FIN', _fmtDate(_fechaFin), () => _pickDate(false))),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Final summary
        Container(
          padding: const EdgeInsets.all(14),
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
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text('RESUMEN FINAL DE PUBLICACIÓN', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.textPrimaryLight)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(10)),
                    child: Text('LISTO PARA CREAR', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _summaryRow(isDark, 'CAMPAÑA',
                  _tituloCtrl.text.isEmpty ? 'Sin título' : _tituloCtrl.text,
                  subtitle: _descCtrl.text.isEmpty ? 'Sin descripción' : _descCtrl.text),
              _divider(isDark),
              _summaryRow(isDark, 'DINÁMICA', _dinamicaLabel, badge: {
                'promo_2x1': '2X1',
                'descuento': '% OFF',
                'precio_especial': 'PRECIO',
                'topping_extra': 'GRATIS',
                'edicion_especial': 'ESPECIAL',
                'oferta_relampago': 'FLASH',
              }[_dinamica]),
              _divider(isDark),
              _summaryRow(isDark, 'PRODUCTOS PARTICIPANTES',
                  '${_selectedProducts.length} platillo${_selectedProducts.length == 1 ? '' : 's'} asignado${_selectedProducts.length == 1 ? '' : 's'}',
                  icon: Icons.restaurant_menu_rounded),
              _divider(isDark),
              _summaryRow(isDark, 'VIGENCIA',
                  _campanaPermanente ? 'Campaña permanente' : '${_fmtDate(_fechaInicio)} → ${_fmtDate(_fechaFin)}'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : AppColors.grey400)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFFE65100)),
                const SizedBox(width: 4),
                Text(value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(bool isDark, String label, String value, {String? subtitle, String? badge, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : AppColors.grey400)),
          const SizedBox(height: 2),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: const Color(0xFFE65100)),
                const SizedBox(width: 4),
              ],
              Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight))),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
            ],
          ),
          if (subtitle != null)
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400)),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(color: isDark ? Colors.white12 : AppColors.grey100, height: 1);

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.inter(color: isDark ? Colors.white54 : AppColors.grey400, fontWeight: FontWeight.w500)),
          ),
          const Spacer(),
          if (_step > 0)
            TextButton.icon(
              onPressed: () => setState(() => _step--),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: Text('Anterior', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFE65100))),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE65100)),
            ),
          if (_step > 0) const SizedBox(width: 10),
          if (_step < 2)
            ElevatedButton(
              onPressed: () => setState(() => _step++),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Siguiente Paso', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 16),
                        const SizedBox(width: 6),
                        Text('Crear y Publicar Campaña', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  // ─── Shared input decoration ──────────────────────────────────────────────
  InputDecoration _inputDeco(bool isDark, {required String hint, String? suffix, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
      suffixText: suffix,
      prefixText: prefix,
      filled: true,
      fillColor: isDark ? Colors.white.withAlpha(8) : AppColors.grey50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE65100))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
