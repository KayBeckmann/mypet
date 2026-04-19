import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../services/upload_service.dart';

/// Controller für Tier-Verwaltung
/// Alle Routen sind authentifiziert (auth-Middleware im Server)
class PetController {
  final Database _db;
  final UploadService _uploadService = UploadService();

  PetController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _listPets);
    router.get('/<id>', _getPet);
    router.post('/', _createPet);
    router.put('/<id>', _updatePet);
    router.delete('/<id>', _deletePet);
    router.post('/<id>/photo', _uploadPhoto);
    router.delete('/<id>/photo', _deletePhoto);

    return router;
  }

  /// GET /pets - Alle zugänglichen Tiere auflisten (eigene + freigegebene)
  Future<Response> _listPets(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      final params = <String, dynamic>{'user_id': userId};
      var orgCondition = 'false';
      if (orgId != null) {
        orgCondition = 'ap.subject_type = \'organization\' AND ap.subject_organization_id = @org_id::uuid';
        params['org_id'] = orgId;
      }

      final pets = await _db.queryAll(
        '''
        SELECT DISTINCT p.id, p.owner_id, p.name, p.species, p.breed,
               p.birth_date, p.weight_kg, p.microchip_id, p.image_url,
               p.notes, p.is_active, p.created_at, p.updated_at
        FROM pets p
        WHERE p.is_active = true
          AND (
            p.owner_id = @user_id::uuid
            OR EXISTS (
              SELECT 1 FROM access_permissions ap
              WHERE ap.pet_id = p.id
                AND ap.is_active = true
                AND (ap.ends_at IS NULL OR ap.ends_at >= NOW())
                AND (
                  (ap.subject_type = 'user' AND ap.subject_user_id = @user_id::uuid)
                  OR ($orgCondition)
                )
            )
          )
        ORDER BY p.created_at DESC
        ''',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({
          'pets': pets.map(_serializePet).toList(),
          'count': pets.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Pets-List-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /pets/:id - Einzelnes Tier abrufen (eigenes oder freigegebenes)
  Future<Response> _getPet(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      final params = <String, dynamic>{'id': id, 'user_id': userId};
      var orgCondition = 'false';
      if (orgId != null) {
        orgCondition = 'ap.subject_type = \'organization\' AND ap.subject_organization_id = @org_id::uuid';
        params['org_id'] = orgId;
      }

      final pet = await _db.queryOne(
        '''
        SELECT DISTINCT p.id, p.owner_id, p.name, p.species, p.breed,
               p.birth_date, p.weight_kg, p.microchip_id, p.image_url,
               p.notes, p.is_active, p.created_at, p.updated_at
        FROM pets p
        WHERE p.id = @id::uuid
          AND p.is_active = true
          AND (
            p.owner_id = @user_id::uuid
            OR EXISTS (
              SELECT 1 FROM access_permissions ap
              WHERE ap.pet_id = p.id
                AND ap.is_active = true
                AND (ap.ends_at IS NULL OR ap.ends_at >= NOW())
                AND (
                  (ap.subject_type = 'user' AND ap.subject_user_id = @user_id::uuid)
                  OR ($orgCondition)
                )
            )
          )
        ''',
        parameters: params,
      );

      if (pet == null) {
        return _error(404, 'Tier nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'pet': _serializePet(pet)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Pet-Get-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets - Neues Tier anlegen
  Future<Response> _createPet(Request request) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      final species = body['species'] as String?;

      // Validierung
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      // Gültige Tierarten
      const validSpecies = [
        'dog', 'cat', 'horse', 'bird', 'rabbit', 'reptile', 'other'
      ];
      if (species != null && !validSpecies.contains(species)) {
        return _error(400, 'Ungültige Tierart: $species');
      }

      final pet = await _db.queryOne(
        '''
        INSERT INTO pets (owner_id, name, species, breed, birth_date, weight_kg, microchip_id, notes)
        VALUES (
          @owner_id::uuid,
          @name,
          @species::pet_species,
          @breed,
          @birth_date::date,
          @weight_kg,
          @microchip_id,
          @notes
        )
        RETURNING id, owner_id, name, species, breed, birth_date,
                  weight_kg, microchip_id, image_url, notes, is_active,
                  created_at, updated_at
        ''',
        parameters: {
          'owner_id': userId,
          'name': name.trim(),
          'species': species ?? 'dog',
          'breed': (body['breed'] as String?)?.trim(),
          'birth_date': body['birth_date'] as String?,
          'weight_kg': body['weight_kg'],
          'microchip_id': (body['microchip_id'] as String?)?.trim(),
          'notes': (body['notes'] as String?)?.trim(),
        },
      );

      if (pet == null) {
        return _error(500, 'Tier konnte nicht erstellt werden');
      }

      return Response(
        201,
        body: jsonEncode({'pet': _serializePet(pet)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Pet-Create-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// PUT /pets/:id - Tier aktualisieren
  Future<Response> _updatePet(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      // Prüfen ob Tier dem Benutzer gehört
      final existing = await _db.queryOne(
        'SELECT id FROM pets WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': id, 'owner_id': userId},
      );
      if (existing == null) {
        return _error(404, 'Tier nicht gefunden');
      }

      // Update zusammenbauen
      final updates = <String>[];
      final params = <String, dynamic>{'id': id, 'owner_id': userId};

      if (body.containsKey('name')) {
        final name = body['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          return _error(400, 'Name darf nicht leer sein');
        }
        updates.add('name = @name');
        params['name'] = name.trim();
      }
      if (body.containsKey('species')) {
        updates.add('species = @species::pet_species');
        params['species'] = body['species'];
      }
      if (body.containsKey('breed')) {
        updates.add('breed = @breed');
        params['breed'] = (body['breed'] as String?)?.trim();
      }
      if (body.containsKey('birth_date')) {
        updates.add('birth_date = @birth_date::date');
        params['birth_date'] = body['birth_date'];
      }
      if (body.containsKey('weight_kg')) {
        updates.add('weight_kg = @weight_kg');
        params['weight_kg'] = body['weight_kg'];
      }
      if (body.containsKey('microchip_id')) {
        updates.add('microchip_id = @microchip_id');
        params['microchip_id'] = (body['microchip_id'] as String?)?.trim();
      }
      if (body.containsKey('notes')) {
        updates.add('notes = @notes');
        params['notes'] = (body['notes'] as String?)?.trim();
      }

      if (updates.isEmpty) {
        return _error(400, 'Keine Felder zum Aktualisieren');
      }

      final pet = await _db.queryOne(
        '''
        UPDATE pets
        SET ${updates.join(', ')}
        WHERE id = @id::uuid AND owner_id = @owner_id::uuid
        RETURNING id, owner_id, name, species, breed, birth_date,
                  weight_kg, microchip_id, image_url, notes, is_active,
                  created_at, updated_at
        ''',
        parameters: params,
      );

      return Response.ok(
        jsonEncode({'pet': _serializePet(pet!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Pet-Update-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:id - Tier löschen (Soft-Delete)
  Future<Response> _deletePet(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final result = await _db.queryOne(
        '''
        UPDATE pets
        SET is_active = false
        WHERE id = @id::uuid AND owner_id = @owner_id::uuid
        RETURNING id
        ''',
        parameters: {'id': id, 'owner_id': userId},
      );

      if (result == null) {
        return _error(404, 'Tier nicht gefunden');
      }

      return Response.ok(
        jsonEncode({'message': 'Tier wurde gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Pet-Delete-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /pets/:id/photo - Foto hochladen
  Future<Response> _uploadPhoto(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      // Prüfen ob Tier dem Benutzer gehört
      final existing = await _db.queryOne(
        'SELECT id, image_url FROM pets WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': id, 'owner_id': userId},
      );
      if (existing == null) {
        return _error(404, 'Tier nicht gefunden');
      }

      // Content-Type prüfen
      final contentType = request.headers['content-type'] ?? '';

      if (contentType.startsWith('multipart/form-data')) {
        // Multipart-Upload verarbeiten
        return await _handleMultipartUpload(request, id, existing);
      } else if (UploadService.allowedImageTypes.containsKey(contentType)) {
        // Direkter Binary-Upload
        return await _handleDirectUpload(request, id, existing, contentType);
      } else {
        return _error(
          400,
          'Ungültiger Content-Type. Verwende multipart/form-data oder einen Bild-MIME-Type',
        );
      }
    } catch (e) {
      if (e is UploadException) {
        return _error(400, e.message);
      }
      print('❌ Photo-Upload-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// Multipart-Upload verarbeiten
  Future<Response> _handleMultipartUpload(
    Request request,
    String petId,
    Map<String, dynamic> existing,
  ) async {
    final contentType = request.headers['content-type']!;

    // Boundary aus Content-Type extrahieren
    final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
    if (boundaryMatch == null) {
      return _error(400, 'Multipart-Boundary fehlt');
    }
    final boundary = boundaryMatch.group(1)!.trim();
    if (boundary.startsWith('"') && boundary.endsWith('"')) {
      // Quoted boundary
    }

    // Body einlesen
    final bodyBytes = await request.read().expand((chunk) => chunk).toList();
    final body = Uint8List.fromList(bodyBytes);

    // Multipart-Teile parsen
    final parts = _parseMultipart(body, boundary);

    // Bild-Teil finden (field name "photo" oder "image" oder "file")
    _MultipartPart? imagePart;
    for (final part in parts) {
      final disposition = part.headers['content-disposition'] ?? '';
      final partContentType = part.headers['content-type'] ?? '';
      if (UploadService.allowedImageTypes.containsKey(partContentType) ||
          disposition.contains('name="photo"') ||
          disposition.contains('name="image"') ||
          disposition.contains('name="file"')) {
        imagePart = part;
        break;
      }
    }

    if (imagePart == null || imagePart.body.isEmpty) {
      return _error(400, 'Kein Bild im Upload gefunden');
    }

    // MIME-Type des Teils bestimmen
    var mimeType = imagePart.headers['content-type'] ?? 'image/jpeg';
    if (!UploadService.allowedImageTypes.containsKey(mimeType)) {
      // Versuche aus Dateiname zu bestimmen
      final disposition = imagePart.headers['content-disposition'] ?? '';
      final filenameMatch = RegExp(r'filename="?([^";\s]+)"?').firstMatch(disposition);
      if (filenameMatch != null) {
        final filename = filenameMatch.group(1)!.toLowerCase();
        if (filename.endsWith('.png')) mimeType = 'image/png';
        else if (filename.endsWith('.jpg') || filename.endsWith('.jpeg')) mimeType = 'image/jpeg';
        else if (filename.endsWith('.webp')) mimeType = 'image/webp';
        else if (filename.endsWith('.gif')) mimeType = 'image/gif';
      }
    }

    return await _saveAndUpdatePhoto(petId, existing, imagePart.body, mimeType);
  }

  /// Direkter Binary-Upload verarbeiten
  Future<Response> _handleDirectUpload(
    Request request,
    String petId,
    Map<String, dynamic> existing,
    String contentType,
  ) async {
    final bodyBytes = await request.read().expand((chunk) => chunk).toList();
    final body = Uint8List.fromList(bodyBytes);

    if (body.isEmpty) {
      return _error(400, 'Leerer Upload');
    }

    return await _saveAndUpdatePhoto(petId, existing, body, contentType);
  }

  /// Bild speichern und Datenbank aktualisieren
  Future<Response> _saveAndUpdatePhoto(
    String petId,
    Map<String, dynamic> existing,
    Uint8List imageBytes,
    String contentType,
  ) async {
    // Altes Bild löschen, falls vorhanden
    final oldImageUrl = existing['image_url'] as String?;
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      final oldRelativePath = oldImageUrl.replaceFirst('/uploads/', '');
      await _uploadService.deleteImage(oldRelativePath);
    }

    // Neues Bild speichern
    final relativePath = await _uploadService.saveImage(
      bytes: imageBytes,
      contentType: contentType,
      petId: petId,
    );

    // URL in Datenbank speichern
    final urlPath = _uploadService.getUrlPath(relativePath);
    final pet = await _db.queryOne(
      '''
      UPDATE pets SET image_url = @image_url
      WHERE id = @id::uuid
      RETURNING id, owner_id, name, species, breed, birth_date,
                weight_kg, microchip_id, image_url, notes, is_active,
                created_at, updated_at
      ''',
      parameters: {'id': petId, 'image_url': urlPath},
    );

    return Response.ok(
      jsonEncode({'pet': _serializePet(pet!)}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// DELETE /pets/:id/photo - Foto löschen
  Future<Response> _deletePhoto(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final existing = await _db.queryOne(
        'SELECT id, image_url FROM pets WHERE id = @id::uuid AND owner_id = @owner_id::uuid',
        parameters: {'id': id, 'owner_id': userId},
      );
      if (existing == null) {
        return _error(404, 'Tier nicht gefunden');
      }

      // Bild-Datei löschen
      final imageUrl = existing['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final relativePath = imageUrl.replaceFirst('/uploads/', '');
        await _uploadService.deleteImage(relativePath);
      }

      // URL aus Datenbank entfernen
      final pet = await _db.queryOne(
        '''
        UPDATE pets SET image_url = NULL
        WHERE id = @id::uuid AND owner_id = @owner_id::uuid
        RETURNING id, owner_id, name, species, breed, birth_date,
                  weight_kg, microchip_id, image_url, notes, is_active,
                  created_at, updated_at
        ''',
        parameters: {'id': id, 'owner_id': userId},
      );

      return Response.ok(
        jsonEncode({'pet': _serializePet(pet!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Photo-Delete-Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// Einfacher Multipart-Parser
  List<_MultipartPart> _parseMultipart(Uint8List body, String boundary) {
    final parts = <_MultipartPart>[];
    final boundaryBytes = '--$boundary'.codeUnits;
    final bodyStr = String.fromCharCodes(body);

    // Teile am Boundary aufteilen
    final segments = bodyStr.split('--$boundary');

    for (final segment in segments) {
      if (segment.trim().isEmpty || segment.trim() == '--') continue;

      // Header und Body durch doppeltes CRLF trennen
      final separatorIndex = segment.indexOf('\r\n\r\n');
      if (separatorIndex == -1) continue;

      final headerStr = segment.substring(0, separatorIndex);
      final bodyStart = separatorIndex + 4;
      var bodyEnd = segment.length;
      // Trailing CRLF entfernen
      if (segment.endsWith('\r\n')) bodyEnd -= 2;

      // Headers parsen
      final headers = <String, String>{};
      for (final line in headerStr.split('\r\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        final colonIndex = trimmed.indexOf(':');
        if (colonIndex == -1) continue;
        final key = trimmed.substring(0, colonIndex).trim().toLowerCase();
        final value = trimmed.substring(colonIndex + 1).trim();
        headers[key] = value;
      }

      if (headers.isEmpty) continue;

      // Body als Bytes extrahieren (aus dem Original-Body)
      // Für Binary-Daten müssen wir die Bytes direkt aus dem Original nehmen
      final partBodyStr = segment.substring(bodyStart, bodyEnd);
      final partBody = Uint8List.fromList(partBodyStr.codeUnits);

      parts.add(_MultipartPart(headers: headers, body: partBody));
    }

    return parts;
  }

  /// Tier-Daten serialisieren
  Map<String, dynamic> _serializePet(Map<String, dynamic> pet) {
    return {
      'id': pet['id'].toString(),
      'owner_id': pet['owner_id'].toString(),
      'name': pet['name'],
      'species': pet['species'].toString(),
      'breed': pet['breed'],
      'birth_date': pet['birth_date'] != null
          ? (pet['birth_date'] as DateTime).toIso8601String().split('T').first
          : null,
      'weight_kg': pet['weight_kg'] is num
          ? (pet['weight_kg'] as num).toDouble()
          : null,
      'microchip_id': pet['microchip_id'],
      'image_url': pet['image_url'],
      'notes': pet['notes'],
      'is_active': pet['is_active'],
      'created_at': (pet['created_at'] as DateTime).toIso8601String(),
      'updated_at': (pet['updated_at'] as DateTime).toIso8601String(),
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

/// Hilfklasse für geparste Multipart-Teile
class _MultipartPart {
  final Map<String, String> headers;
  final Uint8List body;

  const _MultipartPart({required this.headers, required this.body});
}
