import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required ApiService api}) : _api = api;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  // Demo user for development until backend auth is ready
  void loginDemo() {
    _user = User(
      id: 'demo-001',
      email: 'elena@example.com',
      name: 'Elena',
      role: 'owner',
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

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
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
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
      _user = User.fromJson(response['user'] as Map<String, dynamic>);
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

  void logout() {
    _user = null;
    _api.setAuthToken(null);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
