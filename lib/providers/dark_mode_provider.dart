import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global que gestiona el estado del Modo Oscuro
final darkModeProvider = StateProvider<bool>((ref) => false);
