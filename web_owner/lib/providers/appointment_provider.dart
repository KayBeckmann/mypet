import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiService _api;

  AppointmentProvider({required ApiService api}) : _api = api;

  List<Appointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<Appointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  List<Appointment> get upcoming => _appointments
      .where((a) =>
          a.status == AppointmentStatus.requested ||
          a.status == AppointmentStatus.confirmed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<Appointment> get past => _appointments
      .where((a) =>
          a.status == AppointmentStatus.completed ||
          a.status == AppointmentStatus.cancelled ||
          a.status == AppointmentStatus.noShow)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  Future<void> load({String? petId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final path = petId != null
          ? '/appointments?pet_id=$petId'
          : '/appointments';
      final data = await _api.get(path);
      final list = (data['appointments'] as List<dynamic>? ?? []);
      _appointments =
          list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Appointment?> create({
    required String petId,
    required String title,
    required DateTime scheduledAt,
    String? description,
    String? providerId,
    String? organizationId,
    int durationMinutes = 30,
    String? location,
    String? notes,
  }) async {
    try {
      final data = await _api.post('/appointments', body: {
        'pet_id': petId,
        'title': title,
        'scheduled_at': scheduledAt.toIso8601String(),
        if (description != null) 'description': description,
        if (providerId != null) 'provider_id': providerId,
        if (organizationId != null) 'organization_id': organizationId,
        'duration_minutes': durationMinutes,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      });
      final a = Appointment.fromJson(data['appointment'] as Map<String, dynamic>);
      _appointments.insert(0, a);
      notifyListeners();
      return a;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancel(String id, {String? reason}) async {
    try {
      final data = await _api.put('/appointments/$id/cancel',
          body: {if (reason != null) 'reason': reason});
      final updated =
          Appointment.fromJson(data['appointment'] as Map<String, dynamic>);
      _appointments = _appointments.map((a) => a.id == id ? updated : a).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
