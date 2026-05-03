import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OwnerPrescription {
  final String id;
  final String petId;
  final String? issuedByName;
  final String? organizationName;
  final String drugName;
  final String? dosage;
  final String? frequency;
  final int? durationDays;
  final String? instructions;
  final DateTime issuedAt;
  final DateTime? validUntil;
  final int refillsRemaining;
  final String? notes;

  const OwnerPrescription({
    required this.id,
    required this.petId,
    this.issuedByName,
    this.organizationName,
    required this.drugName,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.instructions,
    required this.issuedAt,
    this.validUntil,
    required this.refillsRemaining,
    this.notes,
  });

  factory OwnerPrescription.fromJson(Map<String, dynamic> j) =>
      OwnerPrescription(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        issuedByName: j['issued_by_name'] as String?,
        organizationName: j['organization_name'] as String?,
        drugName: j['drug_name'] as String,
        dosage: j['dosage'] as String?,
        frequency: j['frequency'] as String?,
        durationDays: j['duration_days'] as int?,
        instructions: j['instructions'] as String?,
        issuedAt: DateTime.parse(j['issued_at'] as String),
        validUntil: j['valid_until'] != null
            ? DateTime.tryParse(j['valid_until'] as String)
            : null,
        refillsRemaining: j['refills_remaining'] as int? ?? 0,
        notes: j['notes'] as String?,
      );

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());
}

class OwnerPrescriptionProvider extends ChangeNotifier {
  final ApiService _api;

  OwnerPrescriptionProvider({required ApiService api}) : _api = api;

  final Map<String, List<OwnerPrescription>> _byPet = {};
  final Map<String, bool> _loading = {};
  String? _error;

  String? get error => _error;

  List<OwnerPrescription> forPet(String petId) =>
      _byPet[petId] ?? const [];

  bool isLoading(String petId) => _loading[petId] ?? false;

  Future<void> loadForPet(String petId) async {
    _loading[petId] = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/prescriptions');
      _byPet[petId] = (data['prescriptions'] as List<dynamic>? ?? [])
          .map((j) => OwnerPrescription.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _error = 'Rezepte konnten nicht geladen werden';
    }

    _loading[petId] = false;
    notifyListeners();
  }
}
