import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class MobilePet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final DateTime? birthDate;
  final double? weightKg;
  final String? microchipId;
  final String? imageUrl;
  final String? color;

  const MobilePet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    this.birthDate,
    this.weightKg,
    this.microchipId,
    this.imageUrl,
    this.color,
  });

  factory MobilePet.fromJson(Map<String, dynamic> j) => MobilePet(
        id: j['id'] as String,
        name: j['name'] as String,
        species: j['species'] as String? ?? 'other',
        breed: j['breed'] as String? ?? '',
        birthDate: j['birth_date'] != null
            ? DateTime.tryParse(j['birth_date'] as String)
            : null,
        weightKg: (j['weight_kg'] as num?)?.toDouble(),
        microchipId: j['microchip_id'] as String?,
        imageUrl: j['image_url'] as String?,
        color: j['color'] as String?,
      );

  String get speciesEmoji {
    switch (species) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'horse': return '🐎';
      case 'bird': return '🐦';
      case 'rabbit': return '🐇';
      case 'reptile': return '🦎';
      default: return '🐾';
    }
  }

  String get speciesLabel {
    switch (species) {
      case 'dog': return 'Hund';
      case 'cat': return 'Katze';
      case 'horse': return 'Pferd';
      case 'bird': return 'Vogel';
      case 'rabbit': return 'Kaninchen';
      case 'reptile': return 'Reptil';
      default: return 'Tier';
    }
  }

  int? get ageYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}

class MobilePetProvider extends ChangeNotifier {
  final ApiService _api;

  MobilePetProvider({required ApiService api}) : _api = api;

  List<MobilePet> _pets = [];
  bool _loading = false;
  String? _error;

  List<MobilePet> get pets => _pets;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets');
      _pets = (data['pets'] as List<dynamic>? ?? [])
          .map((j) => MobilePet.fromJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Tiere konnten nicht geladen werden';
    }

    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> loadDetail(String petId) async {
    try {
      final data = await _api.get('/pets/$petId');
      return data['pet'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> loadVaccinations(String petId) async {
    try {
      final data = await _api.get('/pets/$petId/vaccinations');
      return (data['vaccinations'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadMedications(String petId) async {
    try {
      final data = await _api.get('/pets/$petId/medications');
      return (data['medications'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadRecords(String petId) async {
    try {
      final data = await _api.get('/pets/$petId/records');
      return (data['records'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
