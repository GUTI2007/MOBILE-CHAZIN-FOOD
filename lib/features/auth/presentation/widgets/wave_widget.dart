import 'package:flutter/material.dart';

/// Ola decorativa inferior
class WaveWidget extends StatelessWidget {
  const WaveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = const LinearGradient(
      colors: [
        Color(0xFFE2E7F3), // Azul/Morado suave a la izquierda
        Color(0xFFFCEAEB), // Rosado/Durazno suave a la derecha
      ],
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.7,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
