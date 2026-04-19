import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Health-Check Endpoints
class HealthController {
  final Database _db;
  final DateTime _startedAt = DateTime.now();
  static int _requestCount = 0;

  HealthController(this._db);

  static void incrementRequests() => _requestCount++;

  Router get router {
    final r = Router();
    r.get('/', _healthCheck);
    r.get('/ready', _readinessCheck);
    r.get('/metrics', _metrics);
    return r;
  }

  /// GET /health – Liveness probe
  Future<Response> _healthCheck(Request request) async {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
        'service': 'mypet-backend',
        'version': '0.3.0',
        'uptime_seconds': DateTime.now().difference(_startedAt).inSeconds,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// GET /health/ready – Readiness probe (inkl. DB)
  Future<Response> _readinessCheck(Request request) async {
    bool dbHealthy = false;
    int? dbLatencyMs;
    try {
      final sw = Stopwatch()..start();
      await _db.query('SELECT 1');
      sw.stop();
      dbHealthy = true;
      dbLatencyMs = sw.elapsedMilliseconds;
    } catch (e) {
      print('❌ DB-Check fehlgeschlagen: $e');
    }

    final allHealthy = dbHealthy;
    return Response(
      allHealthy ? 200 : 503,
      body: jsonEncode({
        'status': allHealthy ? 'ready' : 'not_ready',
        'timestamp': DateTime.now().toIso8601String(),
        'checks': {
          'server': true,
          'database': dbHealthy,
          if (dbLatencyMs != null) 'db_latency_ms': dbLatencyMs,
        },
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// GET /health/metrics – Einfache Anwendungs-Metriken
  Future<Response> _metrics(Request request) async {
    int? userCount;
    int? petCount;
    try {
      final row = await _db.queryOne('SELECT COUNT(*) as cnt FROM users');
      userCount = row?['cnt'] is int
          ? row!['cnt'] as int
          : int.tryParse(row?['cnt']?.toString() ?? '');
      final petRow = await _db.queryOne('SELECT COUNT(*) as cnt FROM pets');
      petCount = petRow?['cnt'] is int
          ? petRow!['cnt'] as int
          : int.tryParse(petRow?['cnt']?.toString() ?? '');
    } catch (_) {}

    return Response.ok(
      jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'uptime_seconds': DateTime.now().difference(_startedAt).inSeconds,
        'requests_total': _requestCount,
        'process': {
          'pid': pid,
          'memory_rss_kb': ProcessInfo.currentRss ~/ 1024,
        },
        'database': {
          'connected': _db.isConnected,
          if (userCount != null) 'users': userCount,
          if (petCount != null) 'pets': petCount,
        },
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
