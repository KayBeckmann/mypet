import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Controller für Health-Check Endpoints
class HealthController {
  Router get router {
    final router = Router();

    // GET /health - Basis Health-Check
    router.get('/', _healthCheck);

    // GET /health/ready - Readiness Check (inkl. DB)
    router.get('/ready', _readinessCheck);

    return router;
  }

  /// Basis Health-Check - Server läuft
  Future<Response> _healthCheck(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'mypet-backend',
        'version': '0.1.0',
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Readiness Check - Server und Abhängigkeiten bereit
  Future<Response> _readinessCheck(Request request) async {
    // TODO: Datenbank-Verbindung prüfen
    final checks = {
      'server': true,
      'database': false, // Wird in M1.2 implementiert
    };

    final allHealthy = checks.values.every((v) => v);

    return Response(
      allHealthy ? 200 : 503,
      body: jsonEncode({
        'status': allHealthy ? 'ready' : 'not_ready',
        'timestamp': DateTime.now().toIso8601String(),
        'checks': checks,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
