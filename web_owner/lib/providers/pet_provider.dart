import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/appointment.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<Appointment> _appointments = [];
  bool _isLoading = false;

  List<Pet> get pets => _pets;
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;

  PetProvider() {
    _loadDemoData();
  }

  /// Demo data matching the mockup screens
  void _loadDemoData() {
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

  void addPet(Pet pet) {
    _pets.add(pet);
    notifyListeners();
  }

  void updatePet(Pet pet) {
    final index = _pets.indexWhere((p) => p.id == pet.id);
    if (index != -1) {
      _pets[index] = pet;
      notifyListeners();
    }
  }

  void removePet(String id) {
    _pets.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
