import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/custom_toast.dart';

/// Painter para la rejilla de puntos (grid de 8x8) en la esquina superior derecha
class DotGridPainter extends CustomPainter {
  final Color color;

  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double spacing = 14.0;
    const double radius = 2.0;

    // Dibujar cuadrícula de 8x8
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        canvas.drawCircle(
          Offset(size.width - 24 - (i * spacing), 24 + (j * spacing)),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  
  // Login Form Keys & Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).login(
          _loginEmailController.text,
          _loginPasswordController.text,
        );

    if (success && mounted) {
      CustomToast.show(
        context,
        title: 'Sesión iniciada',
        message: '¡Bienvenido al sistema!',
      );
    }

    if (!success && mounted) {
      final error = ref.read(authProvider).error;
      if (error != null) {
        CustomToast.show(
          context,
          title: 'Error de inicio de sesión',
          message: error,
          isError: true,
        );
      }
    }
  }

  // Deleted unused _handleRegister method

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkGradient
              : const LinearGradient(
                  colors: [
                    Color(0xFFFCF8F7), // Soft cream/pink
                    Color(0xFFF3ECEB), // Slightly darker soft pink
                    Color(0xFFEAEAEE), // Soft greyish blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ─── Dotted Grid Background ───
              if (!isDark)
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotGridPainter(
                      color: AppColors.primary.withAlpha(20),
                    ),
                  ),
                ),

              // ─── Main Content ───
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.lg, vertical: AppDimens.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppDimens.md),
                      // ─── Logo Chazin Food personalizado estilo Figma ───
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withAlpha(51), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.asset(
                                  'assets/chazin_logo.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Gorro de chef badge sobrepuesto con animación de rebote
                          Positioned(
                            top: -2,
                            right: -2,
                            child: AnimatedBuilder(
                              animation: _bounceAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _bounceAnimation.value),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE25858),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CustomPaint(
                                    size: const Size(16, 16),
                                    painter: ChefHatPainter(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.lg),

                      // ─── Title & Subtitle ───
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '✨ Sistema de Gestión ✨',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: AppDimens.xl),

                      // ─── Card Container con Login ───
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420), // Exact mobile size simulation on web
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 51 : 13),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white.withAlpha(26) : Colors.black.withAlpha(5),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Red top line to match the Figma mockup exactly
                              Container(
                                height: 4,
                                width: double.infinity,
                                color: AppColors.primary,
                              ),
                              // ─── Custom Tab Header (Single Tab layout) ───
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.primary,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.login_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Iniciar Sesión',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppDimens.lg),
                                child: _buildLoginTab(authState, isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.md),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOGIN VIEW ───
  Widget _buildLoginTab(AuthState authState, bool isDark) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correo Electrónico',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF2D2E33),
            ),
          ),
          const SizedBox(height: 6),
          _customInput(
            hint: 'cliente@chazinfood.com',
            controller: _loginEmailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimens.md),
          Text(
            'Contraseña',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF2D2E33),
            ),
          ),
          const SizedBox(height: 6),
          _customInput(
            hint: '••••••••',
            controller: _loginPasswordController,
            validator: Validators.password,
            obscureText: _loginObscure,
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _loginObscure = !_loginObscure),
            ),
            isDark: isDark,
          ),
          const SizedBox(height: AppDimens.lg),
          AppButton(
            text: 'Iniciar Sesión',
            onPressed: _handleLogin,
            isLoading: authState.isLoading,
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: AppDimens.md),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _RecoverPasswordScreen()),
                );
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Deleted unused _buildRegisterTab view

  // ─── Helper para Input con Styling Exacto del Figma ───
  Widget _customInput({
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white, // White color text entered by user as in the mockup
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: isDark ? Colors.white38 : const Color(0xFFE2E8F0),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDark 
            ? AppColors.cardDark 
            : const Color(0xFFBFC2D0), // Exact grey background color from Figma mockups
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFBFC2D0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFBFC2D0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        prefixIcon: prefixIcon,
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primary;
          }
          return isDark ? Colors.white38 : const Color(0xFF7E818C);
        }),
        suffixIcon: suffixIcon,
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return AppColors.primary;
          }
          return isDark ? Colors.white38 : const Color(0xFF7E818C);
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════
// RECOVER PASSWORD SCREEN (inline private)
// ════════════════════════════════════════════

class _RecoverPasswordScreen extends StatefulWidget {
  const _RecoverPasswordScreen();

  @override
  State<_RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<_RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _loading = false;
        _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 280,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Volver al inicio de sesión',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: _sent ? _buildSentState(isDark) : _buildForm(isDark),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Red circular mail icon badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE25858),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE25858).withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.email_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 28),
          // Title
          Text(
            '¿Olvidaste tu contraseña?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Ingresa tu correo electrónico y te enviaremos las instrucciones para restablecer tu contraseña.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Email label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Correo Electrónico',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Email field
          TextFormField(
            controller: _emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'tu@correo.com',
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white30 : const Color(0xFFAEB5C0),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                size: 20,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE25858), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Send button
          AppButton(
            text: 'Enviar instrucciones',
            onPressed: _handleSend,
            isLoading: _loading,
            icon: Icons.send_rounded,
          ),
          const SizedBox(height: 24),
          // Footer link
          GestureDetector(
            onTap: () {
              if (!_loading) _handleSend();
            },
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                children: [
                  const TextSpan(text: '¿No recibiste el correo? '),
                  TextSpan(
                    text: 'Intentar nuevamente',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE25858),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSentState(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 48),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.linkSent,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            AppStrings.linkSentDesc,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          text: AppStrings.backToLogin,
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true,
        ),
      ],
    );
  }
}

class ChefHatPainter extends CustomPainter {
  final Color color;

  ChefHatPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double w = size.width;
    final double h = size.height;

    // Start bottom left of the puffs
    path.moveTo(w * 0.28, h * 0.65);
    
    // Left puff
    path.cubicTo(
      w * 0.12, h * 0.55,
      w * 0.15, h * 0.35,
      w * 0.33, h * 0.38,
    );
    
    // Center puff
    path.cubicTo(
      w * 0.38, h * 0.18,
      w * 0.62, h * 0.18,
      w * 0.67, h * 0.38,
    );
    
    // Right puff
    path.cubicTo(
      w * 0.85, h * 0.35,
      w * 0.88, h * 0.55,
      w * 0.72, h * 0.65,
    );
    
    canvas.drawPath(path, paint);

    // Draw the band at the bottom
    final bandPath = Path()
      ..moveTo(w * 0.28, h * 0.65)
      ..lineTo(w * 0.72, h * 0.65)
      ..lineTo(w * 0.70, h * 0.82)
      ..lineTo(w * 0.30, h * 0.82)
      ..close();
      
    canvas.drawPath(bandPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
