import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Vaccination {
  final String id;
  final String vaccineName;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime? administeredAt;
  final DateTime? validUntil;
  final String? vetName;
  final String? organizationName;
  final String? notes;

  const Vaccination({
    required this.id,
    required this.vaccineName,
    this.manufacturer,
    this.batchNumber,
    this.administeredAt,
    this.validUntil,
    this.vetName,
    this.organizationName,
    this.notes,
  });

  factory Vaccination.fromJson(Map<String, dynamic> j) => Vaccination(
        id: j['id'] as String,
        vaccineName: j['vaccine_name'] as String,
        manufacturer: j['manufacturer'] as String?,
        batchNumber: j['batch_number'] as String?,
        administeredAt: j['administered_at'] != null
            ? DateTime.tryParse(j['administered_at'] as String)
            : null,
        validUntil: j['valid_until'] != null
            ? DateTime.tryParse(j['valid_until'] as String)
            : null,
        vetName: j['vet_name'] as String?,
        organizationName: j['organization_name'] as String?,
        notes: j['notes'] as String?,
      );

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  bool get expiresSoon =>
      validUntil != null &&
      !isExpired &&
      validUntil!.isBefore(DateTime.now().add(const Duration(days: 30)));

  String get statusLabel {
    if (isExpired) return 'Abgelaufen';
    if (expiresSoon) return 'Läuft bald ab';
    if (validUntil != null) return 'Gültig';
    return 'Eingetragen';
  }

  Color get statusColor {
    if (isExpired) return const Color(0xFFD32F2F);
    if (expiresSoon) return const Color(0xFFF57C00);
    return const Color(0xFF2E7D32);
  }
}

class MedicalRecord {
  final String id;
  final String recordType;
  final String title;
  final String? description;
  final String? diagnosis;
  final String? treatment;
  final DateTime? recordedAt;
  final String? vetName;
  final String? organizationName;

  const MedicalRecord({
    required this.id,
    required this.recordType,
    required this.title,
    this.description,
    this.diagnosis,
    this.treatment,
    this.recordedAt,
    this.vetName,
    this.organizationName,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> j) => MedicalRecord(
        id: j['id'] as String,
        recordType: j['record_type'] as String? ?? 'other',
        title: j['title'] as String,
        description: j['description'] as String?,
        diagnosis: j['diagnosis'] as String?,
        treatment: j['treatment'] as String?,
        recordedAt: j['recorded_at'] != null
            ? DateTime.tryParse(j['recorded_at'] as String)
            : null,
        vetName: j['vet_name'] as String?,
        organizationName: j['organization_name'] as String?,
      );

  String get typeLabel {
    switch (recordType) {
      case 'checkup':
        return 'Untersuchung';
      case 'diagnosis':
        return 'Diagnose';
      case 'treatment':
        return 'Behandlung';
      case 'surgery':
        return 'Operation';
      case 'lab_result':
        return 'Laborergebnis';
      case 'prescription':
        return 'Rezept';
      case 'observation':
        return 'Beobachtung';
      default:
        return 'Sonstiges';
    }
  }
}

class OwnerHealthProvider extends ChangeNotifier {
  final ApiService _api;

  OwnerHealthProvider({required ApiService api}) : _api = api;

  final Map<String, List<Vaccination>> _vaccinations = {};
  final Map<String, List<MedicalRecord>> _records = {};
  final Set<String> _loading = {};
  final Map<String, String?> _errors = {};

  List<Vaccination> vaccinationsForPet(String petId) =>
      _vaccinations[petId] ?? [];

  List<MedicalRecord> recordsForPet(String petId) =>
      _records[petId] ?? [];

  bool isLoading(String petId) => _loading.contains(petId);
  String? error(String petId) => _errors[petId];

  Future<void> loadForPet(String petId) async {
    if (_loading.contains(petId)) return;
    _loading.add(petId);
    _errors.remove(petId);
    notifyListeners();

    try {
      final vaccFuture = _api.get('/pets/$petId/vaccinations');
      final recordsFuture = _api.get('/pets/$petId/records');

      final results = await Future.wait([vaccFuture, recordsFuture]);

      _vaccinations[petId] = (results[0]['vaccinations'] as List? ?? [])
          .map((e) => Vaccination.fromJson(e as Map<String, dynamic>))
          .toList();

      _records[petId] = (results[1]['records'] as List? ?? [])
          .map((e) => MedicalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errors[petId] = e.toString();
    } finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }
}
