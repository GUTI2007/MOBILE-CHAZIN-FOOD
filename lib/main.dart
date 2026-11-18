import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Estilo del status bar (ignorado en Flutter Web, inofensivo)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Orientación vertical fija (ignorado en Flutter Web, inofensivo)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      // MediaQuery.fromView envuelve la app con datos de ventana seguros,
      // evitando la excepción _viewInsets.isNonNegative en Flutter Web
      // cuando el viewport cambia de tamaño dinámicamente.
      child: _SafeMediaQueryWrapper(
        child: ChazinFoodApp(),
      ),
    ),
  );
}

/// Envuelve la app con un MediaQuery derivado de la vista principal del motor,
/// garantizando que viewInsets, viewPadding y padding siempre sean >= 0.
/// Esto previene la aserción _viewInsets.isNonNegative en Flutter Web.
class _SafeMediaQueryWrapper extends StatelessWidget {
  final Widget child;
  const _SafeMediaQueryWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.fromView(
      view: View.of(context),
      child: child,
    );
  }
}
