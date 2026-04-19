import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class AdminAuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AdminAuthProvider({required ApiService api}) : _api = api;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  ApiService get api => _api;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      final user = User.fromJson(response['user'] as Map<String, dynamic>);

      if (user.role != 'superadmin') {
        _error = 'Kein Zugriff. Nur Superadmins dürfen sich hier anmelden.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _api.setAuthToken(response['token'] as String);
      _user = user;
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
