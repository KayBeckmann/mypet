import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class PetProvider extends ChangeNotifier {
  final ApiService _api;
  List<Pet> _pets = [];
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _error;
  bool _useDemoData = false;

  PetProvider({required ApiService api}) : _api = api;

  List<Pet> get pets => _pets;
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Tiere vom Backend laden
  Future<void> loadPets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/pets');
      final petList = response['pets'] as List<dynamic>;
      _pets = petList
          .map((json) => Pet.fromJson(json as Map<String, dynamic>))
          .toList();
      _useDemoData = false;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Fallback auf Demo-Daten wenn Backend nicht erreichbar
      _loadDemoData();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Demo-Daten laden (Fallback & Demo-Modus)
  void loadDemo() {
    _loadDemoData();
    notifyListeners();
  }

  void _loadDemoData() {
    _useDemoData = true;
    _pets = [
      const Pet(
        id: '1',
        name: 'Bello',
        breed: 'Golden Retriever',
        species: PetSpecies.dog,
        healthStatus: HealthStatus.optimal,
        feedingStatus: FeedingStatus.done,
        weightKg: 32.5,
        microchipId: 'DE-276-02-123456',
        ownerName: 'Elena',
      ),
      const Pet(
        id: '2',
        name: 'Luna',
        breed: 'Hauskatze',
        species: PetSpecies.cat,
        healthStatus: HealthStatus.optimal,
        feedingStatus: FeedingStatus.upcoming,
        feedingNote: 'IN 2 STD.',
        weightKg: 4.2,
      ),
      const Pet(
        id: '3',
        name: 'Storm',
        breed: 'Arabisches Vollblut',
        species: PetSpecies.horse,
        healthStatus: HealthStatus.attention,
        feedingStatus: FeedingStatus.done,
        weightKg: 480,
        microchipId: 'DE-276-02-789012',
      ),
    ];

    final now = DateTime.now();
    _appointments = [
      Appointment(
        id: '1',
        title: 'Tierarzt Routinecheck',
        petName: 'Luna',
        dateTime: DateTime(now.year, now.month, now.day + 1, 10, 30),
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: '2',
        title: 'Hufpflege & Beschlag',
        petName: 'Storm',
        dateTime: DateTime(now.year, now.month, now.day + 8, 8, 0),
        status: AppointmentStatus.upcoming,
      ),
      Appointment(
        id: '3',
        title: 'Jährliche Impfung',
        petName: 'Bello',
        dateTime: DateTime(now.year, now.month, now.day + 14, 14, 0),
        status: AppointmentStatus.upcoming,
      ),
    ];
  }

  /// Tier vom Backend anlegen
  Future<bool> addPet(Pet pet) async {
    if (_useDemoData) {
      _pets.add(pet);
      notifyListeners();
      return true;
    }

    try {
      final response = await _api.post('/pets', body: pet.toJson());
      final newPet = Pet.fromJson(response['pet'] as Map<String, dynamic>);
      _pets.insert(0, newPet);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  /// Tier im Backend aktualisieren
  Future<bool> updatePet(Pet pet) async {
    if (_useDemoData) {
      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = pet;
        notifyListeners();
      }
      return true;
    }

    try {
      final response = await _api.put('/pets/${pet.id}', body: pet.toJson());
      final updated = Pet.fromJson(response['pet'] as Map<String, dynamic>);
      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = updated;
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  /// Tier im Backend löschen
  Future<bool> removePet(String id) async {
    if (_useDemoData) {
      _pets.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    }

    try {
      await _api.delete('/pets/$id');
      _pets.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Verbindung zum Server fehlgeschlagen';
      notifyListeners();
      return false;
    }
  }

  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
