import 'dart:convert';
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
    await _openConnection();
  }

  Future<void> _openConnection() async {
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

  /// Verbindet mit Wiederholungsversuchen statt einmalig aufzugeben.
  ///
  /// Wichtig für den Server-Start: `depends_on: condition: service_healthy`
  /// in docker-compose greift nur, wenn der Stack über `docker compose up`
  /// gestartet wird — nach einem Host-/Docker-Daemon-Neustart startet Docker
  /// einzelne Container unabhängig von dieser Reihenfolge neu. Ohne Retry
  /// blieb der Server dann dauerhaft ohne Datenbankverbindung hängen, bis er
  /// manuell neu gestartet wurde (siehe Vorfall 2026-07-31).
  ///
  /// [maxAttempts] = null bedeutet: unbegrenzt weiterversuchen (Standard für
  /// den Server-Start — irgendwann wird Postgres bereit sein).
  Future<void> connectWithRetry({
    int? maxAttempts,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        await _openConnection();
        return;
      } catch (e) {
        final limitText = maxAttempts != null ? '/$maxAttempts' : '';
        if (maxAttempts != null && attempt >= maxAttempts) {
          print('❌ Datenbank nach $attempt Versuchen weiterhin nicht erreichbar: $e');
          rethrow;
        }
        print(
          '⚠️  Datenbank noch nicht erreichbar (Versuch $attempt$limitText), '
          'erneuter Versuch in ${retryDelay.inSeconds}s: $e',
        );
        await Future.delayed(retryDelay);
      }
    }
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

  /// SQL-Query ausführen.
  ///
  /// Self-healing in zwei Fällen:
  /// - Verbindung ist (noch) gar nicht aufgebaut: wird hier einmalig
  ///   nachgeholt, bevor die *erste* Ausführung dieser Query beginnt — das ist
  ///   gefahrlos, weil die Query so noch nicht gelaufen ist.
  /// - Verbindung stirbt *während/nach* der Ausführung (Netzwerkabbruch): wird
  ///   für den nächsten Request neu aufgebaut, die aktuelle Query aber bewusst
  ///   NICHT automatisch wiederholt — bei nicht-idempotenten Statements (z. B.
  ///   INSERT) wüssten wir sonst nicht, ob der erste Versuch serverseitig
  ///   eventuell schon durchgelaufen ist, bevor die Verbindung abbrach.
  Future<Result> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    if (_connection == null) {
      try {
        await _openConnection();
      } catch (e) {
        throw DatabaseException(
          'Keine Datenbankverbindung (Wiederverbindungsversuch fehlgeschlagen: $e)',
        );
      }
    }

    try {
      return await connection.execute(
        Sql.named(sql),
        parameters: parameters ?? {},
      );
    } catch (e) {
      if (_looksLikeConnectionFailure(e)) {
        print('⚠️  Datenbankverbindung verloren, baue sie fürs nächste Mal neu auf: $e');
        _connection = null;
        try {
          await _openConnection();
        } catch (reconnectError) {
          print('❌ Wiederverbindung fehlgeschlagen: $reconnectError');
        }
      }
      rethrow;
    }
  }

  bool _looksLikeConnectionFailure(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('connection closed') ||
        text.contains('connection reset') ||
        text.contains('broken pipe') ||
        text.contains('connection refused');
  }

  /// Einzelne Zeile abrufen
  Future<Map<String, dynamic>?> queryOne(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    if (result.isEmpty) return null;
    return _decodeRow(result.first.toColumnMap());
  }

  /// Alle Zeilen abrufen
  Future<List<Map<String, dynamic>>> queryAll(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await query(sql, parameters: parameters);
    return result.map((row) => _decodeRow(row.toColumnMap())).toList();
  }

  /// Decode UndecodedBytes (enum values returned by postgres 3.x) as UTF-8 strings.
  /// In postgres 3.x, UndecodedBytes is a class with a `bytes` field (List<int>).
  Map<String, dynamic> _decodeRow(Map<String, dynamic> row) {
    return row.map((key, value) {
      if (value == null || value is bool || value is num ||
          value is String || value is DateTime || value is Map) {
        return MapEntry(key, value);
      }
      // Try to access .bytes property (UndecodedBytes in postgres 3.x)
      try {
        final dynamic d = value;
        final bytes = d.bytes as List<int>;
        return MapEntry(key, utf8.decode(bytes));
      } catch (_) {}
      // Fallback: try treating it as List<int> directly
      if (value is List) {
        try {
          return MapEntry(
              key, utf8.decode(value.map((e) => e as int).toList()));
        } catch (_) {}
      }
      return MapEntry(key, value);
    });
  }

  /// Transaktion ausführen
  Future<T> transaction<T>(Future<T> Function(TxSession tx) action) async {
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
