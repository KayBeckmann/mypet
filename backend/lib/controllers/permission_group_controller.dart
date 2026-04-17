import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für einzelne Berechtigungsgruppen (PUT/DELETE)
class PermissionGroupController {
  final Database _db;

  PermissionGroupController(this._db);

  Router get router {
    final router = Router();

    router.put('/<id>', _updateGroup);
    router.delete('/<id>', _deleteGroup);

    return router;
  }

  /// PUT /permission-groups/:id - Gruppe aktualisieren
  Future<Response> _updateGroup(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireOrgAdmin(id, userId)) {
        return _error(403, 'Nur Admins können Berechtigungsgruppen ändern');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final updates = <String>[];
      final params = <String, dynamic>{'id': id};

      if (body.containsKey('name')) {
        final name = body['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          return _error(400, 'Name darf nicht leer sein');
        }
        updates.add('name = @name');
        params['name'] = name.trim();
      }
      if (body.containsKey('description')) {
        updates.add('description = @description');
        params['description'] = (body['description'] as String?)?.trim();
      }
      if (body.containsKey('permissions')) {
        updates.add('permissions = @permissions::jsonb');
        params['permissions'] = jsonEncode(body['permissions']);
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Felder zum Aktualisieren');
      }

      final group = await _db.queryOne(
        '''
        UPDATE permission_groups
        SET ${updates.join(', ')}
        WHERE id = @id::uuid
        RETURNING id, organization_id, name, description, permissions,
                  is_system, created_at, updated_at
        ''',
        parameters: params,
      );

      if (group == null) {
        return _error(404, 'Berechtigungsgruppe nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'permission_group': _serialize(group)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Group-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /permission-groups/:id - Gruppe löschen
  Future<Response> _deleteGroup(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireOrgAdmin(id, userId)) {
        return _error(403, 'Nur Admins können Berechtigungsgruppen löschen');
      }

      final group = await _db.queryOne(
        'SELECT is_system FROM permission_groups WHERE id = @id::uuid',
        parameters: {'id': id},
      );
      if (group == null) {
        return _error(404, 'Berechtigungsgruppe nicht gefunden');
      }
      if (group['is_system'] == true) {
        return _error(400, 'System-Gruppen können nicht gelöscht werden');
      }

      await _db.query(
        'DELETE FROM permission_groups WHERE id = @id::uuid',
        parameters: {'id': id},
      );

      return Response.ok(
        jsonEncode({'message': 'Berechtigungsgruppe gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Group-Delete-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<bool> _requireOrgAdmin(String groupId, String userId) async {
    final result = await _db.queryOne(
      '''
      SELECT m.role
      FROM permission_groups pg
      INNER JOIN organization_members m
        ON m.organization_id = pg.organization_id
      WHERE pg.id = @group_id::uuid
        AND m.user_id = @user_id::uuid
        AND m.is_active = true
      ''',
      parameters: {'group_id': groupId, 'user_id': userId},
    );
    if (result == null) return false;
    return result['role'].toString() == 'admin';
  }

  Map<String, dynamic> _serialize(Map<String, dynamic> group) {
    final permissions = group['permissions'];
    return {
      'id': group['id'].toString(),
      'organization_id': group['organization_id'].toString(),
      'name': group['name'],
      'description': group['description'],
      'permissions': permissions is String
          ? jsonDecode(permissions)
          : permissions ?? {},
      'is_system': group['is_system'],
      'created_at': (group['created_at'] as DateTime).toIso8601String(),
      'updated_at': (group['updated_at'] as DateTime).toIso8601String(),
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
