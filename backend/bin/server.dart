import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:mypet_backend/config/config.dart';
import 'package:mypet_backend/middleware/logging_middleware.dart';
import 'package:mypet_backend/controllers/health_controller.dart';

void main() async {
  // Konfiguration laden
  final config = Config();

  // Konfiguration ausgeben (Debug)
  if (config.debug) {
    config.printConfig();
  }

  // Router erstellen
  final app = Router();

  // Health-Check Routes
  final healthController = HealthController();
  app.mount('/health', healthController.router.call);

  // Root Route
  app.get('/', (Request request) {
    return Response.ok(
      '{"message": "MyPet API", "version": "0.1.0"}',
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
  print('   GET  /           - API Info');
  print('   GET  /health     - Health Check');
  print('   GET  /health/ready - Readiness Check');
  print('');
}
