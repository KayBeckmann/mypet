import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../database/database.dart';
import '../config/config.dart';
import '../middleware/auth_middleware.dart';

/// Controller für Authentifizierung
class AuthController {
  final Database _db;

  AuthController(this._db);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refresh);
    router.post('/logout', _logout);
    router.post('/switch-organization', _switchOrganization);

    return router;
  }

  /// POST /auth/switch-organization - Aktive Organisation ändern
  /// Erwartet Auth-Header mit aktuellem JWT-Token
  Future<Response> _switchOrganization(Request request) async {
    try {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return _error(401, 'Authentifizierung erforderlich');
      }
      final currentToken = authHeader.substring(7);

      final config = Config();
      JWT jwt;
      try {
        jwt = JWT.verify(currentToken, SecretKey(config.jwtSecret));
      } on JWTException {
        return _error(401, 'Ungültiger Token');
      }

      final payload = jwt.payload as Map<String, dynamic>;
      final userId = payload['sub'] as String;

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final orgId = body['organization_id'] as String?;

      String? activeOrgId;

      if (orgId != null && orgId.isNotEmpty) {
        // Prüfen ob Benutzer Mitglied dieser Organisation ist
        final membership = await _db.queryOne(
          '''
          SELECT id FROM organization_members
          WHERE organization_id = @org_id::uuid
            AND user_id = @user_id::uuid
            AND is_active = true
          ''',
          parameters: {'org_id': orgId, 'user_id': userId},
        );
        if (membership == null) {
          return _error(403, 'Keine Mitgliedschaft in dieser Organisation');
        }
        activeOrgId = orgId;
      }

      // Neuen Token mit aktiver Organisation
      final newToken = generateToken(
        userId: userId,
        email: payload['email'] as String,
        role: payload['role'] as String,
        activeOrganizationId: activeOrgId,
      );

      return Response.ok(
        jsonEncode({
          'token': newToken,
          'active_organization_id': activeOrgId,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Switch-Organization-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /auth/register - Neuen Benutzer registrieren
  Future<Response> _register(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final email = body['email'] as String?;
      final password = body['password'] as String?;

      // Validierung
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }
      if (email == null || email.trim().isEmpty || !email.contains('@')) {
        return _error(400, 'Gültige E-Mail-Adresse ist erforderlich');
      }
      if (password == null || password.length < 8) {
        return _error(400, 'Passwort muss mindestens 8 Zeichen lang sein');
      }

      // Prüfen ob E-Mail bereits existiert
      final existing = await _db.queryOne(
        'SELECT id FROM users WHERE email = @email',
        parameters: {'email': email.toLowerCase().trim()},
      );
      if (existing != null) {
        return _error(409, 'E-Mail-Adresse wird bereits verwendet');
      }

      // Passwort hashen
      final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

      // Benutzer erstellen
      final user = await _db.queryOne(
        '''
        INSERT INTO users (email, password_hash, name, role)
        VALUES (@email, @password_hash, @name, 'owner')
        RETURNING id, email, name, role, is_active, email_verified, created_at
        ''',
        parameters: {
          'email': email.toLowerCase().trim(),
          'password_hash': passwordHash,
          'name': name.trim(),
        },
      );

      if (user == null) {
        return _error(500, 'Benutzer konnte nicht erstellt werden');
      }

      // Tokens generieren
      final token = generateToken(
        userId: user['id'].toString(),
        email: user['email'] as String,
        role: user['role'].toString(),
      );
      final refreshToken = generateRefreshToken(
        userId: user['id'].toString(),
      );

      return Response(
        201,
        body: jsonEncode({
          'token': token,
          'refresh_token': refreshToken,
          'user': _sanitizeUser(user),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Register-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /auth/login - Benutzer anmelden
  Future<Response> _login(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final email = body['email'] as String?;
      final password = body['password'] as String?;

      if (email == null || password == null) {
        return _error(400, 'E-Mail und Passwort sind erforderlich');
      }

      // Benutzer suchen
      final user = await _db.queryOne(
        '''
        SELECT id, email, password_hash, name, role, is_active, email_verified, created_at
        FROM users
        WHERE email = @email
        ''',
        parameters: {'email': email.toLowerCase().trim()},
      );

      if (user == null) {
        return _error(401, 'Ungültige Anmeldedaten');
      }

      // Prüfen ob Benutzer aktiv ist
      if (user['is_active'] != true) {
        return _error(403, 'Konto ist deaktiviert');
      }

      // Passwort prüfen
      final passwordHash = user['password_hash'] as String;
      if (!BCrypt.checkpw(password, passwordHash)) {
        return _error(401, 'Ungültige Anmeldedaten');
      }

      // Tokens generieren
      final token = generateToken(
        userId: user['id'].toString(),
        email: user['email'] as String,
        role: user['role'].toString(),
      );
      final refreshToken = generateRefreshToken(
        userId: user['id'].toString(),
      );

      return Response.ok(
        jsonEncode({
          'token': token,
          'refresh_token': refreshToken,
          'user': _sanitizeUser(user),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Login-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /auth/refresh - Token erneuern
  Future<Response> _refresh(Request request) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final refreshToken = body['refresh_token'] as String?;

      if (refreshToken == null) {
        return _error(400, 'Refresh-Token ist erforderlich');
      }

      final config = Config();
      final jwt = JWT.verify(refreshToken, SecretKey(config.jwtSecret));
      final payload = jwt.payload as Map<String, dynamic>;

      if (payload['type'] != 'refresh') {
        return _error(401, 'Ungültiger Refresh-Token');
      }

      final userId = payload['sub'] as String;

      // Benutzer laden
      final user = await _db.queryOne(
        '''
        SELECT id, email, name, role, is_active, email_verified, created_at
        FROM users
        WHERE id = @id::uuid AND is_active = true
        ''',
        parameters: {'id': userId},
      );

      if (user == null) {
        return _error(401, 'Benutzer nicht gefunden');
      }

      // Neue Tokens generieren
      final newToken = generateToken(
        userId: user['id'].toString(),
        email: user['email'] as String,
        role: user['role'].toString(),
      );
      final newRefreshToken = generateRefreshToken(
        userId: user['id'].toString(),
      );

      return Response.ok(
        jsonEncode({
          'token': newToken,
          'refresh_token': newRefreshToken,
          'user': _sanitizeUser(user),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } on JWTExpiredException {
      return _error(401, 'Refresh-Token abgelaufen');
    } on JWTException {
      return _error(401, 'Ungültiger Refresh-Token');
    } catch (e) {
      print('❌ Refresh-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /auth/logout - Abmelden
  Future<Response> _logout(Request request) async {
    // Bei JWT-basierter Auth gibt es serverseitig nichts zu tun,
    // da Tokens stateless sind. Der Client löscht den Token einfach.
    return Response.ok(
      jsonEncode({'message': 'Erfolgreich abgemeldet'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Benutzer-Daten ohne sensible Felder
  Map<String, dynamic> _sanitizeUser(Map<String, dynamic> user) {
    return {
      'id': user['id'].toString(),
      'email': user['email'],
      'name': user['name'],
      'role': user['role'].toString(),
      'is_active': user['is_active'],
      'email_verified': user['email_verified'],
      'created_at': (user['created_at'] as DateTime).toIso8601String(),
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
