import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileAuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _loading = false;
  String? _error;

  MobileAuthProvider({required ApiService api}) : _api = api {
    _restore();
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      _api.setAuthToken(token);
      try {
        final data = await _api.get('/account');
        _user = User.fromJson(data['user'] as Map<String, dynamic>);
        notifyListeners();
      } catch (_) {
        await prefs.remove('auth_token');
        _api.setAuthToken('');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });
      final token = resp['token'] as String;
      _api.setAuthToken(token);
      _user = User.fromJson(resp['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Verbindung fehlgeschlagen';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _api.post('/auth/register', body: {
        'name': name,
        'email': email,
        'password': password,
        'role': 'owner',
      });
      final token = resp['token'] as String;
      _api.setAuthToken(token);
      _user = User.fromJson(resp['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Registrierung fehlgeschlagen';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', body: {});
    } catch (_) {}
    _api.setAuthToken('');
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
