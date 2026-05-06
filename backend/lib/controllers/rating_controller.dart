import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Organisations-Bewertungen
/// Routen: /organizations/:orgId/ratings
class RatingController {
  final Database _db;

  RatingController(this._db);

  Router get router {
    final router = Router();
    router.get('/<orgId>/ratings', _list);
    router.post('/<orgId>/ratings', _create);
    router.delete('/<orgId>/ratings/<ratingId>', _delete);
    return router;
  }

  /// GET /organizations/:orgId/ratings — öffentlich (alle können lesen)
  Future<Response> _list(Request request, String orgId) async {
    try {
      final ratings = await _db.queryAll(
        '''
        SELECT r.*,
               u.name AS owner_name,
               a.title AS appointment_title
        FROM organization_ratings r
        LEFT JOIN users u ON r.owner_id = u.id
        LEFT JOIN appointments a ON r.appointment_id = a.id
        WHERE r.organization_id = @org_id::uuid
        ORDER BY r.created_at DESC
        ''',
        parameters: {'org_id': orgId},
      );

      // Durchschnittsbewertung
      final stats = await _db.queryOne(
        '''
        SELECT ROUND(AVG(rating)::numeric, 1) AS avg_rating,
               COUNT(*) AS total_count
        FROM organization_ratings
        WHERE organization_id = @org_id::uuid
        ''',
        parameters: {'org_id': orgId},
      );

      return Response.ok(
        jsonEncode({
          'ratings': ratings.map(_sanitize).toList(),
          'stats': {
            'avg_rating': stats?['avg_rating'] != null
                ? double.parse(stats!['avg_rating'].toString())
                : null,
            'total_count': stats?['total_count'] ?? 0,
          },
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listRatings Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /organizations/:orgId/ratings — nur Owner
  Future<Response> _create(Request request, String orgId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;

      if (userRole != 'owner') {
        return _error(403, 'Nur Tierbesitzer können Bewertungen abgeben');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final ratingRaw = body['rating'];
      if (ratingRaw == null) return _error(400, 'rating erforderlich (1–5)');
      final rating = int.tryParse(ratingRaw.toString());
      if (rating == null || rating < 1 || rating > 5) {
        return _error(400, 'rating muss zwischen 1 und 5 liegen');
      }

      final review = body['review'] as String?;
      final appointmentId = body['appointment_id'] as String?;

      // Prüfen ob Org existiert
      final org = await _db.queryOne(
        'SELECT id FROM organizations WHERE id = @id::uuid',
        parameters: {'id': orgId},
      );
      if (org == null) return _error(404, 'Organisation nicht gefunden');

      // Prüfen ob Appointment zu dieser Org gehört (wenn angegeben)
      if (appointmentId != null) {
        final appt = await _db.queryOne(
          'SELECT organization_id, owner_id FROM appointments WHERE id = @id::uuid',
          parameters: {'id': appointmentId},
        );
        if (appt == null) return _error(404, 'Termin nicht gefunden');
        if (appt['owner_id'].toString() != userId) {
          return _error(403, 'Dieser Termin gehört nicht dir');
        }
        if (appt['organization_id']?.toString() != orgId) {
          return _error(400, 'Termin gehört nicht zu dieser Organisation');
        }
      }

      final existing = await _db.queryOne(
        '''
        INSERT INTO organization_ratings (organization_id, owner_id, appointment_id, rating, review)
        VALUES (@org_id::uuid, @owner_id::uuid, @appointment_id, @rating, @review)
        ON CONFLICT (organization_id, owner_id, appointment_id)
        DO UPDATE SET rating = @rating, review = @review
        RETURNING *
        ''',
        parameters: {
          'org_id': orgId,
          'owner_id': userId,
          'appointment_id': appointmentId,
          'rating': rating,
          'review': review?.trim(),
        },
      );

      return Response(
        201,
        body: jsonEncode({'rating': _sanitize(existing!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createRating Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /organizations/:orgId/ratings/:ratingId
  Future<Response> _delete(
      Request request, String orgId, String ratingId) async {
    try {
      final userId = request.context['userId'] as String;
      final deleted = await _db.queryOne(
        '''
        DELETE FROM organization_ratings
        WHERE id = @id::uuid AND organization_id = @org_id::uuid AND owner_id = @user_id::uuid
        RETURNING id
        ''',
        parameters: {'id': ratingId, 'org_id': orgId, 'user_id': userId},
      );
      if (deleted == null) return _error(404, 'Bewertung nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Bewertung gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteRating Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> r) {
    return {
      'id': r['id'].toString(),
      'organization_id': r['organization_id'].toString(),
      'owner_id': r['owner_id'].toString(),
      'owner_name': r['owner_name'],
      'appointment_id': r['appointment_id']?.toString(),
      'appointment_title': r['appointment_title'],
      'rating': r['rating'] as int,
      'review': r['review'],
      'created_at': (r['created_at'] as DateTime).toIso8601String(),
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
