import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import 'widgets/cross_label_input_field.dart';
import 'widgets/wave_widget.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _showPassword = false;
  late AnimationController _chefAnimationController;
  late Animation<double> _chefBounceAnimation;

  @override
  void initState() {
    super.initState();
    _chefAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _chefBounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _chefAnimationController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _chefAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    
    final success = await ref.read(authProvider.notifier).login(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      CustomToast.show(
        context,
        title: '¡Bienvenido!',
        message: 'Inicio de sesión exitoso.',
      );
    } else if (mounted) {
      final error = ref.read(authProvider).error;
      CustomToast.show(
        context,
        title: 'Error de autenticación',
        message: error ?? 'Correo o contraseña incorrectos.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    const brandColor = Color(0xFFFF3E55); // Strawberry Red exact color
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          // ─── 1. Fondo de color rosa muy claro y difuminado, casi blanco ───
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFFF9FA),
            ),
          ),
          // ─── 2. Círculos de gradiente difuminados (Blur) ───
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withOpacity(0.15),
                    brandColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF30475E).withOpacity(0.15),
                    const Color(0xFF30475E).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // ─── 3. Ola decorativa inferior ───
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: WaveWidget(),
          ),

          // ─── 5. Contenido Principal ───
          SafeArea(
            child: Align(
              alignment: isKeyboardOpen ? Alignment.topCenter : Alignment.center,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: isKeyboardOpen ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      if (!isKeyboardOpen) ...[
                        const SizedBox(height: 15),
                        // ─── Logo Chazin Food personalizado con círculos concéntricos y cuadrícula detrás ───
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Cuadrícula de puntos grises posicionado ÚNICAMENTE en la zona del logotipo
                            SizedBox(
                              width: 320,
                              height: 130,
                              child: CustomPaint(
                                painter: _DotGridBehindLogoPainter(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                            ),
                            // Círculo concéntrico exterior difuminado (RadialGradient idéntico al fondo)
                            Container(
                              width: 280,
                              height: 280,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    brandColor.withOpacity(0.24),
                                    brandColor.withOpacity(0.0),
                                  ],
                                  stops: const [0.45, 1.0],
                                ),
                              ),
                            ),
                            // Círculo del logotipo principal (Ajustado a 120) con el Gorro de Chef en la parte superior derecha
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 136,
                                  height: 136,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: brandColor.withOpacity(0.12),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/chazin_logo.png',
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.restaurant_rounded,
                                            size: 48,
                                            color: brandColor,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: AnimatedBuilder(
                                    animation: _chefBounceAnimation,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, _chefBounceAnimation.value),
                                        child: child,
                                      );
                                    },
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: brandColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CustomPaint(
                                        painter: ChefHatPainter(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // Título de la App (Poppins con color exacto)
                      Text(
                        'Chazin Food',
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: brandColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Subtítulo con sparkles emoji custom
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(20, 20),
                            painter: SparklePainter(color: brandColor),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sistema de Gestión',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF30475E),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomPaint(
                            size: const Size(20, 20),
                            painter: SparklePainter(color: brandColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─── Card Principal con Formulario ───
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Línea superior de marca
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                color: brandColor,
                              ),
                            ),
                            
                            // Cabecera que simula el tab activo de Iniciar Sesión (Sin pestaña "Registrarse")
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF2F3),
                                border: Border(
                                  bottom: BorderSide(
                                    color: brandColor,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    color: brandColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Iniciar Sesión',
                                    style: GoogleFonts.poppins(
                                      color: brandColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Campo Correo
                                    CrossLabelInputField(
                                      label: 'Correo Electrónico',
                                      prefixIcon: Icons.mail_outline_rounded,
                                      hintText: 'usuario@chazinfood.com',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Campo requerido';
                                        }
                                        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                        if (!emailRegex.hasMatch(value.trim())) {
                                          return 'Ingresa un correo válido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Campo Contraseña
                                    CrossLabelInputField(
                                      label: 'Contraseña',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      hintText: '........',
                                      controller: _passwordController,
                                      obscureText: !_showPassword,
                                      keyboardType: TextInputType.visiblePassword,
                                      suffixIcon: IconButton(
                                        icon: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Icon(
                                              _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                            Icon(
                                              _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                              color: Colors.grey.shade600,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Campo requerido';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    // Botón Iniciar Sesión con FittedBox para prevenir desbordamientos
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          color: brandColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: brandColor.withOpacity(0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: isLoading ? null : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: isLoading
                                                ? Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        'Ingresando...',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.login_rounded, size: 20, color: Colors.white),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Iniciar Sesión',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Olvidaste Contraseña
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!isLoading) {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => const ForgotPasswordScreen(),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: brandColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS DE SOPORTE PERSONALIZADOS ───

/// Rejilla de puntos decorativa detrás del logo
class _DotGridBehindLogoPainter extends CustomPainter {
  final Color color;
  _DotGridBehindLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 30.0; // Espaciado ampliado para que sobresalga
    const double radius = 3.5;   // Tamaño exacto
    const int rows = 8;
    const int cols = 10;         // Más columnas para que sea más ancho

    // Centrar la cuadrícula dentro de la caja de tamaño asignado
    double startX = (size.width - (cols - 1) * spacing) / 2;
    double startY = (size.height - (rows - 1) * spacing) / 2;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(
          Offset(startX + c * spacing, startY + r * spacing),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sparkles (✨ Unicode Emoji Style with 3 stars) Custom Painter
class SparklePainter extends CustomPainter {
  final Color color;
  SparklePainter({required this.color});

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    double cx = center.dx;
    double cy = center.dy;
    
    path.moveTo(cx, cy - radius); 
    path.quadraticBezierTo(cx, cy, cx + radius, cy); 
    path.quadraticBezierTo(cx, cy, cx, cy + radius); 
    path.quadraticBezierTo(cx, cy, cx - radius, cy); 
    path.quadraticBezierTo(cx, cy, cx, cy - radius); 
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Estrella principal grande en el centro-izquierda (✨)
    _drawSparkle(canvas, Offset(size.width * 0.45, size.height * 0.55), size.width * 0.32, paint);
    // Estrella mediana en la parte superior derecha
    _drawSparkle(canvas, Offset(size.width * 0.8, size.height * 0.25), size.width * 0.18, paint);
    // Estrella pequeña abajo
    _drawSparkle(canvas, Offset(size.width * 0.18, size.height * 0.32), size.width * 0.12, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chef Hat Custom Painter
class ChefHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    double w = size.width;
    double h = size.height;

    // 1. Banda inferior (rectángulo outline)
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.28, h * 0.65, w * 0.72, h * 0.77),
      const Radius.circular(2),
    ));

    // 2. Nube superior (los tres domos outline sin cruces internos)
    final domesPath = Path();
    domesPath.moveTo(w * 0.28, h * 0.65);
    
    // Domo izquierdo
    domesPath.cubicTo(
      w * 0.12, h * 0.52,
      w * 0.24, h * 0.35,
      w * 0.40, h * 0.45,
    );
    // Domo central
    domesPath.cubicTo(
      w * 0.42, h * 0.22,
      w * 0.58, h * 0.22,
      w * 0.60, h * 0.45,
    );
    // Domo derecho
    domesPath.cubicTo(
      w * 0.76, h * 0.35,
      w * 0.88, h * 0.52,
      w * 0.72, h * 0.65,
    );

    canvas.drawPath(path, paint);
    canvas.drawPath(domesPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
