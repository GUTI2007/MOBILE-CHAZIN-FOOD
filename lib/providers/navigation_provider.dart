import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global que maneja el índice activo en el Shell principal de la app (AppShell)
final appShellIndexProvider = StateProvider<int>((ref) => 0);
