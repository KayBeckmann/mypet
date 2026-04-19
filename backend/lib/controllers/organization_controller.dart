import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../database/database.dart';

/// Controller für Organisationen (Praxen & Dienstleister-Firmen)
/// Alle Routen sind authentifiziert (auth-Middleware im Server)
class OrganizationController {
  final Database _db;

  OrganizationController(this._db);

  static const _validTypes = ['vet_practice', 'provider_company'];
  static const _validMemberRoles = ['admin', 'member', 'readonly'];

  /// Standard-Berechtigungsgruppen für Tierarztpraxen
  static const _vetPracticeDefaultGroups = [
    {
      'name': 'Praxis-Admin',
      'description': 'Voller Zugriff auf alle Praxis-Funktionen',
      'permissions': {
        'patients_read': true,
        'patients_write': true,
        'medical_read': true,
        'medical_write': true,
        'appointments_read': true,
        'appointments_manage': true,
        'media_upload': true,
        'invoices_create': true,
        'collegial_notes_read': true,
        'members_manage': true,
        'organization_manage': true,
      }
    },
    {
      'name': 'Tierarzt',
      'description': 'Medizinische Akten, Termine, Medien, kollegiale Notizen',
      'permissions': {
        'patients_read': true,
        'patients_write': true,
        'medical_read': true,
        'medical_write': true,
        'appointments_read': true,
        'appointments_manage': true,
        'media_upload': true,
        'invoices_create': false,
        'collegial_notes_read': true,
        'members_manage': false,
        'organization_manage': false,
      }
    },
    {
      'name': 'TFA',
      'description': 'Termine, Patienten-Stammdaten, eingeschränkte Akten',
      'permissions': {
        'patients_read': true,
        'patients_write': true,
        'medical_read': true,
        'medical_write': false,
        'appointments_read': true,
        'appointments_manage': true,
        'media_upload': true,
        'invoices_create': false,
        'collegial_notes_read': false,
        'members_manage': false,
        'organization_manage': false,
      }
    },
    {
      'name': 'Azubi',
      'description': 'Nur Lesen, keine sensiblen Daten',
      'permissions': {
        'patients_read': true,
        'patients_write': false,
        'medical_read': false,
        'medical_write': false,
        'appointments_read': true,
        'appointments_manage': false,
        'media_upload': false,
        'invoices_create': false,
        'collegial_notes_read': false,
        'members_manage': false,
        'organization_manage': false,
      }
    },
    {
      'name': 'Buchhaltung',
      'description': 'Rechnungen, keine medizinischen Daten',
      'permissions': {
        'patients_read': true,
        'patients_write': false,
        'medical_read': false,
        'medical_write': false,
        'appointments_read': true,
        'appointments_manage': false,
        'media_upload': false,
        'invoices_create': true,
        'collegial_notes_read': false,
        'members_manage': false,
        'organization_manage': false,
      }
    },
  ];

  /// Standard-Berechtigungsgruppen für Dienstleister-Firmen
  static const _providerCompanyDefaultGroups = [
    {
      'name': 'Firmen-Admin',
      'description': 'Voller Zugriff auf alle Firmen-Funktionen',
      'permissions': {
        'customers_read': true,
        'customers_write': true,
        'appointments_read': true,
        'appointments_manage': true,
        'services_document': true,
        'members_manage': true,
        'organization_manage': true,
      }
    },
    {
      'name': 'Mitarbeiter',
      'description': 'Kunden, Termine, Leistungen dokumentieren',
      'permissions': {
        'customers_read': true,
        'customers_write': true,
        'appointments_read': true,
        'appointments_manage': true,
        'services_document': true,
        'members_manage': false,
        'organization_manage': false,
      }
    },
    {
      'name': 'Azubi',
      'description': 'Eingeschränkter Zugriff',
      'permissions': {
        'customers_read': true,
        'customers_write': false,
        'appointments_read': true,
        'appointments_manage': false,
        'services_document': false,
        'members_manage': false,
        'organization_manage': false,
      }
    },
  ];

