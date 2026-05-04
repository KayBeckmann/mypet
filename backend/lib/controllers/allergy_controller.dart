import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

class AllergyController {
  final Database _db;

  AllergyController(this._db);

  Router get router {
    final r = Router();
    r.get('/<petId>/allergies', _list);
    r.post('/<petId>/allergies', _create);
    r.put('/<petId>/allergies/<allergyId>', _update);
    r.delete('/<petId>/allergies/<allergyId>', _delete);
    return r;
  }

  Future<Response> _list(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final rows = await _db.queryAll(
        '''
        SELECT a.*, u.name AS recorded_by_name
        FROM pet_allergies a
        JOIN users u ON a.recorded_by = u.id
        WHERE a.pet_id = @pet_id::uuid
        ORDER BY a.severity DESC, a.allergen ASC
        ''',
        parameters: {'pet_id': petId},
      );

      return Response.ok(
        jsonEncode({'allergies': rows.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listAllergies Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _create(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole,
          requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final allergen = (body['allergen'] as String?)?.trim();
      if (allergen == null || allergen.isEmpty) {
        return _error(400, 'Allergen ist erforderlich');
      }

      const validSeverities = ['mild', 'moderate', 'severe'];
      final severity = body['severity'] as String? ?? 'moderate';
      if (!validSeverities.contains(severity)) {
        return _error(400, 'Ungültiger Schweregrad');
      }

      final row = await _db.queryOne(
        '''
        INSERT INTO pet_allergies
          (pet_id, recorded_by, allergen, category, severity, reaction, notes, diagnosed_at)
        VALUES
          (@pet_id::uuid, @user_id::uuid, @allergen, @category, @severity::allergy_severity,
           @reaction, @notes, @diagnosed_at::date)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'user_id': userId,
          'allergen': allergen,
          'category': body['category'],
          'severity': severity,
          'reaction': body['reaction'],
          'notes': body['notes'],
          'diagnosed_at': body['diagnosed_at'],
        },
      );

      final withName = await _db.queryOne(
        'SELECT a.*, u.name AS recorded_by_name FROM pet_allergies a JOIN users u ON a.recorded_by = u.id WHERE a.id = @id::uuid',
        parameters: {'id': row!['id'].toString()},
      );

      return Response(
        201,
        body: jsonEncode({'allergy': _sanitize(withName!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createAllergy Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _update(Request request, String petId, String allergyId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole,
          requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final existing = await _db.queryOne(
        'SELECT id FROM pet_allergies WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': allergyId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Allergie nicht gefunden');

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final allergen = (body['allergen'] as String?)?.trim();
      if (allergen == null || allergen.isEmpty) {
        return _error(400, 'Allergen ist erforderlich');
      }

      const validSeverities = ['mild', 'moderate', 'severe'];
      final severity = body['severity'] as String? ?? 'moderate';
      if (!validSeverities.contains(severity)) {
        return _error(400, 'Ungültiger Schweregrad');
      }

      await _db.query(
        '''
        UPDATE pet_allergies SET
          allergen = @allergen,
          category = @category,
          severity = @severity::allergy_severity,
          reaction = @reaction,
          notes = @notes,
          diagnosed_at = @diagnosed_at::date
        WHERE id = @id::uuid
        ''',
        parameters: {
          'id': allergyId,
          'allergen': allergen,
          'category': body['category'],
          'severity': severity,
          'reaction': body['reaction'],
          'notes': body['notes'],
          'diagnosed_at': body['diagnosed_at'],
        },
      );

      final updated = await _db.queryOne(
        'SELECT a.*, u.name AS recorded_by_name FROM pet_allergies a JOIN users u ON a.recorded_by = u.id WHERE a.id = @id::uuid',
        parameters: {'id': allergyId},
      );

      return Response.ok(
        jsonEncode({'allergy': _sanitize(updated!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateAllergy Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _delete(Request request, String petId, String allergyId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole,
          requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final existing = await _db.queryOne(
        'SELECT id FROM pet_allergies WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': allergyId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Allergie nicht gefunden');

      await _db.query(
        'DELETE FROM pet_allergies WHERE id = @id::uuid',
        parameters: {'id': allergyId},
      );

      return Response.ok(
        jsonEncode({'message': 'Allergie gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteAllergy Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> r) => {
        'id': r['id'].toString(),
        'pet_id': r['pet_id'].toString(),
        'recorded_by': r['recorded_by'].toString(),
        'recorded_by_name': r['recorded_by_name'],
        'allergen': r['allergen'],
        'category': r['category'],
        'severity': r['severity'].toString(),
        'reaction': r['reaction'],
        'notes': r['notes'],
        'diagnosed_at': r['diagnosed_at']?.toString(),
        'created_at': (r['created_at'] as DateTime).toIso8601String(),
        'updated_at': (r['updated_at'] as DateTime).toIso8601String(),
      };

  Response _error(int code, String msg) => Response(
        code,
        body: jsonEncode({'error': msg}),
        headers: {'Content-Type': 'application/json'},
      );
}
