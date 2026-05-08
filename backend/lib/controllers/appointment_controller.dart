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
    router.put('/<id>/no-show', _noShow);
    router.put('/<id>/cancel', _cancel);
    router.put('/<id>/fee', _setFee);
    router.put('/<id>/notes', _setNotes);
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

      final scheduledDate = DateTime.tryParse(scheduledAt);
      if (scheduledDate == null) {
        return _error(400, 'scheduled_at hat ein ungültiges Format');
      }
      if (scheduledDate.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
        return _error(400, 'Termin kann nicht in der Vergangenheit liegen');
      }

      // Überschneidungs-Check (für denselben Provider / Organisation)
      final userRole = request.context['userRole'] as String;
      if (userRole == 'vet' || userRole == 'provider') {
        final orgIdCheck = request.context['activeOrganizationId'] as String?;
        final providerIdCheck = body['provider_id'] as String? ?? userId;
        final overlapCheck = await _db.queryOne(
          '''
          SELECT id FROM appointments
          WHERE status IN ('requested', 'confirmed')
            AND (
              provider_id = @pid::uuid
              ${orgIdCheck != null ? 'OR organization_id = @oid::uuid' : ''}
            )
            AND ABS(EXTRACT(EPOCH FROM (scheduled_at - @sat::timestamp))) < 1800
          LIMIT 1
          ''',
          parameters: {
            'pid': providerIdCheck,
            if (orgIdCheck != null) 'oid': orgIdCheck,
            'sat': scheduledAt,
          },
        );
        if (overlapCheck != null) {
          return _error(409, 'Es gibt bereits einen Termin in diesem Zeitfenster (±30 Min.)');
        }
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

      // Wiederholungs-Termine anlegen
      final isRecurring = body['is_recurring'] as bool? ?? false;
      final recurrenceInterval = body['recurrence_interval'] as String?;
      final recurrenceCount = body['recurrence_count'] as int? ?? 0;

      final createdIds = [appointment!['id'].toString()];

      if (isRecurring && recurrenceInterval != null && recurrenceCount > 0) {
        Duration interval;
        switch (recurrenceInterval) {
          case 'daily':
            interval = const Duration(days: 1);
            break;
          case 'weekly':
            interval = const Duration(days: 7);
            break;
          case 'monthly':
            interval = const Duration(days: 30);
            break;
          case 'yearly':
            interval = const Duration(days: 365);
            break;
          default:
            interval = const Duration(days: 7);
        }

        final parentId = appointment['id'].toString();
        for (var i = 1; i <= recurrenceCount.clamp(1, 12); i++) {
          final nextAt = scheduledDate.add(interval * i);
          await _db.queryOne(
            '''
            INSERT INTO appointments
              (pet_id, owner_id, provider_id, organization_id, title, description,
               scheduled_at, duration_minutes, location, notes,
               is_recurring, recurrence_interval, parent_appointment_id)
            VALUES
              (@pet_id::uuid, @owner_id::uuid, @provider_id::uuid, @org_id::uuid,
               @title, @description, @scheduled_at::timestamp, @duration_minutes,
               @location, @notes, true, @interval::recurrence_interval, @parent::uuid)
            RETURNING id
            ''',
            parameters: {
              'pet_id': petId,
              'owner_id': pet['owner_id'].toString(),
              'provider_id': body['provider_id'] ?? userId,
              'org_id': orgId ?? body['organization_id'],
              'title': title.trim(),
              'description': body['description'],
              'scheduled_at': nextAt,
              'duration_minutes': body['duration_minutes'] ?? 30,
              'location': body['location'],
              'notes': body['notes'],
              'interval': recurrenceInterval,
              'parent': parentId,
            },
          );
        }
      }

      return Response(
        201,
        body: jsonEncode({
          'appointment': _sanitize(appointment),
          'recurring_count': createdIds.length - 1,
        }),
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
    try {
      final appointment = await _db.queryOne(
        '''
        UPDATE appointments SET status = 'confirmed'::appointment_status
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {'id': id},
      );
      if (appointment == null) return _error(404, 'Termin nicht gefunden');

      // Automatischer Zugriff: Tierarzt erhält read-Berechtigung auf das Tier
      final providerId = appointment['provider_id']?.toString();
      final petId = appointment['pet_id']?.toString();
      final scheduledAt = appointment['scheduled_at'] as DateTime;
      // Zugriff bis 24h nach dem Termin
      final expiresAt = scheduledAt.add(const Duration(hours: 24));

      if (providerId != null && petId != null) {
        // Nur einfügen, wenn noch keine aktive Berechtigung existiert
        await _db.queryAll(
          '''
          INSERT INTO access_permissions
            (pet_id, granted_by, subject_type, subject_user_id,
             permission, starts_at, ends_at, note)
          VALUES
            (@pet_id::uuid, @granted_by::uuid,
             'user'::access_subject_type, @user_id::uuid,
             'read'::access_permission_type, NOW(), @ends_at::timestamp,
             'Automatisch bei Terminbestätigung')
          ON CONFLICT DO NOTHING
          ''',
          parameters: {
            'user_id': providerId,
            'pet_id': petId,
            'granted_by': appointment['owner_id'].toString(),
            'ends_at': expiresAt.toIso8601String(),
          },
        );
      }

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appointment)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ confirmAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /appointments/:id/complete
  Future<Response> _complete(Request request, String id) async {
    try {
      final appointment = await _db.queryOne(
        '''
        UPDATE appointments SET status = 'completed'::appointment_status
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {'id': id},
      );
      if (appointment == null) return _error(404, 'Termin nicht gefunden');

      // Automatischer Zugangsentzug: terminbezogene Berechtigung sofort ablaufen lassen
      final providerId = appointment['provider_id']?.toString();
      final petId = appointment['pet_id']?.toString();
      if (providerId != null && petId != null) {
        await _db.queryAll(
          '''
          UPDATE access_permissions
          SET ends_at = NOW()
          WHERE subject_user_id = @user_id::uuid
            AND pet_id = @pet_id::uuid
            AND note = 'Automatisch bei Terminbestätigung'
            AND ends_at > NOW()
          ''',
          parameters: {'user_id': providerId, 'pet_id': petId},
        );
      }

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appointment)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ completeAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /appointments/:id/no-show
  Future<Response> _noShow(Request request, String id) async {
    try {
      final appt = await _db.queryOne(
        '''
        UPDATE appointments SET status = 'no_show'::appointment_status
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {'id': id},
      );
      if (appt == null) return _error(404, 'Termin nicht gefunden');

      // Terminbezogene Berechtigung sofort ablaufen lassen
      final providerId = appt['provider_id']?.toString();
      final petId = appt['pet_id']?.toString();
      if (providerId != null && petId != null) {
        await _db.queryAll(
          '''
          UPDATE access_permissions
          SET ends_at = NOW()
          WHERE subject_user_id = @user_id::uuid
            AND pet_id = @pet_id::uuid
            AND note = 'Automatisch bei Terminbestätigung'
            AND ends_at > NOW()
          ''',
          parameters: {'user_id': providerId, 'pet_id': petId},
        );
      }

      return Response.ok(
        jsonEncode({'appointment': _sanitize(appt)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ noShowAppointment Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
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
      'service_fee_cents': a['service_fee_cents'] as int?,
      'service_fee_currency': a['service_fee_currency'] as String? ?? 'EUR',
      'service_fee_note': a['service_fee_note'] as String?,
      'treatment_notes': a['treatment_notes'] as String?,
      'diagnosis': a['diagnosis'] as String?,
      'created_at': (a['created_at'] as DateTime).toIso8601String(),
      'updated_at': (a['updated_at'] as DateTime).toIso8601String(),
    };
  }

  /// PUT /appointments/:id/fee
  Future<Response> _setFee(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final feeCents = body['service_fee_cents'] as int?;
      final currency = body['service_fee_currency'] as String? ?? 'EUR';
      final feeNote = body['service_fee_note'] as String?;

      // Only the provider of the appointment can set the fee
      final existing = await _db.queryOne(
        'SELECT provider_id FROM appointments WHERE id = @id::uuid',
        parameters: {'id': id},
      );
      if (existing == null) return _error(404, 'Termin nicht gefunden');

      final providerId = existing['provider_id']?.toString();
      if (providerId != userId) {
        return _error(403, 'Nur der Dienstleister kann das Honorar setzen');
      }

      final updated = await _db.queryOne('''
        UPDATE appointments
        SET service_fee_cents = @fee,
            service_fee_currency = @currency,
            service_fee_note = @note
        WHERE id = @id::uuid
        RETURNING *
      ''', parameters: {
        'id': id,
        'fee': feeCents,
        'currency': currency,
        'note': feeNote,
      });

      return Response.ok(
        jsonEncode({'appointment': _sanitize(updated!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ setFee Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /appointments/:id/notes — Tierarzt/Dienstleister trägt Behandlungsnotizen ein
  Future<Response> _setNotes(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      if (userRole == 'owner') {
        return _error(403, 'Nur Tierärzte und Dienstleister können Notizen setzen');
      }

      final treatmentNotes = body['treatment_notes'] as String?;
      final diagnosis = body['diagnosis'] as String?;

      final existing = await _db.queryOne(
        'SELECT provider_id, organization_id, status FROM appointments WHERE id = @id::uuid',
        parameters: {'id': id},
      );
      if (existing == null) return _error(404, 'Termin nicht gefunden');

      final providerId = existing['provider_id']?.toString();
      final status = existing['status'].toString();

      if (providerId != userId) {
        return _error(403, 'Nur der zuständige Dienstleister kann Notizen setzen');
      }

      if (!['completed', 'confirmed', 'no_show'].contains(status)) {
        return _error(400, 'Notizen können nur für bestätigte oder abgeschlossene Termine gesetzt werden');
      }

      final updated = await _db.queryOne('''
        UPDATE appointments
        SET treatment_notes = @treatment_notes,
            diagnosis = @diagnosis
        WHERE id = @id::uuid
        RETURNING *,
          (SELECT name FROM users WHERE id = owner_id) AS owner_name,
          (SELECT name FROM users WHERE id = provider_id) AS provider_name,
          (SELECT name FROM pets WHERE id = pet_id) AS pet_name,
          (SELECT name FROM organizations WHERE id = organization_id) AS organization_name
      ''', parameters: {
        'id': id,
        'treatment_notes': treatmentNotes,
        'diagnosis': diagnosis,
      });

      return Response.ok(
        jsonEncode({'appointment': _sanitize(updated!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ setNotes Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Response _error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
