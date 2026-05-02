import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Impfungen
class VaccinationController {
  final Database _db;

  VaccinationController(this._db);

  Router get router {
    final router = Router();

    router.get('/<petId>/vaccinations', _listVaccinations);
    router.post('/<petId>/vaccinations', _createVaccination);
    router.delete('/<petId>/vaccinations/<vacId>', _deleteVaccination);

    return router;
  }

  /// Separater Router für aggregierte Abfragen (kein petId-Prefix)
  Router get aggregateRouter {
    final router = Router();
    router.get('/expiring', _expiringVaccinations);
    return router;
  }

  /// GET /pets/:petId/vaccinations
  Future<Response> _listVaccinations(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await _hasAccess(petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final vaccinations = await _db.queryAll(
        '''
        SELECT v.*, u.name AS vet_name, o.name AS organization_name
        FROM vaccinations v
        LEFT JOIN users u ON v.vet_id = u.id
        LEFT JOIN organizations o ON v.organization_id = o.id
        WHERE v.pet_id = @pet_id::uuid
        ORDER BY v.administered_at DESC
        ''',
        parameters: {'pet_id': petId},
      );

      return Response.ok(
        jsonEncode({'vaccinations': vaccinations.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listVaccinations Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/vaccinations
  Future<Response> _createVaccination(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await _hasAccess(petId, userId, userRole, requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final vaccineName = body['vaccine_name'] as String?;
      if (vaccineName == null || vaccineName.trim().isEmpty) {
        return _error(400, 'Impfstoff-Name ist erforderlich');
      }

      final vaccination = await _db.queryOne(
        '''
        INSERT INTO vaccinations
          (pet_id, vet_id, organization_id, vaccine_name, batch_number,
           manufacturer, administered_at, valid_until, notes)
        VALUES
          (@pet_id::uuid, @vet_id::uuid, @org_id::uuid, @vaccine_name,
           @batch_number, @manufacturer, @administered_at::date,
           @valid_until::date, @notes)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'vet_id': userId,
          'org_id': orgId,
          'vaccine_name': vaccineName.trim(),
          'batch_number': body['batch_number'],
          'manufacturer': body['manufacturer'],
          'administered_at': body['administered_at'] ??
              DateTime.now().toIso8601String().substring(0, 10),
          'valid_until': body['valid_until'],
          'notes': body['notes'],
        },
      );

      return Response(
        201,
        body: jsonEncode({'vaccination': _sanitize(vaccination!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createVaccination Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/vaccinations/:vacId
  Future<Response> _deleteVaccination(
      Request request, String petId, String vacId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      final existing = await _db.queryOne(
        'SELECT vet_id FROM vaccinations WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': vacId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Impfung nicht gefunden');

      final vetId = existing['vet_id']?.toString();
      if (vetId != userId && userRole != 'superadmin') {
        return _error(403, 'Keine Berechtigung');
      }

      await _db.query(
        'DELETE FROM vaccinations WHERE id = @id::uuid',
        parameters: {'id': vacId},
      );

      return Response.ok(
        jsonEncode({'message': 'Impfung gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteVaccination Fehler: $e');
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
    if (userRole == 'superadmin') return true;

    final pet = await _db.queryOne(
      'SELECT owner_id FROM pets WHERE id = @id::uuid',
      parameters: {'id': petId},
    );
    if (pet == null) return false;
    if (pet['owner_id'].toString() == userId) return true;

    final permLevel =
        requireWrite ? "'write', 'manage'" : "'read', 'write', 'manage'";
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

  Map<String, dynamic> _sanitize(Map<String, dynamic> v) {
    return {
      'id': v['id'].toString(),
      'pet_id': v['pet_id'].toString(),
      'vet_id': v['vet_id']?.toString(),
      'vet_name': v['vet_name'],
      'organization_id': v['organization_id']?.toString(),
      'organization_name': v['organization_name'],
      'vaccine_name': v['vaccine_name'],
      'batch_number': v['batch_number'],
      'manufacturer': v['manufacturer'],
      'administered_at': v['administered_at']?.toString(),
      'valid_until': v['valid_until']?.toString(),
      'notes': v['notes'],
      'created_at': (v['created_at'] as DateTime).toIso8601String(),
    };
  }

  /// GET /vaccinations/expiring?days=30 — Ablaufende Impfungen für zugängliche Tiere
  Future<Response> _expiringVaccinations(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;
      final days = int.tryParse(
              request.requestedUri.queryParameters['days'] ?? '30') ??
          30;

      final params = <String, dynamic>{'user_id': userId, 'days': days};
      var orgCondition = 'false';
      if (orgId != null) {
        orgCondition =
            'ap.subject_type = \'organization\' AND ap.subject_organization_id = @org_id::uuid';
        params['org_id'] = orgId;
      }

      final rows = await _db.queryAll(
        '''
        SELECT v.id, v.pet_id, v.vaccine_name, v.valid_until,
               p.name AS pet_name, p.species::text AS species
        FROM vaccinations v
        JOIN pets p ON v.pet_id = p.id
        WHERE v.valid_until BETWEEN NOW() AND NOW() + INTERVAL \'1 day\' * @days::int
          AND p.is_active = true
          AND (
            p.owner_id = @user_id::uuid
            OR EXISTS (
              SELECT 1 FROM access_permissions ap
              WHERE ap.pet_id = p.id
                AND ap.is_active = true
                AND (ap.ends_at IS NULL OR ap.ends_at >= NOW())
                AND (
                  (ap.subject_type = \'user\' AND ap.subject_user_id = @user_id::uuid)
                  OR ($orgCondition)
                )
            )
          )
        ORDER BY v.valid_until ASC
        LIMIT 20
        ''',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({
          'vaccinations': rows.map((r) => {
                'id': r['id'].toString(),
                'pet_id': r['pet_id'].toString(),
                'pet_name': r['pet_name'],
                'species': r['species'],
                'vaccine_name': r['vaccine_name'],
                'valid_until': r['valid_until']?.toString(),
              }).toList(),
          'count': rows.length,
          'days_ahead': days,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ expiringVaccinations Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Response _error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
