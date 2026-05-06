import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../utils/pet_access.dart';

/// Liefert Gesundheitspass-Daten (Impfungen, Allergien, Medikamente) als JSON
/// GET /pets/:petId/health-passport
class HealthPassportController {
  final Database _db;

  HealthPassportController(this._db);

  Router get router {
    final router = Router();
    router.get('/<petId>/health-passport', _getPassport);
    return router;
  }

  Future<Response> _getPassport(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final userRole = request.context['userRole'] as String;
      final orgId = request.context['activeOrganizationId'] as String?;

      if (!await petHasAccess(_db, petId, userId, userRole, orgId: orgId)) {
        return _error(403, 'Kein Zugriff auf dieses Tier');
      }

      // Tier-Daten
      final pet = await _db.queryOne(
        'SELECT * FROM pets WHERE id = @id::uuid',
        parameters: {'id': petId},
      );
      if (pet == null) return _error(404, 'Tier nicht gefunden');

      // Besitzerdaten
      final owner = await _db.queryOne(
        'SELECT name, email FROM users WHERE id = @id::uuid',
        parameters: {'id': pet['owner_id'].toString()},
      );

      // Impfungen
      final vaccinations = await _db.queryAll(
        '''
        SELECT v.*, u.name AS vet_name
        FROM vaccinations v
        LEFT JOIN users u ON v.vaccinated_by = u.id
        WHERE v.pet_id = @pet_id::uuid
        ORDER BY v.vaccinated_at DESC
        ''',
        parameters: {'pet_id': petId},
      );

      // Allergien
      final allergies = await _db.queryAll(
        'SELECT * FROM pet_allergies WHERE pet_id = @pet_id::uuid ORDER BY severity DESC, created_at DESC',
        parameters: {'pet_id': petId},
      );

      // Aktive Medikamente
      final medications = await _db.queryAll(
        '''
        SELECT * FROM medications
        WHERE pet_id = @pet_id::uuid AND is_active = true
        ORDER BY start_date DESC
        ''',
        parameters: {'pet_id': petId},
      );

      // Letzte Laborwerte (max 10)
      final labResults = await _db.queryAll(
        '''
        SELECT l.*, u.name AS recorded_by_name
        FROM lab_results l
        LEFT JOIN users u ON l.recorded_by = u.id
        WHERE l.pet_id = @pet_id::uuid
        ORDER BY l.tested_at DESC
        LIMIT 10
        ''',
        parameters: {'pet_id': petId},
      );

      // Gewicht (letzter Eintrag)
      final latestWeight = await _db.queryOne(
        'SELECT * FROM weight_history WHERE pet_id = @pet_id::uuid ORDER BY recorded_at DESC LIMIT 1',
        parameters: {'pet_id': petId},
      );

      // Notfallkontakte
      final emergencyContacts = await _db.queryAll(
        'SELECT * FROM emergency_contacts WHERE owner_id = @owner_id::uuid ORDER BY is_primary DESC',
        parameters: {'owner_id': pet['owner_id'].toString()},
      );

      final passport = {
        'pet': {
          'id': pet['id'].toString(),
          'name': pet['name'],
          'species': pet['species'],
          'breed': pet['breed'],
          'birth_date': pet['birth_date'] != null
              ? (pet['birth_date'] as DateTime).toIso8601String()
              : null,
          'chip_number': pet['chip_number'],
          'color': pet['color'],
          'weight_kg': pet['weight_kg'] != null
              ? double.parse(pet['weight_kg'].toString())
              : null,
        },
        'owner': {
          'name': owner?['name'],
          'email': owner?['email'],
        },
        'vaccinations': vaccinations.map((v) => {
          'id': v['id'].toString(),
          'vaccine_name': v['vaccine_name'],
          'batch_number': v['batch_number'],
          'manufacturer': v['manufacturer'],
          'vaccinated_at': (v['vaccinated_at'] as DateTime).toIso8601String(),
          'valid_until': v['valid_until'] != null
              ? (v['valid_until'] as DateTime).toIso8601String()
              : null,
          'vet_name': v['vet_name'],
        }).toList(),
        'allergies': allergies.map((a) => {
          'allergen': a['allergen'],
          'category': a['category'],
          'severity': a['severity'].toString(),
          'reaction': a['reaction'],
          'diagnosed_at': a['diagnosed_at'] != null
              ? (a['diagnosed_at'] as DateTime).toIso8601String()
              : null,
        }).toList(),
        'active_medications': medications.map((m) => {
          'medication_name': m['medication_name'],
          'dosage': m['dosage'],
          'frequency': m['frequency'].toString(),
          'start_date': (m['start_date'] as DateTime).toIso8601String(),
          'end_date': m['end_date'] != null
              ? (m['end_date'] as DateTime).toIso8601String()
              : null,
        }).toList(),
        'lab_results': labResults.map((l) => {
          'test_name': l['test_name'],
          'test_category': l['test_category'],
          'result_value': l['result_value'],
          'unit': l['unit'],
          'reference_range': l['reference_range'],
          'is_abnormal': l['is_abnormal'] as bool? ?? false,
          'tested_at': (l['tested_at'] as DateTime).toIso8601String(),
          'recorded_by_name': l['recorded_by_name'],
        }).toList(),
        'latest_weight': latestWeight != null ? {
          'weight_kg': double.parse(latestWeight['weight_kg'].toString()),
          'recorded_at': (latestWeight['recorded_at'] as DateTime).toIso8601String(),
        } : null,
        'emergency_contacts': emergencyContacts.map((c) => {
          'name': c['name'],
          'relationship': c['relationship'],
          'phone': c['phone'],
          'email': c['email'],
          'is_primary': c['is_primary'] as bool? ?? false,
        }).toList(),
        'generated_at': DateTime.now().toIso8601String(),
      };

      return Response.ok(
        jsonEncode({'passport': passport}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getPassport Fehler: $e');
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
