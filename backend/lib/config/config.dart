import 'dart:io';

/// Zentrale Konfigurationsklasse für alle Umgebungsvariablen
class Config {
  // Singleton
  static final Config _instance = Config._internal();
  factory Config() => _instance;
  Config._internal();

  // ===== Datenbank =====
  String get postgresHost => _env('POSTGRES_HOST', 'localhost');
  int get postgresPort => int.parse(_env('POSTGRES_PORT', '5432'));
  String get postgresDb => _env('POSTGRES_DB', 'mypet');
  String get postgresUser => _env('POSTGRES_USER', 'mypet_user');
  String get postgresPassword => _env('POSTGRES_PASSWORD', 'secret');

  // ===== Server =====
  int get backendPort => int.parse(_env('BACKEND_PORT', '8080'));

  // ===== JWT =====
  String get jwtSecret => _env('JWT_SECRET', 'change-me-in-production');
  int get jwtExpiry => int.parse(_env('JWT_EXPIRY', '3600'));

  // ===== Verschlüsselung =====
  String get encryptionKey => _env('ENCRYPTION_KEY', 'change-me-in-production');

  // ===== Datei-Upload =====
  String get uploadPath => _env('UPLOAD_PATH', '/app/uploads');
  int get maxFileSize => int.parse(_env('MAX_FILE_SIZE', '10485760'));

  // ===== E-Mail (optional) =====
  String? get smtpHost => _envOptional('SMTP_HOST');
  int? get smtpPort => _envOptionalInt('SMTP_PORT');
  String? get smtpUser => _envOptional('SMTP_USER');
  String? get smtpPassword => _envOptional('SMTP_PASSWORD');
  String? get smtpFrom => _envOptional('SMTP_FROM');

  // ===== Entwicklung =====
  bool get debug => _env('DEBUG', 'false').toLowerCase() == 'true';
  String get logLevel => _env('LOG_LEVEL', 'info');

  /// Hilfsmethode: Umgebungsvariable mit Fallback
  String _env(String key, String defaultValue) {
    return Platform.environment[key] ?? defaultValue;
  }

  /// Hilfsmethode: Optionale Umgebungsvariable
  String? _envOptional(String key) {
    return Platform.environment[key];
  }

  /// Hilfsmethode: Optionale Int-Umgebungsvariable
  int? _envOptionalInt(String key) {
    final value = Platform.environment[key];
    return value != null ? int.tryParse(value) : null;
  }

  /// Validiert kritische Konfigurationswerte
  void validate() {
    final errors = <String>[];

    if (jwtSecret == 'change-me-in-production' && !debug) {
      errors.add('JWT_SECRET muss in Produktion gesetzt werden');
    }

    if (encryptionKey == 'change-me-in-production' && !debug) {
      errors.add('ENCRYPTION_KEY muss in Produktion gesetzt werden');
    }

    if (errors.isNotEmpty) {
      throw ConfigurationException(errors);
    }
  }

  /// Debug-Ausgabe der Konfiguration (ohne sensible Daten)
  void printConfig() {
    print('=== MyPet Backend Konfiguration ===');
    print('Server Port: $backendPort');
    print('Database: $postgresUser@$postgresHost:$postgresPort/$postgresDb');
    print('Debug Mode: $debug');
    print('Log Level: $logLevel');
    print('===================================');
  }
}

/// Exception für Konfigurationsfehler
class ConfigurationException implements Exception {
  final List<String> errors;

  ConfigurationException(this.errors);

  @override
  String toString() {
    return 'Konfigurationsfehler:\n${errors.map((e) => '  - $e').join('\n')}';
  }
}
