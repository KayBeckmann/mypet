import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TemperatureEntry {
  final String id;
  final String petId;
  final String recordedBy;
  final String? recordedByName;
  final double temperatureCelsius;
  final String? measurementMethod;
  final String? note;
  final DateTime recordedAt;

  const TemperatureEntry({
    required this.id,
    required this.petId,
    required this.recordedBy,
    this.recordedByName,
    required this.temperatureCelsius,
    this.measurementMethod,
    this.note,
    required this.recordedAt,
  });

  factory TemperatureEntry.fromJson(Map<String, dynamic> j) {
    return TemperatureEntry(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      recordedBy: j['recorded_by'] as String,
      recordedByName: j['recorded_by_name'] as String?,
      temperatureCelsius: double.parse(j['temperature_celsius'].toString()),
      measurementMethod: j['measurement_method'] as String?,
      note: j['note'] as String?,
      recordedAt: DateTime.parse(j['recorded_at'] as String),
    );
  }

  bool get isHigh => temperatureCelsius >= 39.5;
  bool get isLow => temperatureCelsius < 37.5;
  bool get isNormal => !isHigh && !isLow;

  String get label {
    final h = recordedAt.hour.toString().padLeft(2, '0');
    final m = recordedAt.minute.toString().padLeft(2, '0');
    return '${recordedAt.day}.${recordedAt.month}.${recordedAt.year} $h:$m';
  }
}

class TemperatureProvider extends ChangeNotifier {
  final ApiService _api;

  TemperatureProvider({required ApiService api}) : _api = api;

  List<TemperatureEntry> _entries = [];
  String? _currentPetId;
  bool _loading = false;
  String? _error;

  List<TemperatureEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;
  String? get selectedPetId => _currentPetId;

  TemperatureEntry? get latest =>
      _entries.isEmpty ? null : _entries.last;

  Future<void> loadForPet(String petId) async {
    if (_currentPetId == petId && _entries.isNotEmpty) return;
    _currentPetId = petId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/temperature');
      _entries = (data['temperatures'] as List<dynamic>? ?? [])
          .map((e) => TemperatureEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<TemperatureEntry?> add({
    required String petId,
    required double temperatureCelsius,
    String? measurementMethod,
    String? note,
    DateTime? recordedAt,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/temperature', body: {
        'temperature_celsius': temperatureCelsius,
        if (measurementMethod != null) 'measurement_method': measurementMethod,
        if (note != null && note.isNotEmpty) 'note': note,
        if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
      });
      final entry = TemperatureEntry.fromJson(
          data['temperature'] as Map<String, dynamic>);
      _entries.add(entry);
      _entries.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      notifyListeners();
      return entry;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(String petId, String entryId) async {
    try {
      await _api.delete('/pets/$petId/temperature/$entryId');
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
