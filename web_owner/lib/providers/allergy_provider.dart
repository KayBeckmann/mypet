import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PetAllergy {
  final String id;
  final String petId;
  final String? recordedByName;
  final String allergen;
  final String? category;
  final String severity;
  final String? reaction;
  final String? notes;
  final String? diagnosedAt;
  final DateTime createdAt;

  const PetAllergy({
    required this.id,
    required this.petId,
    this.recordedByName,
    required this.allergen,
    this.category,
    required this.severity,
    this.reaction,
    this.notes,
    this.diagnosedAt,
    required this.createdAt,
  });

  factory PetAllergy.fromJson(Map<String, dynamic> j) => PetAllergy(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        recordedByName: j['recorded_by_name'] as String?,
        allergen: j['allergen'] as String,
        category: j['category'] as String?,
        severity: j['severity'] as String? ?? 'moderate',
        reaction: j['reaction'] as String?,
        notes: j['notes'] as String?,
        diagnosedAt: j['diagnosed_at'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Color get severityColor {
    switch (severity) {
      case 'severe':
        return const Color(0xFFD32F2F);
      case 'moderate':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF388E3C);
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'severe':
        return 'Stark';
      case 'moderate':
        return 'Mittel';
      default:
        return 'Leicht';
    }
  }
}

class AllergyProvider extends ChangeNotifier {
  final ApiService _api;

  AllergyProvider({required ApiService api}) : _api = api;

  final Map<String, List<PetAllergy>> _byPet = {};
  final Map<String, bool> _loading = {};
  String? _error;

  String? get error => _error;

  List<PetAllergy> forPet(String petId) => _byPet[petId] ?? const [];

  bool isLoading(String petId) => _loading[petId] ?? false;

  Future<void> loadForPet(String petId) async {
    _loading[petId] = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/allergies');
      _byPet[petId] = (data['allergies'] as List<dynamic>? ?? [])
          .map((j) => PetAllergy.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _error = 'Allergien konnten nicht geladen werden';
    }

    _loading[petId] = false;
    notifyListeners();
  }

  Future<bool> addAllergy(String petId, Map<String, dynamic> body) async {
    try {
      final data = await _api.post('/pets/$petId/allergies', body: body);
      final allergy = PetAllergy.fromJson(data['allergy'] as Map<String, dynamic>);
      _byPet.putIfAbsent(petId, () => []).insert(0, allergy);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateAllergy(String petId, String allergyId, Map<String, dynamic> body) async {
    try {
      final data = await _api.put('/pets/$petId/allergies/$allergyId', body: body);
      final updated = PetAllergy.fromJson(data['allergy'] as Map<String, dynamic>);
      final list = _byPet[petId];
      if (list != null) {
        final idx = list.indexWhere((a) => a.id == allergyId);
        if (idx != -1) list[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAllergy(String petId, String allergyId) async {
    try {
      await _api.delete('/pets/$petId/allergies/$allergyId');
      _byPet[petId]?.removeWhere((a) => a.id == allergyId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
