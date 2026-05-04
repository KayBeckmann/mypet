import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Medication {
  final String id;
  final String petId;
  final String? vetId;
  final String? vetName;
  final String name;
  final String? dosage;
  final String frequency;
  final String? customFrequency;
  final String? instructions;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  const Medication({
    required this.id,
    required this.petId,
    this.vetId,
    this.vetName,
    required this.name,
    this.dosage,
    required this.frequency,
    this.customFrequency,
    this.instructions,
    this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        vetId: j['vet_id'] as String?,
        vetName: j['vet_name'] as String?,
        name: j['name'] as String,
        dosage: j['dosage'] as String?,
        frequency: j['frequency'] as String? ?? 'daily',
        customFrequency: j['custom_frequency'] as String?,
        instructions: j['instructions'] as String?,
        startDate: j['start_date'] != null
            ? DateTime.tryParse(j['start_date'] as String)
            : null,
        endDate: j['end_date'] != null
            ? DateTime.tryParse(j['end_date'] as String)
            : null,
        isActive: j['is_active'] as bool? ?? true,
      );

  bool get isExpired =>
      endDate != null && endDate!.isBefore(DateTime.now());

  bool get endsSoon =>
      endDate != null &&
      !isExpired &&
      endDate!.isBefore(DateTime.now().add(const Duration(days: 3)));

  int? get daysRemaining {
    if (endDate == null) return null;
    final diff = endDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get dosesPerDay {
    switch (frequency) {
      case 'twice_daily':
        return 2;
      case 'three_times_daily':
        return 3;
      case 'weekly':
        return 1 / 7;
      case 'biweekly':
        return 1 / 14;
      case 'monthly':
        return 1 / 30;
      case 'once':
      case 'as_needed':
        return 0;
      default:
        return 1;
    }
  }

  int? get estimatedDosesLeft {
    final dr = daysRemaining;
    if (dr == null) return null;
    return (dr * dosesPerDay).ceil();
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'once':
        return 'Einmalig';
      case 'daily':
        return '1× täglich';
      case 'twice_daily':
        return '2× täglich';
      case 'three_times_daily':
        return '3× täglich';
      case 'weekly':
        return 'Wöchentlich';
      case 'biweekly':
        return '2-wöchentlich';
      case 'monthly':
        return 'Monatlich';
      case 'as_needed':
        return 'Bei Bedarf';
      case 'custom':
        return customFrequency ?? 'Individuell';
      default:
        return frequency;
    }
  }
}

class MedicationProvider extends ChangeNotifier {
  final ApiService _api;

  MedicationProvider({required ApiService api}) : _api = api;

  final Map<String, List<Medication>> _medications = {};
  final Set<String> _loading = {};
  final Map<String, String?> _errors = {};
  String? _selectedPetId;

  List<Medication> forPet(String petId) => _medications[petId] ?? [];
  List<Medication> activeForPet(String petId) =>
      forPet(petId).where((m) => m.isActive && !m.isExpired).toList();
  bool isLoading(String petId) => _loading.contains(petId);
  String? error(String petId) => _errors[petId];
  String? get selectedPetId => _selectedPetId;

  Future<void> loadForPet(String petId) async {
    _selectedPetId = petId;
    if (_loading.contains(petId)) return;
    _loading.add(petId);
    _errors.remove(petId);
    notifyListeners();

    try {
      final res = await _api.get('/pets/$petId/medications');
      _medications[petId] = (res['medications'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errors[petId] = e.toString();
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  Future<bool> administer(
    String petId,
    String medicationId, {
    String? notes,
  }) async {
    try {
      await _api.post(
        '/pets/$petId/medications/$medicationId/administer',
        body: {
          'scheduled_at': DateTime.now().toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return true;
    } catch (e) {
      _errors[petId] = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> skip(
    String petId,
    String medicationId, {
    String? notes,
  }) async {
    try {
      await _api.post(
        '/pets/$petId/medications/$medicationId/skip',
        body: {
          'scheduled_at': DateTime.now().toIso8601String(),
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return true;
    } catch (e) {
      _errors[petId] = e.toString();
      notifyListeners();
      return false;
    }
  }
}
