import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Zugriffsberechtigungen (Urlaubsvertretung, Tierarzt-Freigaben, etc.)
class PermissionController {
  final Database _db;

  PermissionController(this._db);

  static const _validPermissions = ['read', 'write', 'manage'];
  static const _validSubjectTypes = ['user', 'organization'];

  Router get router {
    final router = Router();

    router.get('/', _listPermissions);
    router.post('/', _grantPermission);
    router.put('/<id>', _updatePermission);
    router.delete('/<id>', _revokePermission);

    return router;
  }

  /// GET /permissions - Eigene Berechtigungen (erteilte + erhaltene)
  Future<Response> _listPermissions(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final direction =
          request.url.queryParameters['direction'] ?? 'granted';

      String whereClause;
      if (direction == 'received') {
        whereClause = '''
          (p.subject_type = 'user' AND p.subject_user_id = @user_id::uuid)
          OR (p.subject_type = 'organization' AND EXISTS (
            SELECT 1 FROM organization_members m
            WHERE m.organization_id = p.subject_organization_id
              AND m.user_id = @user_id::uuid
              AND m.is_active = true
          ))
        ''';
      } else {
        whereClause = 'p.granted_by = @user_id::uuid';
      }

      final permissions = await _db.queryAll(
        '''
        SELECT p.id, p.pet_id, p.granted_by, p.subject_type,
               p.subject_user_id, p.subject_organization_id,
               p.permission, p.starts_at, p.ends_at, p.note,
               p.is_active, p.created_at, p.updated_at,
               pets.name AS pet_name, pets.species AS pet_species,
               u.name AS subject_user_name, u.email AS subject_user_email,
               o.name AS subject_organization_name
        FROM access_permissions p
        INNER JOIN pets ON pets.id = p.pet_id
        LEFT JOIN users u ON u.id = p.subject_user_id
        LEFT JOIN organizations o ON o.id = p.subject_organization_id
        WHERE $whereClause
          AND p.is_active = true
        ORDER BY p.created_at DESC
        ''',
        parameters: {'user_id': userId},
      );

      return Response.ok(
        jsonEncode({
          'permissions': permissions.map(_serialize).toList(),
          'count': permissions.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permissions-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /permissions - Berechtigung erteilen
  Future<Response> _grantPermission(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final petId = body['pet_id'] as String?;
      final subjectType = body['subject_type'] as String?;
      final permission = body['permission'] as String? ?? 'read';

      if (petId == null) return _error(400, 'pet_id ist erforderlich');
      if (subjectType == null || !_validSubjectTypes.contains(subjectType)) {
        return _error(400, 'subject_type muss user oder organization sein');
      }
      if (!_validPermissions.contains(permission)) {
        return _error(400, 'Ungültige Berechtigung: $permission');
      }

      // Prüfen ob Tier dem Benutzer gehört
      final pet = await _db.queryOne(
        'SELECT id FROM pets WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': petId, 'owner_id': userId},
      );
      if (pet == null) {
        return _error(404, 'Tier nicht gefunden oder keine Berechtigung');
      }

      String? subjectUserId;
      String? subjectOrgId;

      if (subjectType == 'user') {
        final subjectEmail = body['subject_email'] as String?;
        subjectUserId = body['subject_user_id'] as String?;

        if (subjectUserId == null && subjectEmail != null) {
          final user = await _db.queryOne(
            'SELECT id FROM users WHERE email = @email',
            parameters: {'email': subjectEmail.toLowerCase().trim()},
          );
          if (user == null) {
            return _error(404, 'Benutzer mit dieser E-Mail nicht gefunden');
          }
          subjectUserId = user['id'].toString();
        }
        if (subjectUserId == null) {
          return _error(400,
              'subject_user_id oder subject_email ist erforderlich');
        }
      } else {
        subjectOrgId = body['subject_organization_id'] as String?;
        if (subjectOrgId == null) {
          return _error(400, 'subject_organization_id ist erforderlich');
        }
      }

      final row = await _db.queryOne(
        '''
        INSERT INTO access_permissions (
          pet_id, granted_by, subject_type, subject_user_id,
          subject_organization_id, permission, starts_at, ends_at, note
        ) VALUES (
          @pet_id::uuid, @granted_by::uuid,
          @subject_type::access_subject_type,
          @subject_user_id,
          @subject_organization_id,
          @permission::access_permission_type,
          @starts_at, @ends_at, @note
        )
        RETURNING id, pet_id, granted_by, subject_type, subject_user_id,
                  subject_organization_id, permission, starts_at, ends_at,
                  note, is_active, created_at, updated_at
        ''',
        parameters: {
          'pet_id': petId,
          'granted_by': userId,
          'subject_type': subjectType,
          'subject_user_id': subjectUserId,
          'subject_organization_id': subjectOrgId,
          'permission': permission,
          'starts_at': body['starts_at'],
          'ends_at': body['ends_at'],
          'note': (body['note'] as String?)?.trim(),
        },
      );

      return Response(
        201,
        body: jsonEncode({'permission': _serialize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Grant-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /permissions/:id - Berechtigung aktualisieren
  Future<Response> _updatePermission(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      // Nur der Ersteller darf updaten
      final existing = await _db.queryOne(
        'SELECT id FROM access_permissions WHERE id = @id::uuid AND granted_by = @granted_by::uuid',
        parameters: {'id': id, 'granted_by': userId},
      );
      if (existing == null) {
        return _error(404, 'Berechtigung nicht gefunden');
      }

      final updates = <String>[];
      final params = <String, dynamic>{'id': id};

      if (body.containsKey('permission')) {
        final perm = body['permission'] as String?;
        if (perm == null || !_validPermissions.contains(perm)) {
          return _error(400, 'Ungültige Berechtigung');
        }
        updates.add('permission = @permission::access_permission_type');
        params['permission'] = perm;
      }
      if (body.containsKey('starts_at')) {
        updates.add('starts_at = @starts_at');
        params['starts_at'] = body['starts_at'];
      }
      if (body.containsKey('ends_at')) {
        updates.add('ends_at = @ends_at');
        params['ends_at'] = body['ends_at'];
      }
      if (body.containsKey('note')) {
        updates.add('note = @note');
        params['note'] = (body['note'] as String?)?.trim();
      }
      if (body.containsKey('is_active')) {
        updates.add('is_active = @is_active');
        params['is_active'] = body['is_active'];
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Felder zum Aktualisieren');
      }

      final row = await _db.queryOne(
        '''
        UPDATE access_permissions
        SET ${updates.join(', ')}
        WHERE id = @id::uuid
        RETURNING id, pet_id, granted_by, subject_type, subject_user_id,
                  subject_organization_id, permission, starts_at, ends_at,
                  note, is_active, created_at, updated_at
        ''',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'permission': _serialize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /permissions/:id - Berechtigung widerrufen
  Future<Response> _revokePermission(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final result = await _db.queryOne(
        '''
        UPDATE access_permissions
        SET is_active = false
        WHERE id = @id::uuid AND granted_by = @granted_by::uuid
        RETURNING id
        ''',
        parameters: {'id': id, 'granted_by': userId},
      );

      if (result == null) {
        return _error(404, 'Berechtigung nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'message': 'Berechtigung widerrufen'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Revoke-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _serialize(Map<String, dynamic> p) {
    return {
      'id': p['id'].toString(),
      'pet_id': p['pet_id'].toString(),
      'granted_by': p['granted_by'].toString(),
      'subject_type': p['subject_type'].toString(),
      'subject_user_id': p['subject_user_id']?.toString(),
      'subject_organization_id': p['subject_organization_id']?.toString(),
      'permission': p['permission'].toString(),
      'starts_at': (p['starts_at'] as DateTime?)?.toIso8601String(),
      'ends_at': (p['ends_at'] as DateTime?)?.toIso8601String(),
      'note': p['note'],
      'is_active': p['is_active'],
      'created_at': (p['created_at'] as DateTime).toIso8601String(),
      'updated_at': (p['updated_at'] as DateTime).toIso8601String(),
      if (p.containsKey('pet_name')) 'pet_name': p['pet_name'],
      if (p.containsKey('pet_species'))
        'pet_species': p['pet_species']?.toString(),
      if (p.containsKey('subject_user_name'))
        'subject_user_name': p['subject_user_name'],
      if (p.containsKey('subject_user_email'))
        'subject_user_email': p['subject_user_email'],
      if (p.containsKey('subject_organization_name'))
        'subject_organization_name': p['subject_organization_name'],
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
