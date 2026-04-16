import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:mypet_backend/config/config.dart';
import 'package:mypet_backend/database/database.dart';
import 'package:mypet_backend/database/migrator.dart';
import 'package:mypet_backend/middleware/logging_middleware.dart';
import 'package:mypet_backend/middleware/auth_middleware.dart';
import 'package:mypet_backend/controllers/health_controller.dart';
import 'package:mypet_backend/controllers/auth_controller.dart';
import 'package:mypet_backend/controllers/account_controller.dart';
import 'package:mypet_backend/controllers/pet_controller.dart';

void main(List<String> args) async {
  // Konfiguration laden
  final config = Config();

  // Konfiguration ausgeben (Debug)
  if (config.debug) {
    config.printConfig();
  }

  // Datenbank verbinden
  final db = Database();
  try {
    await db.connect();
  } catch (e) {
    print('❌ Datenbank-Verbindung fehlgeschlagen: $e');
    print('   Starte Server ohne Datenbank...');
  }

  // Migrationen ausführen (wenn --migrate oder -m übergeben)
  if (args.contains('--migrate') || args.contains('-m')) {
    if (!db.isConnected) {
      print('❌ Kann Migrationen nicht ausführen: Keine Datenbankverbindung');
      exit(1);
    }
    final migrator = Migrator(db);
    await migrator.migrate();
    exit(0);
  }

  // Migrations-Status anzeigen (wenn --status oder -s übergeben)
  if (args.contains('--status') || args.contains('-s')) {
    if (!db.isConnected) {
      print('❌ Kann Status nicht anzeigen: Keine Datenbankverbindung');
      exit(1);
    }
    final migrator = Migrator(db);
    await migrator.status();
    exit(0);
  }

  // Rollback (wenn --rollback oder -r übergeben)
  if (args.contains('--rollback') || args.contains('-r')) {
    if (!db.isConnected) {
      print('❌ Kann Rollback nicht ausführen: Keine Datenbankverbindung');
      exit(1);
    }
    final migrator = Migrator(db);
    await migrator.rollback();
    exit(0);
  }

  // Router erstellen
  final app = Router();

  // Health-Check Routes (öffentlich)
  final healthController = HealthController(db);
  app.mount('/health', healthController.router.call);

  // Auth Routes (öffentlich)
  final authController = AuthController(db);
  app.mount('/auth', authController.router.call);

  // Geschützte Routes mit Auth-Middleware
  final accountController = AccountController(db);
  final petController = PetController(db);

  app.mount(
    '/account',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(accountController.router.call),
  );
  app.mount(
    '/pets',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(petController.router.call),
  );

  // Root Route
  app.get('/', (Request request) {
    return Response.ok(
      '{"message": "MyPet API", "version": "0.2.0"}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 404 Handler
  app.all('/<ignored|.*>', (Request request) {
    return Response.notFound(
      '{"error": "Not Found", "path": "${request.requestedUri.path}"}',
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Middleware Pipeline
  final handler = const Pipeline()
      .addMiddleware(loggingMiddleware())
      .addMiddleware(corsHeaders())
      .addHandler(app.call);

  // Server starten
  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.backendPort,
  );

  print('');
  print('🚀 MyPet Backend gestartet');
  print('   http://${server.address.host}:${server.port}');
  print('');
  print('📍 Endpoints:');
  print('   GET  /              - API Info');
  print('   GET  /health        - Health Check');
  print('   GET  /health/ready  - Readiness Check');
  print('');
  print('🔐 Auth:');
  print('   POST /auth/register - Registrierung');
  print('   POST /auth/login    - Login');
  print('   POST /auth/refresh  - Token erneuern');
  print('   POST /auth/logout   - Logout');
  print('');
  print('👤 Account (authentifiziert):');
  print('   GET    /account          - Eigene Daten');
  print('   PUT    /account          - Profil aktualisieren');
  print('   DELETE /account          - Konto löschen');
  print('   PUT    /account/password - Passwort ändern');
  print('');
  print('🐾 Tiere (authentifiziert):');
  print('   GET    /pets      - Alle Tiere');
  print('   GET    /pets/:id  - Einzelnes Tier');
  print('   POST   /pets      - Tier anlegen');
  print('   PUT    /pets/:id  - Tier aktualisieren');
  print('   DELETE /pets/:id  - Tier löschen');
  print('');
  print('🔧 Befehle:');
  print('   --migrate, -m   Migrationen ausführen');
  print('   --status, -s    Migrations-Status anzeigen');
  print('   --rollback, -r  Letzte Migration zurückrollen');
  print('');

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('');
    print('🛑 Server wird heruntergefahren...');
    await db.close();
    await server.close();
    exit(0);
  });
}
