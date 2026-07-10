import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import 'widgets/cross_label_input_field.dart';
import 'widgets/wave_widget.dart';
import 'reset_password_screen.dart';

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
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text;
    final success = await ref.read(authProvider.notifier).sendPasswordInstructions(email);

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
      CustomToast.show(
        context,
        title: '¡Correo enviado!',
        message: 'Revisa tu bandeja de entrada para restablecer tu contraseña',
      );

      // Redirigir después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          final mockToken = base64Encode(utf8.encode('$email${DateTime.now().millisecondsSinceEpoch}'));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: email, token: mockToken),
            ),
          );
        }
      });
    } else if (mounted) {
      CustomToast.show(
        context,
        title: 'Error',
        message: 'Por favor ingresa un correo electrónico válido',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
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
                    brandColor.withOpacity(0.15),
                    brandColor.withOpacity(0.0),
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
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
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
                                                color: brandColor.withOpacity(0.3),
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
                                      'Redirigiendo a la página de restablecimiento...',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontStyle: FontStyle.italic,
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

