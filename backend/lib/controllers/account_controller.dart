import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import '../database/database.dart';

/// Controller für Benutzer-Kontoverwaltung
/// Alle Routen sind authentifiziert (auth-Middleware im Server)
class AccountController {
  final Database _db;

  AccountController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _getAccount);
    router.put('/', _updateAccount);
    router.delete('/', _deleteAccount);
    router.put('/password', _changePassword);
    router.get('/export', _exportData);
    router.get('/audit-log', _getAuditLog);

    return router;
  }

  /// GET /account - Eigene Daten abrufen
  Future<Response> _getAccount(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final user = await _db.queryOne(
        '''
        SELECT id, email, name, role, is_active, email_verified, created_at, updated_at
        FROM users
        WHERE id = @id::uuid
        ''',
        parameters: {'id': userId},
      );

      if (user == null) {
        return _error(404, 'Benutzer nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'user': _sanitizeUser(user)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Account-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /account - Profil aktualisieren
  Future<Response> _updateAccount(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final email = body['email'] as String?;

      // Mindestens ein Feld muss angegeben sein
      if (name == null && email == null) {
        return _error(400, 'Mindestens ein Feld zum Aktualisieren angeben');
      }

      // E-Mail-Validierung
      if (email != null && !email.contains('@')) {
        return _error(400, 'Ungültige E-Mail-Adresse');
      }

      // E-Mail-Eindeutigkeit prüfen
      if (email != null) {
        final existing = await _db.queryOne(
          'SELECT id FROM users WHERE email = @email AND id != @id::uuid',
          parameters: {
            'email': email.toLowerCase().trim(),
            'id': userId,
          },
        );
        if (existing != null) {
          return _error(409, 'E-Mail-Adresse wird bereits verwendet');
        }
      }

      // Update zusammenbauen
      final updates = <String>[];
      final params = <String, dynamic>{'id': userId};

      if (name != null && name.trim().isNotEmpty) {
        updates.add('name = @name');
        params['name'] = name.trim();
      }
      if (email != null) {
        updates.add('email = @email');
        params['email'] = email.toLowerCase().trim();
      }

      final user = await _db.queryOne(
        '''
        UPDATE users
        SET ${updates.join(', ')}
        WHERE id = @id::uuid
        RETURNING id, email, name, role, is_active, email_verified, created_at, updated_at
        ''',
        parameters: params,
      );

      if (user == null) {
        return _error(404, 'Benutzer nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'user': _sanitizeUser(user)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Account-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /account - Konto löschen (DSGVO)
  Future<Response> _deleteAccount(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      // Benutzer und alle zugehörigen Daten löschen
      await _db.transaction((tx) async {
        // Tiere des Benutzers löschen
        await tx.execute(
          Sql.named('DELETE FROM pets WHERE owner_id = @id::uuid'),
          parameters: {'id': userId},
        );

        // Benutzer löschen
        await tx.execute(
          Sql.named('DELETE FROM users WHERE id = @id::uuid'),
          parameters: {'id': userId},
        );
      });

      return Response.ok(
        jsonEncode({'message': 'Konto und alle zugehörigen Daten wurden gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Account-Lösch-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /account/password - Passwort ändern
  Future<Response> _changePassword(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final currentPassword = body['current_password'] as String?;
      final newPassword = body['new_password'] as String?;

      if (currentPassword == null || newPassword == null) {
        return _error(400, 'Aktuelles und neues Passwort sind erforderlich');
      }

      if (newPassword.length < 8) {
        return _error(400, 'Neues Passwort muss mindestens 8 Zeichen lang sein');
      }

      // Aktuelles Passwort prüfen
      final user = await _db.queryOne(
        'SELECT password_hash FROM users WHERE id = @id::uuid',
        parameters: {'id': userId},
      );

      if (user == null) {
        return _error(404, 'Benutzer nicht gefunden');
      }

      if (!BCrypt.checkpw(currentPassword, user['password_hash'] as String)) {
        return _error(401, 'Aktuelles Passwort ist falsch');
      }

      // Neues Passwort setzen
      final newHash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await _db.query(
        'UPDATE users SET password_hash = @hash WHERE id = @id::uuid',
        parameters: {'hash': newHash, 'id': userId},
      );

      return Response.ok(
        jsonEncode({'message': 'Passwort wurde geändert'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Passwort-Änderungs-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /account/audit-log — Eigenes Audit-Log abrufen
  Future<Response> _getAuditLog(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final params = request.requestedUri.queryParameters;
      final limit =
          int.tryParse(params['limit'] ?? '') ?? 50;

      final entries = await _db.queryAll(
        '''
        SELECT id, action, resource_type, resource_id, details, ip_address, created_at
        FROM audit_log
        WHERE user_id = @user_id::uuid
        ORDER BY created_at DESC
        LIMIT @limit
        ''',
        parameters: {'user_id': userId, 'limit': limit},
      );

      return Response.ok(
        jsonEncode({
          'audit_log': entries.map((e) => {
            'id': e['id'].toString(),
            'action': e['action'],
            'resource_type': e['resource_type'],
            'resource_id': e['resource_id']?.toString(),
            'details': e['details'],
            'ip_address': e['ip_address'],
            'created_at': (e['created_at'] as DateTime).toIso8601String(),
          }).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getAuditLog Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /account/export — DSGVO-Datenexport (alle Daten als JSON)
  Future<Response> _exportData(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final user = await _db.queryOne(
        'SELECT id, email, name, role, is_active, created_at FROM users WHERE id = @id::uuid',
        parameters: {'id': userId},
      );
      if (user == null) return _error(404, 'Benutzer nicht gefunden');

      final pets = await _db.queryAll(
        'SELECT id, name, species::text AS species, breed, date_of_birth, microchip_id, created_at FROM pets WHERE owner_id = @id::uuid',
        parameters: {'id': userId},
      );

      final petIds = pets.map((p) => "'${p['id']}'").join(',');

      List<Map<String, dynamic>> vaccinations = [];
      List<Map<String, dynamic>> medications = [];
      List<Map<String, dynamic>> allergies = [];
      List<Map<String, dynamic>> reminders = [];

      if (petIds.isNotEmpty) {
        vaccinations = await _db.queryAll(
          'SELECT pet_id, vaccine_name, batch_number, administered_at, valid_until FROM vaccinations WHERE pet_id::text = ANY(ARRAY[$petIds]::text[]) ORDER BY administered_at DESC',
          parameters: {},
        );
        medications = await _db.queryAll(
          'SELECT pet_id, medication_name, dosage, frequency, start_date, end_date, status::text AS status FROM medications WHERE pet_id::text = ANY(ARRAY[$petIds]::text[]) ORDER BY start_date DESC',
          parameters: {},
        );
        allergies = await _db.queryAll(
          'SELECT pet_id, allergen, category, severity::text AS severity, reaction, diagnosed_at FROM pet_allergies WHERE pet_id::text = ANY(ARRAY[$petIds]::text[]) ORDER BY allergen ASC',
          parameters: {},
        );
      }

      reminders = await _db.queryAll(
        'SELECT id, pet_id, title, due_date, reminder_type::text AS reminder_type, is_done, created_at FROM reminders WHERE user_id = @id::uuid ORDER BY due_date ASC',
        parameters: {'id': userId},
      );

      final appointments = await _db.queryAll(
        'SELECT id, pet_id, title, scheduled_at, status::text AS status, notes, created_at FROM appointments WHERE owner_id = @id::uuid ORDER BY scheduled_at DESC',
        parameters: {'id': userId},
      );

      final emergencyContacts = await _db.queryAll(
        'SELECT name, relationship, phone, email, is_primary FROM emergency_contacts WHERE owner_id = @id::uuid ORDER BY is_primary DESC',
        parameters: {'id': userId},
      );

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'format_version': '1.0',
        'user': {
          'id': user['id'].toString(),
          'email': user['email'],
          'name': user['name'],
          'role': user['role'].toString(),
          'created_at': (user['created_at'] as DateTime).toIso8601String(),
        },
        'pets': pets.map((p) => {
              'id': p['id'].toString(),
              'name': p['name'],
              'species': p['species'],
              'breed': p['breed'],
              'date_of_birth': p['date_of_birth']?.toString(),
              'microchip_id': p['microchip_id'],
            }).toList(),
        'vaccinations': vaccinations.map((v) => {
              'pet_id': v['pet_id'].toString(),
              'vaccine_name': v['vaccine_name'],
              'batch_number': v['batch_number'],
              'administered_at': v['administered_at']?.toString(),
              'valid_until': v['valid_until']?.toString(),
            }).toList(),
        'medications': medications.map((m) => {
              'pet_id': m['pet_id'].toString(),
              'medication_name': m['medication_name'],
              'dosage': m['dosage'],
              'frequency': m['frequency'],
              'start_date': m['start_date']?.toString(),
              'end_date': m['end_date']?.toString(),
              'status': m['status'],
            }).toList(),
        'allergies': allergies.map((a) => {
              'pet_id': a['pet_id'].toString(),
              'allergen': a['allergen'],
              'category': a['category'],
              'severity': a['severity'],
              'reaction': a['reaction'],
              'diagnosed_at': a['diagnosed_at']?.toString(),
            }).toList(),
        'appointments': appointments.map((a) => {
              'pet_id': a['pet_id']?.toString(),
              'title': a['title'],
              'scheduled_at': (a['scheduled_at'] as DateTime).toIso8601String(),
              'status': a['status'],
              'notes': a['notes'],
            }).toList(),
        'reminders': reminders.map((r) => {
              'pet_id': r['pet_id']?.toString(),
              'title': r['title'],
              'due_date': r['due_date']?.toString(),
              'type': r['reminder_type'],
              'is_done': r['is_done'],
            }).toList(),
        'emergency_contacts': emergencyContacts.map((c) => {
              'name': c['name'],
              'relationship': c['relationship'],
              'phone': c['phone'],
              'email': c['email'],
              'is_primary': c['is_primary'],
            }).toList(),
      };

      return Response.ok(
        jsonEncode(exportData),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Content-Disposition':
              'attachment; filename="mypet-export-${DateTime.now().millisecondsSinceEpoch}.json"',
        },
      );
    } catch (e) {
      print('❌ exportData Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitizeUser(Map<String, dynamic> user) {
    return {
      'id': user['id'].toString(),
      'email': user['email'],
      'name': user['name'],
      'role': user['role'].toString(),
      'is_active': user['is_active'],
      'email_verified': user['email_verified'],
      'created_at': (user['created_at'] as DateTime).toIso8601String(),
      'updated_at': (user['updated_at'] as DateTime).toIso8601String(),
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
