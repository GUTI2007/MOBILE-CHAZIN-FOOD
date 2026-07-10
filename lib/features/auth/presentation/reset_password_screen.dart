import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/custom_toast.dart';
import '../providers/auth_provider.dart';
import 'widgets/cross_label_input_field.dart';
import 'widgets/wave_widget.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showPassword1 = false;
  bool _showPassword2 = false;
  bool _resetSuccess = false;

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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _newPasswordController.text;
    final success = await ref.read(authProvider.notifier).resetPassword(widget.email, newPass);

    if (success && mounted) {
      setState(() {
        _resetSuccess = true;
      });
      CustomToast.show(
        context,
        title: '¡Contraseña actualizada!',
        message: 'Tu contraseña ha sido restablecida correctamente.',
      );

      // Redirigir después de 3 segundos al Login
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (mounted) {
      CustomToast.show(
        context,
        title: 'Error',
        message: 'No se pudo restablecer la contraseña. Inténtalo de nuevo.',
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
            child: Container(color: const Color(0xFFFFF9FA)),
          ),
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

          // ─── Contenido Principal ───
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
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
                      child: !_resetSuccess
                          ? Form(
                              key: _formKey,
                              child: Column(
                                key: const ValueKey('reset_form'),
                                children: [
                                  // Icono circular de reseteo de contraseña (sin gorro de chef)
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [brandColor, Color(0xFFE04343)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Títulos
                                  Text(
                                    'Restablecer Contraseña',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF30475E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Restableciendo contraseña para:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    widget.email,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Campo Nueva Contraseña
                                  CrossLabelInputField(
                                    label: 'Nueva Contraseña',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    hintText: 'Ingresa tu nueva contraseña',
                                    controller: _newPasswordController,
                                    obscureText: !_showPassword1,
                                    keyboardType: TextInputType.visiblePassword,
                                    suffixIcon: IconButton(
                                      icon: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            _showPassword1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          Icon(
                                            _showPassword1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: Colors.grey.shade600,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword1 = !_showPassword1;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo requerido';
                                      }
                                      if (value.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Campo Confirmar Contraseña
                                  CrossLabelInputField(
                                    label: 'Confirmar Contraseña',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    hintText: 'Repite tu contraseña',
                                    controller: _confirmPasswordController,
                                    obscureText: !_showPassword2,
                                    keyboardType: TextInputType.visiblePassword,
                                    suffixIcon: IconButton(
                                      icon: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            _showPassword2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          Icon(
                                            _showPassword2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: Colors.grey.shade600,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword2 = !_showPassword2;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo requerido';
                                      }
                                      if (value != _newPasswordController.text) {
                                        return 'Las contraseñas no coinciden';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // Botón Guardar con FittedBox para prevenir desbordamientos
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
                                                      'Guardando...',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  'Restablecer Contraseña',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              key: const ValueKey('success_reset_state'),
                              children: [
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
                                Text(
                                  '¡Contraseña restablecida!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF30475E),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tu contraseña ha sido actualizada con éxito.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Redirigiendo al inicio de sesión...',
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

