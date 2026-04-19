import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Termine
class AppointmentController {
  final Database _db;

  AppointmentController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _listAppointments);
    router.post('/', _createAppointment);
    router.get('/<id>', _getAppointment);
    router.put('/<id>/confirm', _confirm);
    router.put('/<id>/complete', _complete);
    router.put('/<id>/cancel', _cancel);
    router.delete('/<id>', _delete);

    return router;
  }

  /// GET /appointments?status=...&pet_id=...
  Future<Response> _listAppointments(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;
      final params = request.requestedUri.queryParameters;
      final statusFilter = params['status'];
      final petId = params['pet_id'];

      final conditions = <String>[];
      final queryParams = <String, dynamic>{};

      // Zugriffsfilter je Rolle
      if (userRole == 'owner') {
        conditions.add('a.owner_id = @user_id::uuid');
        queryParams['user_id'] = userId;
      } else if (orgId != null) {
        // Tierarzt/Dienstleister: alle Termine der aktiven Organisation
        conditions.add('a.organization_id = @org_id::uuid');
        queryParams['org_id'] = orgId;
      } else {
        conditions.add('a.provider_id = @user_id::uuid');
        queryParams['user_id'] = userId;
      }

      if (statusFilter != null && statusFilter.isNotEmpty) {
        conditions.add('a.status = @status::appointment_status');
        queryParams['status'] = statusFilter;
      }
      if (petId != null && petId.isNotEmpty) {
        conditions.add('a.pet_id = @pet_id::uuid');
        queryParams['pet_id'] = petId;
      }

      final where = conditions.isEmpty
          ? ''
          : 'WHERE ${conditions.join(' AND ')}';

      final appointments = await _db.queryAll(
        '''
        SELECT a.*,
          p.name AS pet_name,
          o.name AS owner_name,
          pr.name AS provider_name,
          org.name AS organization_name
        FROM appointments a
        LEFT JOIN pets p ON a.pet_id = p.id
        LEFT JOIN users o ON a.owner_id = o.id
        LEFT JOIN users pr ON a.provider_id = pr.id
        LEFT JOIN organizations org ON a.organization_id = org.id
        $where
        ORDER BY a.scheduled_at DESC
        LIMIT 100
        ''',
        parameters: queryParams,
      );

      return Response.ok(
        jsonEncode({'appointments': appointments.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listAppointments Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /appointments
  Future<Response> _createAppointment(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final petId = body['pet_id'] as String?;
      final title = body['title'] as String?;
      final scheduledAt = body['scheduled_at'] as String?;

      if (petId == null || petId.isEmpty) {
        return _error(400, 'pet_id ist erforderlich');
      }
      if (title == null || title.trim().isEmpty) {
        return _error(400, 'Titel ist erforderlich');
      }
      if (scheduledAt == null || scheduledAt.isEmpty) {
        return _error(400, 'scheduled_at ist erforderlich');
      }

      // Tier-Eigentümer ermitteln
      final pet = await _db.queryOne(
        'SELECT owner_id FROM pets WHERE id = @id::uuid',
        parameters: {'id': petId},
      );
      if (pet == null) return _error(404, 'Tier nicht gefunden');

      final orgId = request.context['activeOrganizationId'] as String?;

      final appointment = await _db.queryOne(
        '''
        INSERT INTO appointments
          (pet_id, owner_id, provider_id, organization_id, title, description,
           scheduled_at, duration_minutes, location, notes)
        VALUES
          (@pet_id::uuid, @owner_id::uuid, @provider_id::uuid, @org_id::uuid,
           @title, @description, @scheduled_at::timestamp, @duration_minutes,
           @location, @notes)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'owner_id': pet['owner_id'].toString(),
          'provider_id': body['provider_id'] ?? userId,
          'org_id': orgId ?? body['organization_id'],
          'title': title.trim(),
          'description': body['description'],
          'scheduled_at': scheduledAt,
          'duration_minutes': body['duration_minutes'] ?? 30,
          'location': body['location'],
          'notes': body['notes'],
        },
      );

      return Response(
        201,
        body: jsonEncode({'appointment': _sanitize(appointment!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /appointments/:id
  Future<Response> _getAppointment(Request request, String id) async {
    try {
      final appointment = await _db.queryOne(
        '''
        SELECT a.*, p.name AS pet_name, o.name AS owner_name,
          pr.name AS provider_name, org.name AS organization_name
        FROM appointments a
        LEFT JOIN pets p ON a.pet_id = p.id
        LEFT JOIN users o ON a.owner_id = o.id
        LEFT JOIN users pr ON a.provider_id = pr.id
        LEFT JOIN organizations org ON a.organization_id = org.id
        WHERE a.id = @id::uuid
        ''',
        parameters: {'id': id},
      );
      if (appointment == null) return _error(404, 'Termin nicht gefunden');

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appointment)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /appointments/:id/confirm
  Future<Response> _confirm(Request request, String id) async {
    return _updateStatus(id, 'confirmed', request);
  }

  /// PUT /appointments/:id/complete
  Future<Response> _complete(Request request, String id) async {
    return _updateStatus(id, 'completed', request);
  }

  /// PUT /appointments/:id/cancel
  Future<Response> _cancel(Request request, String id) async {
    try {
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final reason = body['reason'] as String?;

      final appointment = await _db.queryOne(
        '''
        UPDATE appointments
        SET status = 'cancelled'::appointment_status,
            cancelled_reason = @reason
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {'id': id, 'reason': reason},
      );
      if (appointment == null) return _error(404, 'Termin nicht gefunden');

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appointment)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ cancelAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _updateStatus(
      String id, String status, Request request) async {
    try {
      final appointment = await _db.queryOne(
        '''
        UPDATE appointments SET status = @status::appointment_status
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {'id': id, 'status': status},
      );
      if (appointment == null) return _error(404, 'Termin nicht gefunden');

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appointment)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateStatus Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /appointments/:id
  Future<Response> _delete(Request request, String id) async {
    try {
      final result = await _db.queryOne(
        'DELETE FROM appointments WHERE id = @id::uuid RETURNING id',
        parameters: {'id': id},
      );
      if (result == null) return _error(404, 'Termin nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Termin gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> a) {
    return {
      'id': a['id'].toString(),
      'pet_id': a['pet_id'].toString(),
      'pet_name': a['pet_name'],
      'owner_id': a['owner_id'].toString(),
      'owner_name': a['owner_name'],
      'provider_id': a['provider_id']?.toString(),
      'provider_name': a['provider_name'],
      'organization_id': a['organization_id']?.toString(),
      'organization_name': a['organization_name'],
      'title': a['title'],
      'description': a['description'],
      'status': a['status'].toString(),
      'scheduled_at': (a['scheduled_at'] as DateTime).toIso8601String(),
      'duration_minutes': a['duration_minutes'],
      'location': a['location'],
      'notes': a['notes'],
      'cancelled_reason': a['cancelled_reason'],
      'created_at': (a['created_at'] as DateTime).toIso8601String(),
      'updated_at': (a['updated_at'] as DateTime).toIso8601String(),
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
