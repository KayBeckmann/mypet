import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FamilyInvitation {
  final String id;
  final String familyId;
  final String familyName;
  final String invitedByName;
  final String? message;
  final int memberCount;
  final DateTime createdAt;

  const FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.invitedByName,
    this.message,
    required this.memberCount,
    required this.createdAt,
  });

  factory FamilyInvitation.fromJson(Map<String, dynamic> j) =>
      FamilyInvitation(
        id: j['id'] as String,
        familyId: j['family_id'] as String,
        familyName: j['family_name'] as String? ?? '—',
        invitedByName: j['invited_by_name'] as String? ?? '—',
        message: j['message'] as String?,
        memberCount: j['member_count'] as int? ?? 0,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class FamilyInvitationProvider extends ChangeNotifier {
  final ApiService _api;

  FamilyInvitationProvider({required ApiService api}) : _api = api;

  List<FamilyInvitation> _invitations = [];
  bool _loading = false;
  String? _error;

  List<FamilyInvitation> get invitations => _invitations;
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount => _invitations.length;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/families/invitations');
      _invitations = (data['invitations'] as List? ?? [])
          .map((e) => FamilyInvitation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> accept(String invitationId) async {
    try {
      await _api.post('/families/invitations/$invitationId/accept', body: {});
      _invitations.removeWhere((i) => i.id == invitationId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reject(String invitationId) async {
    try {
      await _api.post('/families/invitations/$invitationId/reject', body: {});
      _invitations.removeWhere((i) => i.id == invitationId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
