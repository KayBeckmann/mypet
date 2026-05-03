import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

class PrescriptionController {
  final Database _db;

  PrescriptionController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/prescriptions', _list);
    router.post('/<petId>/prescriptions', _create);
    router.delete('/<petId>/prescriptions/<prescId>', _delete);
    return router;
  }

  Future<Response> _list(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _err(403, 'Kein Zugriff auf dieses Tier');
      }

      final rows = await _db.queryAll('''
        SELECT p.*,
          u.name AS issued_by_name,
          o.name AS organization_name
        FROM prescriptions p
        LEFT JOIN users u ON p.issued_by = u.id
        LEFT JOIN organizations o ON p.organization_id = o.id
        WHERE p.pet_id = @pet_id::uuid
        ORDER BY p.issued_at DESC
      ''', parameters: {'pet_id': petId});

      return Response.ok(
        jsonEncode({'prescriptions': rows.map(_serialize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ prescriptions.list: $e');
      return _err(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _create(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (userRole != 'vet' && userRole != 'superadmin') {
        return _err(403, 'Nur Tierärzte können Rezepte ausstellen');
      }

      if (!await petHasAccess(_db, petId, userId, userRole,
          orgId: orgId, requireWrite: true)) {
        return _err(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final drugName = body['drug_name'] as String?;
      if (drugName == null || drugName.trim().isEmpty) {
        return _err(400, 'Medikamentenname ist erforderlich');
      }

      final row = await _db.queryOne('''
        INSERT INTO prescriptions (
          pet_id, issued_by, organization_id,
          drug_name, dosage, frequency, duration_days,
          instructions, valid_until, refills_remaining, notes
        ) VALUES (
          @pet_id::uuid, @issued_by::uuid, @org_id::uuid,
          @drug_name, @dosage, @frequency, @duration_days,
          @instructions, @valid_until::timestamp, @refills, @notes
        )
        RETURNING *
      ''', parameters: {
        'pet_id': petId,
        'issued_by': userId,
        'org_id': orgId,
        'drug_name': drugName.trim(),
        'dosage': body['dosage'] as String?,
        'frequency': body['frequency'] as String?,
        'duration_days': body['duration_days'] as int?,
        'instructions': body['instructions'] as String?,
        'valid_until': body['valid_until'] as String?,
        'refills': body['refills_remaining'] as int? ?? 0,
        'notes': body['notes'] as String?,
      });

      return Response.ok(
        jsonEncode({'prescription': _serialize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ prescriptions.create: $e');
      return _err(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _delete(
      Request request, String petId, String prescId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      final existing = await _db.queryOne(
        'SELECT issued_by FROM prescriptions WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': prescId, 'pet_id': petId},
      );

      if (existing == null) {
        return _err(404, 'Rezept nicht gefunden');
      }

      if (existing['issued_by'].toString() != userId &&
          userRole != 'superadmin') {
        return _err(403, 'Nur der ausstellende Arzt kann das Rezept löschen');
      }

      await _db.query(
        'DELETE FROM prescriptions WHERE id = @id::uuid',
        parameters: {'id': prescId},
      );

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ prescriptions.delete: $e');
      return _err(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _serialize(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'pet_id': row['pet_id'].toString(),
      'issued_by': row['issued_by'].toString(),
      'issued_by_name': row['issued_by_name'] as String?,
      'organization_id': row['organization_id']?.toString(),
      'organization_name': row['organization_name'] as String?,
      'drug_name': row['drug_name'] as String,
      'dosage': row['dosage'] as String?,
      'frequency': row['frequency'] as String?,
      'duration_days': row['duration_days'] as int?,
      'instructions': row['instructions'] as String?,
      'issued_at': row['issued_at']?.toString(),
      'valid_until': row['valid_until']?.toString(),
      'refills_remaining': row['refills_remaining'] as int? ?? 0,
      'notes': row['notes'] as String?,
      'created_at': row['created_at']?.toString(),
    };
  }

  Response _err(int status, String message) => Response(
        status,
        body: jsonEncode({'error': message}),
        headers: {'Content-Type': 'application/json'},
      );
}
