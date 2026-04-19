import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Medikationen und Verabreichungsprotokoll
class MedicationController {
  final Database _db;

  MedicationController(this._db);

  Router get router {
    final router = Router();

    // Medikamente
    router.get('/<petId>/medications', _listMedications);
    router.post('/<petId>/medications', _createMedication);
    router.put('/<petId>/medications/<medId>', _updateMedication);
    router.delete('/<petId>/medications/<medId>', _deleteMedication);

    // Verabreichungsprotokoll
    router.get('/<petId>/medications/<medId>/schedule', _getSchedule);
    router.post('/<petId>/medications/<medId>/administer', _administer);
    router.post('/<petId>/medications/<medId>/skip', _skip);

    return router;
  }

  /// GET /pets/:petId/medications
  Future<Response> _listMedications(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      if (!await _hasAccess(petId, userId, userRole)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final medications = await _db.queryAll(
        '''
        SELECT m.*, u.name AS vet_name
        FROM medications m
        LEFT JOIN users u ON m.vet_id = u.id
        WHERE m.pet_id = @pet_id::uuid
        ORDER BY m.is_active DESC, m.start_date DESC
        ''',
        parameters: {'pet_id': petId},
      );

      return Response.ok(
        jsonEncode({'medications': medications.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listMedications Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/medications
  Future<Response> _createMedication(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      if (!await _hasAccess(petId, userId, userRole, requireWrite: true)) {
        return _error(403, 'Keine Schreibberechtigung');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name des Medikaments ist erforderlich');
      }

      final frequency = body['frequency'] as String? ?? 'daily';
      final validFrequencies = ['once', 'daily', 'twice_daily', 'three_times_daily',
          'weekly', 'biweekly', 'monthly', 'as_needed', 'custom'];
      if (!validFrequencies.contains(frequency)) {
        return _error(400, 'Ungültige Häufigkeit');
      }

      final orgId = request.context['activeOrganizationId'] as String?;

      final med = await _db.queryOne(
        '''
        INSERT INTO medications
          (pet_id, vet_id, organization_id, name, dosage, frequency,
           custom_frequency, instructions, start_date, end_date)
        VALUES
          (@pet_id::uuid, @vet_id::uuid, @org_id::uuid, @name, @dosage,
           @frequency::medication_frequency, @custom_frequency, @instructions,
           @start_date::date, @end_date::date)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'vet_id': userId,
          'org_id': orgId,
          'name': name.trim(),
          'dosage': body['dosage'],
          'frequency': frequency,
          'custom_frequency': body['custom_frequency'],
          'instructions': body['instructions'],
          'start_date': body['start_date'] ??
              DateTime.now().toIso8601String().substring(0, 10),
          'end_date': body['end_date'],
        },
      );

      return Response(
        201,
        body: jsonEncode({'medication': _sanitize(med!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createMedication Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:petId/medications/:medId
  Future<Response> _updateMedication(
      Request request, String petId, String medId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      final existing = await _db.queryOne(
        'SELECT vet_id FROM medications WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': medId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Medikament nicht gefunden');
      if (existing['vet_id']?.toString() != userId && userRole != 'superadmin') {
        return _error(403, 'Keine Berechtigung');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final updates = <String>[];
      final params = <String, dynamic>{'id': medId, 'pet_id': petId};

      if (body.containsKey('dosage')) {
        updates.add('dosage = @dosage');
        params['dosage'] = body['dosage'];
      }
      if (body.containsKey('instructions')) {
        updates.add('instructions = @instructions');
        params['instructions'] = body['instructions'];
      }
      if (body.containsKey('end_date')) {
        updates.add('end_date = @end_date::date');
        params['end_date'] = body['end_date'];
      }
      if (body.containsKey('is_active')) {
        updates.add('is_active = @is_active');
        params['is_active'] = body['is_active'];
      }

      if (updates.isEmpty) return _error(400, 'Keine Änderungen');

      final med = await _db.queryOne(
        'UPDATE medications SET ${updates.join(', ')} WHERE id = @id::uuid AND pet_id = @pet_id::uuid RETURNING *',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'medication': _sanitize(med!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateMedication Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/medications/:medId
  Future<Response> _deleteMedication(
      Request request, String petId, String medId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      final existing = await _db.queryOne(
        'SELECT vet_id FROM medications WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': medId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Medikament nicht gefunden');
      if (existing['vet_id']?.toString() != userId && userRole != 'superadmin') {
        return _error(403, 'Keine Berechtigung');
      }

      await _db.query(
        'DELETE FROM medications WHERE id = @id::uuid',
        parameters: {'id': medId},
      );

      return Response.ok(
        jsonEncode({'message': 'Medikament gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteMedication Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /pets/:petId/medications/:medId/schedule
  Future<Response> _getSchedule(
      Request request, String petId, String medId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      if (!await _hasAccess(petId, userId, userRole)) {
        return _error(403, 'Kein Zugriff');
      }

      final logs = await _db.queryAll(
        '''
        SELECT a.*, u.name AS administered_by_name
        FROM medication_administrations a
        LEFT JOIN users u ON a.administered_by = u.id
        WHERE a.medication_id = @med_id::uuid
        ORDER BY a.scheduled_at DESC
        LIMIT 50
        ''',
        parameters: {'med_id': medId},
      );

      return Response.ok(
        jsonEncode({'schedule': logs.map(_sanitizeAdmin).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getSchedule Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/medications/:medId/administer
  Future<Response> _administer(
      Request request, String petId, String medId) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final log = await _db.queryOne(
        '''
        INSERT INTO medication_administrations
          (medication_id, administered_by, status, scheduled_at, administered_at, notes)
        VALUES
          (@med_id::uuid, @user_id::uuid, 'given',
           @scheduled_at::timestamp, NOW(), @notes)
        RETURNING *
        ''',
        parameters: {
          'med_id': medId,
          'user_id': userId,
          'scheduled_at': body['scheduled_at'] ?? DateTime.now().toIso8601String(),
          'notes': body['notes'],
        },
      );

      return Response(
        201,
        body: jsonEncode({'administration': _sanitizeAdmin(log!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ administer Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/medications/:medId/skip
  Future<Response> _skip(Request request, String petId, String medId) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final log = await _db.queryOne(
        '''
        INSERT INTO medication_administrations
          (medication_id, administered_by, status, scheduled_at, notes)
        VALUES
          (@med_id::uuid, @user_id::uuid, 'skipped',
           @scheduled_at::timestamp, @notes)
        RETURNING *
        ''',
        parameters: {
          'med_id': medId,
          'user_id': userId,
          'scheduled_at': body['scheduled_at'] ?? DateTime.now().toIso8601String(),
          'notes': body['notes'],
        },
      );

      return Response(
        201,
        body: jsonEncode({'administration': _sanitizeAdmin(log!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ skip Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<bool> _hasAccess(
    String petId,
    String userId,
    String userRole, {
    bool requireWrite = false,
  }) async {
    if (userRole == 'superadmin') return true;

    final pet = await _db.queryOne(
      'SELECT owner_id FROM pets WHERE id = @id::uuid',
      parameters: {'id': petId},
    );
    if (pet == null) return false;
    if (pet['owner_id'].toString() == userId) return true;

    final permLevel =
        requireWrite ? "'write', 'manage'" : "'read', 'write', 'manage'";
    final perm = await _db.queryOne(
      '''
      SELECT id FROM access_permissions
      WHERE pet_id = @pet_id::uuid
        AND subject_type = 'user'
        AND subject_user_id = @user_id::uuid
        AND permission IN ($permLevel)
        AND is_active = true
        AND (starts_at IS NULL OR starts_at <= NOW())
        AND (ends_at IS NULL OR ends_at >= NOW())
      ''',
      parameters: {'pet_id': petId, 'user_id': userId},
    );
    return perm != null;
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> m) {
    return {
      'id': m['id'].toString(),
      'pet_id': m['pet_id'].toString(),
      'vet_id': m['vet_id']?.toString(),
      'vet_name': m['vet_name'],
      'organization_id': m['organization_id']?.toString(),
      'name': m['name'],
      'dosage': m['dosage'],
      'frequency': m['frequency'].toString(),
      'custom_frequency': m['custom_frequency'],
      'instructions': m['instructions'],
      'start_date': m['start_date']?.toString(),
      'end_date': m['end_date']?.toString(),
      'is_active': m['is_active'],
      'created_at': (m['created_at'] as DateTime).toIso8601String(),
      'updated_at': (m['updated_at'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> _sanitizeAdmin(Map<String, dynamic> a) {
    return {
      'id': a['id'].toString(),
      'medication_id': a['medication_id'].toString(),
      'administered_by': a['administered_by']?.toString(),
      'administered_by_name': a['administered_by_name'],
      'status': a['status'].toString(),
      'scheduled_at': (a['scheduled_at'] as DateTime).toIso8601String(),
      'administered_at': a['administered_at'] != null
          ? (a['administered_at'] as DateTime).toIso8601String()
          : null,
      'notes': a['notes'],
      'created_at': (a['created_at'] as DateTime).toIso8601String(),
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
