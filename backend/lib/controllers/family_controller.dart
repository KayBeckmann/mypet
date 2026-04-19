import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../database/database.dart';

/// Controller für Familien & Familien-Mitglieder
class FamilyController {
  final Database _db;

  FamilyController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _listFamilies);
    router.post('/', _createFamily);
    router.get('/<id>', _getFamily);
    router.put('/<id>', _updateFamily);
    router.delete('/<id>', _deleteFamily);

    router.get('/<id>/members', _listMembers);
    router.post('/<id>/members', _addMember);
    router.delete('/<id>/members/<userId>', _removeMember);

    return router;
  }

  Future<Response> _listFamilies(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final families = await _db.queryAll(
        '''
        SELECT f.id, f.name, f.created_by, f.created_at, f.updated_at,
               m.role AS member_role
        FROM families f
        INNER JOIN family_members m ON m.family_id = f.id
        WHERE m.user_id = @user_id::uuid
        ORDER BY f.created_at DESC
        ''',
        parameters: {'user_id': userId},
      );

      return Response.ok(
        jsonEncode({
          'families': families.map(_serialize).toList(),
          'count': families.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Families-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _createFamily(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;

      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      final family = await _db.transaction((tx) async {
        final res = await tx.execute(
          Sql.named('''
            INSERT INTO families (name, created_by)
            VALUES (@name, @created_by::uuid)
            RETURNING id, name, created_by, created_at, updated_at
          '''),
          parameters: {'name': name.trim(), 'created_by': userId},
        );
        final row = res.first.toColumnMap();
        await tx.execute(
          Sql.named('''
            INSERT INTO family_members (family_id, user_id, role)
            VALUES (@family_id::uuid, @user_id::uuid, 'owner')
          '''),
          parameters: {
            'family_id': row['id'].toString(),
            'user_id': userId,
          },
        );
        return row;
      });

      return Response(
        201,
        body: jsonEncode({'family': _serialize(family)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Create-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _getFamily(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isMember(id, userId)) {
        return _error(404, 'Familie nicht gefunden');
      }

      final family = await _db.queryOne(
        '''
        SELECT id, name, created_by, created_at, updated_at
        FROM families
        WHERE id = @id::uuid
        ''',
        parameters: {'id': id},
      );

      if (family == null) return _error(404, 'Familie nicht gefunden');

      return Response.ok(
        jsonEncode({'family': _serialize(family)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Get-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _updateFamily(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann die Familie bearbeiten');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;

      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      final family = await _db.queryOne(
        '''
        UPDATE families SET name = @name
        WHERE id = @id::uuid
        RETURNING id, name, created_by, created_at, updated_at
        ''',
        parameters: {'id': id, 'name': name.trim()},
      );

      return Response.ok(
        jsonEncode({'family': _serialize(family!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _deleteFamily(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann die Familie löschen');
      }

      await _db.query(
        'DELETE FROM families WHERE id = @id::uuid',
        parameters: {'id': id},
      );

      return Response.ok(
        jsonEncode({'message': 'Familie wurde gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Delete-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _listMembers(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      if (!await _isMember(id, userId)) {
        return _error(404, 'Familie nicht gefunden');
      }

      final members = await _db.queryAll(
        '''
        SELECT fm.id, fm.family_id, fm.user_id, fm.role, fm.joined_at,
               u.name AS user_name, u.email AS user_email
        FROM family_members fm
        INNER JOIN users u ON u.id = fm.user_id
        WHERE fm.family_id = @id::uuid
        ORDER BY fm.joined_at ASC
        ''',
        parameters: {'id': id},
      );

      return Response.ok(
        jsonEncode({
          'members': members.map(_serializeMember).toList(),
          'count': members.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Members-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _addMember(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann Mitglieder hinzufügen');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;

      if (email == null || email.trim().isEmpty || !email.contains('@')) {
        return _error(400, 'Gültige E-Mail-Adresse ist erforderlich');
      }

      final user = await _db.queryOne(
        'SELECT id FROM users WHERE email = @email',
        parameters: {'email': email.toLowerCase().trim()},
      );
      if (user == null) {
        return _error(404, 'Benutzer mit dieser E-Mail nicht gefunden');
      }

      try {
        final member = await _db.queryOne(
          '''
          INSERT INTO family_members (family_id, user_id, role)
          VALUES (@family_id::uuid, @user_id::uuid, 'member')
          RETURNING id, family_id, user_id, role, joined_at
          ''',
          parameters: {
            'family_id': id,
            'user_id': user['id'].toString(),
          },
        );
        return Response(
          201,
          body: jsonEncode({'member': _serializeMember(member!)}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        if (e.toString().contains('unique')) {
          return _error(409, 'Benutzer ist bereits Mitglied');
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Family-Member-Add-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _removeMember(
      Request request, String id, String memberUserId) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann Mitglieder entfernen');
      }

      // Ersteller kann nicht entfernt werden
      final family = await _db.queryOne(
        'SELECT created_by FROM families WHERE id = @id::uuid',
        parameters: {'id': id},
      );
      if (family == null) {
        return _error(404, 'Familie nicht gefunden');
      }
      if (family['created_by'].toString() == memberUserId) {
        return _error(400, 'Der Ersteller kann nicht entfernt werden');
      }

      final result = await _db.queryOne(
        '''
        DELETE FROM family_members
        WHERE family_id = @family_id::uuid AND user_id = @user_id::uuid
        RETURNING id
        ''',
        parameters: {'family_id': id, 'user_id': memberUserId},
      );

      if (result == null) {
        return _error(404, 'Mitglied nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'message': 'Mitglied wurde entfernt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Member-Remove-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<bool> _isMember(String familyId, String userId) async {
    final row = await _db.queryOne(
      '''
      SELECT id FROM family_members
      WHERE family_id = @family_id::uuid AND user_id = @user_id::uuid
      ''',
      parameters: {'family_id': familyId, 'user_id': userId},
    );
    return row != null;
  }

  Future<bool> _isOwner(String familyId, String userId) async {
    final row = await _db.queryOne(
      '''
      SELECT role FROM family_members
      WHERE family_id = @family_id::uuid AND user_id = @user_id::uuid
      ''',
      parameters: {'family_id': familyId, 'user_id': userId},
    );
    if (row == null) return false;
    return row['role'].toString() == 'owner';
  }

  Map<String, dynamic> _serialize(Map<String, dynamic> family) {
    return {
      'id': family['id'].toString(),
      'name': family['name'],
      'created_by': family['created_by'].toString(),
      'created_at': (family['created_at'] as DateTime).toIso8601String(),
      'updated_at': (family['updated_at'] as DateTime).toIso8601String(),
      if (family.containsKey('member_role'))
        'member_role': family['member_role']?.toString(),
    };
  }

  Map<String, dynamic> _serializeMember(Map<String, dynamic> m) {
    return {
      'id': m['id'].toString(),
      'family_id': m['family_id'].toString(),
      'user_id': m['user_id'].toString(),
      'role': m['role'].toString(),
      'joined_at': (m['joined_at'] as DateTime).toIso8601String(),
      if (m.containsKey('user_name')) 'user_name': m['user_name'],
      if (m.containsKey('user_email')) 'user_email': m['user_email'],
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
