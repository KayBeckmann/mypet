import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class LabResult {
  final String id;
  final String petId;
  final String recordedBy;
  final String? recordedByName;
  final String testName;
  final String? testCategory;
  final String resultValue;
  final String? unit;
  final String? referenceRange;
  final bool isAbnormal;
  final String? notes;
  final DateTime testedAt;

  const LabResult({
    required this.id,
    required this.petId,
    required this.recordedBy,
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

  factory LabResult.fromJson(Map<String, dynamic> j) {
    return LabResult(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      recordedBy: j['recorded_by'] as String,
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

  String get dateLabel {
    return '${testedAt.day}.${testedAt.month}.${testedAt.year}';
  }
}

class VetLabResultProvider extends ChangeNotifier {
  final ApiService _api;

  VetLabResultProvider({required ApiService api}) : _api = api;

  List<LabResult> _results = [];
  String? _currentPetId;
  bool _loading = false;
  String? _error;

  List<LabResult> get results => _results;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadForPet(String petId) async {
    if (_currentPetId == petId) return;
    _currentPetId = petId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/lab-results');
      _results = (data['lab_results'] as List<dynamic>? ?? [])
          .map((e) => LabResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void reload() {
    if (_currentPetId != null) {
      _currentPetId = null;
      loadForPet(_currentPetId ?? '');
    }
  }

  Future<LabResult?> create({
    required String petId,
    required String testName,
    String? testCategory,
    required String resultValue,
    String? unit,
    String? referenceRange,
    bool isAbnormal = false,
    String? notes,
    DateTime? testedAt,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/lab-results', body: {
        'test_name': testName,
        if (testCategory != null) 'test_category': testCategory,
        'result_value': resultValue,
        if (unit != null) 'unit': unit,
        if (referenceRange != null) 'reference_range': referenceRange,
        'is_abnormal': isAbnormal,
        if (notes != null) 'notes': notes,
        if (testedAt != null) 'tested_at': testedAt.toIso8601String(),
      });
      final result =
          LabResult.fromJson(data['lab_result'] as Map<String, dynamic>);
      _results.insert(0, result);
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String petId, String entryId) async {
    try {
      await _api.delete('/pets/$petId/lab-results/$entryId');
      _results.removeWhere((r) => r.id == entryId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
