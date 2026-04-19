import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class UsersProvider extends ChangeNotifier {
  final ApiService _api;

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _pagination;
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  String _roleFilter = '';
  String _searchQuery = '';

  UsersProvider({required ApiService api}) : _api = api;

  List<Map<String, dynamic>> get users => _users;
  Map<String, dynamic>? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  String get roleFilter => _roleFilter;
  String get searchQuery => _searchQuery;

  Future<void> loadUsers({int page = 1, String role = '', String search = ''}) async {
    _isLoading = true;
    _error = null;
    _currentPage = page;
    _roleFilter = role;
    _searchQuery = search;
    notifyListeners();

    try {
      final params = <String, String>{'page': page.toString()};
      if (role.isNotEmpty) params['role'] = role;
      if (search.isNotEmpty) params['search'] = search;

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final response = await _api.get('/admin/users?$query');

      _users = (response['users'] as List<dynamic>).cast<Map<String, dynamic>>();
      _pagination = response['pagination'] as Map<String, dynamic>?;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Fehler beim Laden der Benutzer';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _api.post('/admin/users', body: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      await loadUsers(page: 1, role: _roleFilter, search: _searchQuery);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Anlegen des Benutzers';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _api.put('/admin/users/$id', body: data);
      await loadUsers(page: _currentPage, role: _roleFilter, search: _searchQuery);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Aktualisieren';
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String id, String newPassword) async {
    try {
      await _api.put('/admin/users/$id/reset-password', body: {'password': newPassword});
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Passwort-Reset';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateUser(String id) async {
    try {
      await _api.delete('/admin/users/$id');
      await loadUsers(page: _currentPage, role: _roleFilter, search: _searchQuery);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Deaktivieren';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
