import 'dart:convert';
import 'dart:math';
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
    router.post('/<id>/members', _sendInvitation);
    router.delete('/<id>/members/<userId>', _removeMember);

    // Interne Einladungen (für aktuellen User)
    router.get('/invitations', _listMyInvitations);
    router.post('/invitations/<invId>/accept', _acceptInvitation);
    router.post('/invitations/<invId>/reject', _rejectInvitation);

    // QR-/Code-basiertes Beitreten (bestehend)
    router.post('/<id>/invite-code', _generateInviteCode);
    router.get('/join/<code>', _lookupInviteCode);
    router.post('/join/<code>', _joinByCode);

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

  /// POST /families/:id/members  → sendet interne Einladung per E-Mail-Suche
  Future<Response> _sendInvitation(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann Mitglieder einladen');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final message = body['message'] as String?;

      if (email == null || email.trim().isEmpty || !email.contains('@')) {
        return _error(400, 'Gültige E-Mail-Adresse ist erforderlich');
      }

      final invitee = await _db.queryOne(
        'SELECT id, name FROM users WHERE email = @email',
        parameters: {'email': email.toLowerCase().trim()},
      );
      if (invitee == null) {
        return _error(404, 'Benutzer mit dieser E-Mail nicht gefunden');
      }
      final inviteeId = invitee['id'].toString();

      // Bereits Mitglied?
      if (await _isMember(id, inviteeId)) {
        return _error(409, 'Benutzer ist bereits Mitglied dieser Familie');
      }

      try {
        final inv = await _db.queryOne(
          '''
          INSERT INTO family_invitations
            (family_id, invitee_id, invited_by, message)
          VALUES
            (@family_id::uuid, @invitee_id::uuid, @invited_by::uuid, @message)
          ON CONFLICT (family_id, invitee_id) DO UPDATE
            SET status = 'pending', message = @message, updated_at = NOW()
          RETURNING id, family_id, invitee_id, invited_by, status, message, created_at
          ''',
          parameters: {
            'family_id': id,
            'invitee_id': inviteeId,
            'invited_by': userId,
            'message': message,
          },
        );
        return Response(
          201,
          body: jsonEncode({'invitation': _serializeInvitation(inv!)}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      print('❌ Family-Invite-Send-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /families/invitations  → offene Einladungen für aktuellen User
  Future<Response> _listMyInvitations(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final invitations = await _db.queryAll(
        '''
        SELECT fi.id, fi.family_id, fi.invitee_id, fi.invited_by,
               fi.status, fi.message, fi.created_at,
               f.name AS family_name,
               u.name AS invited_by_name,
               (SELECT COUNT(*) FROM family_members WHERE family_id = fi.family_id)::int AS member_count
        FROM family_invitations fi
        INNER JOIN families f ON f.id = fi.family_id
        INNER JOIN users u ON u.id = fi.invited_by
        WHERE fi.invitee_id = @user_id::uuid
          AND fi.status = 'pending'
        ORDER BY fi.created_at DESC
        ''',
        parameters: {'user_id': userId},
      );

      return Response.ok(
        jsonEncode({
          'invitations': invitations.map(_serializeInvitationFull).toList(),
          'count': invitations.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Invitations-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /families/invitations/:invId/accept
  Future<Response> _acceptInvitation(Request request, String invId) async {
    try {
      final userId = request.context['userId'] as String;

      final inv = await _db.queryOne(
        '''
        SELECT family_id FROM family_invitations
        WHERE id = @id::uuid AND invitee_id = @user_id::uuid AND status = 'pending'
        ''',
        parameters: {'id': invId, 'user_id': userId},
      );
      if (inv == null) return _error(404, 'Einladung nicht gefunden');

      final familyId = inv['family_id'].toString();

      await _db.transaction((tx) async {
        await tx.execute(
          Sql.named('''
            UPDATE family_invitations SET status = 'accepted', updated_at = NOW()
            WHERE id = @id::uuid
          '''),
          parameters: {'id': invId},
        );
        await tx.execute(
          Sql.named('''
            INSERT INTO family_members (family_id, user_id, role)
            VALUES (@family_id::uuid, @user_id::uuid, 'member')
            ON CONFLICT DO NOTHING
          '''),
          parameters: {'family_id': familyId, 'user_id': userId},
        );
      });

      return Response.ok(
        jsonEncode({'message': 'Einladung angenommen', 'family_id': familyId}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Invitation-Accept-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /families/invitations/:invId/reject
  Future<Response> _rejectInvitation(Request request, String invId) async {
    try {
      final userId = request.context['userId'] as String;

      final result = await _db.queryOne(
        '''
        UPDATE family_invitations SET status = 'rejected', updated_at = NOW()
        WHERE id = @id::uuid AND invitee_id = @user_id::uuid AND status = 'pending'
        RETURNING id
        ''',
        parameters: {'id': invId, 'user_id': userId},
      );
      if (result == null) return _error(404, 'Einladung nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Einladung abgelehnt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Family-Invitation-Reject-Fehler: $e');
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

  /// POST /families/:id/invite-code  → erzeugt 6-stelligen Einladungscode
  Future<Response> _generateInviteCode(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      if (!await _isOwner(id, userId)) {
        return _error(403, 'Nur der Ersteller kann Einladungscodes erstellen');
      }

      // Zufälligen 8-stelligen alphanumerischen Code erzeugen
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rand = Random.secure();
      final code =
          List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();

      final expiresAt =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();

      await _db.queryAll(
        '''
        INSERT INTO family_invite_codes (family_id, code, created_by, expires_at)
        VALUES (@family_id::uuid, @code, @created_by::uuid, @expires_at::timestamp)
        ON CONFLICT (family_id) DO UPDATE
          SET code = @code, created_by = @created_by::uuid,
              expires_at = @expires_at::timestamp, used_by = NULL
        ''',
        parameters: {
          'family_id': id,
          'code': code,
          'created_by': userId,
          'expires_at': expiresAt,
        },
      );

      return Response.ok(
        jsonEncode({'code': code, 'expires_at': expiresAt}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ InviteCode-Generate-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /families/join/:code  → zeigt Familieninfo ohne beizutreten
  Future<Response> _lookupInviteCode(Request request, String code) async {
    try {
      final row = await _db.queryOne(
        '''
        SELECT ic.family_id, ic.expires_at, f.name AS family_name,
               u.name AS created_by_name,
               (SELECT COUNT(*) FROM family_members WHERE family_id = ic.family_id)::int AS member_count
        FROM family_invite_codes ic
        INNER JOIN families f ON f.id = ic.family_id
        INNER JOIN users u ON u.id = ic.created_by
        WHERE ic.code = @code
          AND ic.expires_at > NOW()
          AND ic.used_by IS NULL
        ''',
        parameters: {'code': code.toUpperCase()},
      );

      if (row == null) {
        return _error(404, 'Code ungültig oder abgelaufen');
      }

      return Response.ok(
        jsonEncode({
          'family_id': row['family_id'].toString(),
          'family_name': row['family_name'],
          'created_by_name': row['created_by_name'],
          'member_count': row['member_count'],
          'expires_at': (row['expires_at'] as DateTime).toIso8601String(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ InviteCode-Lookup-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /families/join/:code  → tritt Familie bei
  Future<Response> _joinByCode(Request request, String code) async {
    try {
      final userId = request.context['userId'] as String;

      final invite = await _db.queryOne(
        '''
        SELECT ic.family_id, f.name AS family_name
        FROM family_invite_codes ic
        INNER JOIN families f ON f.id = ic.family_id
        WHERE ic.code = @code
          AND ic.expires_at > NOW()
          AND ic.used_by IS NULL
        ''',
        parameters: {'code': code.toUpperCase()},
      );

      if (invite == null) {
        return _error(404, 'Code ungültig oder abgelaufen');
      }

      final familyId = invite['family_id'].toString();

      // Bereits Mitglied?
      if (await _isMember(familyId, userId)) {
        return _error(409, 'Du bist bereits Mitglied dieser Familie');
      }

      await _db.transaction((tx) async {
        await tx.execute(
          Sql.named('''
            INSERT INTO family_members (family_id, user_id, role)
            VALUES (@family_id::uuid, @user_id::uuid, 'member')
          '''),
          parameters: {'family_id': familyId, 'user_id': userId},
        );
        await tx.execute(
          Sql.named('''
            UPDATE family_invite_codes SET used_by = @user_id::uuid
            WHERE code = @code
          '''),
          parameters: {'user_id': userId, 'code': code.toUpperCase()},
        );
      });

      return Response.ok(
        jsonEncode({'family_id': familyId, 'family_name': invite['family_name']}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ InviteCode-Join-Fehler: $e');
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

  Map<String, dynamic> _serializeInvitation(Map<String, dynamic> inv) {
    return {
      'id': inv['id'].toString(),
      'family_id': inv['family_id'].toString(),
      'invitee_id': inv['invitee_id'].toString(),
      'invited_by': inv['invited_by'].toString(),
      'status': inv['status'].toString(),
      'message': inv['message'],
      'created_at': (inv['created_at'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> _serializeInvitationFull(Map<String, dynamic> inv) {
    return {
      ..._serializeInvitation(inv),
      'family_name': inv['family_name'],
      'invited_by_name': inv['invited_by_name'],
      'member_count': inv['member_count'],
    };
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
