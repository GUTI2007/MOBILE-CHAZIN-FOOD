/// Utilidades de Seguridad, Sanitización y Validación contra Inyección
/// Diseñado bajo lineamientos MSP, OWASP Mobile Top 10 y MASVS (OWASP MASVS-CODE / MASVS-CRYPTO).
class SecuritySanitizer {
  SecuritySanitizer._();

  // Patrones SQL Injection comunes
  static final RegExp _sqlInjectionPattern = RegExp(
    r"""('|\")\s*(OR|AND)\s+.*=.*|--|#|;|\/\*|\*\/|\b(UNION(\s+ALL)?\s+SELECT|DROP\s+TABLE|INSERT\s+INTO|DELETE\s+FROM|UPDATE\s+.*SET|EXEC(\s|\+)+(s|x)p|SELECT\s+.*FROM)\b""",
    caseSensitive: false,
    multiLine: true,
  );

  // Patrones XSS / Script Injection
  static final RegExp _xssPattern = RegExp(
    r"""<\s*script[^>]*>|<\s*/\s*script\s*>|javascript\s*:|on\w+\s*=|<\s*iframe|<\s*object|<\s*embed|<\s*svg[^>]*on|eval\s*\(|document\.(cookie|location|write)""",
    caseSensitive: false,
    multiLine: true,
  );

  // Caracteres nulos y de control peligrosos
  static final RegExp _controlCharsPattern = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]',
  );

  // Path Traversal
  static final RegExp _pathTraversalPattern = RegExp(
    r'(\.\./|\.\.\\)',
  );

  /// Verifica si una cadena contiene patrones de inyección SQL
  static bool containsSqlInjection(String? input) {
    if (input == null || input.isEmpty) return false;
    return _sqlInjectionPattern.hasMatch(input);
  }
  static bool hasSqlInjection(String? input) => containsSqlInjection(input);

  /// Verifica si una cadena contiene patrones de Cross-Site Scripting (XSS)
  static bool containsXss(String? input) {
    if (input == null || input.isEmpty) return false;
    return _xssPattern.hasMatch(input);
  }
  static bool hasXss(String? input) => containsXss(input);

  /// Verifica si una cadena contiene caracteres nulos o de control no permitidos
  static bool containsControlChars(String? input) {
    if (input == null || input.isEmpty) return false;
    return _controlCharsPattern.hasMatch(input);
  }
  static bool hasControlChars(String? input) => containsControlChars(input);

  /// Verifica si contiene secuencias de Path Traversal
  static bool containsPathTraversal(String? input) {
    if (input == null || input.isEmpty) return false;
    return _pathTraversalPattern.hasMatch(input);
  }

  /// Sanitiza un texto eliminando caracteres de control, tags HTML peligrosos y recortando espacios
  static String sanitize(String? input) {
    if (input == null) return '';
    var clean = input.replaceAll(_controlCharsPattern, '');
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), '');
    return clean.trim();
  }
  static String stripXss(String? input) => sanitize(input);

  /// Elimina únicamente caracteres de control y bytes nulos
  static String stripControlCharacters(String? input) {
    if (input == null) return '';
    return input.replaceAll(_controlCharsPattern, '');
  }

  /// Sanitiza una ruta de URL o endpoint asegurando que no tenga path traversal
  static String sanitizePath(String path) {
    var clean = path.replaceAll(_pathTraversalPattern, '');
    clean = clean.replaceAll(_controlCharsPattern, '');
    return clean;
  }
}

/// Validadores de Seguridad para formularios y campos de texto
class SecurityValidators {
  SecurityValidators._();

  /// Valida que el texto no contenga inyecciones maliciosas (SQL, XSS, NUL)
  static String? validateNoInjection(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) return null;

    if (SecuritySanitizer.containsControlChars(value)) {
      return '$fieldName contiene caracteres de control no permitidos.';
    }

    if (SecuritySanitizer.containsSqlInjection(value)) {
      return 'Entrada no permitida: contiene secuencias o caracteres de inyección SQL.';
    }

    if (SecuritySanitizer.containsXss(value)) {
      return 'Entrada no permitida: contiene scripts o código no autorizado (XSS).';
    }

    return null;
  }

  /// Valida correo electrónico de forma segura con protección contra inyecciones
  static String? safeEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    final trimmed = value.trim();
    if (trimmed.length > 254) {
      return 'El correo no puede exceder 254 caracteres.';
    }

    final injectionError = validateNoInjection(trimmed, fieldName: 'El correo');
    if (injectionError != null) return injectionError;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  /// Valida contraseña segura evitando bytes nulos y verificando longitud
  static String? safePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Este campo es obligatorio';
    }

    if (SecuritySanitizer.containsControlChars(value)) {
      return 'La contraseña no puede contener caracteres nulos o de control.';
    }

    if (value.length < minLength) {
      return 'Mínimo $minLength caracteres';
    }

    if (value.length > 128) {
      return 'Máximo 128 caracteres permitidos';
    }

    return null;
  }

  /// Valida texto seguro general (requerido opcional)
  static String? safeText(String? value, {bool isRequired = true, String label = 'Este campo', int maxLength = 250}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$label es obligatorio' : null;
    }

    if (value.length > maxLength) {
      return '$label no puede exceder $maxLength caracteres.';
    }

    return validateNoInjection(value, fieldName: label);
  }

  /// Valida un número o precio seguro
  static String? safePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio';
    }

    final clean = value.replaceAll('\$', '').replaceAll('.', '').replaceAll('COP', '').trim();
    final parsed = double.tryParse(clean);
    if (parsed == null || parsed <= 0) {
      return 'Ingresa un precio válido';
    }

    if (parsed > 1000000000) {
      return 'Monto fuera de rango permitido';
    }

    return null;
  }
}

