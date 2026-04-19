import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

enum AppointmentStatus { requested, confirmed, completed, cancelled, noShow }

class VetAppointment {
  final String id;
  final String petId;
  final String? petName;
  final String ownerId;
  final String? ownerName;
  final String? providerId;
  final String? providerName;
  final String? organizationId;
  final String? organizationName;
  final String title;
  final String? description;
  final AppointmentStatus status;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String? cancelledReason;

  const VetAppointment({
    required this.id,
    required this.petId,
    this.petName,
    required this.ownerId,
    this.ownerName,
    this.providerId,
    this.providerName,
    this.organizationId,
    this.organizationName,
    required this.title,
    this.description,
    required this.status,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.location,
    this.notes,
    this.cancelledReason,
  });

  factory VetAppointment.fromJson(Map<String, dynamic> j) {
    return VetAppointment(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      petName: j['pet_name'] as String?,
      ownerId: j['owner_id'] as String,
      ownerName: j['owner_name'] as String?,
      providerId: j['provider_id'] as String?,
      providerName: j['provider_name'] as String?,
      organizationId: j['organization_id'] as String?,
      organizationName: j['organization_name'] as String?,
      title: j['title'] as String,
      description: j['description'] as String?,
      status: _parseStatus(j['status'] as String),
      scheduledAt: DateTime.parse(j['scheduled_at'] as String),
      durationMinutes: j['duration_minutes'] as int? ?? 30,
      location: j['location'] as String?,
      notes: j['notes'] as String?,
      cancelledReason: j['cancelled_reason'] as String?,
    );
  }

  static AppointmentStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.requested;
    }
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.requested:
        return 'Angefragt';
      case AppointmentStatus.confirmed:
        return 'Bestätigt';
      case AppointmentStatus.completed:
        return 'Abgeschlossen';
      case AppointmentStatus.cancelled:
        return 'Abgesagt';
      case AppointmentStatus.noShow:
        return 'Nicht erschienen';
    }
  }

  String get timeLabel {
    return '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get dateLabel {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez',
    ];
    return '${scheduledAt.day}. ${months[scheduledAt.month]} ${scheduledAt.year}';
  }
}

class VetAppointmentProvider extends ChangeNotifier {
  final ApiService _api;

  VetAppointmentProvider({required ApiService api}) : _api = api;

  List<VetAppointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<VetAppointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  List<VetAppointment> get pending => _appointments
      .where((a) => a.status == AppointmentStatus.requested)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<VetAppointment> get confirmed => _appointments
      .where((a) => a.status == AppointmentStatus.confirmed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<VetAppointment> get past => _appointments
      .where((a) =>
          a.status == AppointmentStatus.completed ||
          a.status == AppointmentStatus.cancelled ||
          a.status == AppointmentStatus.noShow)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/appointments');
      final list = (data['appointments'] as List<dynamic>? ?? []);
      _appointments = list
          .map((e) => VetAppointment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> confirm(String id) async => _action(id, 'confirm');
  Future<bool> complete(String id) async => _action(id, 'complete');

  Future<bool> cancel(String id, {String? reason}) async {
    try {
      final data = await _api.put('/appointments/$id/cancel',
          body: {if (reason != null) 'reason': reason});
      _replace(
          VetAppointment.fromJson(data['appointment'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> _action(String id, String action) async {
    try {
      final data = await _api.put('/appointments/$id/$action');
      _replace(
          VetAppointment.fromJson(data['appointment'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _replace(VetAppointment updated) {
    _appointments = _appointments
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
    notifyListeners();
  }
}
