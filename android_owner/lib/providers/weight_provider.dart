import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class MobileWeightEntry {
  final String id;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;

  const MobileWeightEntry({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
  });

  factory MobileWeightEntry.fromJson(Map<String, dynamic> j) {
    return MobileWeightEntry(
      id: j['id'] as String,
      weightKg: double.parse(j['weight_kg'].toString()),
      recordedAt: DateTime.parse(j['recorded_at'] as String),
      notes: j['notes'] as String?,
    );
  }

  String get dateLabel {
    return '${recordedAt.day}.${recordedAt.month}.${recordedAt.year}';
  }
}

class MobileWeightProvider extends ChangeNotifier {
  final ApiService _api;
  final Map<String, List<MobileWeightEntry>> _byPet = {};
  final Set<String> _loading = {};

  MobileWeightProvider({required ApiService api}) : _api = api;

  List<MobileWeightEntry> forPet(String petId) => _byPet[petId] ?? [];
  MobileWeightEntry? latestForPet(String petId) {
    final entries = forPet(petId);
    if (entries.isEmpty) return null;
    return entries.last;
  }
  bool isLoading(String petId) => _loading.contains(petId);

  Future<void> loadForPet(String petId) async {
    if (_loading.contains(petId)) return;
    _loading.add(petId);
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/weight');
      _byPet[petId] = (data['weights'] as List<dynamic>? ?? [])
          .map((e) => MobileWeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _byPet[petId] = [];
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  Future<bool> addEntry({
    required String petId,
    required double weightKg,
    String? notes,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/weight', body: {
        'weight_kg': weightKg,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'recorded_at': DateTime.now().toIso8601String(),
      });
      final entry = MobileWeightEntry.fromJson(data['weight'] as Map<String, dynamic>);
      final list = List<MobileWeightEntry>.from(_byPet[petId] ?? []);
      list.add(entry);
      list.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      _byPet[petId] = list;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
