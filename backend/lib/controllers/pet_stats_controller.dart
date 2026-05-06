import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

/// Schneller Aggregations-Endpoint für Tier-Statistiken
/// GET /pets/:petId/stats
class PetStatsController {
  final Database _db;

  PetStatsController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/stats', _getStats);
    return router;
  }

  Future<Response> _getStats(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final results = await Future.wait([
        _db.queryOne('SELECT COUNT(*) AS c FROM vaccinations WHERE pet_id = @id::uuid', parameters: {'id': petId}),
        _db.queryOne('SELECT COUNT(*) AS c FROM medications WHERE pet_id = @id::uuid AND is_active = true', parameters: {'id': petId}),
        _db.queryOne('SELECT COUNT(*) AS c FROM appointments WHERE pet_id = @id::uuid', parameters: {'id': petId}),
        _db.queryOne('SELECT COUNT(*) AS c FROM medical_records WHERE pet_id = @id::uuid', parameters: {'id': petId}),
        _db.queryOne('SELECT COUNT(*) AS c FROM lab_results WHERE pet_id = @id::uuid', parameters: {'id': petId}),
        _db.queryOne('SELECT COUNT(*) AS c FROM pet_allergies WHERE pet_id = @id::uuid', parameters: {'id': petId}),
        _db.queryOne('SELECT weight_kg, recorded_at FROM weight_history WHERE pet_id = @id::uuid ORDER BY recorded_at DESC LIMIT 1', parameters: {'id': petId}),
        _db.queryOne('SELECT temperature_celsius, recorded_at FROM temperature_history WHERE pet_id = @id::uuid ORDER BY recorded_at DESC LIMIT 1', parameters: {'id': petId}),
        _db.queryOne('SELECT vaccinated_at, valid_until, vaccine_name FROM vaccinations WHERE pet_id = @id::uuid ORDER BY valid_until ASC LIMIT 1', parameters: {'id': petId}),
      ]);

      int _c(int i) => int.tryParse(results[i]?['c']?.toString() ?? '0') ?? 0;

      final latestWeight = results[6];
      final latestTemp = results[7];
      final nextExpiry = results[8];

      return Response.ok(
        jsonEncode({
          'stats': {
            'vaccinations_total': _c(0),
            'active_medications': _c(1),
            'appointments_total': _c(2),
            'medical_records_total': _c(3),
            'lab_results_total': _c(4),
            'allergies_total': _c(5),
            'latest_weight': latestWeight != null ? {
              'weight_kg': double.parse(latestWeight['weight_kg'].toString()),
              'recorded_at': (latestWeight['recorded_at'] as DateTime).toIso8601String(),
            } : null,
            'latest_temperature': latestTemp != null ? {
              'temperature_celsius': double.parse(latestTemp['temperature_celsius'].toString()),
              'recorded_at': (latestTemp['recorded_at'] as DateTime).toIso8601String(),
            } : null,
            'next_vaccination_expiry': nextExpiry != null && nextExpiry['valid_until'] != null ? {
              'vaccine_name': nextExpiry['vaccine_name'],
              'valid_until': (nextExpiry['valid_until'] as DateTime).toIso8601String(),
              'days_remaining': (nextExpiry['valid_until'] as DateTime).difference(DateTime.now()).inDays,
            } : null,
            'health_score': _calcHealthScore(
              vaccinationsTotal: _c(0),
              activeMedications: _c(1),
              nextVaccinationDays: nextExpiry?['valid_until'] != null
                  ? (nextExpiry!['valid_until'] as DateTime).difference(DateTime.now()).inDays
                  : null,
              hasRecentWeight: latestWeight != null,
            ),
          }
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ PetStats Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// Berechnet einen einfachen Gesundheits-Score (0–100)
  int _calcHealthScore({
    required int vaccinationsTotal,
    required int activeMedications,
    int? nextVaccinationDays,
    required bool hasRecentWeight,
  }) {
    int score = 60; // Basiswert

    // Impfungen
    if (vaccinationsTotal > 0) score += 15;
    if (nextVaccinationDays != null) {
      if (nextVaccinationDays > 60) score += 15;
      else if (nextVaccinationDays > 14) score += 8;
      else if (nextVaccinationDays < 0) score -= 20; // abgelaufen
    }

    // Gewichts-Tracking vorhanden
    if (hasRecentWeight) score += 10;

    return score.clamp(0, 100);
  }

  Response _error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
