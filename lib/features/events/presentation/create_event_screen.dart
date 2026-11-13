import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../events/providers/events_provider.dart';
import '../../products/providers/products_provider.dart';

// ─── Función pública para abrir el modal ─────────────────────────────────────
Future<bool?> showCreateEventModal(
  BuildContext context,
  WidgetRef ref, {
  Product? linkedProduct,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _EventModalContent(
      linkedProduct: linkedProduct,
      providerRef: ref,
    ),
  );
}

// ─── Tipos de campaña ─────────────────────────────────────────────────────────
class _TipoInfo {
  final String id;
  final String nombre;
  final String emoji;
  const _TipoInfo(this.id, this.nombre, this.emoji);
}

const _tipos = [
  _TipoInfo('promo_2x1', 'Promo 2×1', '🏷️'),
  _TipoInfo('descuento', 'Descuento %', '💯'),
  _TipoInfo('precio_especial', 'Precio Especial', '💲'),
  _TipoInfo('topping_extra', 'Topping Extra', '➕'),
  _TipoInfo('edicion_especial', 'Edición Especial', '⭐'),
  _TipoInfo('oferta_relampago', 'Oferta Relámpago', '⚡'),
];

// ─── Contenido del Modal ──────────────────────────────────────────────────────
class _EventModalContent extends ConsumerStatefulWidget {
  final Product? linkedProduct;
  final WidgetRef providerRef;
  const _EventModalContent({
    this.linkedProduct,
    required this.providerRef,
  });

  @override
  ConsumerState<_EventModalContent> createState() =>
      _EventModalContentState();
}

