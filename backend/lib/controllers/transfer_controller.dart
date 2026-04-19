import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

/// Controller für Besitzerwechsel
class TransferController {
  final Database _db;
  final _rng = Random.secure();

  TransferController(this._db);

  /// Routen unter /pets/:petId/...
  Router get router {
    final router = Router();
    router.post('/<petId>/transfer', _initiateTransfer);
    router.delete('/<petId>/transfer/<transferId>', _cancelTransfer);
    router.get('/<petId>/transfers', _listTransfers);
    return router;
  }

  /// Routen unter /transfers/... (token-basiert)
  Router get tokenRouter {
    final router = Router();
    router.post('/<token>/accept', _acceptTransfer);
    router.post('/<token>/reject', _rejectTransfer);
    return router;
  }

  /// POST /pets/:petId/transfer — Transfer initiieren
  Future<Response> _initiateTransfer(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;

      // Prüfen, ob petId dem Benutzer gehört
      final pet = await _db.queryOne(
        'SELECT id, owner_id, name FROM pets WHERE id = @id::uuid',
        parameters: {'id': petId},
      );
      if (pet == null) return _error(404, 'Tier nicht gefunden');
      if (pet['owner_id'].toString() != userId) {
        return _error(403, 'Nur der Besitzer kann einen Transfer initiieren');
      }

      // Laufenden Transfer prüfen
      final existing = await _db.queryOne(
        "SELECT id FROM ownership_transfers WHERE pet_id = @pet_id::uuid AND status = 'pending'",
        parameters: {'pet_id': petId},
      );
      if (existing != null) {
        return _error(409, 'Es gibt bereits einen ausstehenden Transfer für dieses Tier');
      }

      final body =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final toEmail = body['to_email'] as String?;
      final message = body['message'] as String?;

      if (toEmail == null || toEmail.trim().isEmpty) {
        return _error(400, 'E-Mail des neuen Besitzers erforderlich');
      }

      // Prüfen, ob Empfänger existiert
      final recipient = await _db.queryOne(
        "SELECT id FROM users WHERE email = @email AND role = 'owner'",
        parameters: {'email': toEmail.trim().toLowerCase()},
      );

      final token = _generateToken();

      final transfer = await _db.queryOne(
        '''
        INSERT INTO ownership_transfers
          (pet_id, from_owner_id, to_email, to_user_id, message, token)
        VALUES
          (@pet_id::uuid, @from_owner_id::uuid, @to_email, @to_user_id::uuid, @message, @token)
        RETURNING *
        ''',
        parameters: {
          'pet_id': petId,
          'from_owner_id': userId,
          'to_email': toEmail.trim().toLowerCase(),
          'to_user_id': recipient?['id'],
          'message': message,
          'token': token,
        },
      );

      return Response(
        201,
        body: jsonEncode({'transfer': _sanitize(transfer!)}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ initiateTransfer Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// GET /pets/:petId/transfers
  Future<Response> _listTransfers(Request request, String petId) async {
    try {
      final userId = request.context['userId'] as String;

      final transfers = await _db.queryAll(
        '''
        SELECT t.*,
               u1.name AS from_owner_name,
               u2.name AS to_user_name
        FROM ownership_transfers t
        LEFT JOIN users u1 ON t.from_owner_id = u1.id
        LEFT JOIN users u2 ON t.to_user_id = u2.id
        WHERE t.pet_id = @pet_id::uuid
          AND (t.from_owner_id = @user_id::uuid OR t.to_user_id = @user_id::uuid)
        ORDER BY t.created_at DESC
        LIMIT 20
        ''',
        parameters: {'pet_id': petId, 'user_id': userId},
      );

      return Response.ok(
        jsonEncode({'transfers': transfers.map(_sanitize).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ listTransfers Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// DELETE /pets/:petId/transfer/:transferId — Transfer abbrechen (nur Absender)
  Future<Response> _cancelTransfer(
      Request request, String petId, String transferId) async {
    try {
      final userId = request.context['userId'] as String;

      final deleted = await _db.queryOne(
        '''
        UPDATE ownership_transfers
        SET status = 'cancelled'
        WHERE id = @id::uuid
          AND pet_id = @pet_id::uuid
          AND from_owner_id = @user_id::uuid
          AND status = 'pending'
        RETURNING id
        ''',
        parameters: {
          'id': transferId,
          'pet_id': petId,
          'user_id': userId,
        },
      );
      if (deleted == null) return _error(404, 'Transfer nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Transfer abgebrochen'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ cancelTransfer Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /transfers/:token/accept — Transfer annehmen
  Future<Response> _acceptTransfer(Request request, String token) async {
    try {
      final userId = request.context['userId'] as String;

      final transfer = await _db.queryOne(
        "SELECT * FROM ownership_transfers WHERE token = @token AND status = 'pending'",
        parameters: {'token': token},
      );
      if (transfer == null) return _error(404, 'Transfer nicht gefunden oder bereits verarbeitet');

      // Prüfen, ob der eingeloggte User der Empfänger ist
      final toUserId = transfer['to_user_id']?.toString();
      if (toUserId != null && toUserId != userId) {
        return _error(403, 'Dieser Transfer ist nicht für Sie');
      }

      final petId = transfer['pet_id'].toString();

      // Besitzerwechsel durchführen
      await _db.queryAll(
        'UPDATE pets SET owner_id = @new_owner_id::uuid WHERE id = @pet_id::uuid',
        parameters: {'new_owner_id': userId, 'pet_id': petId},
      );

      // Transfer als akzeptiert markieren
      await _db.queryAll(
        '''
        UPDATE ownership_transfers
        SET status = 'accepted', to_user_id = @user_id::uuid, responded_at = NOW()
        WHERE token = @token
        ''',
        parameters: {'user_id': userId, 'token': token},
      );

      // Alte Zugriffsberechtigungen des früheren Besitzers entziehen (optional)
      // Behalte medizinische Einträge, transferiere nur Besitz

      return Response.ok(
        jsonEncode({'message': 'Transfer angenommen. Das Tier gehört nun Ihnen.'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ acceptTransfer Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  /// POST /transfers/:token/reject — Transfer ablehnen
  Future<Response> _rejectTransfer(Request request, String token) async {
    try {
      final updated = await _db.queryOne(
        '''
        UPDATE ownership_transfers
        SET status = 'rejected', responded_at = NOW()
        WHERE token = @token AND status = 'pending'
        RETURNING id
        ''',
        parameters: {'token': token},
      );
      if (updated == null) return _error(404, 'Transfer nicht gefunden');

      return Response.ok(
        jsonEncode({'message': 'Transfer abgelehnt'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ rejectTransfer Fehler: $e');
      return _error(500, 'Interner Serverfehler');
    }
  }

  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
        32, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> t) {
    return {
      'id': t['id'].toString(),
      'pet_id': t['pet_id'].toString(),
      'from_owner_id': t['from_owner_id'].toString(),
      'from_owner_name': t['from_owner_name'],
      'to_email': t['to_email'],
      'to_user_id': t['to_user_id']?.toString(),
      'to_user_name': t['to_user_name'],
      'status': t['status'].toString(),
      'message': t['message'],
      'token': t['token'],
      'created_at': (t['created_at'] as DateTime).toIso8601String(),
      'responded_at': t['responded_at'] != null
          ? (t['responded_at'] as DateTime).toIso8601String()
          : null,
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
