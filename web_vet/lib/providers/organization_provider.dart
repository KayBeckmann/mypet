import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class OrganizationProvider extends ChangeNotifier {
  final ApiService _api;
  List<Map<String, dynamic>> _organizations = [];
  Map<String, dynamic>? _activeOrg;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = false;
  String? _error;

  OrganizationProvider({required ApiService api}) : _api = api;

  List<Map<String, dynamic>> get organizations => _organizations;
  Map<String, dynamic>? get activeOrg => _activeOrg;
  List<Map<String, dynamic>> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrganizations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/organizations');
      _organizations =
          (response['organizations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      // Erste Organisation als aktive setzen
      if (_organizations.isNotEmpty && _activeOrg == null) {
        _activeOrg = _organizations.first;
        await loadMembers(_activeOrg!['id'] as String);
      }
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Organisationen konnten nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectOrganization(String orgId) async {
    final org = _organizations.firstWhere(
      (o) => o['id'] == orgId,
      orElse: () => {},
    );
    if (org.isEmpty) return;
    _activeOrg = org;
    await loadMembers(orgId);
    notifyListeners();
  }

  Future<bool> updateOrganization(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/organizations/$id', body: data);
      final updated = response['organization'] as Map<String, dynamic>;
      final idx = _organizations.indexWhere((o) => o['id'] == id);
      if (idx >= 0) _organizations[idx] = updated;
      if (_activeOrg?['id'] == id) _activeOrg = updated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Aktualisierung fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMembers(String orgId) async {
    try {
      final response = await _api.get('/organizations/$orgId/members');
      _members =
          (response['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {
      _members = [];
    }
  }

  Future<bool> inviteMember(
      String orgId, String email, String role, String? position) async {
    try {
      await _api.post('/organizations/$orgId/members/invite', body: {
        'email': email,
        'role': role,
        if (position != null && position.isNotEmpty) 'position': position,
      });
      await loadMembers(orgId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Einladung fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(String orgId, String userId) async {
    try {
      await _api.delete('/organizations/$orgId/members/$userId');
      _members.removeWhere((m) => m['user_id'] == userId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Mitglied konnte nicht entfernt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeMemberRole(
      String orgId, String userId, String newRole) async {
    try {
      await _api.put('/organizations/$orgId/members/$userId',
          body: {'role': newRole});
      await loadMembers(orgId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Rollen-Änderung fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
