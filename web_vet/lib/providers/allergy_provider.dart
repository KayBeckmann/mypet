import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class VetAllergy {
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

  const VetAllergy({
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

  factory VetAllergy.fromJson(Map<String, dynamic> j) => VetAllergy(
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

class VetAllergyProvider extends ChangeNotifier {
  final ApiService _api;

  VetAllergyProvider({required ApiService api}) : _api = api;

  String? _petId;
  List<VetAllergy> _allergies = [];
  bool _isLoading = false;
  String? _error;

  List<VetAllergy> get allergies => _allergies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForPet(String petId) async {
    _petId = petId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/allergies');
      _allergies = (data['allergies'] as List<dynamic>? ?? [])
          .map((j) => VetAllergy.fromJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Allergien konnten nicht geladen werden';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> add({
    required String petId,
    required String allergen,
    String? category,
    required String severity,
    String? reaction,
    String? notes,
    String? diagnosedAt,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/allergies', body: {
        'allergen': allergen,
        if (category != null) 'category': category,
        'severity': severity,
        if (reaction != null) 'reaction': reaction,
        if (notes != null) 'notes': notes,
        if (diagnosedAt != null) 'diagnosed_at': diagnosedAt,
      });
      final allergy = VetAllergy.fromJson(data['allergy'] as Map<String, dynamic>);
      _allergies.insert(0, allergy);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Speichern';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String allergyId) async {
    if (_petId == null) return false;
    try {
      await _api.delete('/pets/$_petId/allergies/$allergyId');
      _allergies.removeWhere((a) => a.id == allergyId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Löschen';
      notifyListeners();
      return false;
    }
  }
}
