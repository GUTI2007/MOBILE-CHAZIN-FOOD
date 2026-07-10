import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/products_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isActive = true;
  bool _isSaving = false;
  String? _imageUrl;

  late final TextEditingController _prepProcedureController;
  late final TextEditingController _prepTimeController;
  late final TextEditingController _portionsController;
  late final TextEditingController _observationsController;
  late final TextEditingController _insumosSearchController;

  final List<Map<String, dynamic>> _mockInsumos = [
    {'name': 'Lechuga', 'category': 'Verduras', 'price': '\$2.000/und', 'unit': 'und'},
    {'name': 'Pollo', 'category': 'Proteínas', 'price': '\$12.000/kg', 'unit': 'kg'},
    {'name': 'Queso Mozzarella', 'category': 'Lácteos', 'price': '\$18.000/kg', 'unit': 'kg'},
    {'name': 'Salchicha Premium', 'category': 'Proteínas', 'price': '\$15.000/kg', 'unit': 'kg'},
    {'name': 'Salsa BBQ', 'category': 'Condimentos', 'price': '\$4.000/und', 'unit': 'und'},
    {'name': 'Pan de hamburguesa', 'category': 'Panadería', 'price': '\$1.500/und', 'unit': 'und'},
    {'name': 'Papas a la francesa', 'category': 'Verduras', 'price': '\$3.000/kg', 'unit': 'kg'},
    {'name': 'Carne de hamburguesa 150g', 'category': 'Proteínas', 'price': '\$4.500/und', 'unit': 'und'},
    {'name': 'Tocineta Ahumada', 'category': 'Proteínas', 'price': '\$22.000/kg', 'unit': 'kg'},
    {'name': 'Queso Cheddar rebanado', 'category': 'Lácteos', 'price': '\$20.000/kg', 'unit': 'kg'},
    {'name': 'Salsa de ajo especial', 'category': 'Condimentos', 'price': '\$3.500/und', 'unit': 'und'},
  ];

  List<Map<String, dynamic>> _adicionesIngredientes = [];
  List<Map<String, dynamic>> _salsas = [];
  List<Map<String, dynamic>> _acompanamientos = [];
  List<Map<String, dynamic>> _bebidas = [];

  bool _adicionesExpanded = true;
  bool _salsasExpanded = true;
  bool _acompanamientosExpanded = true;
  bool _bebidasExpanded = true;

  List<Map<String, dynamic>> _filteredInsumos = [];
  final List<Map<String, dynamic>> _selectedInsumos = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toStringAsFixed(0) : '',
    );
    _selectedCategoryId = widget.product?.categoryId;
    _selectedCategoryName = widget.product?.categoryName;
    _isActive = widget.product?.isActive ?? true;
    _imageUrl = widget.product?.imageUrl;

    _prepProcedureController = TextEditingController();
    _prepTimeController = TextEditingController(text: '0');
    _portionsController = TextEditingController();
    _observationsController = TextEditingController();
    _insumosSearchController = TextEditingController();

    _insumosSearchController.addListener(_onSearchChanged);

    _adicionesIngredientes = [
      {'nombre': 'Queso extra', 'precio': 2000.0},
      {'nombre': 'Tocineta', 'precio': 3000.0},
      {'nombre': 'Carne extra', 'precio': 5000.0},
    ];
    _salsas = [
      {'nombre': 'Salsa BBQ', 'precio': 1000.0},
      {'nombre': 'Salsa de la casa', 'precio': 0.0},
      {'nombre': 'Salsa picante', 'precio': 500.0},
    ];
    _acompanamientos = [
      {'nombre': 'Papas fritas', 'precio': 4000.0},
      {'nombre': 'Ensalada', 'precio': 3500.0},
    ];
    _bebidas = [
      {'nombre': 'Gaseosa 350ml', 'precio': 4000.0},
      {'nombre': 'Jugo natural', 'precio': 5000.0},
    ];
  }

  void _onSearchChanged() {
    final query = _insumosSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredInsumos = []);
    } else {
      setState(() {
        _filteredInsumos = _mockInsumos
            .where((insumo) => insumo['name'].toString().toLowerCase().contains(query))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _prepProcedureController.dispose();
    _prepTimeController.dispose();
    _portionsController.dispose();
    _observationsController.dispose();
    _insumosSearchController.removeListener(_onSearchChanged);
    _insumosSearchController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      if (_selectedCategoryId == null) {
        CustomToast.show(
          context,
          title: 'Categoría requerida',
          message: 'Por favor selecciona una categoría para el producto',
          isError: true,
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (isEditing) {
        await ref.read(productsProvider.notifier).updateProduct(
              widget.product!.id,
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              price: double.parse(_priceController.text),
              categoryId: _selectedCategoryId,
              categoryName: _selectedCategoryName,
              imageUrl: _imageUrl,
              isActive: _isActive,
            );
      } else {
        await ref.read(productsProvider.notifier).createProduct(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              price: double.parse(_priceController.text),
              categoryId: _selectedCategoryId!,
              categoryName: _selectedCategoryName!,
              imageUrl: _imageUrl,
            );
      }

      if (mounted) {
        CustomToast.show(
          context,
          title: isEditing ? 'Producto actualizado' : 'Producto creado',
          message: isEditing
              ? 'Los cambios se guardaron correctamente'
              : 'El producto fue creado exitosamente',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Error al guardar',
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  bool _fichaTecnicaExpanded = true;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageUrl = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Error al seleccionar imagen',
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Widget _buildImageWidget(String path) {
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image_outlined, size: 40));
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image_outlined, size: 40));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // Don't show default back arrow
        title: Text(
          isEditing ? 'Editar Producto' : 'Nuevo Producto',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white70 : AppColors.grey600),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Imagen del Producto (Figma upload box) ───
              Text(
                'Imagen del Producto',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : AppColors.grey300,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildImageWidget(_imageUrl!),
                            // Remove image / change image action button overlay
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageUrl = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black45,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Haz clic para cambiar la imagen',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                color: isDark ? Colors.white.withAlpha(13) : const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                color: Color(0xFF3B82F6),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Haz clic para subir una imagen',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PNG, JPG hasta 5MB',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? Colors.white30 : AppColors.grey400,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Nombre del Producto ───
              Text(
                'Nombre del Producto',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ej: Hamburguesa Especial',
                  hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : AppColors.grey400),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Categoría (idCategoriaProducto) ───
              Text(
                'Categoría (idCategoriaProducto)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white24 : AppColors.grey300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategoryId,
                    hint: Text(
                      'Seleccionar...',
                      style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white30 : AppColors.grey400),
                    ),
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    items: state.categories
                        .where((c) => c.id != 'cat_all')
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      final cat = state.categories.firstWhere((c) => c.id == value);
                      setState(() {
                        _selectedCategoryId = value;
                        _selectedCategoryName = cat.name;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Precio de Venta ───
              Text(
                'Precio de Venta',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                validator: (v) => v == null || v.isEmpty ? 'Este campo es obligatorio' : null,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : AppColors.textPrimaryLight),
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : AppColors.grey400),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Estado ───
              Text(
                'Estado',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.white24 : AppColors.grey300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: _isActive,
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Disponible'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('No Disponible'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _isActive = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Descripción ───
              Text(
                'Descripción',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Describe el producto...',
                  hintStyle: GoogleFonts.inter(color: isDark ? Colors.white30 : AppColors.grey400),
                  filled: true,
                  fillColor: isDark ? AppColors.cardDark : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Adiciones, Salsas, Acompañamientos, Bebidas ───
              _buildExpandableSection(
                title: 'Adiciones de Ingredientes',
                items: _adicionesIngredientes,
                isExpanded: _adicionesExpanded,
                onToggle: () => setState(() => _adicionesExpanded = !_adicionesExpanded),
                onAdd: () {
                  setState(() {
                    _adicionesIngredientes.add({'nombre': '', 'precio': 0.0});
                  });
                },
                onNameChanged: (idx, val) => _adicionesIngredientes[idx]['nombre'] = val,
                onPriceChanged: (idx, val) => _adicionesIngredientes[idx]['precio'] = val,
                onDelete: (idx) => setState(() => _adicionesIngredientes.removeAt(idx)),
                isDark: isDark,
                textPrimary: isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937),
                textSecondary: isDark ? AppColors.textSecondaryDark : Colors.grey[600]!,
                borderColor: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                cardColor: isDark ? AppColors.cardDark : Colors.white,
              ),

              _buildExpandableSection(
                title: 'Salsas',
                items: _salsas,
                isExpanded: _salsasExpanded,
                onToggle: () => setState(() => _salsasExpanded = !_salsasExpanded),
                onAdd: () {
                  setState(() {
                    _salsas.add({'nombre': '', 'precio': 0.0});
                  });
                },
                onNameChanged: (idx, val) => _salsas[idx]['nombre'] = val,
                onPriceChanged: (idx, val) => _salsas[idx]['precio'] = val,
                onDelete: (idx) => setState(() => _salsas.removeAt(idx)),
                isDark: isDark,
                textPrimary: isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937),
                textSecondary: isDark ? AppColors.textSecondaryDark : Colors.grey[600]!,
                borderColor: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                cardColor: isDark ? AppColors.cardDark : Colors.white,
              ),

              _buildExpandableSection(
                title: 'Acompañamientos',
                items: _acompanamientos,
                isExpanded: _acompanamientosExpanded,
                onToggle: () => setState(() => _acompanamientosExpanded = !_acompanamientosExpanded),
                onAdd: () {
                  setState(() {
                    _acompanamientos.add({'nombre': '', 'precio': 0.0});
                  });
                },
                onNameChanged: (idx, val) => _acompanamientos[idx]['nombre'] = val,
                onPriceChanged: (idx, val) => _acompanamientos[idx]['precio'] = val,
                onDelete: (idx) => setState(() => _acompanamientos.removeAt(idx)),
                isDark: isDark,
                textPrimary: isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937),
                textSecondary: isDark ? AppColors.textSecondaryDark : Colors.grey[600]!,
                borderColor: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                cardColor: isDark ? AppColors.cardDark : Colors.white,
              ),

              _buildExpandableSection(
                title: 'Bebidas',
                items: _bebidas,
                isExpanded: _bebidasExpanded,
                onToggle: () => setState(() => _bebidasExpanded = !_bebidasExpanded),
                onAdd: () {
                  setState(() {
                    _bebidas.add({'nombre': '', 'precio': 0.0});
                  });
                },
                onNameChanged: (idx, val) => _bebidas[idx]['nombre'] = val,
                onPriceChanged: (idx, val) => _bebidas[idx]['precio'] = val,
                onDelete: (idx) => setState(() => _bebidas.removeAt(idx)),
                isDark: isDark,
                textPrimary: isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937),
                textSecondary: isDark ? AppColors.textSecondaryDark : Colors.grey[600]!,
                borderColor: isDark ? Colors.white.withAlpha(20) : const Color(0xFFE5E7EB),
                cardColor: isDark ? AppColors.cardDark : Colors.white,
              ),

              const SizedBox(height: 24),

              // ─── Ficha Técnica (Collapsible panel) ───
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.grey200),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() => _fichaTecnicaExpanded = !_fichaTecnicaExpanded);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              _fichaTecnicaExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: isDark ? Colors.white54 : AppColors.grey600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.assignment_outlined,
                              color: isDark ? Colors.white70 : AppColors.grey700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ficha Técnica',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_fichaTecnicaExpanded) ...[
                      const Divider(height: 1, thickness: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Ingredientes header ──
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                                children: [
                                  TextSpan(
                                    text: 'Ingredientes / Insumos necesarios ',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  TextSpan(
                                    text: '— busca y selecciona',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: isDark ? Colors.white30 : AppColors.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ── Search input ──
                            TextField(
                              controller: _insumosSearchController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search, size: 18, color: isDark ? Colors.white38 : AppColors.grey400),
                                hintText: 'Buscar insumo por nombre...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white38 : AppColors.grey400),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),

                            // ── Search results dropdown ──
                            if (_filteredInsumos.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? Colors.white10 : AppColors.grey200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(13),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(maxHeight: 220),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _filteredInsumos.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: isDark ? Colors.white10 : AppColors.grey100,
                                  ),
                                  itemBuilder: (context, index) {
                                    final insumo = _filteredInsumos[index];
                                    final alreadySelected = _selectedInsumos.any((s) => s['name'] == insumo['name']);
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                      leading: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: alreadySelected ? AppColors.grey300 : const Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        insumo['name'] as String,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: alreadySelected
                                              ? (isDark ? Colors.white30 : AppColors.grey400)
                                              : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                        ),
                                      ),
                                      subtitle: Text(
                                        insumo['category'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: isDark ? Colors.white24 : AppColors.grey400,
                                        ),
                                      ),
                                      trailing: Text(
                                        insumo['price'] as String,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.white54 : AppColors.grey600,
                                        ),
                                      ),
                                      onTap: alreadySelected
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedInsumos.add({
                                                  'name': insumo['name'],
                                                  'category': insumo['category'],
                                                  'qty': 1,
                                                  'unit': insumo['unit'] ?? 'und',
                                                });
                                                _insumosSearchController.clear();
                                                _filteredInsumos = [];
                                              });
                                            },
                                    );
                                  },
                                ),
                              ),

                            const SizedBox(height: 16),

                            // ── Empty state or selected insumos ──
                            if (_selectedInsumos.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 28),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.settings_outlined,
                                      size: 36,
                                      color: isDark ? Colors.white12 : AppColors.grey300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Busca y agrega los insumos necesarios para este\nproducto',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? Colors.white24 : AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              // ── Insumos seleccionados header ──
                              Text(
                                'Insumos seleccionados (${_selectedInsumos.length})',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // ── Table header ──
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(5) : AppColors.grey100,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'INSUMO',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white38 : AppColors.grey500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        'CANTIDAD',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white38 : AppColors.grey500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        'UNIDAD',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white38 : AppColors.grey500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                  ],
                                ),
                              ),

                              // ── Selected insumos rows ──
                              ...List.generate(_selectedInsumos.length, (i) {
                                final insumo = _selectedInsumos[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark ? Colors.white10 : AppColors.grey200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Insumo name
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEF4444),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                insumo['name'] as String,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quantity controls: - qty +
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if ((insumo['qty'] as int) > 1) {
                                                  setState(() => insumo['qty'] = (insumo['qty'] as int) - 1);
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(Icons.remove, size: 14, color: isDark ? Colors.white54 : AppColors.grey600),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                '${insumo['qty']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() => insumo['qty'] = (insumo['qty'] as int) + 1);
                                              },
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(Icons.add, size: 14, color: isDark ? Colors.white54 : AppColors.grey600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      // Unit dropdown
                                      SizedBox(
                                        width: 60,
                                        child: Container(
                                          height: 28,
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: isDark ? Colors.white24 : AppColors.grey300),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: insumo['unit'] as String,
                                              isDense: true,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                              ),
                                              items: const [
                                                DropdownMenuItem(value: 'und', child: Text('und')),
                                                DropdownMenuItem(value: 'kg', child: Text('kg')),
                                                DropdownMenuItem(value: 'g', child: Text('g')),
                                                DropdownMenuItem(value: 'ml', child: Text('ml')),
                                                DropdownMenuItem(value: 'lt', child: Text('lt')),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => insumo['unit'] = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Delete button
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 20,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() => _selectedInsumos.removeAt(i));
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: Icon(
                                            Icons.close,
                                            size: 18,
                                            color: isDark ? Colors.white30 : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            const SizedBox(height: 20),

                            // ── Procedimiento de Preparación ──
                            Text(
                              'Procedimiento de Preparación',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _prepProcedureController,
                              maxLines: 4,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Describe paso a paso cómo se prepara\nel producto...',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Tiempo de Preparación (min) ──
                            Text(
                              'Tiempo de Preparación (min)',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _prepTimeController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Rendimiento / Porciones ──
                            Text(
                              'Rendimiento / Porciones',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _portionsController,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Ej: 1 porción',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Observaciones ──
                            Text(
                              'Observaciones',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _observationsController,
                              maxLines: 3,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Notas adicionales, alergenos,\ncertificaciones, etc.',
                                hintStyle: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white30 : AppColors.grey400),
                                filled: true,
                                fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.grey200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Guardar Ficha Técnica button ──
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  CustomToast.show(
                                    context,
                                    title: 'Ficha técnica guardada',
                                    message: 'Los insumos se vincularon correctamente',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Guardar Ficha Técnica',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Bottom action buttons: Cancelar + Guardar Producto ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? Colors.white24 : AppColors.grey300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        'Guardar Producto',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onAdd,
    required void Function(int, String) onNameChanged,
    required void Function(int, double) onPriceChanged,
    required void Function(int) onDelete,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
    required Color cardColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: title,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '(${items.length})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: Text(
                      'Agregar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE25858),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    children: [
                      // Name Input
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: item['nombre'],
                          onChanged: (val) => onNameChanged(index, val),
                          style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50]!,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price Input
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: (item['precio'] as double).toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            final price = double.tryParse(val) ?? 0.0;
                            onPriceChanged(index, price);
                          },
                          style: GoogleFonts.inter(fontSize: 13, color: textPrimary),
                          decoration: InputDecoration(
                            prefixText: '\$ ',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            fillColor: isDark ? AppColors.surfaceDark : Colors.grey[50]!,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete Icon Button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                        onPressed: () => onDelete(index),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
