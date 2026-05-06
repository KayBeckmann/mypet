import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Patientenzuweisungen innerhalb einer Praxis
/// GET/PUT/DELETE /pets/:petId/assignment
class PatientAssignmentController {
  final Database _db;

  PatientAssignmentController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/assignment', _getAssignment);
    router.put('/<petId>/assignment', _setAssignment);
    router.delete('/<petId>/assignment', _removeAssignment);
    return router;
  }

  /// GET /pets/:petId/assignment
  Future<Response> _getAssignment(Request request, String petId) async {
    try {
      final orgId = request.context['activeOrganizationId'] as String?;
      if (orgId == null) return _error(400, 'Keine aktive Organisation');

      final row = await _db.queryOne(
        '''
        SELECT pa.*, u.name AS assigned_to_name, u.email AS assigned_to_email,
               ab.name AS assigned_by_name
        FROM patient_assignments pa
        LEFT JOIN users u ON pa.assigned_to = u.id
        LEFT JOIN users ab ON pa.assigned_by = ab.id
        WHERE pa.pet_id = @pet_id::uuid AND pa.organization_id = @org_id::uuid
        ''',
        parameters: {'pet_id': petId, 'org_id': orgId},
      );

      if (row == null) {
        return Response.ok(
          jsonEncode({'assignment': null}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'assignment': _sanitize(row)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getAssignment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:petId/assignment
  Future<Response> _setAssignment(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;
      if (orgId == null) return _error(400, 'Keine aktive Organisation');

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final assignedTo = body['assigned_to'] as String?;
      if (assignedTo == null) return _error(400, 'assigned_to erforderlich');

      final note = body['note'] as String?;

      final row = await _db.queryOne(
        '''
        INSERT INTO patient_assignments (pet_id, organization_id, assigned_to, assigned_by, note)
        VALUES (@pet_id::uuid, @org_id::uuid, @assigned_to::uuid, @assigned_by::uuid, @note)
        ON CONFLICT (pet_id, organization_id)
        DO UPDATE SET assigned_to = @assigned_to::uuid, assigned_by = @assigned_by::uuid, note = @note
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'org_id': orgId,
          'assigned_to': assignedTo,
          'assigned_by': userId,
          'note': note,
        },
      );

      return Response.ok(
        jsonEncode({'assignment': _sanitize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ setAssignment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/assignment
  Future<Response> _removeAssignment(Request request, String petId) async {
    try {
      final orgId = request.context['activeOrganizationId'] as String?;
      if (orgId == null) return _error(400, 'Keine aktive Organisation');

      await _db.query(
        'DELETE FROM patient_assignments WHERE pet_id = @pet_id::uuid AND organization_id = @org_id::uuid',
        parameters: {'pet_id': petId, 'org_id': orgId},
      );

      return Response.ok(
        jsonEncode({'message': 'Zuweisung entfernt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ removeAssignment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> r) {
    return {
      'id': r['id'].toString(),
      'pet_id': r['pet_id'].toString(),
      'organization_id': r['organization_id'].toString(),
      'assigned_to': r['assigned_to'].toString(),
      'assigned_to_name': r['assigned_to_name'],
      'assigned_to_email': r['assigned_to_email'],
      'assigned_by': r['assigned_by'].toString(),
      'assigned_by_name': r['assigned_by_name'],
      'note': r['note'],
      'created_at': (r['created_at'] as DateTime).toIso8601String(),
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