class _EventModalContentState extends ConsumerState<_EventModalContent> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _tipo = 'promo_2x1';
  bool _permanente = true;
  DateTime _inicio = DateTime.now();
  DateTime _fin = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  String? _errorTitulo;
  String? _errorValor;

  // Productos seleccionados
  late List<Product> _selProd;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selProd = widget.linkedProduct != null ? [widget.linkedProduct!] : [];
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool _needsValor() =>
      _tipo == 'descuento' ||
      _tipo == 'precio_especial' ||
      _tipo == 'topping_extra';

  bool _validate() {
    bool ok = true;
    setState(() {
      _errorTitulo =
          _tituloCtrl.text.trim().isEmpty ? 'El título es obligatorio' : null;
      if (_tipo == 'descuento' || _tipo == 'precio_especial') {
        final v = double.tryParse(_valorCtrl.text);
        if (v == null || v <= 0) {
          _errorValor = 'Ingresa un valor mayor a 0';
          ok = false;
        } else {
          _errorValor = null;
        }
      } else {
        _errorValor = null;
      }
      if (_errorTitulo != null) ok = false;
    });
    return ok;
  }

  Future<void> _guardar() async {
    if (!_validate()) return;
    setState(() => _saving = true);

    final ids = _selProd
        .map((p) => p.id.isNotEmpty ? int.tryParse(p.id) : null)
        .whereType<int>()
        .toList();

    final event = Event(
      nombre: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      tipoEvento: _tipo,
      descuento:
          _tipo == 'descuento' ? double.tryParse(_valorCtrl.text) : null,
      nuevoPrecio: _tipo == 'precio_especial'
          ? double.tryParse(_valorCtrl.text)
          : null,
      accionInsumo:
          _tipo == 'topping_extra' ? _valorCtrl.text.trim() : null,
      isActive: true,
      estado: 'Activo',
      fechaInicio: _permanente ? null : _inicio.toIso8601String(),
      fechaFin: _permanente ? null : _fin.toIso8601String(),
      productosAsociados: ids.isEmpty ? null : ids,
      icono: null,
      isTemporal: !_permanente,
    );

    final ok =
        await widget.providerRef.read(eventsProvider.notifier).createEvent(event);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.grey100;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor =
        isDark ? AppColors.grey700 : AppColors.grey200;
    const orange = Color(0xFFE65100);

    // Productos del catálogo para selector adicional
    final allProducts =
        widget.providerRef.read(productsProvider).products;
    final filtered = _search.isEmpty
        ? allProducts
        : allProducts
            .where((p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return Padding(
      // Sube el modal cuando aparece el teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ────────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.campaign, color: orange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Crear Campaña o Promoción',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Aplica descuentos, 2×1 o beneficios',
                          style: TextStyle(
                              fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              if (widget.linkedProduct != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: orange.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: orange.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fastfood,
                            color: orange, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.linkedProduct!.name,
                            style: const TextStyle(
                              color: orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1),
              ),
              const SizedBox(height: 16),

              // ── Sección: Tipo de campaña ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'TIPO DE CAMPAÑA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _tipos.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                                child: _buildTipoChip(
                                    _tipos[i], isDark, orange)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: i + 1 < _tipos.length
                                  ? _buildTipoChip(
                                      _tipos[i + 1], isDark, orange)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── Sección: Título ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                child: _fieldLabel('TÍTULO DE LA CAMPAÑA *', textSecondary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _tituloCtrl,
                  onChanged: (_) {
                    if (_errorTitulo != null) {
                      setState(() => _errorTitulo = null);
                    }
                  },
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: _inputDeco(
                    'Ej: Jueves 2×1 en Burger Artesanal',
                    isDark,
                    borderColor,
                    orange,
                    errorText: _errorTitulo,
                  ),
                ),
              ),

              // ── Campos dinámicos según tipo ────────────────────────────
              if (_needsValor()) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: _fieldLabel(
                    _tipo == 'descuento'
                        ? 'PORCENTAJE DE DESCUENTO *'
                        : _tipo == 'precio_especial'
                            ? 'NUEVO PRECIO (COP) *'
                            : 'DESCRIPCIÓN DEL TOPPING',
                    textSecondary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _valorCtrl,
                    keyboardType: _tipo == 'topping_extra'
                        ? TextInputType.text
                        : TextInputType.number,
                    inputFormatters: _tipo != 'topping_extra'
                        ? [FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'))]
                        : null,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: _inputDeco(
                      _tipo == 'descuento'
                          ? 'Ej: 15'
                          : _tipo == 'precio_especial'
                              ? 'Ej: 15000'
                              : 'Ej: Extra Tocineta Ahumada',
                      isDark,
                      borderColor,
                      orange,
                      suffix: _tipo == 'descuento' ? '%' : null,
                      prefix: _tipo == 'precio_especial' ? r'$' : null,
                      errorText: _errorValor,
                    ),
                  ),
                ),
              ],

              // ── Descripción ────────────────────────────────────────────
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: _fieldLabel('DESCRIPCIÓN (OPCIONAL)', textSecondary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: _inputDeco(
                    'Breve descripción de la campaña...',
                    isDark,
                    borderColor,
                    orange,
                  ),
                ),
              ),

              // ── Vigencia ───────────────────────────────────────────────
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        dense: true,
                        title: Text(
                          'Campaña Permanente',
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Sin fecha de vencimiento',
                          style: TextStyle(
                              color: textSecondary, fontSize: 11),
                        ),
                        value: _permanente,
                        activeTrackColor: orange,
                        activeThumbColor: Colors.white,
                        onChanged: (v) =>
                            setState(() => _permanente = v),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      if (!_permanente) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _dateTile(
                                  'INICIO',
                                  _fmt(_inicio),
                                  isDark,
                                  textPrimary,
                                  textSecondary,
                                  orange,
                                  () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _inicio,
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) {
                                      setState(() => _inicio = d);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dateTile(
                                  'FIN',
                                  _fmt(_fin),
                                  isDark,
                                  textPrimary,
                                  textSecondary,
                                  orange,
                                  () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _fin,
                                      firstDate: DateTime(2024),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) {
                                      setState(() => _fin = d);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Selector de productos adicionales ──────────────────────
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _fieldLabel('PRODUCTOS', textSecondary),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_selProd.length}',
                        style: const TextStyle(
                            color: orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(color: textPrimary, fontSize: 13),
                  decoration: _inputDeco(
                    'Buscar producto...',
                    isDark,
                    borderColor,
                    orange,
                    prefix: null,
                    suffix: null,
                    icon: Icons.search,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Lista de productos (máx. 5 visible para no hacer el modal enorme)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filtered.take(8).map((p) {
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
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? orange.withAlpha(25) : cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel ? orange : borderColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sel
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: sel ? orange : textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 12,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              r'$' + p.price.toStringAsFixed(0),
                              style: TextStyle(
                                color: orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Botón Guardar ──────────────────────────────────────────
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: orange.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rocket_launch, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Crear y Publicar Campaña',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chip de tipo de campaña ─────────────────────────────────────────────────
  Widget _buildTipoChip(_TipoInfo t, bool isDark, Color orange) {
    final sel = _tipo == t.id;
    final cardColor = isDark ? AppColors.cardDark : AppColors.grey100;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return GestureDetector(
      onTap: () => setState(() => _tipo = t.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? orange.withAlpha(35) : cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? orange : (isDark ? AppColors.grey700 : AppColors.grey200),
            width: sel ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.nombre,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? orange : textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sel)
              const Icon(Icons.check_circle, size: 14, color: Color(0xFFE65100)),
          ],
        ),
      ),
    );
  }

  // ── Tile de fecha ───────────────────────────────────────────────────────────
  Widget _dateTile(
    String label,
    String value,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color orange,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.grey50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isDark ? AppColors.grey700 : AppColors.grey200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 9, color: textSecondary)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 11, color: orange),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  // ── Helpers de UI ────────────────────────────────────────────────────────────
  Widget _fieldLabel(String t, Color color) => Text(
        t,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDeco(
    String hint,
    bool isDark,
    Color borderColor,
    Color orange, {
    String? suffix,
    String? prefix,
    String? errorText,
    IconData? icon,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.grey500 : AppColors.grey400,
          fontSize: 13,
        ),
        suffixText: suffix,
        prefixText: prefix,
        prefixIcon: icon != null ? Icon(icon, color: orange, size: 20) : null,
        errorText: errorText,
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.grey50,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      );
}

// ─── Clase pública vacía para mantener compatibilidad de imports ──────────────
// (product_list_screen.dart importa este archivo; ahora usa showCreateEventModal)
class CreateEventScreen {
  const CreateEventScreen._();
}
