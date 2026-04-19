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
import 'package:mypet_backend/controllers/organization_controller.dart';
import 'package:mypet_backend/controllers/invitation_controller.dart';
import 'package:mypet_backend/controllers/permission_group_controller.dart';
import 'package:mypet_backend/controllers/family_controller.dart';
import 'package:mypet_backend/controllers/permission_controller.dart';
import 'package:mypet_backend/controllers/admin_controller.dart';
import 'package:mypet_backend/controllers/medical_record_controller.dart';
import 'package:mypet_backend/controllers/vaccination_controller.dart';
import 'package:mypet_backend/controllers/medication_controller.dart';
import 'package:mypet_backend/controllers/appointment_controller.dart';
import 'package:mypet_backend/controllers/feeding_controller.dart';
import 'package:mypet_backend/controllers/media_controller.dart';
import 'package:mypet_backend/controllers/note_controller.dart';
import 'package:mypet_backend/services/upload_service.dart';
import 'package:mypet_backend/middleware/static_files_middleware.dart';

Future<void> main(List<String> args) async {
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

  // Upload-Verzeichnis sicherstellen
  final uploadService = UploadService();
  await uploadService.ensureUploadDir();

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
  final organizationController = OrganizationController(db);
  final invitationController = InvitationController(db);
  final permissionGroupController = PermissionGroupController(db);
  final familyController = FamilyController(db);
  final permissionController = PermissionController(db);

  // Medizinische Daten Controller
  final medicalRecordController = MedicalRecordController(db);
  final vaccinationController = VaccinationController(db);
  final medicationController = MedicationController(db);

  // Termin Controller
  final appointmentController = AppointmentController(db);

  // Fütterungs Controller
  final feedingController = FeedingController(db);

  // Media Controller
  final mediaController = MediaController(db);

  // Notizen Controller
  final noteController = NoteController(db);

  app.mount(
    '/account',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(accountController.router.call),
  );

  // Alle /pets-Routen in einer Cascade (PetController + medizinische Sub-Routen)
  final petsCascade = Cascade()
      .add(petController.router.call)
      .add(medicalRecordController.router.call)
      .add(vaccinationController.router.call)
      .add(medicationController.router.call)
      .add(feedingController.router.call)
      .add(mediaController.router.call)
      .add(noteController.router.call)
      .handler;
  app.mount(
    '/pets',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(petsCascade),
  );

  app.mount(
    '/organizations',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(organizationController.router.call),
  );
  app.mount(
    '/invitations',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(invitationController.router.call),
  );
  app.mount(
    '/permission-groups',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(permissionGroupController.router.call),
  );
  app.mount(
    '/families',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(familyController.router.call),
  );
  app.mount(
    '/permissions',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(permissionController.router.call),
  );

  app.mount(
    '/appointments',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(appointmentController.router.call),
  );

  // Admin Routes (nur superadmin)
  final adminController = AdminController(db);
  app.mount(
    '/admin',
    const Pipeline()
        .addMiddleware(authMiddleware())
        .addMiddleware(requireSuperadmin())
        .addHandler(adminController.router.call),
  );

  // Static Files für Uploads (öffentlich, Bilder über URL abrufbar)
  app.mount(
    '/uploads/',
    staticFilesHandler(
      basePath: config.uploadPath,
      urlPrefix: '/uploads',
    ),
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
  print('   POST   /pets/:id/photo - Foto hochladen');
  print('   DELETE /pets/:id/photo - Foto löschen');
  print('');
  print('🏢 Organisationen (authentifiziert):');
  print('   GET/POST       /organizations');
  print('   GET/PUT/DELETE /organizations/:id');
  print('   GET            /organizations/:id/members');
  print('   POST           /organizations/:id/members/invite');
  print('   PUT/DELETE     /organizations/:id/members/:userId');
  print('   GET/POST       /organizations/:id/permission-groups');
  print('   PUT/DELETE     /permission-groups/:id');
  print('');
  print('✉️  Einladungen (authentifiziert):');
  print('   GET  /invitations');
  print('   POST /invitations/:code/accept');
  print('   POST /invitations/:code/reject');
  print('');
  print('👪 Familien (authentifiziert):');
  print('   GET/POST       /families');
  print('   GET/PUT/DELETE /families/:id');
  print('   GET/POST       /families/:id/members');
  print('   DELETE         /families/:id/members/:userId');
  print('');
  print('🔐 Zugriffsberechtigungen (authentifiziert):');
  print('   GET/POST       /permissions');
  print('   PUT/DELETE     /permissions/:id');
  print('');
  print('📎 Medien (authentifiziert):');
  print('   GET/POST   /pets/:id/media');
  print('   GET/DELETE /pets/:id/media/:mediaId');
  print('');
  print('🍽️  Fütterung (authentifiziert):');
  print('   GET/POST   /pets/:id/feeding-plans');
  print('   GET/PUT/DELETE /pets/:id/feeding-plans/:planId');
  print('   POST/DELETE /pets/:id/feeding-plans/:planId/meals');
  print('   GET/POST   /pets/:id/feeding-log');
  print('');
  print('📅 Termine (authentifiziert):');
  print('   GET    /appointments          - Termine auflisten');
  print('   POST   /appointments          - Termin anlegen');
  print('   GET    /appointments/:id      - Termin abrufen');
  print('   PUT    /appointments/:id/confirm  - Bestätigen');
  print('   PUT    /appointments/:id/complete - Abschließen');
  print('   PUT    /appointments/:id/cancel   - Absagen');
  print('   DELETE /appointments/:id      - Termin löschen');
  print('');
  print('🛡️  Admin (nur superadmin):');
  print('   GET    /admin/users          - Alle Benutzer');
  print('   POST   /admin/users          - Benutzer anlegen');
  print('   GET    /admin/users/:id      - Benutzer abrufen');
  print('   PUT    /admin/users/:id      - Benutzer bearbeiten');
  print('   PUT    /admin/users/:id/reset-password - Passwort reset');
  print('   DELETE /admin/users/:id      - Benutzer deaktivieren');
  print('');
  print('📁 Uploads:');
  print('   GET  /uploads/...  - Hochgeladene Dateien');
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
