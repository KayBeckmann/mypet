import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Fütterungspläne und Protokoll
/// Routen werden unter /pets/:petId/ gemountet
class FeedingController {
  final Database _db;

  FeedingController(this._db);

  Router get router {
    final router = Router();

    // Futterpläne
    router.get('/<petId>/feeding-plans', _listPlans);
    router.post('/<petId>/feeding-plans', _createPlan);
    router.get('/<petId>/feeding-plans/<planId>', _getPlan);
    router.put('/<petId>/feeding-plans/<planId>', _updatePlan);
    router.delete('/<petId>/feeding-plans/<planId>', _deletePlan);

    // Mahlzeiten
    router.post('/<petId>/feeding-plans/<planId>/meals', _addMeal);
    router.put('/<petId>/feeding-plans/<planId>/meals/<mealId>', _updateMeal);
    router.delete('/<petId>/feeding-plans/<planId>/meals/<mealId>', _deleteMeal);

    // Komponenten
    router.post(
        '/<petId>/feeding-plans/<planId>/meals/<mealId>/components',
        _addComponent);
    router.delete(
        '/<petId>/feeding-plans/<planId>/meals/<mealId>/components/<componentId>',
        _deleteComponent);

    // Fütterungs-Protokoll
    router.get('/<petId>/feeding-log', _listLog);
    router.post('/<petId>/feeding-log', _addLog);

    return router;
  }

  // ── Futterpläne ─────────────────────────────────────────────────────────────

