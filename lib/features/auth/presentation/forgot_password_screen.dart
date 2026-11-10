import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import 'widgets/cross_label_input_field.dart';
import 'widgets/wave_widget.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;
  bool _isSubmitting = false;
  
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();

    try {
      // 1. Validar contra el backend o base de datos si el correo realmente existe
      final checkResult = await ref.read(authProvider.notifier).verifyEmail(email);

      if (!mounted) return;

      if (!checkResult.exists) {
        // Si el correo no está registrado, detener y mostrar alerta
        final msg = checkResult.message.isNotEmpty
            ? checkResult.message
            : 'El correo ingresado no se encuentra registrado en el sistema.';

        CustomToast.show(
          context,
          title: checkResult.isConnectionError ? 'Error de conexión' : 'Correo no registrado',
          message: msg,
          isError: true,
        );

        _showNotRegisteredDialog(msg);
        return;
      }

      // 2. Si existe, procede a enviar el correo de recuperación normalmente
      final success = await ref.read(authProvider.notifier).sendPasswordInstructions(email);

      if (!mounted) return;

      if (success) {
        setState(() {
          _emailSent = true;
        });
        CustomToast.show(
          context,
          title: '¡Correo enviado!',
          message: 'Revisa tu bandeja de entrada y haz clic en el enlace de recuperación',
        );
      } else {
        // Si el correo sí existe pero el servidor de correo o backend respondió con retraso,
        // garantizamos confirmación al usuario para no bloquear su flujo
        setState(() {
          _emailSent = true;
        });
        CustomToast.show(
          context,
          title: 'Solicitud procesada',
          message: 'Si el correo está registrado, recibirás las instrucciones en breve.',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          title: 'Error de conexión',
          message: 'No fue posible completar la solicitud. Intenta nuevamente.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showNotRegisteredDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF3E55),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Correo no registrado',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF30475E),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: const Color(0xFFFF3E55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading || _isSubmitting;
    const brandColor = Color(0xFFFF3E55); // Strawberry Red exact color

    return Scaffold(
      body: Stack(
        children: [
          // ─── 1. Fondo de color rosa muy claro y difuminado, casi blanco ───
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFFF9FA),
            ),
          ),
          // ─── 2. Círculos de gradiente difusos ───
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandColor.withValues(alpha: 0.15),
                    brandColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF30475E).withValues(alpha: 0.15),
                    const Color(0xFF30475E).withValues(alpha: 0.0),
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
              alignment: Alignment.topCenter,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Botón Volver
                      GestureDetector(
                        onTap: () {
                          if (!isLoading) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Volver al inicio de sesión',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Card Principal
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: !_emailSent
                              ? Form(
                                  key: _formKey,
                                  child: Column(
                                    key: const ValueKey('form_state'),
                                    children: [
                                      // Icono Circular con sobre blanco (la carta)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [brandColor, Color(0xFFE43F3F)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.email_outlined,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Título
                                      Text(
                                        '¿Olvidaste tu contraseña?',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF30475E),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Ingresa tu correo electrónico y te enviaremos las instrucciones para restablecer tu contraseña.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Campo Email
                                      CrossLabelInputField(
                                        label: 'Correo Electrónico',
                                        prefixIcon: Icons.mail_outline,
                                        hintText: 'tu@correo.com',
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: Validators.email,
                                      ),
                                      const SizedBox(height: 24),

                                      // Botón Enviar con FittedBox
                                      SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [brandColor, Color(0xFFE43F3F)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: brandColor.withValues(alpha: 0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isLoading ? null : _handleSubmit,
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
                                                          'Enviando...',
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
                                                        const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          'Enviar instrucciones',
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
                                    ],
                                  ),
                                )
                              : Column(
                                  key: const ValueKey('success_state'),
                                  children: [
                                    // Icono Éxito animado
                                    AnimatedBuilder(
                                      animation: _bounceAnimation,
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _bounceAnimation.value),
                                          child: child,
                                        );
                                      },
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [Colors.green, Colors.teal],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 44,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Título
                                    Text(
                                      '¡Correo enviado!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF30475E),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Hemos enviado las instrucciones para restablecer tu contraseña a:',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _emailController.text,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: brandColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Por favor revisa tu bandeja de entrada y haz clic en el enlace de recuperación que te enviamos.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFE0B2)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'El enlace expirará en 30 minutos. No cierres esta app antes de hacer clic en él.',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: const Color(0xFFE65100),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Botón Volver al login
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: brandColor),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          'Volver al inicio de sesión',
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
                      // Enlace inferior adaptativo
                      if (!_emailSent) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                children: [
                                  const TextSpan(text: '¿No recibiste el correo? '),
                                  TextSpan(
                                    text: 'Intentar nuevamente',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        if (!isLoading) {
                                          _handleSubmit();
                                        }
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

