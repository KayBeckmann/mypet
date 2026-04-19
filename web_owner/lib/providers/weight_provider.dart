import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WeightEntry {
  final String id;
  final String petId;
  final String recordedBy;
  final String? recordedByName;
  final double weightKg;
  final String? notes;
  final DateTime recordedAt;

  const WeightEntry({
    required this.id,
    required this.petId,
    required this.recordedBy,
    this.recordedByName,
    required this.weightKg,
    this.notes,
    required this.recordedAt,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        recordedBy: j['recorded_by'] as String,
        recordedByName: j['recorded_by_name'] as String?,
        weightKg: (j['weight_kg'] as num).toDouble(),
        notes: j['notes'] as String?,
        recordedAt: DateTime.parse(j['recorded_at'] as String),
      );
}

class WeightProvider extends ChangeNotifier {
  final ApiService _api;

  WeightProvider({required ApiService api}) : _api = api;

  String? _selectedPetId;
  List<WeightEntry> _entries = [];
  bool _loading = false;
  String? _error;

  String? get selectedPetId => _selectedPetId;
  List<WeightEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;

  double? get latestWeight =>
      _entries.isNotEmpty ? _entries.last.weightKg : null;
  double? get minWeight =>
      _entries.isEmpty ? null : _entries.map((e) => e.weightKg).reduce((a, b) => a < b ? a : b);
  double? get maxWeight =>
      _entries.isEmpty ? null : _entries.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);

  Future<void> loadForPet(String petId) async {
    _selectedPetId = petId;
    _entries = [];
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    if (_selectedPetId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$_selectedPetId/weight');
      _entries = (data['weights'] as List<dynamic>? ?? [])
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add({
    required double weightKg,
    String? notes,
    DateTime? recordedAt,
  }) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.post('/pets/$_selectedPetId/weight', body: {
        'weight_kg': weightKg,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
      });
      await _load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String entryId) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.delete('/pets/$_selectedPetId/weight/$entryId');
      _entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
