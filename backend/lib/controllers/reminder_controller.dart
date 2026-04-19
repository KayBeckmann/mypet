import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../services/email_service.dart';

class ReminderController {
  final Database _db;
  final EmailService _email = EmailService();

  ReminderController({required Database db}) : _db = db;

  Router get router {
    final r = Router();
    r.get('/', _list);
    r.post('/', _create);
    r.put('/<id>', _update);
    r.delete('/<id>', _delete);
    r.post('/<id>/dismiss', _dismiss);
    return r;
  }

  /// GET /reminders – Alle Erinnerungen des Nutzers
  Future<Response> _list(Request request) async {
    final userId = request.context['userId'] as String;
    try {
      final rows = await _db.queryAll(
        '''
        SELECT r.id, r.pet_id, p.name as pet_name,
               r.reminder_type::text as reminder_type,
               r.title, r.message,
               r.remind_at, r.status::text as status,
               r.email_sent, r.email_sent_at, r.created_at
        FROM reminders r
        LEFT JOIN pets p ON p.id = r.pet_id
        WHERE r.user_id = @uid
        ORDER BY r.remind_at ASC
        ''',
        parameters: {'uid': userId},
      );
      return Response.ok(
        jsonEncode({'reminders': rows.map(_serializeRow).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Fehler beim Laden der Erinnerungen'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// POST /reminders – Erinnerung anlegen
  Future<Response> _create(Request request) async {
    final userId = request.context['userId'] as String;
    final userEmail = request.context['userEmail'] as String? ?? '';
    final userName = 'Nutzer';
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final title = body['title'] as String?;
    if (title == null || title.trim().isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Titel erforderlich'}),
          headers: {'Content-Type': 'application/json'});
    }

    final remindAtRaw = body['remind_at'] as String?;
    DateTime? remindAt;
    if (remindAtRaw != null) {
      remindAt = DateTime.tryParse(remindAtRaw);
    }
    if (remindAt == null) {
      return Response(400,
          body: jsonEncode({'error': 'Gültiges remind_at Datum erforderlich'}),
          headers: {'Content-Type': 'application/json'});
    }

    final type = body['reminder_type'] as String? ?? 'custom';
    final message = body['message'] as String? ?? '';
    final petId = body['pet_id'] as String?;

    try {
      final row = await _db.queryOne(
        '''
        INSERT INTO reminders (user_id, pet_id, reminder_type, title, message, remind_at)
        VALUES (@uid, @pet_id, @type::reminder_type, @title, @message, @remind_at)
        RETURNING id, pet_id, reminder_type::text as reminder_type,
                  title, message, remind_at, status::text as status,
                  email_sent, email_sent_at, created_at
        ''',
        parameters: {
          'uid': userId,
          'pet_id': petId,
          'type': type,
          'title': title.trim(),
          'message': message,
          'remind_at': remindAt.toIso8601String(),
        },
      );

      // Schedule email if remind_at is in the future (fire-and-forget)
      if (remindAt.isAfter(DateTime.now())) {
        _scheduleEmail(
          toEmail: userEmail,
          toName: userName,
          title: title.trim(),
          message: message,
          remindAt: remindAt,
          reminderId: row!['id'].toString(),
        );
      }

      return Response(201,
          body: jsonEncode({'reminder': _serializeRow(row!)}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Fehler beim Erstellen der Erinnerung'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// PUT /reminders/:id – Erinnerung aktualisieren
  Future<Response> _update(Request request, String id) async {
    final userId = request.context['userId'] as String;
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final existing = await _db.queryOne(
      'SELECT id FROM reminders WHERE id = @id AND user_id = @uid',
      parameters: {'id': id, 'uid': userId},
    );
    if (existing == null) {
      return Response(404,
          body: jsonEncode({'error': 'Erinnerung nicht gefunden'}),
          headers: {'Content-Type': 'application/json'});
    }

    final title = body['title'] as String?;
    final message = body['message'] as String?;
    final remindAtRaw = body['remind_at'] as String?;

    try {
      final row = await _db.queryOne(
        '''
        UPDATE reminders
        SET title = COALESCE(@title, title),
            message = COALESCE(@message, message),
            remind_at = COALESCE(@remind_at, remind_at)
        WHERE id = @id AND user_id = @uid
        RETURNING id, pet_id, reminder_type::text as reminder_type,
                  title, message, remind_at, status::text as status,
                  email_sent, email_sent_at, created_at
        ''',
        parameters: {
          'id': id,
          'uid': userId,
          'title': title?.trim(),
          'message': message,
          'remind_at': remindAtRaw != null
              ? DateTime.tryParse(remindAtRaw)?.toIso8601String()
              : null,
        },
      );
      return Response.ok(
          jsonEncode({'reminder': _serializeRow(row!)}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Fehler beim Aktualisieren'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// DELETE /reminders/:id
  Future<Response> _delete(Request request, String id) async {
    final userId = request.context['userId'] as String;
    try {
      await _db.query(
        'DELETE FROM reminders WHERE id = @id AND user_id = @uid',
        parameters: {'id': id, 'uid': userId},
      );
      return Response.ok(
          jsonEncode({'message': 'Erinnerung gelöscht'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Fehler beim Löschen'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// POST /reminders/:id/dismiss – Als erledigt markieren
  Future<Response> _dismiss(Request request, String id) async {
    final userId = request.context['userId'] as String;
    try {
      final row = await _db.queryOne(
        '''
        UPDATE reminders SET status = 'dismissed'
        WHERE id = @id AND user_id = @uid
        RETURNING id, status::text as status
        ''',
        parameters: {'id': id, 'uid': userId},
      );
      if (row == null) {
        return Response(404,
            body: jsonEncode({'error': 'Nicht gefunden'}),
            headers: {'Content-Type': 'application/json'});
      }
      return Response.ok(
          jsonEncode({'message': 'Erledigt'}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': 'Fehler'}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  /// Fire-and-forget: send email when remind_at arrives
  void _scheduleEmail({
    required String toEmail,
    required String toName,
    required String title,
    required String message,
    required DateTime remindAt,
    required String reminderId,
  }) {
    final delay = remindAt.difference(DateTime.now());
    if (delay.isNegative) return;

    Future.delayed(delay, () async {
      final sent = await _email.sendReminderEmail(
        toEmail: toEmail,
        toName: toName,
        title: title,
        message: message,
        remindAt: remindAt,
      );
      if (sent) {
        await _db.query(
          '''UPDATE reminders
             SET email_sent = true, email_sent_at = NOW(), status = 'sent'
             WHERE id = @id''',
          parameters: {'id': reminderId},
        );
      }
    });
  }

  Map<String, dynamic> _serializeRow(Map<String, dynamic> row) {
    return {
      'id': row['id'].toString(),
      'pet_id': row['pet_id']?.toString(),
      'pet_name': row['pet_name'],
      'reminder_type': row['reminder_type'],
      'title': row['title'],
      'message': row['message'],
      'remind_at': (row['remind_at'] as DateTime?)?.toIso8601String(),
      'status': row['status'],
      'email_sent': row['email_sent'],
      'email_sent_at': (row['email_sent_at'] as DateTime?)?.toIso8601String(),
      'created_at': (row['created_at'] as DateTime?)?.toIso8601String(),
    };
  }
}
