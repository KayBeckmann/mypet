import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class Prescription {
  final String id;
  final String petId;
  final String issuedBy;
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

  const Prescription({
    required this.id,
    required this.petId,
    required this.issuedBy,
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

  factory Prescription.fromJson(Map<String, dynamic> j) => Prescription(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        issuedBy: j['issued_by'] as String,
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

class PrescriptionProvider extends ChangeNotifier {
  final ApiService _api;

  PrescriptionProvider({required ApiService api}) : _api = api;

  String? _petId;
  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _error;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForPet(String petId) async {
    _petId = petId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/prescriptions');
      _prescriptions = (data['prescriptions'] as List<dynamic>? ?? [])
          .map((j) => Prescription.fromJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Rezepte konnten nicht geladen werden';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> create({
    required String petId,
    required String drugName,
    String? dosage,
    String? frequency,
    int? durationDays,
    String? instructions,
    String? validUntil,
    int refillsRemaining = 0,
    String? notes,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/prescriptions', body: {
        'drug_name': drugName,
        if (dosage != null) 'dosage': dosage,
        if (frequency != null) 'frequency': frequency,
        if (durationDays != null) 'duration_days': durationDays,
        if (instructions != null) 'instructions': instructions,
        if (validUntil != null) 'valid_until': validUntil,
        'refills_remaining': refillsRemaining,
        if (notes != null) 'notes': notes,
      });
      final p = Prescription.fromJson(
          data['prescription'] as Map<String, dynamic>);
      _prescriptions.insert(0, p);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Fehler beim Erstellen des Rezepts';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String prescriptionId) async {
    if (_petId == null) return false;
    try {
      await _api.delete('/pets/$_petId/prescriptions/$prescriptionId');
      _prescriptions.removeWhere((p) => p.id == prescriptionId);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
