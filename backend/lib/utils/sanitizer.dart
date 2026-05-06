/// Utility-Funktionen zur Eingabe-Bereinigung
class InputSanitizer {
  /// Entfernt führende/abschließende Leerzeichen und beschränkt die Länge
  static String? sanitizeText(dynamic value, {int maxLength = 1000}) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return str.length > maxLength ? str.substring(0, maxLength) : str;
  }

  /// Sanitiert eine E-Mail-Adresse (lowercase + trim)
  static String? sanitizeEmail(dynamic value) {
    final str = sanitizeText(value, maxLength: 255);
    return str?.toLowerCase();
  }

  /// Sanitiert einen Namen (max 255 Zeichen, keine Zeilenumbrüche)
  static String? sanitizeName(dynamic value) {
    final str = sanitizeText(value, maxLength: 255);
    return str?.replaceAll(RegExp(r'[\r\n\t]'), ' ');
  }

  /// Prüft ob ein String eine gültige UUID ist
  static bool isValidUuid(String? value) {
    if (value == null) return false;
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  /// Prüft ob ein String eine gültige E-Mail-Adresse ist
  static bool isValidEmail(String? value) {
    if (value == null || value.isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
  }

  /// Sanitiert einen Telefon-String
  static String? sanitizePhone(dynamic value) {
    final str = sanitizeText(value, maxLength: 50);
    return str?.replaceAll(RegExp(r'[^\d\s+\-().ext]'), '');
  }

  /// Begrenzt eine Zahl auf einen Bereich
  static int clampInt(dynamic value, {required int min, required int max, int defaultValue = 0}) {
    if (value == null) return defaultValue;
    final i = int.tryParse(value.toString()) ?? defaultValue;
    return i.clamp(min, max);
  }
}
