import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class PatientsProvider extends ChangeNotifier {
  final ApiService _api;
  List<Map<String, dynamic>> _patients = [];
  bool _isLoading = false;
  String? _error;

  PatientsProvider({required ApiService api}) : _api = api;

  List<Map<String, dynamic>> get patients => _patients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPatients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Lade alle Tiere, auf die der Tierarzt Zugriff hat
      final response = await _api.get('/pets');
      _patients =
          (response['pets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Patienten konnten nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
