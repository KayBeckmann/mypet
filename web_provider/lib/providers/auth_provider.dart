import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class ProviderAuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _refreshToken;
  List<Map<String, dynamic>> _organizations = [];
  String? _activeOrganizationId;

  ProviderAuthProvider({required ApiService api}) : _api = api;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  List<Map<String, dynamic>> get organizations => _organizations;
  String? get activeOrganizationId => _activeOrganizationId;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      _api.setAuthToken(response['token'] as String);
      _refreshToken = response['refresh_token'] as String?;
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      await _loadOrganizations();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'provider',
      });
      _api.setAuthToken(response['token'] as String);
      _refreshToken = response['refresh_token'] as String?;
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      await _loadOrganizations();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      final response = await _api.get('/organizations');
      final list = response['organizations'] as List<dynamic>? ?? [];
      _organizations = list.cast<Map<String, dynamic>>();
      if (_organizations.isNotEmpty && _activeOrganizationId == null) {
        await switchOrganization(_organizations.first['id'] as String);
      }
    } catch (_) {
      _organizations = [];
    }
  }

  Future<bool> switchOrganization(String organizationId) async {
    try {
      final response = await _api.post(
        '/auth/switch-organization',
        body: {'organization_id': organizationId},
      );
      _api.setAuthToken(response['token'] as String);
      _activeOrganizationId = organizationId;
      _api.setActiveOrganization(organizationId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createOrganization({
    required String name,
    required String type,
  }) async {
    try {
      final response = await _api.post('/organizations', body: {
        'name': name,
        'type': type,
      });
      final org = response['organization'] as Map<String, dynamic>;
      _organizations.add(org);
      await switchOrganization(org['id'] as String);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    _refreshToken = null;
    _activeOrganizationId = null;
    _organizations = [];
    _api.setAuthToken(null);
    _api.setActiveOrganization(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
