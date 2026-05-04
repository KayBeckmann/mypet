import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class ProviderAllergy {
  final String id;
  final String petId;
  final String? recordedByName;
  final String allergen;
  final String? category;
  final String severity;
  final String? reaction;
  final String? notes;
  final String? diagnosedAt;

  const ProviderAllergy({
    required this.id,
    required this.petId,
    this.recordedByName,
    required this.allergen,
    this.category,
    required this.severity,
    this.reaction,
    this.notes,
    this.diagnosedAt,
  });

  factory ProviderAllergy.fromJson(Map<String, dynamic> j) => ProviderAllergy(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        recordedByName: j['recorded_by_name'] as String?,
        allergen: j['allergen'] as String,
        category: j['category'] as String?,
        severity: j['severity'] as String? ?? 'moderate',
        reaction: j['reaction'] as String?,
        notes: j['notes'] as String?,
        diagnosedAt: j['diagnosed_at'] as String?,
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

class ProviderAllergyProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderAllergyProvider({required ApiService api}) : _api = api;

  final Map<String, List<ProviderAllergy>> _byPet = {};
  final Map<String, bool> _loading = {};
  String? _error;

  String? get error => _error;

  List<ProviderAllergy> forPet(String petId) => _byPet[petId] ?? const [];
  bool isLoading(String petId) => _loading[petId] ?? false;

  Future<void> loadForPet(String petId) async {
    _loading[petId] = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/allergies');
      _byPet[petId] = (data['allergies'] as List<dynamic>? ?? [])
          .map((j) => ProviderAllergy.fromJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Allergien konnten nicht geladen werden';
    }

    _loading[petId] = false;
    notifyListeners();
  }
}
