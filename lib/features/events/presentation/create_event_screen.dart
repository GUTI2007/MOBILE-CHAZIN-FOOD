import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/models/event_model.dart';
import '../../events/providers/events_provider.dart';

/// Formulario simple para crear un evento/campaña.
/// Sin wizard, sin pasos, sin Google Fonts — máxima compatibilidad
/// con Flutter Web CanvasKit.
class CreateEventScreen extends ConsumerStatefulWidget {
  final Product? linkedProduct;
  const CreateEventScreen({super.key, this.linkedProduct});

  @override
  ConsumerState<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _tituloCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  String _tipo = '2x1';
  bool _saving = false;

  static const _tipos = ['2x1', 'Descuento %', 'Precio Especial'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo = _tituloCtrl.text.trim();
    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El título es obligatorio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final String tipoBackend;
    double? descuento;
    double? nuevoPrecio;

    switch (_tipo) {
      case '2x1':
        tipoBackend = 'promo_2x1';
      case 'Descuento %':
        tipoBackend = 'descuento';
        descuento = double.tryParse(_valorCtrl.text);
      case 'Precio Especial':
        tipoBackend = 'precio_especial';
        nuevoPrecio = double.tryParse(_valorCtrl.text);
      default:
        tipoBackend = 'promo_2x1';
    }

    final productId = widget.linkedProduct?.id ?? '';
    final ids = productId.isNotEmpty
        ? [int.tryParse(productId)].whereType<int>().toList()
        : <int>[];

    final event = Event(
      nombre: titulo,
      descripcion: '',
      tipoEvento: tipoBackend,
      descuento: descuento,
      nuevoPrecio: nuevoPrecio,
      accionInsumo: null,
      isActive: true,
      estado: 'Activo',
      fechaInicio: null,
      fechaFin: null,
      productosAsociados: ids.isEmpty ? null : ids,
      icono: null,
      isTemporal: false,
    );

    final ok = await ref.read(eventsProvider.notifier).createEvent(event);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar. Intenta de nuevo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text(
          'Crear Evento',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Producto vinculado
            if (widget.linkedProduct != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE65100)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fastfood,
                        color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.linkedProduct!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Título
            const Text(
              'Título del evento *',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tituloCtrl,
              decoration: InputDecoration(
                hintText: 'Ej: Jueves 2×1 Burger',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFFE65100),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tipo de promoción
            const Text(
              'Tipo de promoción',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _tipo,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: _tipos
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tipo = v);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Valor / Descuento (solo si aplica)
            if (_tipo != '2x1') ...[
              Text(
                _tipo == 'Descuento %'
                    ? 'Porcentaje de descuento'
                    : 'Nuevo precio especial (COP)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _valorCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: _tipo == 'Descuento %' ? 'Ej: 15' : 'Ej: 15000',
                  suffixText: _tipo == 'Descuento %' ? '%' : null,
                  prefixText: _tipo == 'Precio Especial' ? r'$' : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE65100),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            const SizedBox(height: 8),

            // Botón guardar
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                    : const Text(
                        'Guardar Evento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