  Future<Response> _listPlans(Request request, String petId) async {
    try {
      final plans = await _db.queryAll(
        '''
        SELECT fp.*, COUNT(fm.id) AS meal_count
        FROM feeding_plans fp
        LEFT JOIN feeding_meals fm ON fm.plan_id = fp.id
        WHERE fp.pet_id = @pet_id::uuid
        GROUP BY fp.id
        ORDER BY fp.is_active DESC, fp.created_at DESC
        ''',
        parameters: {'pet_id': petId},
      );
      return Response.ok(
        jsonEncode({'plans': plans.map(_sanitizePlan).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listFeedingPlans Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _createPlan(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final name = body['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      final plan = await _db.queryOne(
        '''
        INSERT INTO feeding_plans
          (pet_id, created_by, name, description, valid_from, valid_until)
        VALUES
          (@pet_id::uuid, @created_by::uuid, @name, @description,
           @valid_from::date, @valid_until::date)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'created_by': userId,
          'name': name.trim(),
          'description': body['description'],
          'valid_from': body['valid_from'],
          'valid_until': body['valid_until'],
        },
      );
      return Response(
        201,
        body: jsonEncode({'plan': _sanitizePlan(plan!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ createFeedingPlan Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _getPlan(
      Request request, String petId, String planId) async {
    try {
      final plan = await _db.queryOne(
        'SELECT * FROM feeding_plans WHERE id = @id::uuid AND pet_id = @pet_id::uuid',
        parameters: {'id': planId, 'pet_id': petId},
      );
      if (plan == null) return _error(404, 'Futterplan nicht gefunden');

      final meals = await _db.queryAll(
        '''
        SELECT fm.*, COALESCE(
          json_agg(fc ORDER BY fc.sort_order) FILTER (WHERE fc.id IS NOT NULL),
          '[]'
        ) AS components
        FROM feeding_meals fm
        LEFT JOIN feeding_components fc ON fc.meal_id = fm.id
        WHERE fm.plan_id = @plan_id::uuid
        GROUP BY fm.id
        ORDER BY fm.sort_order, fm.time_of_day
        ''',
        parameters: {'plan_id': planId},
      );

      final result = _sanitizePlan(plan)
        ..['meals'] = meals.map(_sanitizeMeal).toList();
      return Response.ok(
        jsonEncode({'plan': result}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ getFeedingPlan Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _updatePlan(
      Request request, String petId, String planId) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final plan = await _db.queryOne(
        '''
        UPDATE feeding_plans
        SET name = COALESCE(@name, name),
            description = COALESCE(@description, description),
            is_active = COALESCE(@is_active, is_active),
            valid_from = COALESCE(@valid_from::date, valid_from),
            valid_until = COALESCE(@valid_until::date, valid_until)
        WHERE id = @id::uuid AND pet_id = @pet_id::uuid
        RETURNING *
        ''',
        parameters: {
          'id': planId,
          'pet_id': petId,
          'name': body['name'],
          'description': body['description'],
          'is_active': body['is_active'],
          'valid_from': body['valid_from'],
          'valid_until': body['valid_until'],
        },
      );
      if (plan == null) return _error(404, 'Futterplan nicht gefunden');
      return Response.ok(
        jsonEncode({'plan': _sanitizePlan(plan)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateFeedingPlan Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _deletePlan(
      Request request, String petId, String planId) async {
    try {
      final result = await _db.queryOne(
        'DELETE FROM feeding_plans WHERE id = @id::uuid AND pet_id = @pet_id::uuid RETURNING id',
        parameters: {'id': planId, 'pet_id': petId},
      );
      if (result == null) return _error(404, 'Futterplan nicht gefunden');
      return Response.ok(
        jsonEncode({'message': 'Futterplan gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteFeedingPlan Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  // ── Mahlzeiten ────────────────────────────────────────────────────────────

  Future<Response> _addMeal(
      Request request, String petId, String planId) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final name = body['name'] as String?;
      if (name == null || name.trim().isEmpty) {
        return _error(400, 'Name ist erforderlich');
      }

      final meal = await _db.queryOne(
        '''
        INSERT INTO feeding_meals (plan_id, name, time_of_day, notes, sort_order)
        VALUES (@plan_id::uuid, @name, @time_of_day::time, @notes, @sort_order)
        RETURNING *
        ''',
        parameters: {
          'plan_id': planId,
          'name': name.trim(),
          'time_of_day': body['time_of_day'],
          'notes': body['notes'],
          'sort_order': body['sort_order'] ?? 0,
        },
      );
      return Response(
        201,
        body: jsonEncode({'meal': _sanitizeMeal(meal!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ addFeedingMeal Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _updateMeal(
      Request request, String petId, String planId, String mealId) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final meal = await _db.queryOne(
        '''
        UPDATE feeding_meals
        SET name = COALESCE(@name, name),
            time_of_day = COALESCE(@time_of_day::time, time_of_day),
            notes = COALESCE(@notes, notes),
            sort_order = COALESCE(@sort_order, sort_order)
        WHERE id = @id::uuid AND plan_id = @plan_id::uuid
        RETURNING *
        ''',
        parameters: {
          'id': mealId,
          'plan_id': planId,
          'name': body['name'],
          'time_of_day': body['time_of_day'],
          'notes': body['notes'],
          'sort_order': body['sort_order'],
        },
      );
      if (meal == null) return _error(404, 'Mahlzeit nicht gefunden');
      return Response.ok(
        jsonEncode({'meal': _sanitizeMeal(meal)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ updateFeedingMeal Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _deleteMeal(
      Request request, String petId, String planId, String mealId) async {
    try {
      final result = await _db.queryOne(
        'DELETE FROM feeding_meals WHERE id = @id::uuid AND plan_id = @plan_id::uuid RETURNING id',
        parameters: {'id': mealId, 'plan_id': planId},
      );
      if (result == null) return _error(404, 'Mahlzeit nicht gefunden');
      return Response.ok(
        jsonEncode({'message': 'Mahlzeit gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteFeedingMeal Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  // ── Komponenten ───────────────────────────────────────────────────────────

  Future<Response> _addComponent(
      Request request, String petId, String planId, String mealId) async {
    try {
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final foodName = body['food_name'] as String?;
      if (foodName == null || foodName.trim().isEmpty) {
        return _error(400, 'food_name ist erforderlich');
      }

      final component = await _db.queryOne(
        '''
        INSERT INTO feeding_components
          (meal_id, food_name, amount_grams, unit, notes, sort_order)
        VALUES
          (@meal_id::uuid, @food_name, @amount_grams, @unit, @notes, @sort_order)
        RETURNING *
        ''',
        parameters: {
          'meal_id': mealId,
          'food_name': foodName.trim(),
          'amount_grams': body['amount_grams'],
          'unit': body['unit'] ?? 'g',
          'notes': body['notes'],
          'sort_order': body['sort_order'] ?? 0,
        },
      );
      return Response(
        201,
        body: jsonEncode({'component': _sanitizeComponent(component!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ addFeedingComponent Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _deleteComponent(Request request, String petId,
      String planId, String mealId, String componentId) async {
    try {
      final result = await _db.queryOne(
        'DELETE FROM feeding_components WHERE id = @id::uuid AND meal_id = @meal_id::uuid RETURNING id',
        parameters: {'id': componentId, 'meal_id': mealId},
      );
      if (result == null) return _error(404, 'Komponente nicht gefunden');
      return Response.ok(
        jsonEncode({'message': 'Komponente gelöscht'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ deleteFeedingComponent Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  // ── Fütterungs-Protokoll ─────────────────────────────────────────────────

  Future<Response> _listLog(Request request, String petId) async {
    try {
      final params = request.requestedUri.queryParameters;
      final limit = int.tryParse(params['limit'] ?? '') ?? 50;
      final offset = int.tryParse(params['offset'] ?? '') ?? 0;

      final logs = await _db.queryAll(
        '''
        SELECT fl.*, u.name AS fed_by_name, fm.name AS meal_name
        FROM feeding_log fl
        LEFT JOIN users u ON fl.fed_by = u.id
        LEFT JOIN feeding_meals fm ON fl.meal_id = fm.id
        WHERE fl.pet_id = @pet_id::uuid
        ORDER BY fl.fed_at DESC
        LIMIT @limit OFFSET @offset
        ''',
        parameters: {'pet_id': petId, 'limit': limit, 'offset': offset},
      );
      return Response.ok(
        jsonEncode({'log': logs.map(_sanitizeLog).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listFeedingLog Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  Future<Response> _addLog(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;
      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final entry = await _db.queryOne(
        '''
        INSERT INTO feeding_log
          (pet_id, meal_id, fed_by, fed_at, notes, amount_fed_grams, skipped, skip_reason)
        VALUES
          (@pet_id::uuid, @meal_id::uuid, @fed_by::uuid,
           COALESCE(@fed_at::timestamp, NOW()),
           @notes, @amount_fed_grams, @skipped, @skip_reason)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'meal_id': body['meal_id'],
          'fed_by': userId,
          'fed_at': body['fed_at'],
          'notes': body['notes'],
          'amount_fed_grams': body['amount_fed_grams'],
          'skipped': body['skipped'] ?? false,
          'skip_reason': body['skip_reason'],
        },
      );
      return Response(
        201,
        body: jsonEncode({'entry': _sanitizeLog(entry!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ addFeedingLog Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _sanitizePlan(Map<String, dynamic> p) {
    return {
      'id': p['id'].toString(),
      'pet_id': p['pet_id'].toString(),
      'created_by': p['created_by'].toString(),
      'name': p['name'],
      'description': p['description'],
      'is_active': p['is_active'],
      'valid_from': p['valid_from']?.toString(),
      'valid_until': p['valid_until']?.toString(),
      'meal_count': p['meal_count'],
      'created_at': (p['created_at'] as DateTime).toIso8601String(),
      'updated_at': (p['updated_at'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> _sanitizeMeal(Map<String, dynamic> m) {
    return {
      'id': m['id'].toString(),
      'plan_id': m['plan_id'].toString(),
      'name': m['name'],
      'time_of_day': m['time_of_day']?.toString(),
      'notes': m['notes'],
      'sort_order': m['sort_order'],
      'components': m['components'],
      'created_at': (m['created_at'] as DateTime).toIso8601String(),
    };
  }

  Map<String, dynamic> _sanitizeComponent(Map<String, dynamic> c) {
    return {
      'id': c['id'].toString(),
      'meal_id': c['meal_id'].toString(),
      'food_name': c['food_name'],
      'amount_grams': c['amount_grams'],
      'unit': c['unit'],
      'notes': c['notes'],
      'sort_order': c['sort_order'],
    };
  }

  Map<String, dynamic> _sanitizeLog(Map<String, dynamic> l) {
    return {
      'id': l['id'].toString(),
      'pet_id': l['pet_id'].toString(),
      'meal_id': l['meal_id']?.toString(),
      'meal_name': l['meal_name'],
      'fed_by': l['fed_by'].toString(),
      'fed_by_name': l['fed_by_name'],
      'fed_at': (l['fed_at'] as DateTime).toIso8601String(),
      'notes': l['notes'],
      'amount_fed_grams': l['amount_fed_grams'],
      'skipped': l['skipped'],
      'skip_reason': l['skip_reason'],
      'created_at': (l['created_at'] as DateTime).toIso8601String(),
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
