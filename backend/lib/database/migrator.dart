import 'package:postgres/postgres.dart';
import 'database.dart';
import 'migrations/migrations.dart';

/// Datenbank-Migrator
class Migrator {
  final Database _db;

  Migrator(this._db);

  /// Alle ausstehenden Migrationen ausführen
  Future<void> migrate() async {
    await _ensureMigrationsTable();

    final executed = await _getExecutedMigrations();
    final pending = migrations.where((m) => !executed.contains(m.version)).toList();

    if (pending.isEmpty) {
      print('✅ Keine ausstehenden Migrationen');
      return;
    }

    print('📦 ${pending.length} Migration(en) ausstehend...');

    for (final migration in pending) {
      print('   ⏳ Migration ${migration.version}: ${migration.name}');

      await _db.transaction((tx) async {
        // Split multi-statement SQL, respecting dollar-quoted blocks ($$...$$)
        for (final stmt in _splitSql(migration.up)) {
          await tx.execute(stmt);
        }

        // Migration als ausgeführt markieren
        await tx.execute(
          Sql.named('''
            INSERT INTO _migrations (version, name, executed_at)
            VALUES (@version, @name, NOW())
          '''),
          parameters: {
            'version': migration.version,
            'name': migration.name,
          },
        );
      });

      print('   ✅ Migration ${migration.version} abgeschlossen');
    }

    print('✅ Alle Migrationen abgeschlossen');
  }

  /// Migrations-Tabelle erstellen (falls nicht vorhanden)
  Future<void> _ensureMigrationsTable() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        version INTEGER NOT NULL UNIQUE,
        name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    ''');
  }

  /// Bereits ausgeführte Migrationen abrufen
  Future<Set<int>> _getExecutedMigrations() async {
    final result = await _db.queryAll('SELECT version FROM _migrations');
    return result.map((r) => r['version'] as int).toSet();
  }

  /// Letzte Migration rückgängig machen
  Future<void> rollback() async {
    final executed = await _db.queryAll(
      'SELECT version, name FROM _migrations ORDER BY version DESC LIMIT 1',
    );

    if (executed.isEmpty) {
      print('⚠️ Keine Migrationen zum Zurückrollen');
      return;
    }

    final version = executed.first['version'] as int;
    final name = executed.first['name'] as String;
    final migration = migrations.firstWhere((m) => m.version == version);

    print('⏪ Rollback Migration $version: $name');

    await _db.transaction((tx) async {
      for (final stmt in _splitSql(migration.down)) {
        await tx.execute(stmt);
      }
      await tx.execute(
        Sql.named('DELETE FROM _migrations WHERE version = @version'),
        parameters: {'version': version},
      );
    });

    print('✅ Rollback abgeschlossen');
  }

  /// Status der Migrationen anzeigen
  Future<void> status() async {
    await _ensureMigrationsTable();
    final executed = await _getExecutedMigrations();

    print('');
    print('=== Migrations-Status ===');
    for (final migration in migrations) {
      final status = executed.contains(migration.version) ? '✅' : '⏳';
      print('$status ${migration.version}: ${migration.name}');
    }
    print('=========================');
    print('');
  }
}

/// Split a SQL script into individual statements, respecting dollar-quoted
/// blocks (e.g. $$ ... $$ used in PL/pgSQL functions).
List<String> _splitSql(String sql) {
  final statements = <String>[];
  final buf = StringBuffer();
  bool inDollarQuote = false;
  int i = 0;

  while (i < sql.length) {
    // Check for start/end of $$ dollar-quote
    if (i + 1 < sql.length && sql[i] == r'$' && sql[i + 1] == r'$') {
      inDollarQuote = !inDollarQuote;
      buf.write(r'$$');
      i += 2;
      continue;
    }

    final ch = sql[i];
    if (ch == ';' && !inDollarQuote) {
      final stmt = buf.toString().trim();
      if (stmt.isNotEmpty) statements.add(stmt);
      buf.clear();
    } else {
      buf.write(ch);
    }
    i++;
  }

  // Remaining text after last semicolon
  final remaining = buf.toString().trim();
  if (remaining.isNotEmpty) statements.add(remaining);

  return statements;
}

/// Migration Basis-Klasse
class Migration {
  final int version;
  final String name;
  final String up;
  final String down;

  const Migration({
    required this.version,
    required this.name,
    required this.up,
    required this.down,
  });
}
