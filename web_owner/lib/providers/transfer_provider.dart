import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransferRecord {
  final String id;
  final String petId;
  final String fromOwnerId;
  final String? fromOwnerName;
  final String toEmail;
  final String? toUserId;
  final String? toUserName;
  final String status;
  final String? message;
  final String token;
  final DateTime createdAt;

  const TransferRecord({
    required this.id,
    required this.petId,
    required this.fromOwnerId,
    this.fromOwnerName,
    required this.toEmail,
    this.toUserId,
    this.toUserName,
    required this.status,
    this.message,
    required this.token,
    required this.createdAt,
  });

  factory TransferRecord.fromJson(Map<String, dynamic> j) => TransferRecord(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        fromOwnerId: j['from_owner_id'] as String,
        fromOwnerName: j['from_owner_name'] as String?,
        toEmail: j['to_email'] as String,
        toUserId: j['to_user_id'] as String?,
        toUserName: j['to_user_name'] as String?,
        status: j['status'] as String,
        message: j['message'] as String?,
        token: j['token'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get statusLabel => switch (status) {
        'pending' => 'Ausstehend',
        'accepted' => 'Angenommen',
        'rejected' => 'Abgelehnt',
        'cancelled' => 'Abgebrochen',
        _ => status,
      };
}

class TransferProvider extends ChangeNotifier {
  final ApiService _api;

  TransferProvider({required ApiService api}) : _api = api;

  // Pending incoming transfers (for the current user)
  final Map<String, List<TransferRecord>> _transfersByPet = {};
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  List<TransferRecord> transfersForPet(String petId) =>
      _transfersByPet[petId] ?? [];

  Future<void> loadForPet(String petId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/transfers');
      _transfersByPet[petId] =
          (data['transfers'] as List<dynamic>? ?? [])
              .map((e) =>
                  TransferRecord.fromJson(e as Map<String, dynamic>))
              .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> initiate(
    String petId, {
    required String toEmail,
    String? message,
  }) async {
    try {
      await _api.post('/pets/$petId/transfer', body: {
        'to_email': toEmail,
        if (message != null && message.isNotEmpty) 'message': message,
      });
      await loadForPet(petId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancel(String petId, String transferId) async {
    try {
      await _api.delete('/pets/$petId/transfer/$transferId');
      _transfersByPet[petId]?.removeWhere((t) => t.id == transferId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> accept(String token) async {
    try {
      await _api.post('/transfers/$token/accept');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reject(String token) async {
    try {
      await _api.post('/transfers/$token/reject');
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
