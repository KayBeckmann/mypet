import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Organisations-Einladungen
/// Authentifizierte Routen (auth-Middleware)
class InvitationController {
  final Database _db;

  InvitationController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _listMyInvitations);
    router.post('/<code>/accept', _acceptInvitation);
    router.post('/<code>/reject', _rejectInvitation);

    return router;
  }

  /// GET /invitations - Eigene ausstehende Einladungen
  Future<Response> _listMyInvitations(Request request) async {
    try {
      final userEmail = request.context['userEmail'] as String;

      final invitations = await _db.queryAll(
        '''
        SELECT i.id, i.organization_id, i.email, i.role, i.position,
               i.permission_group_id, i.invitation_code, i.invited_by,
               i.status, i.expires_at, i.created_at,
               o.name AS organization_name, o.type AS organization_type
        FROM organization_invitations i
        INNER JOIN organizations o ON o.id = i.organization_id
        WHERE i.email = @email
          AND i.status = 'pending'
          AND i.expires_at > NOW()
          AND o.is_active = true
        ORDER BY i.created_at DESC
        ''',
        parameters: {'email': userEmail.toLowerCase()},
      );

      return Response.ok(
        jsonEncode({
          'invitations': invitations.map(_serialize).toList(),
          'count': invitations.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Invitations-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /invitations/:code/accept - Einladung annehmen
  Future<Response> _acceptInvitation(Request request, String code) async {
    try {
      final userId = request.context['userId'] as String;
      final userEmail = request.context['userEmail'] as String;

      final invitation = await _db.queryOne(
        '''
        SELECT id, organization_id, email, role, position,
               permission_group_id, invited_by, status, expires_at
        FROM organization_invitations
        WHERE invitation_code = @code::uuid
        ''',
        parameters: {'code': code},
      );

      if (invitation == null) {
        return _error(404, 'Einladung nicht gefunden');
      }

      if (invitation['status'].toString() != 'pending') {
        return _error(400,
            'Einladung ist nicht mehr gültig (Status: ${invitation['status']})');
      }

      final expiresAt = invitation['expires_at'] as DateTime;
      if (expiresAt.isBefore(DateTime.now())) {
        await _db.query(
          "UPDATE organization_invitations SET status = 'expired' WHERE id = @id::uuid",
          parameters: {'id': invitation['id'].toString()},
        );
        return _error(400, 'Einladung ist abgelaufen');
      }

      final invitedEmail = (invitation['email'] as String).toLowerCase();
      if (invitedEmail != userEmail.toLowerCase()) {
        return _error(403, 'Diese Einladung ist für eine andere E-Mail-Adresse');
      }

      await _db.transaction((tx) async {
        // Mitglied hinzufügen (oder reaktivieren)
        await tx.execute(
          Sql.named('''
            INSERT INTO organization_members (
              organization_id, user_id, role, position, permission_group_id,
              invited_by, is_active
            ) VALUES (
              @org_id::uuid, @user_id::uuid, @role::organization_member_role,
              @position, @permission_group_id::uuid,
              @invited_by::uuid, true
            )
            ON CONFLICT (organization_id, user_id) DO UPDATE SET
              role = EXCLUDED.role,
              position = EXCLUDED.position,
              permission_group_id = EXCLUDED.permission_group_id,
              is_active = true
          '''),
          parameters: {
            'org_id': invitation['organization_id'].toString(),
            'user_id': userId,
            'role': invitation['role'].toString(),
            'position': invitation['position'],
            'permission_group_id': invitation['permission_group_id']?.toString(),
            'invited_by': invitation['invited_by']?.toString(),
          },
        );

        // Einladung als angenommen markieren
        await tx.execute(
          Sql.named(
              "UPDATE organization_invitations SET status = 'accepted' WHERE id = @id::uuid"),
          parameters: {'id': invitation['id'].toString()},
        );
      });

      return Response.ok(
        jsonEncode({
          'message': 'Einladung angenommen',
          'organization_id': invitation['organization_id'].toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Invitation-Accept-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /invitations/:code/reject - Einladung ablehnen
  Future<Response> _rejectInvitation(Request request, String code) async {
    try {
      final userEmail = request.context['userEmail'] as String;

      final invitation = await _db.queryOne(
        '''
        SELECT id, email, status
        FROM organization_invitations
        WHERE invitation_code = @code::uuid
        ''',
        parameters: {'code': code},
      );

      if (invitation == null) {
        return _error(404, 'Einladung nicht gefunden');
      }

      final invitedEmail = (invitation['email'] as String).toLowerCase();
      if (invitedEmail != userEmail.toLowerCase()) {
        return _error(403, 'Diese Einladung ist für eine andere E-Mail-Adresse');
      }

      if (invitation['status'].toString() != 'pending') {
        return _error(400, 'Einladung ist nicht mehr ausstehend');
      }

      await _db.query(
        "UPDATE organization_invitations SET status = 'rejected' WHERE id = @id::uuid",
        parameters: {'id': invitation['id'].toString()},
      );

      return Response.ok(
        jsonEncode({'message': 'Einladung abgelehnt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Invitation-Reject-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _serialize(Map<String, dynamic> inv) {
    return {
      'id': inv['id'].toString(),
      'organization_id': inv['organization_id'].toString(),
      'organization_name': inv['organization_name'],
      'organization_type': inv['organization_type']?.toString(),
      'email': inv['email'],
      'role': inv['role'].toString(),
      'position': inv['position'],
      'permission_group_id': inv['permission_group_id']?.toString(),
      'invitation_code': inv['invitation_code'].toString(),
      'invited_by': inv['invited_by']?.toString(),
      'status': inv['status'].toString(),
      'expires_at': (inv['expires_at'] as DateTime).toIso8601String(),
      'created_at': (inv['created_at'] as DateTime).toIso8601String(),
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
