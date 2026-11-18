import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/dark_mode_provider.dart';
import 'routes/app_shell.dart';

class ChazinFoodApp extends ConsumerWidget {
  const ChazinFoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Segunda capa de protección: sanitiza el MediaQuery que inyecta
      // MaterialApp antes de que llegue al árbol de widgets.
      // Esto captura cualquier valor negativo en viewInsets que haya escapado
      // al wrapper del main.dart (ej. al recargar en caliente en Flutter Web).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final safe = mq.copyWith(
          viewInsets: _clampEdgeInsets(mq.viewInsets),
          viewPadding: _clampEdgeInsets(mq.viewPadding),
          padding: _clampEdgeInsets(mq.padding),
        );
        return MediaQuery(
          data: safe,
          child: child!,
        );
      },
      home: const AppShell(),
    );
  }

  /// Clampea cada lado de un [EdgeInsets] a >= 0.0
  static EdgeInsets _clampEdgeInsets(EdgeInsets e) => EdgeInsets.only(
        left: e.left < 0 ? 0 : e.left,
        top: e.top < 0 ? 0 : e.top,
        right: e.right < 0 ? 0 : e.right,
        bottom: e.bottom < 0 ? 0 : e.bottom,
      );
}
