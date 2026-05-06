import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

/// Controller für Körpertemperatur-Verlauf
/// Routen unter /pets/:petId/temperature
class TemperatureController {
  final Database _db;

  TemperatureController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/temperature', _listTemperature);
    router.post('/<petId>/temperature', _addTemperature);
    router.delete('/<petId>/temperature/<entryId>', _deleteTemperature);
    return router;
  }

  /// GET /pets/:petId/temperature
  Future<Response> _listTemperature(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final params = request.requestedUri.queryParameters;
      final limit = int.tryParse(params['limit'] ?? '') ?? 100;

      final entries = await _db.queryAll(
        '''
        SELECT t.*, u.name AS recorded_by_name
        FROM temperature_history t
        LEFT JOIN users u ON t.recorded_by = u.id
        WHERE t.pet_id = @pet_id::uuid
        ORDER BY t.recorded_at ASC
        LIMIT @limit
        ''',
        parameters: {'pet_id': petId, 'limit': limit},
      );

      return Response.ok(
        jsonEncode({'temperatures': entries.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listTemperature Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/temperature
  Future<Response> _addTemperature(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole,
          requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final tempRaw = body['temperature_celsius'];
      if (tempRaw == null) return _error(400, 'temperature_celsius erforderlich');

      final tempC = double.tryParse(tempRaw.toString());
      if (tempC == null || tempC < 25.0 || tempC > 45.0) {
        return _error(400, 'Ungültige Temperatur (25–45 °C)');
      }

      final method = body['measurement_method'] as String?;
      final note = body['note'] as String?;
      final recordedAtRaw = body['recorded_at'] as String?;
      DateTime recordedAt;
      try {
        recordedAt = recordedAtRaw != null
            ? DateTime.parse(recordedAtRaw)
            : DateTime.now();
      } catch (_) {
        recordedAt = DateTime.now();
      }

      final entry = await _db.queryOne(
        '''
        INSERT INTO temperature_history (pet_id, recorded_by, temperature_celsius, measurement_method, note, recorded_at)
        VALUES (@pet_id::uuid, @recorded_by::uuid, @temp, @method, @note, @recorded_at)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'recorded_by': userId,
          'temp': tempC,
          'method': method,
          'note': note,
          'recorded_at': recordedAt.toIso8601String(),
        },
      );

      return Response(
        201,
        body: jsonEncode({'temperature': _sanitize(entry!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ addTemperature Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/temperature/:entryId
  Future<Response> _deleteTemperature(
      Request request, String petId, String entryId) async {
    try {
      final userId = request.context['userId'] as String;
      final deleted = await _db.queryOne(
        'DELETE FROM temperature_history WHERE id = @id::uuid AND pet_id = @pet_id::uuid AND recorded_by = @user_id::uuid RETURNING id',
        parameters: {'id': entryId, 'pet_id': petId, 'user_id': userId},
      );
      if (deleted == null) return _error(404, 'Eintrag nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Temperatureintrag gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteTemperature Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> t) {
    return {
      'id': t['id'].toString(),
      'pet_id': t['pet_id'].toString(),
      'recorded_by': t['recorded_by'].toString(),
      'recorded_by_name': t['recorded_by_name'],
      'temperature_celsius': double.parse(t['temperature_celsius'].toString()),
      'measurement_method': t['measurement_method'],
      'note': t['note'],
      'recorded_at': (t['recorded_at'] as DateTime).toIso8601String(),
    };
  }

  Response _error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