  Router get router {
    final router = Router();

    router.get('/', _listOrganizations);
    router.post('/', _createOrganization);
    router.get('/<id>', _getOrganization);
    router.put('/<id>', _updateOrganization);
    router.delete('/<id>', _deleteOrganization);

    // Mitglieder
    router.get('/<id>/members', _listMembers);
    router.post('/<id>/members/invite', _inviteMember);
    router.put('/<id>/members/<userId>', _updateMember);
    router.delete('/<id>/members/<userId>', _removeMember);

    // Berechtigungsgruppen
    router.get('/<id>/permission-groups', _listPermissionGroups);
    router.post('/<id>/permission-groups', _createPermissionGroup);

    return router;
  }

  /// GET /organizations - Eigene Organisationen
  Future<Response> _listOrganizations(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final orgs = await _db.queryAll(
        '''
        SELECT o.id, o.name, o.type, o.provider_type, o.description,
               o.address, o.phone, o.mobile, o.email, o.website,
               o.opening_hours, o.service_radius_km, o.specialization,
               o.created_by, o.is_active, o.created_at, o.updated_at,
               m.role AS member_role, m.position AS member_position
        FROM organizations o
        INNER JOIN organization_members m ON m.organization_id = o.id
        WHERE m.user_id = @user_id::uuid
          AND m.is_active = true
          AND o.is_active = true
        ORDER BY o.created_at DESC
        ''',
        parameters: {'user_id': userId},
      );

      return Response.ok(
        jsonEncode({
          'organizations': orgs.map(_serializeOrganization).toList(),
          'count': orgs.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Organizations-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /organizations - Neue Organisation erstellen
  Future<Response> _createOrganization(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final type = body['type'] as String?;

      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }
      if (type == null || !_validTypes.contains(type)) {
        return _error(400,
            'Gültiger Typ ist erforderlich (vet_practice | provider_company)');
      }

      final org = await _db.transaction((tx) async {
        // Organisation anlegen
        final orgResult = await tx.execute(
          Sql.named('''
            INSERT INTO organizations (
              name, type, provider_type, description, address, phone, mobile,
              email, website, opening_hours, service_radius_km, specialization, created_by
            ) VALUES (
              @name, @type::organization_type, @provider_type, @description,
              @address, @phone, @mobile, @email, @website, @opening_hours,
              @service_radius_km, @specialization, @created_by::uuid
            )
            RETURNING id, name, type, provider_type, description, address,
                      phone, mobile, email, website, opening_hours,
                      service_radius_km, specialization, created_by,
                      is_active, created_at, updated_at
          '''),
          parameters: {
            'name': name.trim(),
            'type': type,
            'provider_type': (body['provider_type'] as String?)?.trim(),
            'description': (body['description'] as String?)?.trim(),
            'address': (body['address'] as String?)?.trim(),
            'phone': (body['phone'] as String?)?.trim(),
            'mobile': (body['mobile'] as String?)?.trim(),
            'email': (body['email'] as String?)?.trim(),
            'website': (body['website'] as String?)?.trim(),
            'opening_hours': (body['opening_hours'] as String?)?.trim(),
            'service_radius_km': body['service_radius_km'],
            'specialization': (body['specialization'] as String?)?.trim(),
            'created_by': userId,
          },
        );

        final orgRow = orgResult.first.toColumnMap();
        final orgId = orgRow['id'].toString();

        // Standard-Berechtigungsgruppen anlegen
        final defaultGroups = type == 'vet_practice'
            ? _vetPracticeDefaultGroups
            : _providerCompanyDefaultGroups;

        String? adminGroupId;
        for (final group in defaultGroups) {
          final groupResult = await tx.execute(
            Sql.named('''
              INSERT INTO permission_groups (
                organization_id, name, description, permissions, is_system
              ) VALUES (
                @organization_id::uuid, @name, @description,
                @permissions::jsonb, true
              )
              RETURNING id, name
            '''),
            parameters: {
              'organization_id': orgId,
              'name': group['name'],
              'description': group['description'],
              'permissions': jsonEncode(group['permissions']),
            },
          );
          final groupRow = groupResult.first.toColumnMap();
          final groupName = groupRow['name'] as String;
          if (groupName.toLowerCase().contains('admin')) {
            adminGroupId = groupRow['id'].toString();
          }
        }

        // Ersteller als Admin-Mitglied hinzufügen
        await tx.execute(
          Sql.named('''
            INSERT INTO organization_members (
              organization_id, user_id, role, permission_group_id
            ) VALUES (
              @organization_id::uuid, @user_id::uuid, 'admin',
              @permission_group_id::uuid
            )
          '''),
          parameters: {
            'organization_id': orgId,
            'user_id': userId,
            'permission_group_id': adminGroupId,
          },
        );

        return orgRow;
      });

      return Response(
        201,
        body: jsonEncode({'organization': _serializeOrganization(org)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Organization-Create-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /organizations/:id - Organisation abrufen
  Future<Response> _getOrganization(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      // Prüfen ob Benutzer Mitglied ist
      final membership = await _getMembership(id, userId);
      if (membership == null) {
        return _error(404, 'Organisation nicht gefunden');
      }

      final org = await _db.queryOne(
        '''
        SELECT id, name, type, provider_type, description, address,
               phone, mobile, email, website, opening_hours,
               service_radius_km, specialization, created_by,
               is_active, created_at, updated_at
        FROM organizations
        WHERE id = @id::uuid AND is_active = true
        ''',
        parameters: {'id': id},
      );

      if (org == null) {
        return _error(404, 'Organisation nicht gefunden');
      }

      final result = _serializeOrganization(org);
      result['member_role'] = membership['role'].toString();
      result['member_position'] = membership['position'];

      return Response.ok(
        jsonEncode({'organization': result}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Organization-Get-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /organizations/:id - Organisation aktualisieren (nur Admin)
  Future<Response> _updateOrganization(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireAdmin(id, userId)) {
        return _error(403, 'Nur Admins können die Organisation bearbeiten');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final updates = <String>[];
      final params = <String, dynamic>{'id': id};

      for (final field in [
        'name',
        'provider_type',
        'description',
        'address',
        'phone',
        'mobile',
        'email',
        'website',
        'opening_hours',
        'specialization',
      ]) {
        if (body.containsKey(field)) {
          updates.add('$field = @$field');
          params[field] = (body[field] as String?)?.trim();
        }
      }
      if (body.containsKey('service_radius_km')) {
        updates.add('service_radius_km = @service_radius_km');
        params['service_radius_km'] = body['service_radius_km'];
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Felder zum Aktualisieren');
      }

      final org = await _db.queryOne(
        '''
        UPDATE organizations
        SET ${updates.join(', ')}
        WHERE id = @id::uuid
        RETURNING id, name, type, provider_type, description, address,
                  phone, mobile, email, website, opening_hours,
                  service_radius_km, specialization, created_by,
                  is_active, created_at, updated_at
        ''',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'organization': _serializeOrganization(org!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Organization-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /organizations/:id - Organisation löschen (nur Gründer)
  Future<Response> _deleteOrganization(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final org = await _db.queryOne(
        'SELECT created_by FROM organizations WHERE id = @id::uuid',
        parameters: {'id': id},
      );

      if (org == null) {
        return _error(404, 'Organisation nicht gefunden');
      }

      if (org['created_by'].toString() != userId) {
        return _error(403, 'Nur der Gründer kann die Organisation löschen');
      }

      await _db.query(
        'UPDATE organizations SET is_active = false WHERE id = @id::uuid',
        parameters: {'id': id},
      );

      return Response.ok(
        jsonEncode({'message': 'Organisation wurde gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Organization-Delete-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /organizations/:id/members - Mitglieder auflisten
  Future<Response> _listMembers(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (await _getMembership(id, userId) == null) {
        return _error(404, 'Organisation nicht gefunden');
      }

      final members = await _db.queryAll(
        '''
        SELECT m.id, m.organization_id, m.user_id, m.role, m.position,
               m.permission_group_id, m.joined_at, m.is_active,
               u.name AS user_name, u.email AS user_email,
               pg.name AS permission_group_name
        FROM organization_members m
        INNER JOIN users u ON u.id = m.user_id
        LEFT JOIN permission_groups pg ON pg.id = m.permission_group_id
        WHERE m.organization_id = @org_id::uuid
        ORDER BY m.joined_at ASC
        ''',
        parameters: {'org_id': id},
      );

      return Response.ok(
        jsonEncode({
          'members': members.map(_serializeMember).toList(),
          'count': members.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Members-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /organizations/:id/members/invite - Mitglied einladen
  Future<Response> _inviteMember(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireAdmin(id, userId)) {
        return _error(403, 'Nur Admins können Mitglieder einladen');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final email = body['email'] as String?;
      final role = body['role'] as String? ?? 'member';
      final position = body['position'] as String?;
      final permissionGroupId = body['permission_group_id'] as String?;

      if (email == null || email.trim().isEmpty || !email.contains('@')) {
        return _error(400, 'Gültige E-Mail-Adresse ist erforderlich');
      }
      if (!_validMemberRoles.contains(role)) {
        return _error(400, 'Ungültige Rolle: $role');
      }

      // Prüfen ob bereits ein Mitglied mit dieser E-Mail existiert
      final existingUser = await _db.queryOne(
        'SELECT id FROM users WHERE email = @email',
        parameters: {'email': email.toLowerCase().trim()},
      );
      if (existingUser != null) {
        final existingMember = await _db.queryOne(
          '''
          SELECT id FROM organization_members
          WHERE organization_id = @org_id::uuid AND user_id = @user_id::uuid
          ''',
          parameters: {
            'org_id': id,
            'user_id': existingUser['id'].toString(),
          },
        );
        if (existingMember != null) {
          return _error(
              409, 'Benutzer ist bereits Mitglied dieser Organisation');
        }
      }

      final invitation = await _db.queryOne(
        '''
        INSERT INTO organization_invitations (
          organization_id, email, role, position, permission_group_id, invited_by
        ) VALUES (
          @organization_id::uuid, @email, @role::organization_member_role,
          @position, @permission_group_id,
          @invited_by::uuid
        )
        RETURNING id, organization_id, email, role, position,
                  permission_group_id, invitation_code, invited_by,
                  status, expires_at, created_at
        ''',
        parameters: {
          'organization_id': id,
          'email': email.toLowerCase().trim(),
          'role': role,
          'position': position?.trim(),
          'permission_group_id': permissionGroupId,
          'invited_by': userId,
        },
      );

      // TODO: E-Mail-Versand wenn SMTP konfiguriert ist

      return Response(
        201,
        body: jsonEncode({'invitation': _serializeInvitation(invitation!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Member-Invite-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /organizations/:id/members/:userId - Rolle/Position ändern
  Future<Response> _updateMember(
      Request request, String id, String memberUserId) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireAdmin(id, userId)) {
        return _error(403, 'Nur Admins können Mitglieder bearbeiten');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final updates = <String>[];
      final params = <String, dynamic>{
        'org_id': id,
        'user_id': memberUserId,
      };

      if (body.containsKey('role')) {
        final role = body['role'] as String?;
        if (role == null || !_validMemberRoles.contains(role)) {
          return _error(400, 'Ungültige Rolle');
        }
        updates.add('role = @role::organization_member_role');
        params['role'] = role;
      }
      if (body.containsKey('position')) {
        updates.add('position = @position');
        params['position'] = (body['position'] as String?)?.trim();
      }
      if (body.containsKey('permission_group_id')) {
        updates.add('permission_group_id = @permission_group_id');
        params['permission_group_id'] = body['permission_group_id'];
      }
      if (body.containsKey('is_active')) {
        updates.add('is_active = @is_active');
        params['is_active'] = body['is_active'];
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Felder zum Aktualisieren');
      }

      final member = await _db.queryOne(
        '''
        UPDATE organization_members
        SET ${updates.join(', ')}
        WHERE organization_id = @org_id::uuid AND user_id = @user_id::uuid
        RETURNING id, organization_id, user_id, role, position,
                  permission_group_id, joined_at, is_active
        ''',
        parameters: params,
      );

      if (member == null) {
        return _error(404, 'Mitglied nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'member': _serializeMember(member)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Member-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /organizations/:id/members/:userId - Mitglied entfernen
  Future<Response> _removeMember(
      Request request, String id, String memberUserId) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireAdmin(id, userId)) {
        return _error(403, 'Nur Admins können Mitglieder entfernen');
      }

      // Gründer darf nicht entfernt werden
      final org = await _db.queryOne(
        'SELECT created_by FROM organizations WHERE id = @id::uuid',
        parameters: {'id': id},
      );
      if (org != null && org['created_by'].toString() == memberUserId) {
        return _error(400, 'Der Gründer kann nicht entfernt werden');
      }

      final result = await _db.queryOne(
        '''
        DELETE FROM organization_members
        WHERE organization_id = @org_id::uuid AND user_id = @user_id::uuid
        RETURNING id
        ''',
        parameters: {'org_id': id, 'user_id': memberUserId},
      );

      if (result == null) {
        return _error(404, 'Mitglied nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'message': 'Mitglied wurde entfernt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Member-Remove-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /organizations/:id/permission-groups - Berechtigungsgruppen
  Future<Response> _listPermissionGroups(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (await _getMembership(id, userId) == null) {
        return _error(404, 'Organisation nicht gefunden');
      }

      final groups = await _db.queryAll(
        '''
        SELECT id, organization_id, name, description, permissions,
               is_system, created_at, updated_at
        FROM permission_groups
        WHERE organization_id = @org_id::uuid
        ORDER BY is_system DESC, name ASC
        ''',
        parameters: {'org_id': id},
      );

      return Response.ok(
        jsonEncode({
          'permission_groups': groups.map(_serializePermissionGroup).toList(),
          'count': groups.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Groups-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /organizations/:id/permission-groups - Berechtigungsgruppe erstellen
  Future<Response> _createPermissionGroup(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      if (!await _requireAdmin(id, userId)) {
        return _error(
            403, 'Nur Admins können Berechtigungsgruppen erstellen');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      final permissions = body['permissions'] as Map<String, dynamic>? ?? {};

      final group = await _db.queryOne(
        '''
        INSERT INTO permission_groups (
          organization_id, name, description, permissions, is_system
        ) VALUES (
          @organization_id::uuid, @name, @description, @permissions::jsonb, false
        )
        RETURNING id, organization_id, name, description, permissions,
                  is_system, created_at, updated_at
        ''',
        parameters: {
          'organization_id': id,
          'name': name.trim(),
          'description': (body['description'] as String?)?.trim(),
          'permissions': jsonEncode(permissions),
        },
      );

      return Response(
        201,
        body: jsonEncode({'permission_group': _serializePermissionGroup(group!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Permission-Group-Create-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// Prüft ob Benutzer Admin in der Organisation ist
  Future<bool> _requireAdmin(String orgId, String userId) async {
    final membership = await _getMembership(orgId, userId);
    if (membership == null) return false;
    return membership['role'].toString() == 'admin';
  }

  /// Mitgliedschaft prüfen
  Future<Map<String, dynamic>?> _getMembership(
      String orgId, String userId) async {
    return await _db.queryOne(
      '''
      SELECT role, position, permission_group_id
      FROM organization_members
      WHERE organization_id = @org_id::uuid
        AND user_id = @user_id::uuid
        AND is_active = true
      ''',
      parameters: {'org_id': orgId, 'user_id': userId},
    );
  }

  Map<String, dynamic> _serializeOrganization(Map<String, dynamic> org) {
    return {
      'id': org['id'].toString(),
      'name': org['name'],
      'type': org['type'].toString(),
      'provider_type': org['provider_type'],
      'description': org['description'],
      'address': org['address'],
      'phone': org['phone'],
      'mobile': org['mobile'],
      'email': org['email'],
      'website': org['website'],
      'opening_hours': org['opening_hours'],
      'service_radius_km': org['service_radius_km'],
      'specialization': org['specialization'],
      'created_by': org['created_by']?.toString(),
      'is_active': org['is_active'],
      'created_at': (org['created_at'] as DateTime).toIso8601String(),
      'updated_at': (org['updated_at'] as DateTime).toIso8601String(),
      if (org.containsKey('member_role'))
        'member_role': org['member_role']?.toString(),
      if (org.containsKey('member_position'))
        'member_position': org['member_position'],
    };
  }

  Map<String, dynamic> _serializeMember(Map<String, dynamic> member) {
    return {
      'id': member['id'].toString(),
      'organization_id': member['organization_id'].toString(),
      'user_id': member['user_id'].toString(),
      'role': member['role'].toString(),
      'position': member['position'],
      'permission_group_id': member['permission_group_id']?.toString(),
      'permission_group_name': member['permission_group_name'],
      'user_name': member['user_name'],
      'user_email': member['user_email'],
      'joined_at': (member['joined_at'] as DateTime).toIso8601String(),
      'is_active': member['is_active'],
    };
  }

  Map<String, dynamic> _serializePermissionGroup(Map<String, dynamic> group) {
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

  Map<String, dynamic> _serializeInvitation(Map<String, dynamic> inv) {
    return {
      'id': inv['id'].toString(),
      'organization_id': inv['organization_id'].toString(),
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
