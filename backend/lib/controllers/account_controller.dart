import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
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
