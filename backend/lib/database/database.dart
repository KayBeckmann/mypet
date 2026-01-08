import 'package:postgres/postgres.dart';
import '../config/config.dart';

/// Datenbank-Service mit Connection-Pooling
class Database {
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  Connection? _connection;
  final _config = Config();

  /// Verbindung zur Datenbank herstellen
  Future<void> connect() async {
    if (_connection != null) return;

    final endpoint = Endpoint(
      host: _config.postgresHost,
      port: _config.postgresPort,
      database: _config.postgresDb,
      username: _config.postgresUser,
      password: _config.postgresPassword,
    );

    _connection = await Connection.open(
      endpoint,
      settings: ConnectionSettings(
        sslMode: SslMode.disable, // Für lokale Entwicklung
      ),
    );

    print('✅ Datenbank verbunden: ${_config.postgresDb}@${_config.postgresHost}');
  }

  /// Verbindung schließen
  Future<void> close() async {
    await _connection?.close();
    _connection = null;
    print('🔌 Datenbank-Verbindung geschlossen');
  }

  /// Aktive Verbindung abrufen
  Connection get connection {
    if (_connection == null) {
      throw DatabaseException('Keine Datenbankverbindung. Bitte erst connect() aufrufen.');
    }
    return _connection!;
  }

  /// Prüfen ob verbunden
  bool get isConnected => _connection != null;

  /// SQL-Query ausführen
  Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return await connection.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );
  }

  /// Einzelne Zeile abrufen
  Future<Map<String, dynamic>?> queryOne(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  /// Alle Zeilen abrufen
  Future<List<Map<String, dynamic>>> queryAll(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    return result.map((row) => row.toColumnMap()).toList();
  }

  /// Transaktion ausführen
  Future<T> transaction<T>(Future<T> Function(Connection tx) action) async {
    return await connection.runTx(action);
  }
}

/// Exception für Datenbankfehler
class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
