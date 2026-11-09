import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/security_sanitizer.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/cloudinary_service.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../../../widgets/common_app_bar.dart';
import '../providers/products_provider.dart';

/// Rediseño completo de Gestión de Productos (Formulario / Wizard Paso a Paso)
/// Siguiendo la estética, estructura y estándares del panel Web de Chazin Food.
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─── Paso del Asistente ───
  int _currentStep = 0;

  // ─── Tipo de Producto: 'comida' | 'bebida' | 'combo' ───
  String _tipoProducto = 'comida';

  // ─── Paso 1: Datos & Tipo ───
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isActive = true;
  String? _imageUrl;
  bool _isSaving = false;

  // ─── Paso 2: Variantes ───
  final List<Map<String, dynamic>> _variantes = [];

  // ─── Paso 3: Adiciones & Extras (Comida / Bebida) ───
  List<Map<String, dynamic>> _todasAdiciones = [];
  final List<Map<String, dynamic>> _selectedAdiciones = [];
  final TextEditingController _adicionesSearchController = TextEditingController();

  // ─── Paso 3: Armador de Combo (Combo Especial) ───
  final List<Map<String, dynamic>> _comboPlatos = [];
  int _comboBebidasQty = 1;
  final Set<String> _comboBebidasPermitidas = {};
  final List<String> _todasBebidasCatalogo = [
    'Gaseosa Coca-Cola 400ml',
    'Gaseosa Manzana Postobón 400ml',
    'Agua Cristal sin Gas 600ml',
    'Gaseosa Pepsi 400ml',
    'Gaseosa Sprite 400ml',
    'Gaseosa Colombiana Postobón 400ml',
    'Gaseosa Cuatro Toronja 400ml',
    'Gaseosa Coca-Cola Sin Azúcar / Light 400ml',
    'Gaseosa sabor a uva presentación PET 400ml',
    'Gaseosa Naranja Postobón 400ml',
  ];
  final TextEditingController _comboSearchController = TextEditingController();

  // ─── Paso 4: Ficha Técnica & Receta (Comida) ───
  late final TextEditingController _controlCalidadController;
  late final TextEditingController _tiempoPrepController;
  late final TextEditingController _rendimientoController;
  late final TextEditingController _vidaUtilController;
  late final TextEditingController _especificacionesController;
  late final TextEditingController _sensorialesController;
  late final TextEditingController _nutricionalController;
  late final TextEditingController _almacenamientoController;
  late final TextEditingController _alergenosController;

  bool get isEditing => widget.product != null;

  // Pasos totales dinámicos según el tipo de producto
  int get totalSteps {
    if (_tipoProducto == 'combo') return 2; // Paso 1: Datos & Tipo, Paso 2: Armador de Combo
    if (_tipoProducto == 'bebida') return 3; // Paso 1: Datos & Tipo, Paso 2: Presentaciones, Paso 3: Adiciones
    return 4; // Comida: Datos, Variantes, Adiciones, Ficha Técnica
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _selectedCategoryId = p?.categoryId;
    _selectedCategoryName = p?.categoryName;
    _isActive = p?.isActive ?? true;
    _imageUrl = p?.imageUrl;

    // Detectar tipo de producto
    if (p != null) {
      final cat = p.categoryName.toLowerCase();
      final name = p.name.toLowerCase();
      if (cat.contains('combo') || name.contains('combo') || p.insumos.isNotEmpty && p.variantes.isEmpty) {
        _tipoProducto = 'combo';
      } else if (cat.contains('bebida') || cat.contains('gaseosa') || cat.contains('refresco') || cat.contains('jugo')) {
        _tipoProducto = 'bebida';
      } else {
        _tipoProducto = 'comida';
      }

      // Cargar variantes existentes
      if (p.variantes.isNotEmpty) {
        for (final v in p.variantes) {
          _variantes.add({
            'nombre': v['nombre'] ?? '',
            'tipo': v['tipo'] ?? 'presentacion',
            'imagen': v['imagen'] ?? '',
          });
        }
      }

      // Cargar adiciones existentes
      if (p.adiciones.isNotEmpty) {
        for (final a in p.adiciones) {
          _selectedAdiciones.add({
            'nombre': a['nombre'] ?? '',
            'precio': (a['precio'] is num) ? (a['precio'] as num).toDouble() : 0.0,
          });
        }
      }
    }

    // Ficha técnica controllers
    _controlCalidadController = TextEditingController(
      text: 'Verificar temperatura adecuada, empaque hermético sellado y presentación estética.',
    );
    _tiempoPrepController = TextEditingController(text: '15');
    _rendimientoController = TextEditingController(text: '1 porción');
    _vidaUtilController = TextEditingController(text: p?.vidaUtil ?? 'Consumo inmediato');
    _especificacionesController = TextEditingController(
      text: 'Gramaje estándar de preparación, ingredientes frescos bajo normas BPM.',
    );
    _sensorialesController = TextEditingController(
      text: 'Sabor característico, textura crujiente y jugosa, aroma fresco.',
    );
    _nutricionalController = TextEditingController(
      text: 'Aporte calórico balanceado, proteínas de alta calidad.',
    );
    _almacenamientoController = TextEditingController(
      text: 'Refrigeración entre 2°C y 4°C previa a preparación.',
    );
    _alergenosController = TextEditingController(
      text: 'Puede contener trazas de gluten, derivados lácteos o soya.',
    );

    // Bebidas permitidas por defecto
    _comboBebidasPermitidas.addAll(_todasBebidasCatalogo);

    // Adiciones predeterminadas del catálogo
    _todasAdiciones = [
      {'nombre': 'Queso extra', 'precio': 2500.0, 'categoria': 'Quesos'},
      {'nombre': 'Tocineta crujiente', 'precio': 3500.0, 'categoria': 'Carnes'},
      {'nombre': 'Carne extra 150g', 'precio': 5500.0, 'categoria': 'Carnes'},
      {'nombre': 'Papas a la francesa', 'precio': 4500.0, 'categoria': 'Acompañantes'},
      {'nombre': 'Aros de cebolla', 'precio': 4000.0, 'categoria': 'Acompañantes'},
      {'nombre': 'Salsa de la casa especial', 'precio': 1500.0, 'categoria': 'Salsas'},
      {'nombre': 'Salsa BBQ ahumada', 'precio': 1500.0, 'categoria': 'Salsas'},
      {'nombre': 'Guacamole fresco', 'precio': 3000.0, 'categoria': 'Salsas'},
      {'nombre': 'Pepinillos agridulces', 'precio': 1500.0, 'categoria': 'Vegetales'},
      {'nombre': 'Huevo frito', 'precio': 2000.0, 'categoria': 'Extras'},
    ];

    _priceController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _adicionesSearchController.dispose();
    _comboSearchController.dispose();
    _controlCalidadController.dispose();
    _tiempoPrepController.dispose();
    _rendimientoController.dispose();
    _vidaUtilController.dispose();
    _especificacionesController.dispose();
    _sensorialesController.dispose();
    _nutricionalController.dispose();
    _almacenamientoController.dispose();
    _alergenosController.dispose();
    super.dispose();
  }

  // ─── Subida de Imagen ───
  Future<void> _pickImage() async {
    try {
      final String? uploadedUrl = await CloudinaryService.pickAndUploadImage(context);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        setState(() {
          _imageUrl = uploadedUrl;
        });
        if (mounted) {
          CustomToast.show(
            context,
            title: '¡Imagen Cargada!',
            message: 'La fotografía se asoció correctamente al producto.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Error al subir imagen',
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  // ─── Guardado Final ───
  Future<void> _handleSave() async {
    // Validar nombre y precio del paso 1
    if (_nameController.text.trim().isEmpty) {
      setState(() => _currentStep = 0);
      CustomToast.show(
        context,
        title: 'Nombre requerido',
        message: 'Por favor ingresa el nombre del producto en el Paso 1.',
        isError: true,
      );
      return;
    }

    final double priceVal = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (priceVal <= 0) {
      setState(() => _currentStep = 0);
      CustomToast.show(
        context,
        title: 'Precio inválido',
        message: 'Por favor ingresa un precio de venta mayor a 0 en COP.',
        isError: true,
      );
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() => _currentStep = 0);
      CustomToast.show(
        context,
        title: 'Categoría requerida',
        message: 'Por favor selecciona la categoría del producto.',
        isError: true,
      );
      return;
    }

    // Validaciones específicas de Combo
    if (_tipoProducto == 'combo' && _comboPlatos.isEmpty) {
      setState(() => _currentStep = 1);
      CustomToast.show(
        context,
        title: 'Combo sin platillos',
        message: 'Agrega al menos un platillo o acompañamiento al combo.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Estructurar configuración de combo
      final Map<String, dynamic>? configuracionCombo = _tipoProducto == 'combo'
          ? {
              'esCombo': true,
              'cantidadBebidas': _comboBebidasQty,
              'bebidasPermitidas': _comboBebidasPermitidas.toList(),
              'productosAsociados': _comboPlatos,
            }
          : null;

      // Estructurar ficha técnica (solo para comidas)
      final Map<String, dynamic>? fichaTecnica = _tipoProducto == 'comida'
          ? {
              'tiempoPreparacion': int.tryParse(_tiempoPrepController.text.trim()) ?? 15,
              'rendimiento': _rendimientoController.text.trim(),
              'vidaUtil': _vidaUtilController.text.trim(),
              'controlCalidad': _controlCalidadController.text.trim(),
              'especificacionesTecnicas': _especificacionesController.text.trim(),
              'caracteristicasSensoriales': _sensorialesController.text.trim(),
              'informacionNutricional': _nutricionalController.text.trim(),
              'condicionesAlmacenamiento': _almacenamientoController.text.trim(),
              'observacionesAlergenos': _alergenosController.text.trim(),
            }
          : null;

      if (isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(
              widget.product!.id,
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              price: priceVal,
              categoryId: _selectedCategoryId,
              categoryName: _selectedCategoryName,
              imageUrl: _imageUrl,
              isActive: _isActive,
              variantes: _variantes,
              adiciones: _selectedAdiciones,
              configuracionCombo: configuracionCombo,
              itemsCombo: _comboPlatos,
              fichaTecnica: fichaTecnica,
            );
      } else {
        await ref.read(productsProvider.notifier).createProduct(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              price: priceVal,
              categoryId: _selectedCategoryId!,
              categoryName: _selectedCategoryName ?? 'General',
              imageUrl: _imageUrl,
              estado: _isActive ? 1 : 0,
              variantes: _variantes,
              adiciones: _selectedAdiciones,
              configuracionCombo: configuracionCombo,
              itemsCombo: _comboPlatos,
              fichaTecnica: fichaTecnica,
            );
      }

      if (mounted) {
        CustomToast.show(
          context,
          title: isEditing ? '¡Producto Actualizado!' : '¡Producto Creado!',
          message: isEditing
              ? 'Los cambios se guardaron con éxito en Chazin Food.'
              : 'El nuevo producto fue registrado en el catálogo.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        CustomToast.show(
          context,
          title: 'Error al procesar',
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  // ─── Helpers de Navegación del Wizard ───
  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        CustomToast.show(
          context,
          title: 'Nombre requerido',
          message: 'Por favor ingresa el nombre del producto.',
          isError: true,
        );
        return;
      }
      final nameErr = SecurityValidators.validateNoInjection(_nameController.text.trim(), fieldName: 'Nombre');
      if (nameErr != null) {
        CustomToast.show(
          context,
          title: 'Entrada no permitida',
          message: nameErr,
          isError: true,
        );
        return;
      }
      final descErr = SecurityValidators.validateNoInjection(_descController.text.trim(), fieldName: 'Descripción');
      if (descErr != null) {
        CustomToast.show(
          context,
          title: 'Entrada no permitida',
          message: descErr,
          isError: true,
        );
        return;
      }
      final p = double.tryParse(_priceController.text.trim()) ?? 0.0;
      if (p <= 0) {
        CustomToast.show(
          context,
          title: 'Precio requerido',
          message: 'Ingresa un precio base válido en COP.',
          isError: true,
        );
        return;
      }
      if (_selectedCategoryId == null) {
        CustomToast.show(
          context,
          title: 'Categoría requerida',
          message: 'Selecciona una categoría para el producto.',
          isError: true,
        );
        return;
      }
    }

    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: CommonAppBar(
        title: isEditing ? 'Editar Producto' : 'Nuevo Producto',
        onClose: () => Navigator.pop(context),
        showRefresh: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Stepper Header Visual ───
            _buildStepperHeader(isDark),

            // ─── Contenido del Paso Activo ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStepContent(state, isDark),
                ),
              ),
            ),

            // ─── Barra Inferior Fija de Navegación & Resumen ───
            _buildBottomActionBar(isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STEPPER HEADER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStepperHeader(bool isDark) {
    // Definición de pasos según el tipo
    final List<Map<String, String>> steps;
    if (_tipoProducto == 'combo') {
      steps = [
        {'num': '1', 'title': 'Datos & Tipo', 'sub': 'Nombre y precio'},
        {'num': '2', 'title': 'Armador de Combo', 'sub': 'Platos y bebidas'},
      ];
    } else if (_tipoProducto == 'bebida') {
      steps = [
        {'num': '1', 'title': 'Datos & Tipo', 'sub': 'Nombre y precio'},
        {'num': '2', 'title': 'Presentaciones', 'sub': 'Tamaños y sabores'},
        {'num': '3', 'title': 'Adiciones', 'sub': 'Extras permitidos'},
      ];
    } else {
      steps = [
        {'num': '1', 'title': 'Datos & Tipo', 'sub': 'Nombre y precio'},
        {'num': '2', 'title': 'Variantes', 'sub': 'Opciones y tamaños'},
        {'num': '3', 'title': 'Adiciones', 'sub': 'Extras permitidos'},
        {'num': '4', 'title': 'Ficha Técnica', 'sub': 'Receta culinaria'},
      ];
    }

    // Color del badge de tipo
    Color badgeColor;
    Color badgeBg;
    String badgeText;
    if (_tipoProducto == 'combo') {
      badgeColor = const Color(0xFF2563EB);
      badgeBg = const Color(0xFFDBEAFE);
      badgeText = 'COMBO ESPECIAL';
    } else if (_tipoProducto == 'bebida') {
      badgeColor = const Color(0xFF7C3AED);
      badgeBg = const Color(0xFFEDE9FE);
      badgeText = 'BEBIDA / REFRESCO';
    } else {
      badgeColor = AppColors.primary;
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = 'COMIDA / PLATO';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo con Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? badgeColor.withAlpha(45) : badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withAlpha(80)),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paso ${_currentStep + 1} de $totalSteps • ${steps[_currentStep]['sub']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper bar con bolitas y líneas
          Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index < _currentStep;
              final isActive = index == _currentStep;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Row(
                  children: [
                    // Círculo del paso
                    GestureDetector(
                      onTap: () {
                        // Permitir regresar o avanzar si los datos iniciales son válidos
                        if (index < _currentStep || _nameController.text.trim().isNotEmpty) {
                          setState(() => _currentStep = index);
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.primary
                              : isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(90),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  steps[index]['num']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: (isActive || isCompleted)
                                        ? Colors.white
                                        : (isDark ? Colors.grey[400] : const Color(0xFF6B7280)),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Título del paso (abreviado en pantallas pequeñas)
                    Flexible(
                      child: Text(
                        steps[index]['title']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primary
                              : (isDark ? Colors.grey[400] : const Color(0xFF4B5563)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Línea conectora
                    if (!isLast) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SELECTOR DE CONTENIDO SEGÚN PASO
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCurrentStepContent(ProductsState state, bool isDark) {
    if (_tipoProducto == 'combo') {
      switch (_currentStep) {
        case 0:
          return _buildStep1DatosYTipo(state, isDark);
        case 1:
          return _buildStepArmadorCombo(state, isDark);
        default:
          return _buildStep1DatosYTipo(state, isDark);
      }
    } else if (_tipoProducto == 'bebida') {
      switch (_currentStep) {
        case 0:
          return _buildStep1DatosYTipo(state, isDark);
        case 1:
          return _buildStep2Variantes(isDark);
        case 2:
          return _buildStep3Adiciones(isDark);
        default:
          return _buildStep1DatosYTipo(state, isDark);
      }
    } else {
      switch (_currentStep) {
        case 0:
          return _buildStep1DatosYTipo(state, isDark);
        case 1:
          return _buildStep2Variantes(isDark);
        case 2:
          return _buildStep3Adiciones(isDark);
        case 3:
          return _buildStep4FichaTecnica(isDark);
        default:
          return _buildStep1DatosYTipo(state, isDark);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PASO 1: DATOS & TIPO
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep1DatosYTipo(ProductsState state, bool isDark) {
    final double rawPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final String formattedPriceCOP = Formatters.currency(rawPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. SELECTOR DE TIPO DE PRODUCTO ──
        Text(
          '¿Qué tipo de producto deseas crear? *',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTipoCard(
              tipo: 'comida',
              titulo: 'Comida / Platillo',
              sub: 'Hamburguesas, perros, papas...',
              icon: Icons.lunch_dining_rounded,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTipoCard(
              tipo: 'bebida',
              titulo: 'Bebida / Refresco',
              sub: 'Gaseosas, jugos, agua...',
              icon: Icons.local_drink_rounded,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTipoCard(
              tipo: 'combo',
              titulo: 'Combo Especial',
              sub: 'Paquete platos + bebidas',
              icon: Icons.fastfood_rounded,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 2. PREVISUALIZACIÓN EN VIVO & FOTO ──
        Text(
          'Fotografía y Vista en Menú',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),

        // Tarjeta combinada de Carga y Preview tipo Menú Web
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Área de imagen o subida
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildNetworkOrFileImage(_imageUrl!),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xBF000000),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Toca para cambiar foto',
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sin fotografía asignada',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF374151),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Haz clic aquí para cargar imagen (JPG, PNG o WEBP)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                              label: Text(
                                'Cargar Imagen',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Vista previa de la tarjeta del menú
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (_selectedCategoryName ?? 'CATEGORÍA').toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Precio destacado en COP
                        Text(
                          formattedPriceCOP,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Nombre de tu producto...'
                          : _nameController.text.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _descController.text.trim().isEmpty
                          ? 'Tu descripción apetitosa aparecerá aquí para los comensales...'
                          : _descController.text.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 3. CAMPOS DE FORMULARIO ──
        // Nombre del Producto
        _buildSectionLabel('Nombre del Producto *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Ej. Hamburguesa Doble Queso',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Categoría y Estado en fila
        Row(
          children: [
            // Categoría Dropdown
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Categoría *', isDark),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategoryId,
                        hint: Text(
                          'Seleccionar...',
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                        ),
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                        items: state.categories
                            .where((c) => c.id != 'cat_all' && c.id != '0' && c.isActive)
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) {
                          final cat = state.categories.firstWhere((c) => c.id == val);
                          setState(() {
                            _selectedCategoryId = val;
                            _selectedCategoryName = cat.name;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Estado de Venta
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('Estado de Venta', isDark),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _isActive,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        items: [
                          DropdownMenuItem(
                            value: true,
                            child: Row(
                              children: [
                                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('Activo', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827))),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Row(
                              children: [
                                Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF9CA3AF), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('Inactivo', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827))),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _isActive = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Precio de Venta Base ($ COP)
        _buildSectionLabel('Precio de Venta Base (\$ COP) *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Ej. 18000',
            prefixText: '\$ ',
            suffixText: 'COP',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Descripción del Platillo (Opcional)
        _buildSectionLabel('Descripción del Platillo (Opcional)', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descController,
          maxLines: 3,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Describe los ingredientes principales, preparación o por qué a los clientes les encanta...',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PASO 2: PRESENTACIONES & VARIANTES (Comida / Bebida)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep2Variantes(bool isDark) {
    final bool isDrink = _tipoProducto == 'bebida';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Explicativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.layers_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDrink ? 'Presentaciones y Variantes de la Bebida' : 'Presentaciones y Variantes de la Comida',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Las variantes representan opciones que el cliente puede elegir (como porciones, sabores o tamaños). Todas comparten el precio base configurado en el Paso 1.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cabecera con botón de agregar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Presentaciones (${_variantes.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _variantes.add({
                    'nombre': '',
                    'tipo': isDrink ? 'tamano' : 'presentacion',
                    'imagen': '',
                  });
                });
              },
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: Text(
                'Añadir Presentación',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chips de sugerencia rápida
        Text(
          'Ejemplos frecuentes:',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500]),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: (isDrink
                  ? ['+ 400ml', '+ 1.5 Litros', '+ 2.5 Litros Mega', '+ Sin Azúcar / Light']
                  : ['+ Sencilla', '+ Doble Carne', '+ Tamaño Familiar', '+ Con Queso Extra'])
              .map((chipText) {
            return InkWell(
              onTap: () {
                final cleanName = chipText.replaceFirst('+ ', '');
                setState(() {
                  _variantes.add({
                    'nombre': cleanName,
                    'tipo': isDrink ? 'tamano' : 'presentacion',
                    'imagen': '',
                  });
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
                ),
                child: Text(
                  chipText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Lista de variantes configuradas o empty state
        if (_variantes.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.fastfood_outlined, size: 36, color: AppColors.primary),
                const SizedBox(height: 10),
                Text(
                  'Sin variantes adicionales',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                Text(
                  'El producto se ofrecerá con su presentación estándar y precio base. Si deseas añadir opciones como "Doble Carne", haz clic en el botón superior.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[400] : const Color(0xFF6B7280)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _variantes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final v = _variantes[idx];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    // Badge número
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Input Nombre de la Variante
                    Expanded(
                      child: TextFormField(
                        initialValue: v['nombre'],
                        onChanged: (val) => v['nombre'] = val,
                        style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                        decoration: _inputDecoration(
                          hintText: isDrink ? 'Ej. 1.5 Litros / Sabor Manzana' : 'Ej. Doble Carne / Familiar',
                          isDark: isDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón eliminar
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      onPressed: () => setState(() => _variantes.removeAt(idx)),
                      tooltip: 'Eliminar variante',
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PASO 3: ADICIONES & EXTRAS (Comida / Bebida)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep3Adiciones(bool isDark) {
    final query = _adicionesSearchController.text.trim().toLowerCase();
    final adicionesFiltradas = query.isEmpty
        ? _todasAdiciones
        : _todasAdiciones.where((a) => a['nombre'].toString().toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Explicativo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adiciones y Extras Permitidos',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Activa los ingredientes y complementos extras que el cliente puede sumar al pedir este producto. Los precios se sumarán automáticamente.',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[300] : const Color(0xFF4B5563), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Buscador de adiciones
        TextFormField(
          controller: _adicionesSearchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Buscar adición (ej: Queso, Tocineta)...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 14),

        // Lista de adiciones en cards
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Adiciones Disponibles (${_selectedAdiciones.length} activadas)',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827)),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedAdiciones.length == _todasAdiciones.length) {
                    _selectedAdiciones.clear();
                  } else {
                    _selectedAdiciones.clear();
                    _selectedAdiciones.addAll(_todasAdiciones);
                  }
                });
              },
              icon: Icon(
                _selectedAdiciones.length == _todasAdiciones.length ? Icons.clear_all : Icons.select_all,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                _selectedAdiciones.length == _todasAdiciones.length ? 'Desmarcar todas' : 'Activar todas',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: adicionesFiltradas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final ad = adicionesFiltradas[idx];
            final bool isSelected = _selectedAdiciones.any((a) => a['nombre'] == ad['nombre']);
            final double precio = (ad['precio'] as num).toDouble();

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAdiciones.removeWhere((a) => a['nombre'] == ad['nombre']);
                  } else {
                    _selectedAdiciones.add(ad);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primary.withAlpha(30) : const Color(0xFFFFF1F1))
                      : (isDark ? const Color(0xFF1F2937) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Checkbox
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey[400]!,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),

                    // Nombre y categoría
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad['nombre'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            ad['categoria']?.toString() ?? 'Extra',
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),

                    // Precio en COP
                    Text(
                      '+${Formatters.currency(precio)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
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

  // ═══════════════════════════════════════════════════════════════════════
  // PASO 3 (COMBO): ARMADOR DE COMBO GASTRONÓMICO
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStepArmadorCombo(ProductsState state, bool isDark) {
    final query = _comboSearchController.text.trim().toLowerCase();
    final productosDisponibles = state.products.where((p) {
      if (p.id == widget.product?.id) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) || p.categoryName.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner Explicativo de Combo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withAlpha(15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2563EB).withAlpha(40)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Armador de Combo Gastronómico',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Selecciona los platillos existentes que componen este paquete. El cliente recibirá todo en una sola orden con precio promocional.',
                      style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[300] : const Color(0xFF4B5563), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── 1. PLATILLOS Y ACOMPAÑAMIENTOS INCLUIDOS ──
        Text(
          '1. PLATILLOS Y ACOMPAÑAMIENTOS INCLUIDOS:',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1F2937), letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),

        // Buscador de productos para el combo
        TextFormField(
          controller: _comboSearchController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Buscar producto para agregar (Hamburguesa, Perro, Papas)...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 10),

        // Desplegable de catálogo para agregar
        if (query.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: productosDisponibles.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final p = productosDisponibles[idx];
                return ListTile(
                  dense: true,
                  title: Text(p.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                  subtitle: Text(Formatters.currency(p.price), style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        final exist = _comboPlatos.indexWhere((it) => it['idProducto'] == p.id);
                        if (exist >= 0) {
                          _comboPlatos[exist]['cantidad'] = (_comboPlatos[exist]['cantidad'] as int) + 1;
                        } else {
                          _comboPlatos.add({
                            'idProducto': p.id,
                            'nombre': p.name,
                            'precio': p.price,
                            'cantidad': 1,
                            'imagen': p.imageUrl ?? '',
                          });
                        }
                        _comboSearchController.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    child: const Text('Agregar', style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Lista de platos agregados al combo
        if (_comboPlatos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.fastfood_outlined, size: 30, color: Color(0xFF2563EB)),
                const SizedBox(height: 6),
                Text(
                  'Aún no has agregado productos al combo',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
                ),
                Text(
                  'Escribe en el buscador para añadir los platos que integran este combo especial.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comboPlatos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final it = _comboPlatos[idx];
              final double precio = (it['precio'] as num).toDouble();
              final int qty = (it['cantidad'] as num).toInt();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it['nombre'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(Formatters.currency(precio), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    // Cantidad
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () {
                            setState(() {
                              if (qty > 1) {
                                it['cantidad'] = qty - 1;
                              } else {
                                _comboPlatos.removeAt(idx);
                              }
                            });
                          },
                        ),
                        Text('$qty', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                          onPressed: () {
                            setState(() => it['cantidad'] = qty + 1);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 20),

        // ── 2. BEBIDAS A ELECCIÓN DEL CLIENTE ──
        Text(
          '2. BEBIDAS A ELECCIÓN DEL CLIENTE:',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1F2937), letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '✓ El cliente elegirá $_comboBebidasQty bebida(s) incluida(s) en el precio (\$0 COP).',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981)),
        ),
        const SizedBox(height: 10),

        // Selector de cantidad de bebidas
        Row(
          children: [0, 1, 2, 3, 4].map((n) {
            final bool sel = _comboBebidasQty == n;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(n == 0 ? 'Sin bebida' : '$n Bebida${n > 1 ? 's' : ''}'),
                selected: sel,
                selectedColor: const Color(0xFF2563EB),
                labelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : (isDark ? Colors.grey[300] : const Color(0xFF374151)),
                ),
                onSelected: (_) => setState(() => _comboBebidasQty = n),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Checklist de bebidas permitidas
        if (_comboBebidasQty > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bebidas permitidas (${_comboBebidasPermitidas.length} de ${_todasBebidasCatalogo.length}):',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500]),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_comboBebidasPermitidas.length == _todasBebidasCatalogo.length) {
                      _comboBebidasPermitidas.clear();
                    } else {
                      _comboBebidasPermitidas.addAll(_todasBebidasCatalogo);
                    }
                  });
                },
                child: Text(
                  _comboBebidasPermitidas.length == _todasBebidasCatalogo.length ? 'Desmarcar todas' : 'Permitir todas',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _todasBebidasCatalogo.map((b) {
              final sel = _comboBebidasPermitidas.contains(b);
              return FilterChip(
                label: Text(b),
                selected: sel,
                selectedColor: const Color(0xFFDBEAFE),
                checkmarkColor: const Color(0xFF2563EB),
                labelStyle: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: sel ? const Color(0xFF1D4ED8) : (isDark ? Colors.grey[400] : const Color(0xFF4B5563)),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _comboBebidasPermitidas.add(b);
                    } else {
                      _comboBebidasPermitidas.remove(b);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PASO 4: FICHA TÉCNICA & RECETA CULINARIA (Comida)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStep4FichaTecnica(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. CONTROL DE CALIDAD Y EMPAQUE ──
        _buildSectionLabel('Control de Calidad y Empaque', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controlCalidadController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(
            hintText: 'Describe las instrucciones operativas de "Control de Calidad y Empaque"...',
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 18),

        // ── 2. PARÁMETROS DE PREPARACIÓN Y RENDIMIENTO ──
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 6),
            Text(
              'PARÁMETROS DE PREPARACIÓN Y RENDIMIENTO',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFFF59E0B), letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('TIEMPO PREPARACIÓN (MIN) *', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _tiempoPrepController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: _inputDecoration(hintText: 'Ej. 15', isDark: isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('RENDIMIENTO / PORCIONES *', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _rendimientoController,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: _inputDecoration(hintText: '1 porción', isDark: isDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('VIDA ÚTIL *', isDark),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _vidaUtilController,
                    style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                    decoration: _inputDecoration(hintText: 'Consumo inmediato', isDark: isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 3. ESPECIFICACIONES TÉCNICAS, CALIDAD Y CONSERVACIÓN ──
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 6),
            Text(
              'ESPECIFICACIONES TÉCNICAS, CALIDAD Y CONSERVACIÓN',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildSectionLabel('ESPECIFICACIONES TÉCNICAS *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _especificacionesController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(hintText: 'Gramaje, temperatura de cocción, estándares...', isDark: isDark),
        ),
        const SizedBox(height: 12),

        _buildSectionLabel('CARACTERÍSTICAS SENSORIALES *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _sensorialesController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(hintText: 'Sabor, textura, aroma, apariencia...', isDark: isDark),
        ),
        const SizedBox(height: 12),

        _buildSectionLabel('INFORMACIÓN NUTRICIONAL *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nutricionalController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(hintText: 'Calorías, proteínas, carbohidratos...', isDark: isDark),
        ),
        const SizedBox(height: 12),

        _buildSectionLabel('CONDICIONES DE ALMACENAMIENTO *', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _almacenamientoController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(hintText: 'Refrigeración, temperatura ideal...', isDark: isDark),
        ),
        const SizedBox(height: 12),

        _buildSectionLabel('OBSERVACIONES Y ALÉRGENOS (OPCIONAL)', isDark),
        const SizedBox(height: 6),
        TextFormField(
          controller: _alergenosController,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1F2937)),
          decoration: _inputDecoration(hintText: 'Notas adicionales para cocina, advertencias de alérgenos...', isDark: isDark),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BARRA INFERIOR FIJA (Resumen y Botones de Navegación)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBottomActionBar(bool isDark) {
    final double rawPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final String formattedPriceCOP = Formatters.currency(rawPrice);
    final String prodName = _nameController.text.trim().isEmpty ? 'Sin nombre' : _nameController.text.trim();
    final bool isLast = _currentStep == totalSteps - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resumen rápido en texto
          Row(
            children: [
              Expanded(
                child: Text(
                  '$prodName • $formattedPriceCOP • ${_variantes.length} var. • ${_selectedAdiciones.length} adic.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[400] : const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Botones de acción
          Row(
            children: [
              // Botón Cancelar o Anterior
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'Cancelar' : '← Anterior',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botón Siguiente o Guardar
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? const Color(0xFF10B981) : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast
                                  ? (isEditing ? '✓ Guardar Cambios' : '✓ Crear Producto')
                                  : 'Siguiente →',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WIDGETS AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTipoCard({
    required String tipo,
    required String titulo,
    required String sub,
    required IconData icon,
    required bool isDark,
  }) {
    final bool isSelected = _tipoProducto == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipoProducto = tipo;
            // Ajustar el paso actual si sobrepasa los pasos permitidos
            if (_currentStep >= totalSteps) {
              _currentStep = totalSteps - 1;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary.withAlpha(30) : const Color(0xFFFFF1F1))
                : (isDark ? const Color(0xFF1F2937) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : Colors.grey[500],
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white : const Color(0xFF1F2937)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: Colors.grey[500],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey[300] : const Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? prefixText,
    String? suffixText,
    Widget? prefixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[400]),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
      suffixText: suffixText,
      suffixStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildNetworkOrFileImage(String path) {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 36, color: Colors.grey)),
      );
    }
  }
}
