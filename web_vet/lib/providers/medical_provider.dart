import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class MedicalProvider extends ChangeNotifier {
  final ApiService _api;

  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _medications = [];
  final Map<String, List<Map<String, dynamic>>> _schedules = {};
  bool _isLoading = false;
  String? _error;
  String? _currentPetId;

  MedicalProvider({required ApiService api}) : _api = api;

  List<Map<String, dynamic>> get records => _records;
  List<Map<String, dynamic>> get vaccinations => _vaccinations;
  List<Map<String, dynamic>> get medications => _medications;
  Map<String, List<Map<String, dynamic>>> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentPetId => _currentPetId;

  Future<void> loadForPet(String petId) async {
    if (_currentPetId == petId) return;
    _currentPetId = petId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.get('/pets/$petId/records'),
        _api.get('/pets/$petId/vaccinations'),
        _api.get('/pets/$petId/medications'),
      ]);
      _records = (results[0]['records'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _vaccinations = (results[1]['vaccinations'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _medications = (results[2]['medications'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Medizinische Daten konnten nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRecord(String petId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/pets/$petId/records', body: data);
      _records.insert(
          0, response['record'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Eintrag konnte nicht erstellt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createVaccination(String petId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/pets/$petId/vaccinations', body: data);
      _vaccinations.insert(0, response['vaccination'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Impfung konnte nicht eingetragen werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMedication(String petId, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/pets/$petId/medications', body: data);
      _medications.insert(0, response['medication'] as Map<String, dynamic>);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Medikament konnte nicht eingetragen werden';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSchedule(String petId, String medId) async {
    try {
      final response =
          await _api.get('/pets/$petId/medications/$medId/schedule');
      _schedules[medId] =
          (response['schedule'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (_) {}
  }

  void reset() {
    _currentPetId = null;
    _records = [];
    _vaccinations = [];
    _medications = [];
    _schedules.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
