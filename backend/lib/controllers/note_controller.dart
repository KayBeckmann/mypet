import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../services/encryption_service.dart';

/// Controller für professionelle Notizen
/// Routen: /pets/:petId/notes
class NoteController {
  final Database _db;
  final _enc = EncryptionService();

  NoteController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/notes', _listNotes);
    router.post('/<petId>/notes', _createNote);
    router.put('/<petId>/notes/<noteId>', _updateNote);
    router.delete('/<petId>/notes/<noteId>', _deleteNote);
    return router;
  }

  /// GET /pets/:petId/notes
  Future<Response> _listNotes(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['organizationId'] as String?;

      // Sichtbarkeits-Filter:
      // - 'private': nur Autor selbst
      // - 'colleagues': Autor + Mitglieder derselben Organisation
      // - 'all_professionals': alle vets/providers
      final isProf = userRole == 'vet' || userRole == 'provider';

      String visibilityFilter;
      if (!isProf) {
        // Owner sieht keine professionellen Notizen
        return Response.ok(
          jsonEncode({'notes': []}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (orgId != null) {
        visibilityFilter = '''
          (n.author_id = @user_id::uuid
           OR n.visibility = 'all_professionals'
           OR (n.visibility = 'colleagues' AND n.organization_id = @org_id::uuid))
        ''';
      } else {
        visibilityFilter = '''
          (n.author_id = @user_id::uuid
           OR n.visibility = 'all_professionals')
        ''';
      }

      final notes = await _db.queryAll(
        '''
        SELECT n.*, u.name AS author_name, o.name AS organization_name
        FROM pet_notes n
        LEFT JOIN users u ON n.author_id = u.id
        LEFT JOIN organizations o ON n.organization_id = o.id
        WHERE n.pet_id = @pet_id::uuid
          AND $visibilityFilter
        ORDER BY n.created_at DESC
        LIMIT 100
        ''',
        parameters: {
          'pet_id': petId,
          'user_id': userId,
          if (orgId != null) 'org_id': orgId,
        },
      );

      return Response.ok(
        jsonEncode({'notes': notes.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listNotes Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/notes
  Future<Response> _createNote(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['organizationId'] as String?;

      if (userRole != 'vet' && userRole != 'provider') {
        return _error(403, 'Nur Tierärzte und Dienstleister dürfen Notizen erstellen');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final title = body['title'] as String?;
      final content = body['content'] as String? ?? '';
      final visibility = body['visibility'] as String? ?? 'private';

      if (content.trim().isEmpty) {
        return _error(400, 'Inhalt darf nicht leer sein');
      }

      final validVisibilities = {'private', 'colleagues', 'all_professionals'};
      if (!validVisibilities.contains(visibility)) {
        return _error(400, 'Ungültige Sichtbarkeit');
      }

      final encryptedContent = _enc.encrypt(content);
      final note = await _db.queryOne(
        '''
        INSERT INTO pet_notes (pet_id, author_id, organization_id, title, content, visibility, is_encrypted)
        VALUES (@pet_id::uuid, @author_id::uuid, @org_id::uuid, @title, @content, @visibility::note_visibility, true)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'author_id': userId,
          'org_id': orgId,
          'title': title,
          'content': encryptedContent,
          'visibility': visibility,
        },
      );

      return Response(
        201,
        body: jsonEncode({'note': _sanitize(note!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createNote Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:petId/notes/:noteId
  Future<Response> _updateNote(
      Request request, String petId, String noteId) async {
    try {
      final userId = request.context['userId'] as String;

      // Nur der Autor darf bearbeiten
      final existing = await _db.queryOne(
        'SELECT author_id FROM pet_notes WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': noteId, 'pet_id': petId},
      );
      if (existing == null) return _error(404, 'Notiz nicht gefunden');
      if (existing['author_id'].toString() != userId) {
        return _error(403, 'Nur der Autor darf diese Notiz bearbeiten');
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final title = body['title'] as String?;
      final content = body['content'] as String?;
      final visibility = body['visibility'] as String?;

      final sets = <String>['updated_at = NOW()'];
      final params = <String, dynamic>{'id': noteId, 'pet_id': petId};

      if (title != null) {
        sets.add('title = @title');
        params['title'] = title;
      }
      if (content != null && content.trim().isNotEmpty) {
        sets.add('content = @content');
        sets.add('is_encrypted = true');
        params['content'] = _enc.encrypt(content);
      }
      if (visibility != null) {
        sets.add('visibility = @visibility::note_visibility');
        params['visibility'] = visibility;
      }

      final updated = await _db.queryOne(
        'UPDATE pet_notes SET ${sets.join(', ')} WHERE id = @id::uuid AND pet_id = @pet_id::uuid RETURNING *',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'note': _sanitize(updated!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateNote Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/notes/:noteId
  Future<Response> _deleteNote(
      Request request, String petId, String noteId) async {
    try {
      final userId = request.context['userId'] as String;

      final deleted = await _db.queryOne(
        '''
        DELETE FROM pet_notes
        WHERE id = @id::uuid AND pet_id = @pet_id::uuid AND author_id = @author_id::uuid
        RETURNING id
        ''',
        parameters: {'id': noteId, 'pet_id': petId, 'author_id': userId},
      );
      if (deleted == null) return _error(404, 'Notiz nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Notiz gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteNote Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> n) {
    final rawContent = n['content'] as String? ?? '';
    final isEncrypted = n['is_encrypted'] == true;
    final content = isEncrypted ? (_enc.decrypt(rawContent) ?? rawContent) : rawContent;
    return {
      'id': n['id'].toString(),
      'pet_id': n['pet_id'].toString(),
      'author_id': n['author_id'].toString(),
      'author_name': n['author_name'],
      'organization_id': n['organization_id']?.toString(),
      'organization_name': n['organization_name'],
      'title': n['title'],
      'content': content,
      'visibility': n['visibility'].toString(),
      'created_at': (n['created_at'] as DateTime).toIso8601String(),
      'updated_at': (n['updated_at'] as DateTime).toIso8601String(),
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
