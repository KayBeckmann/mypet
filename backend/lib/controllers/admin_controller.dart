import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import '../database/database.dart';

/// Controller für Superadmin-Verwaltung
class AdminController {
  final Database _db;

  AdminController(this._db);

  Router get router {
    final router = Router();

    router.get('/users', _listUsers);
    router.post('/users', _createUser);
    router.get('/users/<id>', _getUser);
    router.put('/users/<id>', _updateUser);
    router.put('/users/<id>/reset-password', _resetPassword);
    router.delete('/users/<id>', _deactivateUser);

    return router;
  }

  /// GET /admin/users?role=vet&search=...&page=1&limit=20
  Future<Response> _listUsers(Request request) async {
    try {
      final params = request.requestedUri.queryParameters;
      final role = params['role'];
      final search = params['search'];
      final page = int.tryParse(params['page'] ?? '1') ?? 1;
      final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
      final offset = (page - 1) * limit;

      final conditions = <String>[];
      final parameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (role != null && role.isNotEmpty) {
        conditions.add("role = @role::user_role");
        parameters['role'] = role;
      }
      if (search != null && search.isNotEmpty) {
        conditions.add("(name ILIKE @search OR email ILIKE @search)");
        parameters['search'] = '%$search%';
      }

      final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      final users = await _db.queryAll(
        '''
        SELECT id, email, name, role, is_active, email_verified, created_at, updated_at
        FROM users
        $where
        ORDER BY created_at DESC
        LIMIT @limit OFFSET @offset
        ''',
        parameters: parameters,
      );

      final countResult = await _db.queryOne(
        'SELECT COUNT(*) AS total FROM users $where',
        parameters: parameters,
      );
      final total = int.tryParse(countResult?['total']?.toString() ?? '0') ?? 0;

      return Response.ok(
        jsonEncode({
          'users': users.map(_sanitizeUser).toList(),
          'pagination': {
            'page': page,
            'limit': limit,
            'total': total,
            'pages': (total / limit).ceil(),
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin listUsers Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /admin/users — Benutzer anlegen
  Future<Response> _createUser(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      final role = body['role'] as String?;

      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }
      if (email == null || !email.contains('@')) {
        return _error(400, 'Gültige E-Mail-Adresse ist erforderlich');
      }
      if (password == null || password.length < 8) {
        return _error(400, 'Passwort muss mindestens 8 Zeichen lang sein');
      }
      if (role == null || !['owner', 'vet', 'provider'].contains(role)) {
        return _error(400, 'Ungültige Rolle. Erlaubt: owner, vet, provider');
      }

      final existing = await _db.queryOne(
        'SELECT id FROM users WHERE email = @email',
        parameters: {'email': email.toLowerCase().trim()},
      );
      if (existing != null) {
        return _error(409, 'E-Mail-Adresse wird bereits verwendet');
      }

      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final user = await _db.queryOne(
        '''
        INSERT INTO users (email, password_hash, name, role)
        VALUES (@email, @password_hash, @name, @role::user_role)
        RETURNING id, email, name, role, is_active, email_verified, created_at, updated_at
        ''',
        parameters: {
          'email': email.toLowerCase().trim(),
          'password_hash': passwordHash,
          'name': name.trim(),
          'role': role,
        },
      );

      if (user == null) {
        return _error(500, 'Benutzer konnte nicht erstellt werden');
      }

      return Response(
        201,
        body: jsonEncode({'user': _sanitizeUser(user)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin createUser Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /admin/users/:id
  Future<Response> _getUser(Request request, String id) async {
    try {
      final user = await _db.queryOne(
        '''
        SELECT id, email, name, role, is_active, email_verified, created_at, updated_at
        FROM users WHERE id = @id::uuid
        ''',
        parameters: {'id': id},
      );
      if (user == null) return _error(404, 'Benutzer nicht gefunden');

      return Response.ok(
        jsonEncode({'user': _sanitizeUser(user)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin getUser Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /admin/users/:id — Name, Rolle, Status ändern
  Future<Response> _updateUser(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

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

      if (body.containsKey('role')) {
        final role = body['role'] as String?;
        if (!['owner', 'vet', 'provider'].contains(role)) {
          return _error(400, 'Ungültige Rolle. Erlaubt: owner, vet, provider');
        }
        updates.add('role = @role::user_role');
        params['role'] = role;
      }

      if (body.containsKey('is_active')) {
        updates.add('is_active = @is_active');
        params['is_active'] = body['is_active'] as bool;
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Änderungen angegeben');
      }

      final user = await _db.queryOne(
        '''
        UPDATE users SET ${updates.join(', ')}
        WHERE id = @id::uuid
        RETURNING id, email, name, role, is_active, email_verified, created_at, updated_at
        ''',
        parameters: params,
      );

      if (user == null) return _error(404, 'Benutzer nicht gefunden');

      return Response.ok(
        jsonEncode({'user': _sanitizeUser(user)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin updateUser Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /admin/users/:id/reset-password
  Future<Response> _resetPassword(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final password = body['password'] as String?;

      if (password == null || password.length < 8) {
        return _error(400, 'Passwort muss mindestens 8 Zeichen lang sein');
      }

      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      final result = await _db.queryOne(
        '''
        UPDATE users SET password_hash = @password_hash
        WHERE id = @id::uuid
        RETURNING id
        ''',
        parameters: {'id': id, 'password_hash': passwordHash},
      );

      if (result == null) return _error(404, 'Benutzer nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Passwort erfolgreich geändert'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin resetPassword Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /admin/users/:id — Benutzer deaktivieren (nicht löschen)
  Future<Response> _deactivateUser(Request request, String id) async {
    try {
      final adminId = request.context['userId'] as String;
      if (id == adminId) {
        return _error(400, 'Sie können sich nicht selbst deaktivieren');
      }

      final result = await _db.queryOne(
        '''
        UPDATE users SET is_active = false
        WHERE id = @id::uuid
        RETURNING id
        ''',
        parameters: {'id': id},
      );

      if (result == null) return _error(404, 'Benutzer nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Benutzer deaktiviert'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Admin deactivateUser Fehler: $e');
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
