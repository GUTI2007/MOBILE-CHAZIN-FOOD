import 'package:intl/intl.dart';

/// Utilidades de formateo
class Formatters {
  Formatters._();

  static final _currencyCOP = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'es');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'es');
  static final _timeFormat = DateFormat('HH:mm', 'es');

  /// Formato moneda COP: $15.000
  static String currency(double amount) => _currencyCOP.format(amount);

  /// Formato fecha: 01/07/2026
  static String date(DateTime date) => _dateFormat.format(date);

  /// Formato fecha y hora: 01/07/2026 14:30
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Formato hora: 14:30
  static String time(DateTime date) => _timeFormat.format(date);
}

/// Validadores de formularios
class Validators {
  Validators._();

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    if (double.tryParse(value) == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un precio válido';
    }
    return null;
  }
}
