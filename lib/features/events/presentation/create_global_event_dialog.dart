import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../events/providers/events_provider.dart';
import '../../products/providers/products_provider.dart';

/// Modal completo de "Crear Evento Global" — idéntico al Web Frontend.
/// Se abre desde ProductListScreen o desde cualquier acción de Eventos.
class CreateGlobalEventDialog extends ConsumerStatefulWidget {
  /// Si se pasa un [linkedProduct], el modo "Vincular" queda preseleccionado.
  final Product? linkedProduct;

  const CreateGlobalEventDialog({super.key, this.linkedProduct});

  @override
  ConsumerState<CreateGlobalEventDialog> createState() =>
      _CreateGlobalEventDialogState();
}

class _CreateGlobalEventDialogState
    extends ConsumerState<CreateGlobalEventDialog> {
  // ─── Modo de creación ───
  bool _modoNuevoProducto = false; // false = vincular existente

  // ─── Formato del evento ───
  String _formato = 'edicion_limitada';
  final List<Map<String, dynamic>> _formatos = [
    {
      'id': 'edicion_limitada',
      'label': 'Edición Limitada',
      'icon': Icons.local_fire_department_rounded,
      'subtitle': 'Plato festivo único y\nconmemorativo',
    },
    {
      'id': 'combo_festivo',
      'label': 'Combo Festivo',
      'icon': Icons.fastfood_rounded,
      'subtitle': 'Mucho + acompañamiento\n+ bebida',
    },
    {
      'id': 'promo_2x1',
      'label': 'Promoción 2x1',
      'icon': Icons.local_offer_rounded,
      'subtitle': 'Lleva 2 por el precio de 1',
    },
    {
      'id': 'precio_rebajado',
      'label': 'Precio Rebajado',
      'icon': Icons.price_change_rounded,
      'subtitle': 'Descuento directo sobre\nprecio regular',
    },
  ];

  // ─── Iconografía ───
  final List<IconData> _iconoGrid = [
    Icons.local_fire_department_rounded,
    Icons.star_rounded,
    Icons.cake_rounded,
    Icons.celebration_rounded,
    Icons.emoji_events_rounded,
    Icons.favorite_rounded,
    Icons.flash_on_rounded,
    Icons.ac_unit_rounded,
    Icons.spa_rounded,
    Icons.local_florist_rounded,
    Icons.music_note_rounded,
    Icons.restaurant_rounded,
    Icons.local_pizza_rounded,
    Icons.icecream_rounded,
    Icons.bakery_dining_rounded,
    Icons.dinner_dining_rounded,
    Icons.ramen_dining_rounded,
    Icons.coffee_rounded,
    Icons.local_bar_rounded,
    Icons.wine_bar_rounded,
    Icons.sports_esports_rounded,
    Icons.beach_access_rounded,
    Icons.nights_stay_rounded,
    Icons.wb_sunny_rounded,
  ];
  IconData? _selectedIcon;
  String _selectedInsignia = 'Celebración / Fiesta';
  final List<String> _insignias = [
    'Celebración / Fiesta',
    'Temporada',
    'Especial del Chef',
    'Plato Estrella',
    'Vegano / Veggie',
    'Sin Gluten',
  ];

  // ─── Vigencia ───
  bool _esTemporal = true;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 31));
  bool _destacarEnPortada = true;

  // ─── Topping de Cortesía ───
  bool _sinCortesia = false;
  String _toppingCortesia = '';

  // ─── Datos del Evento Global (modo nuevo producto) ───
  final _tituloEventoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String? _imagenEventoUrl;
  bool _subiendoImagenEvento = false;

  // ─── Datos del Producto del Evento ───
  Product? _productoVinculado;
  final _nombreProductoCtrl = TextEditingController();
  final _descripcionProductoCtrl = TextEditingController();
  String _categoriaSeleccionada = '';
  String _categoriaId = '';
  int _rendimiento = 1;
  String _etiquetaEstado = 'Activo (Publicado de inmediato en Menú)';
  final List<String> _etiquetasDestacadas = [];
  final _precioCartaCtrl = TextEditingController();
  final _precioEventoCtrl = TextEditingController();
  String? _imagenProductoUrl;
  bool _subiendoImagenProducto = false;

  // ─── Adiciones disponibles (desde producto vinculado) ───
  List<Map<String, dynamic>> _adicionesSeleccionadas = [];

  // ─── Ficha Técnica ───
  final _especTecnicasCtrl = TextEditingController();
  final _caracterOrganCtrl = TextEditingController();
  final _infoNutricionalCtrl = TextEditingController();
  final _condAlmacenamCtrl = TextEditingController();
  final _vidaUtilCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  // ─── Pasos de Preparación ───
  final List<Map<String, dynamic>> _pasos = [
    {'titulo': 'Alistamiento / Mise en place', 'instrucciones': ''},
    {'titulo': 'Cocción / Procesamiento térmico', 'instrucciones': ''},
    {'titulo': 'Ensamblaje y Montaje', 'instrucciones': ''},
  ];

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.linkedProduct != null) {
      _productoVinculado = widget.linkedProduct;
      _nombreProductoCtrl.text = widget.linkedProduct!.name;
      _categoriaSeleccionada = widget.linkedProduct!.categoryName;
      _categoriaId = widget.linkedProduct!.categoryId;
      _precioCartaCtrl.text = widget.linkedProduct!.price.toStringAsFixed(0);
      _adicionesSeleccionadas = List.from(widget.linkedProduct!.adiciones);
    }
  }

  @override
  void dispose() {
    _tituloEventoCtrl.dispose();
    _descripcionCtrl.dispose();
    _nombreProductoCtrl.dispose();
    _descripcionProductoCtrl.dispose();
    _precioCartaCtrl.dispose();
    _precioEventoCtrl.dispose();
    _especTecnicasCtrl.dispose();
    _caracterOrganCtrl.dispose();
    _infoNutricionalCtrl.dispose();
    _condAlmacenamCtrl.dispose();
    _vidaUtilCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  int get _duracionDias => _fechaFin.difference(_fechaInicio).inDays;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ─── Subir imagen (usa el método estático de CloudinaryService) ───
  Future<String?> _pickAndUploadImage() async {
    try {
      if (!mounted) return null;
      return await CloudinaryService.pickAndUploadImage(context);
    } catch (_) {
      return null;
    }
  }

  Future<void> _guardarEvento() async {
    final titulo = _tituloEventoCtrl.text.trim();
    if (titulo.isEmpty) {
      _showSnack('Por favor ingresa el título del evento.');
      return;
    }
    if (!_modoNuevoProducto && _productoVinculado == null) {
      _showSnack('Selecciona un producto existente para vincular.');
      return;
    }
    if (_modoNuevoProducto && _precioEventoCtrl.text.trim().isEmpty) {
      _showSnack('Ingresa el precio especial del evento.');
      return;
    }

    setState(() => _guardando = true);

    final event = Event(
      nombre: titulo,
      descripcion: _descripcionCtrl.text.trim(),
      fechaInicio: _esTemporal ? _fechaInicio.toIso8601String() : null,
      fechaFin: _esTemporal ? _fechaFin.toIso8601String() : null,
      isActive: true,
      estado: 'Activo',
      idProducto: int.tryParse(_productoVinculado?.id ?? ''),
      tipoEvento: _formato,
      nuevoPrecio: double.tryParse(_precioEventoCtrl.text.replaceAll(',', '').replaceAll('.', '')),
      accionInsumo: _sinCortesia ? null : _toppingCortesia.trim(),
      icono: _selectedIcon?.codePoint.toString(),
      isTemporal: _esTemporal,
      insumosAsociados: _adicionesSeleccionadas.isNotEmpty
          ? _adicionesSeleccionadas
          : null,
      productosAsociados: _modoNuevoProducto
          ? [
              {
                'nombre': _nombreProductoCtrl.text.trim(),
                'descripcion': _descripcionProductoCtrl.text.trim(),
                'categoria': _categoriaSeleccionada,
                'idCategoriaProducto': _categoriaId,
                'precio': double.tryParse(_precioCartaCtrl.text) ?? 0,
                'precioEvento': double.tryParse(_precioEventoCtrl.text) ?? 0,
                'imagen': _imagenProductoUrl ?? '',
                'rendimiento': _rendimiento,
                'destacarPortada': _destacarEnPortada,
                'fichaTecnica': {
                  'especificacionesTecnicas': _especTecnicasCtrl.text.trim(),
                  'caracteristicasOrganolépticas': _caracterOrganCtrl.text.trim(),
                  'informacionNutricional': _infoNutricionalCtrl.text.trim(),
                  'condicionesAlmacenamiento': _condAlmacenamCtrl.text.trim(),
                  'vidaUtil': _vidaUtilCtrl.text.trim(),
                  'observaciones': _observacionesCtrl.text.trim(),
                },
                'pasos': _pasos,
              }
            ]
          : null,
    );

    final ok = await ref.read(eventsProvider.notifier).createEvent(event);
    setState(() => _guardando = false);

    if (ok && mounted) {
      Navigator.of(context).pop(true);
      _showSnack('¡Evento creado exitosamente!', isSuccess: true);
    } else if (mounted) {
      final err = ref.read(eventsProvider).error;
      _showSnack(err ?? 'Error al crear el evento. Intenta de nuevo.');
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productState = ref.watch(productsProvider);

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header rojo ───
            _buildHeader(isDark),

            // ─── Selector modo creación ───
            _buildModeSelector(isDark),

            // ─── Contenido scrollable ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector de producto existente (si modo vincular)
                    if (!_modoNuevoProducto) ...[
                      _buildSectionTitle('Producto a Vincular', isDark),
                      const SizedBox(height: 8),
                      _buildProductSelector(isDark, productState.products),
                      const SizedBox(height: 16),
                    ],

                    // Información Principal y Formato
                    _buildSectionHeader(
                        'INFORMACIÓN PRINCIPAL Y FORMATO DE CAMPAÑA', isDark),
                    const SizedBox(height: 10),
                    _buildFormatoGrid(isDark),
                    const SizedBox(height: 16),

                    // Iconografía
                    _buildSectionTitle('Iconografía del Evento', isDark),
                    const SizedBox(height: 6),
                    _buildInsigniaRow(isDark),
                    const SizedBox(height: 8),
                    _buildIconGrid(isDark),
                    const SizedBox(height: 16),

                    // Switch Evento Temporal / Vigencia
                    _buildVigenciaSection(isDark),
                    const SizedBox(height: 16),

                    // Título del Evento (Global, para portada)
                    _buildSectionTitle('Título del Evento *', isDark),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _tituloEventoCtrl,
                      hint: 'Ej: Temporada de verano — carne extra incluida',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildSectionTitle('Descripción', isDark),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _descripcionCtrl,
                      hint: 'Describe brevemente este evento...',
                      isDark: isDark,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    // Imagen del Evento (Carrusel/Portada)
                    _buildSectionHeader('IMAGEN DEL EVENTO (CARRUSEL & PORTADA)', isDark),
                    const SizedBox(height: 8),
                    _buildImageUploadButton(
                      label: 'Subir Imagen desde PC',
                      urlLabel: 'O ingresar URL web...',
                      imageUrl: _imagenEventoUrl,
                      isLoading: _subiendoImagenEvento,
                      isDark: isDark,
                      onTap: () async {
                        setState(() => _subiendoImagenEvento = true);
                        final url = await _pickAndUploadImage();
                        setState(() {
                          _imagenEventoUrl = url;
                          _subiendoImagenEvento = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Topping de Cortesía
                    _buildSectionHeader(
                        'TOPPING DE CORTESÍA INCLUIDO POR LA CAMPAÑA (OPCIONAL)',
                        isDark),
                    const SizedBox(height: 8),
                    _buildToppingSection(isDark),
                    const SizedBox(height: 16),

                    // Datos del Producto (modo nuevo o complementario)
                    _buildSectionHeader(
                        _modoNuevoProducto
                            ? 'DATOS DEL PRODUCTO DE EVENTO'
                            : 'DATOS COMPLEMENTARIOS DEL EVENTO',
                        isDark),
                    const SizedBox(height: 10),
                    _buildProductDataSection(isDark, productState),
                    const SizedBox(height: 16),

                    // Adiciones Disponibles
                    _buildSectionHeader('ADICIONES DISPONIBLES', isDark),
                    const SizedBox(height: 8),
                    _buildAdicionesSection(isDark),
                    const SizedBox(height: 16),

                    // Ficha Técnica Gastronómica
                    _buildSectionHeader('FICHA TÉCNICA GASTRONÓMICA', isDark),
                    const SizedBox(height: 10),
                    _buildFichaTecnicaSection(isDark),
                    const SizedBox(height: 16),

                    // Pasos de Preparación
                    _buildSectionHeader(
                        'ORDEN LÓGICO DE PROCESO DE PREPARACIÓN', isDark),
                    const SizedBox(height: 6),
                    _buildPasosHeader(isDark),
                    const SizedBox(height: 8),
                    _buildPasosSection(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ─── Footer acciones ───
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  BUILDERS
  // ════════════════════════════════════════════════════════

  Widget _buildHeader(bool isDark) {
    return Container(
      color: const Color(0xFFCC2222),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear Evento Global',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                Text('Múltiples productos',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white70,
                    )),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Container(
      color: isDark ? AppColors.cardDark : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _modePill('Vincular a Producto Existente', !_modoNuevoProducto, isDark, () {
            setState(() => _modoNuevoProducto = false);
          })),
          const SizedBox(width: 6),
          Expanded(child: _modePill('✨ Crear Producto de Evento Nuevo', _modoNuevoProducto, isDark, () {
            setState(() => _modoNuevoProducto = true);
          })),
        ],
      ),
    );
  }

  Widget _modePill(String label, bool isSelected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCC2222) : (isDark ? Colors.white10 : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: isDark ? Colors.white24 : const Color(0xFFDDDDDD)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondaryLight),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: const Color(0xFFCC2222), margin: const EdgeInsets.only(right: 8)),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFCC2222),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        suffixText: suffixText,
        hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : AppColors.grey400, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC2222))),
      ),
    );
  }

  Widget _buildProductSelector(bool isDark, List<Product> products) {
    return DropdownButtonFormField<String>(
      initialValue: _productoVinculado?.id,
      hint: Text('Selecciona un producto...', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white38 : AppColors.grey400)),
      onChanged: (id) {
        final prod = products.firstWhere((p) => p.id == id, orElse: () => products.first);
        setState(() {
          _productoVinculado = prod;
          _nombreProductoCtrl.text = prod.name;
          _categoriaSeleccionada = prod.categoryName;
          _categoriaId = prod.categoryId;
          _precioCartaCtrl.text = prod.price.toStringAsFixed(0);
          _adicionesSeleccionadas = List.from(prod.adiciones);
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC2222))),
      ),
      items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: GoogleFonts.inter(fontSize: 13)))).toList(),
    );
  }

  Widget _buildFormatoGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: _formatos.map((f) {
        final isSelected = _formato == f['id'];
        return GestureDetector(
          onTap: () => setState(() => _formato = f['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCC2222).withAlpha(15) : (isDark ? AppColors.cardDark : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFFCC2222) : (isDark ? Colors.white12 : AppColors.grey200), width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Icon(f['icon'] as IconData, color: isSelected ? const Color(0xFFCC2222) : (isDark ? Colors.white38 : AppColors.grey400), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f['label'] as String, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: isSelected ? const Color(0xFFCC2222) : (isDark ? Colors.white : AppColors.textPrimaryLight))),
                      Text(f['subtitle'] as String, style: GoogleFonts.inter(fontSize: 9, color: isDark ? Colors.white38 : AppColors.grey400), maxLines: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsigniaRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text('Elige el ícono vectorial que acompañará la promoción en el carrusel y en el menú.',
              style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.white38 : AppColors.grey400)),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (val) => setState(() => _selectedInsignia = val),
          itemBuilder: (ctx) => _insignias.map((ins) => PopupMenuItem(value: ins, child: Text(ins, style: GoogleFonts.inter(fontSize: 12)))).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFCC2222).withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFCC2222).withAlpha(60)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.shield_rounded, color: Color(0xFFCC2222), size: 13),
              const SizedBox(width: 4),
              Text(_selectedInsignia, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFCC2222))),
              const Icon(Icons.keyboard_arrow_down, color: Color(0xFFCC2222), size: 14),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildIconGrid(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _iconoGrid.map((icon) {
        final isSelected = _selectedIcon == icon;
        return GestureDetector(
          onTap: () => setState(() => _selectedIcon = isSelected ? null : icon),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFCC2222) : (isDark ? AppColors.cardDark : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? null : Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white60 : AppColors.grey500), size: 18),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVigenciaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('VIGENCIA DE LA CAMPAÑA Y PUBLICACIÓN WEB', isDark),
        const SizedBox(height: 10),
        // Botones temporal vs permanente
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _esTemporal = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _esTemporal ? const Color(0xFFCC2222) : (isDark ? Colors.white10 : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: _esTemporal ? null : Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  child: Center(child: Text(
                    '⏰ Campaña Temporal (con fecha límite)',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: _esTemporal ? Colors.white : (isDark ? Colors.white60 : AppColors.grey700)),
                    textAlign: TextAlign.center,
                  )),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _esTemporal = false),
                child: Row(
                  children: [
                    Icon(
                      _esTemporal ? Icons.radio_button_off_rounded : Icons.radio_button_checked_rounded,
                      size: 20,
                      color: !_esTemporal ? const Color(0xFFCC2222) : (isDark ? Colors.white38 : AppColors.grey400),
                    ),
                    Text('Vigencia Permanente / Indefinida', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.grey700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_esTemporal) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDateTile('Fecha Inicio de Campaña', _fechaInicio, isDark, (d) => setState(() => _fechaInicio = d))),
              const SizedBox(width: 10),
              Expanded(child: _buildDateTile('Fecha Fin de Campaña', _fechaFin, isDark, (d) => setState(() => _fechaFin = d))),
            ],
          ),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFCC2222), size: 13),
            const SizedBox(width: 4),
            Text(
              'Duración de la campaña: $_duracionDias días (del ${_formatDate(_fechaInicio)} al ${_formatDate(_fechaFin)})',
              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFFCC2222), fontWeight: FontWeight.w500),
            ),
          ]),
        ],
        const SizedBox(height: 10),
        // Switch Destacar en Portada
        Row(
          children: [
            Checkbox(
              value: _destacarEnPortada,
              onChanged: (v) => setState(() => _destacarEnPortada = v ?? false),
              activeColor: const Color(0xFFCC2222),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Destacar en Portada Web & Menú Principal',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                Text('Aparecerá en el carrusel superior y en la sección especial de eventos de la tienda web.',
                    style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTile(String label, DateTime date, bool isDark, Function(DateTime) onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFCC2222))),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.white54 : AppColors.grey500)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white12 : AppColors.grey300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Expanded(child: Text(_formatDate(date), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimaryLight))),
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFFCC2222)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildToppingSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCC2222).withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('¿Este festival incluye un topping o ingrediente de regalo sin costo adicional para el comensal?',
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white60 : AppColors.grey600)),
              ),
              const SizedBox(width: 10),
              Row(children: [
                Checkbox(
                  value: _sinCortesia,
                  onChanged: (v) => setState(() { _sinCortesia = v ?? false; if (_sinCortesia) _toppingCortesia = ''; }),
                  activeColor: const Color(0xFFCC2222),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                Text('Sin Cortesía', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.grey700)),
              ]),
            ],
          ),
          if (!_sinCortesia) ...[
            const SizedBox(height: 10),
            _buildField(controller: TextEditingController(text: _toppingCortesia)..addListener(() {}), hint: 'Ej: Papas medianas de cortesía, salsa especial...', isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDataSection(bool isDark, dynamic productState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre del producto en menú
        if (_modoNuevoProducto && _productoVinculado != null) ...[
          Text('Producto Base: ${_productoVinculado!.name}',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFCC2222))),
          const SizedBox(height: 10),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Nombre del Producto en Menú *', isDark),
            const SizedBox(height: 6),
            _buildField(controller: _nombreProductoCtrl, hint: 'Hamburguesa Burger Fest Trufa', isDark: isDark),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Categoría del Menú *', isDark),
            const SizedBox(height: 6),
            _buildCategoryDropdown(isDark, productState.categories),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Rendimiento / Porciones', isDark),
            const SizedBox(height: 6),
            _buildRendimientoDropdown(isDark),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Estado Inicial del Producto', isDark),
            const SizedBox(height: 6),
            _buildEstadoDropdown(isDark),
          ])),
        ]),
        const SizedBox(height: 10),
        _buildSectionTitle('Etiquetas Destacadas para el Menú', isDark),
        const SizedBox(height: 6),
        _buildEtiquetasRow(isDark),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Precio Normal de Carta (\$) *', isDark),
            const SizedBox(height: 6),
            _buildField(controller: _precioCartaCtrl, hint: '23000', isDark: isDark, keyboardType: TextInputType.number, prefixText: '\$ '),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle('Precio Especial de Evento (\$) *', isDark),
            const SizedBox(height: 6),
            _buildField(controller: _precioEventoCtrl, hint: '24500', isDark: isDark, keyboardType: TextInputType.number, prefixText: '\$ '),
          ])),
        ]),
        const SizedBox(height: 10),
        _buildSectionTitle('Imagen del Producto (Subir a Cloudinary o URL)', isDark),
        const SizedBox(height: 6),
        _buildImageUploadButton(
          label: 'Subir Imagen desde PC',
          urlLabel: 'O ingresar URL web...',
          imageUrl: _imagenProductoUrl,
          isLoading: _subiendoImagenProducto,
          isDark: isDark,
          onTap: () async {
            setState(() => _subiendoImagenProducto = true);
            final url = await _pickAndUploadImage();
            setState(() { _imagenProductoUrl = url; _subiendoImagenProducto = false; });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(bool isDark, List<ProductCategory> categories) {
    final filteredCats = categories.where((c) => c.id != 'cat_all' && c.name != '__SISTEMA_VARIANTE_CERO__').toList();
    return DropdownButtonFormField<String>(
      initialValue: _categoriaId.isEmpty ? null : _categoriaId,
      hint: Text('Hamburguesas', style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white38 : AppColors.grey400)),
      onChanged: (id) {
        if (id == null) return;
        final cat = filteredCats.firstWhere((c) => c.id == id, orElse: () => filteredCats.first);
        setState(() { _categoriaId = id; _categoriaSeleccionada = cat.name; });
      },
      decoration: InputDecoration(
        filled: true, fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC2222))),
      ),
      items: filteredCats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: GoogleFonts.inter(fontSize: 13)))).toList(),
    );
  }

  Widget _buildRendimientoDropdown(bool isDark) {
    final opciones = {'1 Persona (Personal)': 1, '2 Personas': 2, '3-4 Personas': 3, '5-6 Personas': 5, 'Familiar (+6)': 6};
    return DropdownButtonFormField<int>(
      initialValue: _rendimiento,
      onChanged: (v) => setState(() => _rendimiento = v ?? 1),
      decoration: InputDecoration(
        filled: true, fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC2222))),
      ),
      items: opciones.entries.map((e) => DropdownMenuItem(value: e.value, child: Text(e.key, style: GoogleFonts.inter(fontSize: 12)))).toList(),
    );
  }

  Widget _buildEstadoDropdown(bool isDark) {
    final estados = ['Activo (Publicado de inmediato en Menú)', 'Borrador (No visible en Menú)', 'Agotado'];
    return DropdownButtonFormField<String>(
      initialValue: _etiquetaEstado,
      onChanged: (v) => setState(() => _etiquetaEstado = v ?? estados[0]),
      decoration: InputDecoration(
        filled: true, fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCC2222))),
      ),
      items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 11), maxLines: 2))).toList(),
    );
  }

  Widget _buildEtiquetasRow(bool isDark) {
    final opciones = ['Edición Festival', 'Recomendado del Chef', 'Plato Gourmet', 'Plato Estrella', 'Vegano Veggie', 'Extra Demo'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: opciones.map((tag) {
        final sel = _etiquetasDestacadas.contains(tag);
        return GestureDetector(
          onTap: () => setState(() { sel ? _etiquetasDestacadas.remove(tag) : _etiquetasDestacadas.add(tag); }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFCC2222) : (isDark ? AppColors.cardDark : AppColors.grey50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sel ? const Color(0xFFCC2222) : (isDark ? Colors.white12 : AppColors.grey300)),
            ),
            child: Text(tag, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? Colors.white60 : AppColors.grey700))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImageUploadButton({
    required String label,
    required String urlLabel,
    required String? imageUrl,
    required bool isLoading,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC2222),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (isLoading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    else const Icon(Icons.upload_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(urlLabel, style: GoogleFonts.inter(fontSize: 10.5, color: isDark ? Colors.white38 : AppColors.grey400)),
          ],
        ),
        if (imageUrl != null && imageUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, height: 80, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (ctx, e, st) => const SizedBox.shrink()),
          ),
        ],
        const SizedBox(height: 4),
        Text('Sube una foto desde la computadora. Se guarda permanentemente en Cloudinary (PNG, JPG, WEBP).',
            style: GoogleFonts.inter(fontSize: 9.5, color: isDark ? Colors.white30 : AppColors.grey400)),
      ],
    );
  }

  Widget _buildAdicionesSection(bool isDark) {
    if (_adicionesSeleccionadas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
        ),
        child: Row(children: [
          Checkbox(value: false, onChanged: null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
          Text(_modoNuevoProducto ? 'No es Combo' : 'Selecciona un producto para ver sus adiciones disponibles.',
              style: GoogleFonts.inter(fontSize: 11.5, color: isDark ? Colors.white38 : AppColors.grey400)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Configuración de Combo / Bebidas Incluidas',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _adicionesSeleccionadas = []),
              child: Text('Deseleccionar todas', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFCC2222))),
            ),
          ]),
          const SizedBox(height: 2),
          Text('Escoge una o varias bebidas/acompañamientos para combinar en la adición de múltiples productos.',
              style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _adicionesSeleccionadas.map((a) {
              final nombre = a['nombre']?.toString() ?? '';
              final precio = (a['precio'] is num) ? (a['precio'] as num).toDouble() : 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Checkbox(
                    value: true,
                    onChanged: null,
                    activeColor: const Color(0xFFCC2222),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nombre, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight)),
                    Text('+ ${Formatters.currency(precio)}',
                        style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400)),
                  ]),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFichaTecnicaSection(bool isDark) {
    final campos = [
      {'ctrl': _especTecnicasCtrl, 'label': 'Especificaciones Técnicas *', 'hint': 'Gramaje, temperatura de cocción, estándares...'},
      {'ctrl': _caracterOrganCtrl, 'label': 'Características Organolépticas *', 'hint': 'Sabor, textura, aroma, apariencia...'},
      {'ctrl': _infoNutricionalCtrl, 'label': 'Información Nutricional *', 'hint': 'Calorías, proteínas, carbohidratos...'},
      {'ctrl': _condAlmacenamCtrl, 'label': 'Condiciones de Almacenamiento *', 'hint': 'Refrigeración, temperatura ideal...'},
      {'ctrl': _vidaUtilCtrl, 'label': 'Vida Útil *', 'hint': 'Ej: Consumo inmediato o 24h refrigerado'},
      {'ctrl': _observacionesCtrl, 'label': 'Observaciones', 'hint': 'Notas adicionales, alérgenos...'},
    ];

    final rows = <Widget>[];
    for (int i = 0; i < campos.length; i += 2) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSectionTitle(campos[i]['label'] as String, isDark),
            const SizedBox(height: 4),
            _buildField(controller: campos[i]['ctrl'] as TextEditingController, hint: campos[i]['hint'] as String, isDark: isDark, maxLines: 2),
          ])),
          const SizedBox(width: 10),
          if (i + 1 < campos.length)
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildSectionTitle(campos[i + 1]['label'] as String, isDark),
              const SizedBox(height: 4),
              _buildField(controller: campos[i + 1]['ctrl'] as TextEditingController, hint: campos[i + 1]['hint'] as String, isDark: isDark, maxLines: 2),
            ]))
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      if (i + 2 < campos.length) rows.add(const SizedBox(height: 10));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...rows,
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.check_rounded, size: 15),
          label: Text('Guardar Ficha Técnica', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildPasosHeader(bool isDark) {
    return Row(
      children: [
        Expanded(child: Text(
          'Se generan automáticamente las 3 fases estándar (Alistamiento, Cocción, Ensamblaje y Control de calidad).',
          style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white38 : AppColors.grey400),
        )),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {}, // Cargar desde Estándar
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            side: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Cargar desde Estándar', style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white60 : AppColors.grey700)),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          onPressed: () => setState(() => _pasos.add({'titulo': 'Nuevo Paso', 'instrucciones': ''})),
          icon: const Icon(Icons.add, size: 14),
          label: Text('Agregar Paso', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCC2222),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasosSection(bool isDark) {
    return Column(
      children: List.generate(_pasos.length, (i) {
        final paso = _pasos[i];
        final instrCtrl = TextEditingController(text: paso['instrucciones'] as String);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.grey50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white12 : AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: const Color(0xFFCC2222), shape: BoxShape.circle),
                  child: Center(child: Text('${i + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(paso['titulo'] as String, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimaryLight))),
                // Up
                if (i > 0)
                  GestureDetector(
                    onTap: () => setState(() { final p = _pasos.removeAt(i); _pasos.insert(i - 1, p); }),
                    child: const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: Color(0xFFCC2222)),
                  ),
                // Down
                if (i < _pasos.length - 1)
                  GestureDetector(
                    onTap: () => setState(() { final p = _pasos.removeAt(i); _pasos.insert(i + 1, p); }),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFFCC2222)),
                  ),
                // Delete (only if not default 3)
                if (_pasos.length > 3)
                  GestureDetector(
                    onTap: () => setState(() => _pasos.removeAt(i)),
                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                  ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: instrCtrl,
                maxLines: 2,
                onChanged: (val) => _pasos[i] = {...paso, 'instrucciones': val},
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Describe las instrucciones operativas de "${paso['titulo']}"...',
                  hintStyle: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.white24 : AppColors.grey400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCC2222))),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : AppColors.grey200)),
        color: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Cancelar', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.textSecondaryLight)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardarEvento,
              icon: _guardando
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: Text(_guardando ? 'Guardando...' : '✦ Crear Evento',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC2222),
                disabledBackgroundColor: const Color(0xFFCC2222).withAlpha(120),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Función de ayuda para abrir el modal desde cualquier parte de la app.
Future<bool?> showCreateGlobalEventDialog(
  BuildContext context, {
  Product? linkedProduct,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => CreateGlobalEventDialog(linkedProduct: linkedProduct),
  );
}

