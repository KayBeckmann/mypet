import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Tier-Verwaltung
/// Alle Routen sind authentifiziert (auth-Middleware im Server)
class PetController {
  final Database _db;

  PetController(this._db);

  Router get router {
    final router = Router();

    router.get('/', _listPets);
    router.get('/<id>', _getPet);
    router.post('/', _createPet);
    router.put('/<id>', _updatePet);
    router.delete('/<id>', _deletePet);

    return router;
  }

  /// GET /pets - Alle eigenen Tiere auflisten
  Future<Response> _listPets(Request request) async {
    try {
      final userId = request.context['userId'] as String;

      final pets = await _db.queryAll(
        '''
        SELECT id, owner_id, name, species, breed, birth_date,
               weight_kg, microchip_id, image_url, notes, is_active,
               created_at, updated_at
        FROM pets
        WHERE owner_id = @owner_id::uuid AND is_active = true
        ORDER BY created_at DESC
        ''',
        parameters: {'owner_id': userId},
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

  /// GET /pets/:id - Einzelnes Tier abrufen
  Future<Response> _getPet(Request request, String id) async {
    try {
      final userId = request.context['userId'] as String;

      final pet = await _db.queryOne(
        '''
        SELECT id, owner_id, name, species, breed, birth_date,
               weight_kg, microchip_id, image_url, notes, is_active,
               created_at, updated_at
        FROM pets
        WHERE id = @id::uuid AND owner_id = @owner_id::uuid
        ''',
        parameters: {'id': id, 'owner_id': userId},
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
