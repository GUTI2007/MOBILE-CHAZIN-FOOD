import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
  }) {
    try {
      final overlayState = Overlay.maybeOf(context) ?? Navigator.of(context).overlay;
      if (overlayState == null) {
        // Fallback to standard SnackBar if overlay is not available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $message'),
            backgroundColor: isError ? Colors.red : Colors.green,
          ),
        );
        return;
      }

      late OverlayEntry overlayEntry;
      overlayEntry = OverlayEntry(
        builder: (context) => _CustomToastWidget(
          title: title,
          message: message,
          isError: isError,
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      );

      overlayState.insert(overlayEntry);
    } catch (e) {
      debugPrint("CustomToast overlay show error: $e");
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $message'),
            backgroundColor: isError ? Colors.red : Colors.green,
          ),
        );
      } catch (_) {}
    }
  }
}

class _CustomToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _CustomToastWidget({
    required this.title,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_CustomToastWidget> createState() => _CustomToastWidgetState();
}

class _CustomToastWidgetState extends State<_CustomToastWidget> {
  Offset _offset = const Offset(0.0, -1.5);
  double _opacity = 0.0;
  Timer? _dismissTimer;
  Timer? _removeTimer;

  @override
  void initState() {
    super.initState();
    // Animación de entrada: deslizamiento desde arriba y fade in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _offset = Offset.zero;
          _opacity = 1.0;
        });
      }
    });

    // Iniciar temporizador para la salida
    _dismissTimer = Timer(const Duration(milliseconds: 2800), () {
      _triggerExit();
    });
  }

  void _triggerExit() {
    if (mounted) {
      setState(() {
        _offset = const Offset(1.5, 0.0); // Desplazamiento rápido a la derecha
        _opacity = 0.0;
      });
    }
    _removeTimer = Timer(const Duration(milliseconds: 400), () {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = widget.isError
        ? (isDark ? const Color(0xFF3F2020) : const Color(0xFFFDF2F2))
        : (isDark ? const Color(0xFF1E3A2F) : const Color(0xFFF0FDF4));

    final Color borderColor = widget.isError
        ? const Color(0xFFF87171)
        : const Color(0xFF4ADE80);

    final Color titleColor = widget.isError
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    final Color descColor = isDark
        ? Colors.white70
        : const Color(0xFF374151);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: AnimatedSlide(
            offset: _offset,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.isError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: titleColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: descColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _triggerExit,
                        child: Icon(
                          Icons.close_rounded,
                          color: descColor.withAlpha(153),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
