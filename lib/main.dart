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

  // El clamping de viewInsets negativos se hace en el builder de MaterialApp
  // dentro de ChazinFoodApp (app.dart). No se necesita ningún wrapper aquí.
  runApp(
    const ProviderScope(
      child: ChazinFoodApp(),
    ),
  );
}
