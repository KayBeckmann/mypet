import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _refreshToken;
  bool _isDemoMode = false;

  AuthProvider({required ApiService api}) : _api = api;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  bool get isDemoMode => _isDemoMode;

  /// Demo-Login für Entwicklung (kein Backend nötig)
  void loginDemo() {
    _isDemoMode = true;
    _user = User(
      id: 'demo-001',
      email: 'elena@example.com',
      name: 'Elena',
      role: 'owner',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Login über Backend-API
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
      _isDemoMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registrierung über Backend-API
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
      });
      _api.setAuthToken(response['token'] as String);
      _refreshToken = response['refresh_token'] as String?;
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      _isDemoMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Token erneuern
  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _api.post('/auth/refresh', body: {
        'refresh_token': _refreshToken,
      });
      _api.setAuthToken(response['token'] as String);
      _refreshToken = response['refresh_token'] as String?;
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } catch (_) {
      logout();
      return false;
    }
  }

  /// Abmelden
  void logout() {
    _user = null;
    _refreshToken = null;
    _isDemoMode = false;
    _api.setAuthToken(null);
    notifyListeners();
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    if (_user == null || _isDemoMode) return false;
    try {
      final data = await _api.put('/account', body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      final updated = data['user'] as Map<String, dynamic>?;
      if (updated != null) {
        _user = User.fromJson(updated);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_isDemoMode) return false;
    try {
      await _api.put('/account/password', body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
