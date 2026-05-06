import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

enum MedFrequency { once, daily, twiceDaily, threeTimesDaily, weekly, biweekly, monthly, asNeeded, custom }

class MobileMedication {
  final String id;
  final String petId;
  final String name;
  final String? dosage;
  final MedFrequency frequency;
  final bool isActive;
  final DateTime? endDate;
  final String? instructions;

  const MobileMedication({
    required this.id,
    required this.petId,
    required this.name,
    this.dosage,
    required this.frequency,
    required this.isActive,
    this.endDate,
    this.instructions,
  });

  factory MobileMedication.fromJson(Map<String, dynamic> j) {
    return MobileMedication(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      name: j['medication_name'] as String? ?? j['name'] as String? ?? '?',
      dosage: j['dosage'] as String?,
      frequency: _parseFreq(j['frequency']?.toString() ?? ''),
      isActive: j['is_active'] as bool? ?? true,
      endDate: j['end_date'] != null ? DateTime.tryParse(j['end_date'].toString()) : null,
      instructions: j['instructions'] as String?,
    );
  }

  static MedFrequency _parseFreq(String s) {
    switch (s) {
      case 'twice_daily': return MedFrequency.twiceDaily;
      case 'three_times_daily': return MedFrequency.threeTimesDaily;
      case 'weekly': return MedFrequency.weekly;
      case 'biweekly': return MedFrequency.biweekly;
      case 'monthly': return MedFrequency.monthly;
      case 'as_needed': return MedFrequency.asNeeded;
      case 'custom': return MedFrequency.custom;
      case 'once': return MedFrequency.once;
      default: return MedFrequency.daily;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case MedFrequency.once: return 'Einmalig';
      case MedFrequency.daily: return 'Täglich';
      case MedFrequency.twiceDaily: return '2x täglich';
      case MedFrequency.threeTimesDaily: return '3x täglich';
      case MedFrequency.weekly: return 'Wöchentlich';
      case MedFrequency.biweekly: return '2x wöchentlich';
      case MedFrequency.monthly: return 'Monatlich';
      case MedFrequency.asNeeded: return 'Bei Bedarf';
      case MedFrequency.custom: return 'Individuell';
    }
  }

  bool get endsSoon {
    if (endDate == null) return false;
    return endDate!.difference(DateTime.now()).inDays <= 3;
  }
}

class MobileMedicationProvider extends ChangeNotifier {
  final ApiService _api;
  final Map<String, List<MobileMedication>> _byPet = {};
  final Set<String> _loading = {};

  MobileMedicationProvider({required ApiService api}) : _api = api;

  List<MobileMedication> forPet(String petId) => _byPet[petId] ?? [];
  List<MobileMedication> activeForPet(String petId) =>
      forPet(petId).where((m) => m.isActive).toList();
  bool isLoading(String petId) => _loading.contains(petId);

  Future<void> loadForPet(String petId) async {
    if (_loading.contains(petId)) return;
    _loading.add(petId);
    notifyListeners();
    try {
      final data = await _api.get('/pets/$petId/medications');
      _byPet[petId] = (data['medications'] as List<dynamic>? ?? [])
          .map((e) => MobileMedication.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _byPet[petId] = [];
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  Future<bool> administer(String petId, String medicationId) async {
    try {
      await _api.post('/pets/$petId/medications/$medicationId/administer', body: {
        'scheduled_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> skip(String petId, String medicationId) async {
    try {
      await _api.post('/pets/$petId/medications/$medicationId/skip', body: {
        'scheduled_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
