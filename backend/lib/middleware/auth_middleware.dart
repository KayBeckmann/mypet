import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../config/config.dart';

/// Middleware für JWT-Authentifizierung
Middleware authMiddleware() {
  final config = Config();

  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentifizierung erforderlich'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);

      try {
        final jwt = JWT.verify(token, SecretKey(config.jwtSecret));
        final payload = jwt.payload as Map<String, dynamic>;

        // Header-Override für aktive Organisation
        final activeOrgHeader = request.headers['x-active-organization'];
        final activeOrgId = activeOrgHeader?.trim().isNotEmpty == true
            ? activeOrgHeader
            : payload['active_organization_id'] as String?;

        // Benutzer-Daten in Request-Context weiterreichen
        final updatedRequest = request.change(context: {
          'userId': payload['sub'] as String,
          'userEmail': payload['email'] as String,
          'userRole': payload['role'] as String,
          if (activeOrgId != null) 'activeOrganizationId': activeOrgId,
        });

        return innerHandler(updatedRequest);
      } on JWTExpiredException {
        return Response(
          401,
          body: jsonEncode({'error': 'Token abgelaufen'}),
          headers: {'Content-Type': 'application/json'},
        );
      } on JWTException {
        return Response(
          401,
          body: jsonEncode({'error': 'Ungültiger Token'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    };
  };
}

/// Middleware für Rollen-Prüfung (muss nach authMiddleware verwendet werden)
Middleware requireRole(List<String> roles) {
  return (Handler innerHandler) {
    return (Request request) async {
      final userRole = request.context['userRole'] as String?;

      if (userRole == null || !roles.contains(userRole)) {
        return Response(
          403,
          body: jsonEncode({'error': 'Keine Berechtigung'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Middleware die nur Superadmins durchlässt
Middleware requireSuperadmin() => requireRole(['superadmin']);

/// JWT-Token generieren
String generateToken({
  required String userId,
  required String email,
  required String role,
  String? activeOrganizationId,
}) {
  final config = Config();

  final jwt = JWT(
    {
      'sub': userId,
      'email': email,
      'role': role,
      if (activeOrganizationId != null)
        'active_organization_id': activeOrganizationId,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    },
  );

  return jwt.sign(
    SecretKey(config.jwtSecret),
    expiresIn: Duration(seconds: config.jwtExpiry),
  );
}

/// Refresh-Token generieren (längere Gültigkeit)
String generateRefreshToken({
  required String userId,
}) {
  final config = Config();

  final jwt = JWT(
    {
      'sub': userId,
      'type': 'refresh',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    },
  );

  return jwt.sign(
    SecretKey(config.jwtSecret),
    expiresIn: const Duration(days: 30),
  );
}
