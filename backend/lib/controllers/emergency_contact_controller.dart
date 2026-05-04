import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

class EmergencyContactController {
  final Database _db;

  EmergencyContactController(this._db);

  Router get router {
    final r = Router();
    r.get('/', _list);
    r.post('/', _create);
    r.put('/<contactId>', _update);
    r.delete('/<contactId>', _delete);
    return r;
  }

  Future<Response> _list(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final rows = await _db.queryAll(
        '''
        SELECT * FROM emergency_contacts
        WHERE owner_id = @owner_id::uuid
        ORDER BY is_primary DESC, created_at ASC
        ''',
        parameters: {'owner_id': userId},
      );

      return Response.ok(
        jsonEncode({'contacts': rows.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listEmergencyContacts Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _create(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = (body['name'] as String?)?.trim();
      final phone = (body['phone'] as String?)?.trim();
      if (name == null || name.isEmpty) return _error(400, 'Name ist erforderlich');
      if (phone == null || phone.isEmpty) return _error(400, 'Telefonnummer ist erforderlich');

      final isPrimary = body['is_primary'] as bool? ?? false;

      if (isPrimary) {
        await _db.query(
          'UPDATE emergency_contacts SET is_primary = false WHERE owner_id = @owner_id::uuid',
          parameters: {'owner_id': userId},
        );
      }

      final row = await _db.queryOne(
        '''
        INSERT INTO emergency_contacts
          (owner_id, name, relationship, phone, email, notes, is_primary)
        VALUES
          (@owner_id::uuid, @name, @relationship, @phone, @email, @notes, @is_primary)
        RETURNING *
        ''',
        parameters: {
          'owner_id': userId,
          'name': name,
          'relationship': body['relationship'],
          'phone': phone,
          'email': body['email'],
          'notes': body['notes'],
          'is_primary': isPrimary,
        },
      );

      return Response(
        201,
        body: jsonEncode({'contact': _sanitize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createEmergencyContact Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _update(Request request, String contactId) async {
    try {
      final userId = request.context['userId'] as String;

      final existing = await _db.queryOne(
        'SELECT id FROM emergency_contacts WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': contactId, 'owner_id': userId},
      );
      if (existing == null) return _error(404, 'Kontakt nicht gefunden');

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = (body['name'] as String?)?.trim();
      final phone = (body['phone'] as String?)?.trim();
      if (name == null || name.isEmpty) return _error(400, 'Name ist erforderlich');
      if (phone == null || phone.isEmpty) return _error(400, 'Telefonnummer ist erforderlich');

      final isPrimary = body['is_primary'] as bool? ?? false;
      if (isPrimary) {
        await _db.query(
          'UPDATE emergency_contacts SET is_primary = false WHERE owner_id = @owner_id::uuid AND id != @id::uuid',
          parameters: {'owner_id': userId, 'id': contactId},
        );
      }

      final row = await _db.queryOne(
        '''
        UPDATE emergency_contacts SET
          name = @name, relationship = @relationship, phone = @phone,
          email = @email, notes = @notes, is_primary = @is_primary
        WHERE id = @id::uuid
        RETURNING *
        ''',
        parameters: {
          'id': contactId,
          'name': name,
          'relationship': body['relationship'],
          'phone': phone,
          'email': body['email'],
          'notes': body['notes'],
          'is_primary': isPrimary,
        },
      );

      return Response.ok(
        jsonEncode({'contact': _sanitize(row!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateEmergencyContact Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _delete(Request request, String contactId) async {
    try {
      final userId = request.context['userId'] as String;

      final existing = await _db.queryOne(
        'SELECT id FROM emergency_contacts WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': contactId, 'owner_id': userId},
      );
      if (existing == null) return _error(404, 'Kontakt nicht gefunden');

      await _db.query(
        'DELETE FROM emergency_contacts WHERE id = @id::uuid',
        parameters: {'id': contactId},
      );

      return Response.ok(
        jsonEncode({'message': 'Kontakt gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteEmergencyContact Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> r) => {
        'id': r['id'].toString(),
        'owner_id': r['owner_id'].toString(),
        'name': r['name'],
        'relationship': r['relationship'],
        'phone': r['phone'],
        'email': r['email'],
        'notes': r['notes'],
        'is_primary': r['is_primary'],
        'created_at': (r['created_at'] as DateTime).toIso8601String(),
        'updated_at': (r['updated_at'] as DateTime).toIso8601String(),
      };

  Response _error(int code, String msg) => Response(
        code,
        body: jsonEncode({'error': msg}),
        headers: {'Content-Type': 'application/json'},
      );
}
