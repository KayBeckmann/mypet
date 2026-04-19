import 'dart:convert';
import 'dart:typed_data';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import '../database/database.dart';
import '../services/upload_service.dart';
import '../utils/pet_access.dart';

/// Controller für Medien/Dokumente zu Tieren
/// Routen werden unter /pets/:petId/ gemountet (via Cascade)
class MediaController {
  final Database _db;
  final UploadService _uploadService;

  MediaController(this._db) : _uploadService = UploadService();

  Router get router {
    final router = Router();
    router.get('/<petId>/media', _listMedia);
    router.post('/<petId>/media', _uploadMedia);
    router.get('/<petId>/media/<mediaId>', _getMedia);
    router.delete('/<petId>/media/<mediaId>', _deleteMedia);
    return router;
  }

  /// GET /pets/:petId/media
  Future<Response> _listMedia(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      final params = request.requestedUri.queryParameters;
      final typeFilter = params['type'];

      final conditions = ['m.pet_id = @pet_id::uuid'];
      final queryParams = <String, dynamic>{'pet_id': petId};

      // Privat-Filter: Besitzer sieht alle, andere nur nicht-private
      if (userRole == 'owner') {
        // owner sieht alle
      } else {
        conditions.add('(m.is_private = false OR m.uploaded_by = @user_id::uuid)');
        queryParams['user_id'] = userId;
      }

      if (typeFilter != null && typeFilter.isNotEmpty) {
        conditions.add('m.media_type = @media_type::media_type');
        queryParams['media_type'] = typeFilter;
      }

      final where = 'WHERE ${conditions.join(' AND ')}';

      final media = await _db.queryAll(
        '''
        SELECT m.*, u.name AS uploaded_by_name, mr.title AS record_title
        FROM pet_media m
        LEFT JOIN users u ON m.uploaded_by = u.id
        LEFT JOIN medical_records mr ON m.medical_record_id = mr.id
        $where
        ORDER BY m.created_at DESC
        LIMIT 100
        ''',
        parameters: queryParams,
      );

      return Response.ok(
        jsonEncode({'media': media.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listMedia Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:petId/media (multipart/form-data)
  Future<Response> _uploadMedia(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, requireWrite: true, orgId: orgId)) {
        return _error(403, 'Keine Schreibberechtigung für dieses Tier');
      }

      final contentType = request.headers['content-type'] ?? '';

      if (!contentType.contains('multipart/form-data')) {
        return _error(400, 'multipart/form-data erwartet');
      }

      final boundary = _extractBoundary(contentType);
      if (boundary == null) {
        return _error(400, 'Boundary fehlt im Content-Type');
      }

      final bodyBytes = await request.read().fold<List<int>>(
        [],
        (acc, chunk) => acc..addAll(chunk),
      );

      final transformer = MimeMultipartTransformer(boundary);
      final bodyStream = Stream.fromIterable([Uint8List.fromList(bodyBytes)]);
      final parts = await transformer.bind(bodyStream).toList();

      Uint8List? fileBytes;
      String? mimeType;
      String? originalName;
      String mediaType = 'image';
      String? title;
      String? description;
      String? medicalRecordId;
      bool isPrivate = false;

      for (final part in parts) {
        final disposition = part.headers['content-disposition'] ?? '';
        final name = _extractFormField(disposition, 'name');
        final filename = _extractFormField(disposition, 'filename');

        final partBytes = await part.fold<List<int>>(
          [],
          (acc, chunk) => acc..addAll(chunk),
        );

        if (filename != null) {
          fileBytes = Uint8List.fromList(partBytes);
          mimeType = part.headers['content-type'] ??
              lookupMimeType(filename) ??
              'application/octet-stream';
          originalName = filename;
        } else {
          final value = utf8.decode(partBytes).trim();
          switch (name) {
            case 'media_type':
              mediaType = value;
              break;
            case 'title':
              title = value;
              break;
            case 'description':
              description = value;
              break;
            case 'medical_record_id':
              medicalRecordId = value.isEmpty ? null : value;
              break;
            case 'is_private':
              isPrivate = value == 'true' || value == '1';
              break;
          }
        }
      }

      if (fileBytes == null || mimeType == null) {
        return _error(400, 'Keine Datei gefunden');
      }

      // Datei speichern (nutze vorhandenen UploadService mit generischem Pfad)
      final allowedTypes = {
        ...UploadService.allowedImageTypes,
        'application/pdf': '.pdf',
        'application/msword': '.doc',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
            '.docx',
        'text/plain': '.txt',
      };

      final ext = allowedTypes[mimeType] ?? '.bin';
      final filename = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final storagePath = 'media/$filename';
      await _uploadService.ensureMediaDir();
      await _uploadService.saveRaw(fileBytes, storagePath);

      final entry = await _db.queryOne(
        '''
        INSERT INTO pet_media
          (pet_id, uploaded_by, medical_record_id, media_type, filename,
           original_name, mime_type, file_size, storage_path, title,
           description, is_private)
        VALUES
          (@pet_id::uuid, @uploaded_by::uuid, @medical_record_id::uuid,
           @media_type::media_type, @filename, @original_name, @mime_type,
           @file_size, @storage_path, @title, @description, @is_private)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'uploaded_by': userId,
          'medical_record_id': medicalRecordId,
          'media_type': mediaType,
          'filename': filename,
          'original_name': originalName,
          'mime_type': mimeType,
          'file_size': fileBytes.length,
          'storage_path': storagePath,
          'title': title,
          'description': description,
          'is_private': isPrivate,
        },
      );

      return Response(
        201,
        body: jsonEncode({'media': _sanitize(entry!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ uploadMedia Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /pets/:petId/media/:mediaId
  Future<Response> _getMedia(
      Request request, String petId, String mediaId) async {
    try {
      final entry = await _db.queryOne(
        '''
        SELECT m.*, u.name AS uploaded_by_name
        FROM pet_media m
        LEFT JOIN users u ON m.uploaded_by = u.id
        WHERE m.id = @id::uuid AND m.pet_id = @pet_id::uuid
        ''',
        parameters: {'id': mediaId, 'pet_id': petId},
      );
      if (entry == null) return _error(404, 'Medium nicht gefunden');

      return Response.ok(
        jsonEncode({'media': _sanitize(entry)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getMedia Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/media/:mediaId
  Future<Response> _deleteMedia(
      Request request, String petId, String mediaId) async {
    try {
      final entry = await _db.queryOne(
        'DELETE FROM pet_media WHERE id = @id::uuid AND pet_id = @pet_id::uuid RETURNING storage_path',
        parameters: {'id': mediaId, 'pet_id': petId},
      );
      if (entry == null) return _error(404, 'Medium nicht gefunden');

      // Datei löschen
      await _uploadService.deleteImage(entry['storage_path'] as String);

      return Response.ok(
        jsonEncode({'message': 'Medium gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteMedia Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _sanitize(Map<String, dynamic> m) {
    return {
      'id': m['id'].toString(),
      'pet_id': m['pet_id'].toString(),
      'uploaded_by': m['uploaded_by'].toString(),
      'uploaded_by_name': m['uploaded_by_name'],
      'medical_record_id': m['medical_record_id']?.toString(),
      'record_title': m['record_title'],
      'media_type': m['media_type'].toString(),
      'filename': m['filename'],
      'original_name': m['original_name'],
      'mime_type': m['mime_type'],
      'file_size': m['file_size'],
      'url': '/uploads/${m['storage_path']}',
      'title': m['title'],
      'description': m['description'],
      'is_private': m['is_private'],
      'created_at': (m['created_at'] as DateTime).toIso8601String(),
    };
  }

  String? _extractBoundary(String contentType) {
    final parts = contentType.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.startsWith('boundary=')) {
        return trimmed.substring('boundary='.length).trim().replaceAll('"', '');
      }
    }
    return null;
  }

  String? _extractFormField(String disposition, String key) {
    final pattern = RegExp('$key="([^"]*)"');
    final match = pattern.firstMatch(disposition);
    return match?.group(1);
  }

  Response _error(int statusCode, String message) {
    return Response(
      statusCode,
      body: jsonEncode({'error': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
