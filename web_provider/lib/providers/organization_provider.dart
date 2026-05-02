import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class ProviderOrganizationProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderOrganizationProvider({required ApiService api}) : _api = api;

  Map<String, dynamic>? _organization;
  List<Map<String, dynamic>> _members = [];
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get organization => _organization;
  List<Map<String, dynamic>> get members => _members;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String orgId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/organizations/$orgId');
      _organization = data['organization'] as Map<String, dynamic>;
      await _loadMembers(orgId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMembers(String orgId) async {
    try {
      final data = await _api.get('/organizations/$orgId/members');
      _members =
          (data['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> createOrganization({
    required String name,
    String? description,
    String? website,
    String? phone,
    String? address,
  }) async {
    try {
      final data = await _api.post('/organizations', body: {
        'name': name,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });
      _organization = data['organization'] as Map<String, dynamic>;
      notifyListeners();
      return _organization;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(String orgId, Map<String, dynamic> fields) async {
    try {
      final data = await _api.put('/organizations/$orgId', body: fields);
      _organization = data['organization'] as Map<String, dynamic>;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> invite(String orgId, String email, String role) async {
    try {
      await _api.post('/organizations/$orgId/members/invite',
          body: {'email': email, 'role': role});
      await _loadMembers(orgId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(String orgId, String userId) async {
    try {
      await _api.delete('/organizations/$orgId/members/$userId');
      _members.removeWhere((m) => m['user_id'].toString() == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeRole(
      String orgId, String userId, String newRole) async {
    try {
      await _api.put('/organizations/$orgId/members/$userId',
          body: {'role': newRole});
      await _loadMembers(orgId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Invitations ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> get pendingInvitations => _invitations;

  Future<void> loadInvitations() async {
    try {
      final data = await _api.get('/invitations');
      _invitations = (data['invitations'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> acceptInvitation(String code) async {
    try {
      await _api.post('/invitations/$code/accept', body: {});
      await loadInvitations();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectInvitation(String code) async {
    try {
      await _api.post('/invitations/$code/reject', body: {});
      await loadInvitations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
