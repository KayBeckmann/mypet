import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für medizinische Akten
class MedicalRecordController {
  final Database _db;

  MedicalRecordController(this._db);

  Router get router {
    final router = Router();

    router.get('/<petId>/records', _listRecords);
    router.post('/<petId>/records', _createRecord);
    router.get('/<petId>/records/<recordId>', _getRecord);
    router.put('/<petId>/records/<recordId>', _updateRecord);
    router.delete('/<petId>/records/<recordId>', _deleteRecord);

    return router;
  }

  /// GET /pets/:petId/records
  Future<Response> _listRecords(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      // Zugriffscheck: Eigentümer oder Zugriffsberechtigung
      if (!await _hasAccess(petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      // Tierärzte/Admins sehen alle Einträge, Besitzer nur nicht-private
      final showPrivate = userRole == 'vet' || userRole == 'superadmin';

      final records = await _db.queryAll(
        '''
        SELECT r.*, u.name AS vet_name, o.name AS organization_name
        FROM medical_records r
        LEFT JOIN users u ON r.vet_id = u.id
        LEFT JOIN organizations o ON r.organization_id = o.id
        WHERE r.pet_id = @pet_id::uuid
          ${showPrivate ? '' : 'AND r.is_private = false'}
        ORDER BY r.recorded_at DESC
        ''',
        parameters: {'pet_id': petId},
      );

      return Response.ok(
        jsonEncode({'records': records.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listRecords Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/records
  Future<Response> _createRecord(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await _hasAccess(petId, userId, userRole, requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final title = body['title'] as String?;
      if (title == null || title.trim().isEmpty) {
        return _error(400, 'Titel ist erforderlich');
      }

      final recordType = body['record_type'] as String? ?? 'observation';
      final validTypes = ['checkup', 'diagnosis', 'treatment', 'surgery',
          'lab_result', 'prescription', 'observation', 'other'];
      if (!validTypes.contains(recordType)) {
        return _error(400, 'Ungültiger Eintragstyp');
      }

      final record = await _db.queryOne(
        '''
        INSERT INTO medical_records
          (pet_id, vet_id, organization_id, record_type, title, description,
           diagnosis, treatment, follow_up_date, is_private, recorded_at)
        VALUES
          (@pet_id::uuid, @vet_id::uuid, @org_id::uuid, @record_type::medical_record_type,
           @title, @description, @diagnosis, @treatment,
           @follow_up_date::date, @is_private, @recorded_at::timestamp)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'vet_id': userId,
          'org_id': orgId,
          'record_type': recordType,
          'title': title.trim(),
          'description': body['description'],
          'diagnosis': body['diagnosis'],
          'treatment': body['treatment'],
          'follow_up_date': body['follow_up_date'],
          'is_private': body['is_private'] as bool? ?? false,
          'recorded_at': body['recorded_at'] ?? DateTime.now().toIso8601String(),
        },
      );

      return Response(
        201,
        body: jsonEncode({'record': _sanitize(record!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createRecord Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /pets/:petId/records/:recordId
  Future<Response> _getRecord(
      Request request, String petId, String recordId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await _hasAccess(petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final record = await _db.queryOne(
        '''
        SELECT r.*, u.name AS vet_name, o.name AS organization_name
        FROM medical_records r
        LEFT JOIN users u ON r.vet_id = u.id
        LEFT JOIN organizations o ON r.organization_id = o.id
        WHERE r.id = @id::uuid AND r.pet_id = @pet_id::uuid
        ''',
        parameters: {'id': recordId, 'pet_id': petId},
      );

      if (record == null) return _error(404, 'Eintrag nicht gefunden');

      // Private Einträge nur für Tierärzte
      if (record['is_private'] == true && userRole == 'owner') {
        return _error(403, 'Kein Zugriff auf diesen Eintrag');
      }

      return Response.ok(
        jsonEncode({'record': _sanitize(record)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getRecord Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:petId/records/:recordId
  Future<Response> _updateRecord(
      Request request, String petId, String recordId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      // Nur Ersteller oder Superadmin darf bearbeiten
      final existing = await _db.queryOne(
        'SELECT vet_id FROM medical_records WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': recordId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Eintrag nicht gefunden');

      final vetId = existing['vet_id']?.toString();
      if (vetId != userId && userRole != 'superadmin') {
        return _error(403, 'Nur der Ersteller kann diesen Eintrag bearbeiten');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final updates = <String>[];
      final params = <String, dynamic>{'id': recordId, 'pet_id': petId};

      if (body.containsKey('title')) {
        updates.add('title = @title');
        params['title'] = body['title'];
      }
      if (body.containsKey('description')) {
        updates.add('description = @description');
        params['description'] = body['description'];
      }
      if (body.containsKey('diagnosis')) {
        updates.add('diagnosis = @diagnosis');
        params['diagnosis'] = body['diagnosis'];
      }
      if (body.containsKey('treatment')) {
        updates.add('treatment = @treatment');
        params['treatment'] = body['treatment'];
      }
      if (body.containsKey('follow_up_date')) {
        updates.add('follow_up_date = @follow_up_date::date');
        params['follow_up_date'] = body['follow_up_date'];
      }
      if (body.containsKey('is_private')) {
        updates.add('is_private = @is_private');
        params['is_private'] = body['is_private'];
      }

      if (updates.isEmpty) return _error(400, 'Keine Änderungen angegeben');

      final record = await _db.queryOne(
        'UPDATE medical_records SET ${updates.join(', ')} WHERE id = @id::uuid AND pet_id = @pet_id::uuid RETURNING *',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'record': _sanitize(record!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateRecord Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/records/:recordId
  Future<Response> _deleteRecord(
      Request request, String petId, String recordId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      final existing = await _db.queryOne(
        'SELECT vet_id FROM medical_records WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': recordId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Eintrag nicht gefunden');

      final vetId = existing['vet_id']?.toString();
      if (vetId != userId && userRole != 'superadmin') {
        return _error(403, 'Keine Berechtigung');
      }

      await _db.query(
        'DELETE FROM medical_records WHERE id = @id::uuid',
        parameters: {'id': recordId},
      );

      return Response.ok(
        jsonEncode({'message': 'Eintrag gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteRecord Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<bool> _hasAccess(
    String petId,
    String userId,
    String userRole, {
    bool requireWrite = false,
    String? orgId,
  }) async {
    // Superadmin hat immer Zugriff
    if (userRole == 'superadmin') return true;

    // Eigentümer des Tieres
    final pet = await _db.queryOne(
      'SELECT owner_id FROM pets WHERE id = @id::uuid',
      parameters: {'id': petId},
    );
    if (pet == null) return false;
    if (pet['owner_id'].toString() == userId) return true;

    // Zugriffsberechtigungen prüfen (User oder Organisation)
    final permLevel = requireWrite ? "'write', 'manage'" : "'read', 'write', 'manage'";
    final orgCondition = orgId != null
        ? "OR (subject_type = 'organization' AND subject_organization_id = @org_id::uuid)"
        : '';
    final params = <String, dynamic>{'pet_id': petId, 'user_id': userId};
    if (orgId != null) params['org_id'] = orgId;

    final perm = await _db.queryOne(
      '''
      SELECT id FROM access_permissions
      WHERE pet_id = @pet_id::uuid
        AND permission IN ($permLevel)
        AND is_active = true
        AND (starts_at IS NULL OR starts_at <= NOW())
        AND (ends_at IS NULL OR ends_at >= NOW())
        AND (
          (subject_type = 'user' AND subject_user_id = @user_id::uuid)
          $orgCondition
        )
      ''',
      parameters: params,
    );
    return perm != null;
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> r) {
    return {
      'id': r['id'].toString(),
      'pet_id': r['pet_id'].toString(),
      'vet_id': r['vet_id']?.toString(),
      'vet_name': r['vet_name'],
      'organization_id': r['organization_id']?.toString(),
      'organization_name': r['organization_name'],
      'record_type': r['record_type'].toString(),
      'title': r['title'],
      'description': r['description'],
      'diagnosis': r['diagnosis'],
      'treatment': r['treatment'],
      'follow_up_date': r['follow_up_date']?.toString(),
      'is_private': r['is_private'],
      'recorded_at': (r['recorded_at'] as DateTime).toIso8601String(),
      'created_at': (r['created_at'] as DateTime).toIso8601String(),
      'updated_at': (r['updated_at'] as DateTime).toIso8601String(),
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
