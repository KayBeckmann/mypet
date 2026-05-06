import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class OwnerLabResult {
  final String id;
  final String petId;
  final String? recordedByName;
  final String testName;
  final String? testCategory;
  final String resultValue;
  final String? unit;
  final String? referenceRange;
  final bool isAbnormal;
  final String? notes;
  final DateTime testedAt;

  const OwnerLabResult({
    required this.id,
    required this.petId,
    this.recordedByName,
    required this.testName,
    this.testCategory,
    required this.resultValue,
    this.unit,
    this.referenceRange,
    required this.isAbnormal,
    this.notes,
    required this.testedAt,
  });

  factory OwnerLabResult.fromJson(Map<String, dynamic> j) {
    return OwnerLabResult(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      recordedByName: j['recorded_by_name'] as String?,
      testName: j['test_name'] as String,
      testCategory: j['test_category'] as String?,
      resultValue: j['result_value'] as String,
      unit: j['unit'] as String?,
      referenceRange: j['reference_range'] as String?,
      isAbnormal: j['is_abnormal'] as bool? ?? false,
      notes: j['notes'] as String?,
      testedAt: DateTime.parse(j['tested_at'] as String),
    );
  }

  String get dateLabel =>
      '${testedAt.day}.${testedAt.month}.${testedAt.year}';
}

class OwnerLabResultProvider extends ChangeNotifier {
  final ApiService _api;

  OwnerLabResultProvider({required ApiService api}) : _api = api;

  List<OwnerLabResult> _results = [];
  String? _currentPetId;
  bool _loading = false;

  List<OwnerLabResult> get results => _results;
  bool get loading => _loading;
  String? get selectedPetId => _currentPetId;

  Future<void> loadForPet(String petId) async {
    if (_currentPetId == petId) return;
    _currentPetId = petId;
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/lab-results');
      _results = (data['lab_results'] as List<dynamic>? ?? [])
          .map((e) => OwnerLabResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _results = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
