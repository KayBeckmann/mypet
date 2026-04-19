import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Gewichtsverlauf
/// Routen unter /pets/:petId/weight
class WeightController {
  final Database _db;

  WeightController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/weight', _listWeight);
    router.post('/<petId>/weight', _addWeight);
    router.delete('/<petId>/weight/<entryId>', _deleteWeight);
    return router;
  }

  /// GET /pets/:petId/weight
  Future<Response> _listWeight(Request request, String petId) async {
    try {
      final params = request.requestedUri.queryParameters;
      final limit = int.tryParse(params['limit'] ?? '') ?? 100;

      final entries = await _db.queryAll(
        '''
        SELECT w.*, u.name AS recorded_by_name
        FROM weight_history w
        LEFT JOIN users u ON w.recorded_by = u.id
        WHERE w.pet_id = @pet_id::uuid
        ORDER BY w.recorded_at ASC
        LIMIT @limit
        ''',
        parameters: {'pet_id': petId, 'limit': limit},
      );

      return Response.ok(
        jsonEncode({'weights': entries.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listWeight Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/weight
  Future<Response> _addWeight(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final weightRaw = body['weight_kg'];
      if (weightRaw == null) return _error(400, 'weight_kg erforderlich');

      final weightKg = double.tryParse(weightRaw.toString());
      if (weightKg == null || weightKg <= 0) {
        return _error(400, 'Ungültiges Gewicht');
      }

      final notes = body['notes'] as String?;
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
        INSERT INTO weight_history (pet_id, recorded_by, weight_kg, notes, recorded_at)
        VALUES (@pet_id::uuid, @recorded_by::uuid, @weight_kg, @notes, @recorded_at)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'recorded_by': userId,
          'weight_kg': weightKg,
          'notes': notes,
          'recorded_at': recordedAt.toIso8601String(),
        },
      );

      // Auch Tier-Gewicht aktualisieren (schnellere Anzeige)
      await _db.queryAll(
        'UPDATE pets SET weight_kg = @weight_kg WHERE id = @id::uuid',
        parameters: {'weight_kg': weightKg, 'id': petId},
      );

      return Response(
        201,
        body: jsonEncode({'weight': _sanitize(entry!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ addWeight Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/weight/:entryId
  Future<Response> _deleteWeight(
      Request request, String petId, String entryId) async {
    try {
      final userId = request.context['userId'] as String;
      final deleted = await _db.queryOne(
        'DELETE FROM weight_history WHERE id = @id::uuid AND pet_id = @pet_id::uuid AND recorded_by = @user_id::uuid RETURNING id',
        parameters: {'id': entryId, 'pet_id': petId, 'user_id': userId},
      );
      if (deleted == null) return _error(404, 'Eintrag nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Gewichtseintrag gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteWeight Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> w) {
    return {
      'id': w['id'].toString(),
      'pet_id': w['pet_id'].toString(),
      'recorded_by': w['recorded_by'].toString(),
      'recorded_by_name': w['recorded_by_name'],
      'weight_kg': double.parse(w['weight_kg'].toString()),
      'notes': w['notes'],
      'recorded_at': (w['recorded_at'] as DateTime).toIso8601String(),
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
