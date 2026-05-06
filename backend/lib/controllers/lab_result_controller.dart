import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

/// Controller für Laborbefunde
/// Routen unter /pets/:petId/lab-results
class LabResultController {
  final Database _db;

  LabResultController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/lab-results', _list);
    router.post('/<petId>/lab-results', _create);
    router.put('/<petId>/lab-results/<entryId>', _update);
    router.delete('/<petId>/lab-results/<entryId>', _delete);
    return router;
  }

  /// GET /pets/:petId/lab-results
  Future<Response> _list(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final entries = await _db.queryAll(
        '''
        SELECT l.*, u.name AS recorded_by_name
        FROM lab_results l
        LEFT JOIN users u ON l.recorded_by = u.id
        WHERE l.pet_id = @pet_id::uuid
        ORDER BY l.tested_at DESC
        ''',
        parameters: {'pet_id': petId},
      );

      return Response.ok(
        jsonEncode({'lab_results': entries.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listLabResults Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/lab-results  (nur vet/provider)
  Future<Response> _create(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (userRole == 'owner') {
        return _error(403, 'Nur Tierärzte können Laborbefunde eintragen');
      }

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final testName = body['test_name'] as String?;
      if (testName == null || testName.trim().isEmpty) {
        return _error(400, 'test_name erforderlich');
      }
      final resultValue = body['result_value'] as String?;
      if (resultValue == null || resultValue.trim().isEmpty) {
        return _error(400, 'result_value erforderlich');
      }

      final testedAtRaw = body['tested_at'] as String?;
      DateTime testedAt;
      try {
        testedAt = testedAtRaw != null
            ? DateTime.parse(testedAtRaw)
            : DateTime.now();
      } catch (_) {
        testedAt = DateTime.now();
      }

      final entry = await _db.queryOne(
        '''
        INSERT INTO lab_results (pet_id, recorded_by, test_name, test_category, result_value, unit, reference_range, is_abnormal, notes, tested_at)
        VALUES (@pet_id::uuid, @recorded_by::uuid, @test_name, @test_category, @result_value, @unit, @reference_range, @is_abnormal, @notes, @tested_at)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'recorded_by': userId,
          'test_name': testName.trim(),
          'test_category': body['test_category'] as String?,
          'result_value': resultValue.trim(),
          'unit': body['unit'] as String?,
          'reference_range': body['reference_range'] as String?,
          'is_abnormal': body['is_abnormal'] as bool? ?? false,
          'notes': body['notes'] as String?,
          'tested_at': testedAt.toIso8601String(),
        },
      );

      return Response(
        201,
        body: jsonEncode({'lab_result': _sanitize(entry!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createLabResult Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:petId/lab-results/:entryId
  Future<Response> _update(
      Request request, String petId, String entryId) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final existing = await _db.queryOne(
        'SELECT recorded_by FROM lab_results WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': entryId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Laborbefund nicht gefunden');
      if (existing['recorded_by'].toString() != userId) {
        return _error(403, 'Nur der Ersteller kann diesen Befund bearbeiten');
      }

      final updated = await _db.queryOne(
        '''
        UPDATE lab_results
        SET test_name = COALESCE(@test_name, test_name),
            test_category = @test_category,
            result_value = COALESCE(@result_value, result_value),
            unit = @unit,
            reference_range = @reference_range,
            is_abnormal = COALESCE(@is_abnormal, is_abnormal),
            notes = @notes
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {
          'id': entryId,
          'test_name': body['test_name'] as String?,
          'test_category': body['test_category'] as String?,
          'result_value': body['result_value'] as String?,
          'unit': body['unit'] as String?,
          'reference_range': body['reference_range'] as String?,
          'is_abnormal': body['is_abnormal'] as bool?,
          'notes': body['notes'] as String?,
        },
      );

      return Response.ok(
        jsonEncode({'lab_result': _sanitize(updated!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateLabResult Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/lab-results/:entryId
  Future<Response> _delete(
      Request request, String petId, String entryId) async {
    try {
      final userId = request.context['userId'] as String;
      final deleted = await _db.queryOne(
        'DELETE FROM lab_results WHERE id = @id::uuid AND pet_id = @pet_id::uuid AND recorded_by = @user_id::uuid RETURNING id',
        parameters: {'id': entryId, 'pet_id': petId, 'user_id': userId},
      );
      if (deleted == null) return _error(404, 'Laborbefund nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Laborbefund gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteLabResult Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> l) {
    return {
      'id': l['id'].toString(),
      'pet_id': l['pet_id'].toString(),
      'recorded_by': l['recorded_by'].toString(),
      'recorded_by_name': l['recorded_by_name'],
      'test_name': l['test_name'],
      'test_category': l['test_category'],
      'result_value': l['result_value'],
      'unit': l['unit'],
      'reference_range': l['reference_range'],
      'is_abnormal': l['is_abnormal'] as bool? ?? false,
      'notes': l['notes'],
      'tested_at': (l['tested_at'] as DateTime).toIso8601String(),
      'created_at': (l['created_at'] as DateTime).toIso8601String(),
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
