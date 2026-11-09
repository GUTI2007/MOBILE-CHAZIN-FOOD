import 'package:intl/intl.dart';
import 'security_sanitizer.dart';

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

  /// Formato moneda COP: $15.000 COP
  static String currency(double amount) => '${_currencyCOP.format(amount)} COP';

  /// Formato fecha: 01/07/2026
  static String date(DateTime date) => _dateFormat.format(date);

  /// Formato fecha y hora: 01/07/2026 14:30
  static String dateTime(DateTime date) => _dateTimeFormat.format(date);

  /// Formato hora: 14:30
  static String time(DateTime date) => _timeFormat.format(date);
}

/// Validadores de formularios con protección contra inyección (OWASP Mobile / MASVS)
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return SecurityValidators.validateNoInjection(value, fieldName: fieldName);
  }

  static String? email(String? value) {
    return SecurityValidators.safeEmail(value);
  }

  static String? password(String? value, {int minLength = 6}) {
    return SecurityValidators.safePassword(value, minLength: minLength);
  }

  static String? number(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    final injectionCheck = SecurityValidators.validateNoInjection(value, fieldName: fieldName);
    if (injectionCheck != null) return injectionCheck;

    if (double.tryParse(value.trim()) == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }

  static String? price(String? value) {
    return SecurityValidators.safePrice(value);
  }

  static String? safeText(String? value, {bool isRequired = true, String label = 'Este campo', int maxLength = 250}) {
    return SecurityValidators.safeText(value, isRequired: isRequired, label: label, maxLength: maxLength);
  }
}
