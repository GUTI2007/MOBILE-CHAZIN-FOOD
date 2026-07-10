import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input estilizado con etiqueta flotante, borde dinámico y cambio de color cuando tiene datos
class CrossLabelInputField extends StatefulWidget {
  final String label;
  final IconData prefixIcon;
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  const CrossLabelInputField({
    super.key,
    required this.label,
    required this.prefixIcon,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.validator,
  });

  @override
  State<CrossLabelInputField> createState() => _CrossLabelInputFieldState();
}

class _CrossLabelInputFieldState extends State<CrossLabelInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF3E55);
    final hasData = widget.controller.text.isNotEmpty;

    // Colores dinámicos basados en si el campo tiene texto (isNotEmpty)
    final fillColor = hasData 
        ? const Color(0xFFB0B7C3) 
        : (_isFocused ? const Color(0xFFFFF2F3) : const Color(0xFFFCFDFD));
    final textColor = hasData ? Colors.white : const Color(0xFF30475E);
    final iconColor = _isFocused 
        ? brandColor 
        : (hasData ? const Color(0xFF8E95A5) : Colors.grey.shade400);
    final borderColor = _isFocused 
        ? brandColor 
        : (hasData ? const Color(0xFFB0B7C3) : Colors.grey.shade200);
        
    final suffixIconColor = hasData 
        ? Colors.white.withOpacity(0.85) 
        : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF30475E),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: brandColor.withOpacity(0.08),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: GoogleFonts.poppins(
                color: hasData ? Colors.white.withOpacity(0.7) : Colors.grey.shade400,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: iconColor,
                size: 20,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? Theme(
                      data: Theme.of(context).copyWith(
                        iconTheme: IconThemeData(color: suffixIconColor),
                      ),
                      child: widget.suffixIcon!,
                    )
                  : null,
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: borderColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.red.shade300,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.red.shade500,
                  width: 1.5,
                ),
              ),
              errorStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
