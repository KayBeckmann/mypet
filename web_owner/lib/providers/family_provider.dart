import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Family {
  final String id;
  final String name;
  final String createdBy;
  final List<Map<String, dynamic>> members;

  const Family({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'].toString(),
      name: json['name'] as String,
      createdBy: json['created_by']?.toString() ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
    );
  }
}

class FamilyProvider extends ChangeNotifier {
  final ApiService _api;
  List<Family> _families = [];
  bool _isLoading = false;
  String? _error;

  FamilyProvider({required ApiService api}) : _api = api;

  List<Family> get families => _families;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFamilies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/families');
      final list = response['families'] as List<dynamic>? ?? [];
      _families = list
          .map((j) => Family.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Familie konnte nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createFamily(String name) async {
    try {
      final response = await _api.post('/families', body: {'name': name});
      final family = Family.fromJson(response['family'] as Map<String, dynamic>);
      _families.add(family);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Familie konnte nicht erstellt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> inviteMember(String familyId, String email) async {
    try {
      await _api.post('/families/$familyId/members', body: {'email': email});
      await loadFamilies();
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

  Future<bool> removeMember(String familyId, String userId) async {
    try {
      await _api.delete('/families/$familyId/members/$userId');
      await loadFamilies();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
