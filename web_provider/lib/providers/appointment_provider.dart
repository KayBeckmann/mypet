import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

enum ProviderAppointmentStatus {
  requested,
  confirmed,
  completed,
  cancelled,
  noShow,
}

class ProviderAppointment {
  final String id;
  final String petId;
  final String? petName;
  final String ownerId;
  final String? ownerName;
  final String? providerId;
  final String? providerName;
  final String? organizationId;
  final String title;
  final String? description;
  final ProviderAppointmentStatus status;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String? cancelledReason;

  const ProviderAppointment({
    required this.id,
    required this.petId,
    this.petName,
    required this.ownerId,
    this.ownerName,
    this.providerId,
    this.providerName,
    this.organizationId,
    required this.title,
    this.description,
    required this.status,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.location,
    this.notes,
    this.cancelledReason,
  });

  factory ProviderAppointment.fromJson(Map<String, dynamic> j) {
    return ProviderAppointment(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      petName: j['pet_name'] as String?,
      ownerId: j['owner_id'] as String,
      ownerName: j['owner_name'] as String?,
      providerId: j['provider_id'] as String?,
      providerName: j['provider_name'] as String?,
      organizationId: j['organization_id'] as String?,
      title: j['title'] as String,
      description: j['description'] as String?,
      status: _parse(j['status'] as String),
      scheduledAt: DateTime.parse(j['scheduled_at'] as String),
      durationMinutes: j['duration_minutes'] as int? ?? 30,
      location: j['location'] as String?,
      notes: j['notes'] as String?,
      cancelledReason: j['cancelled_reason'] as String?,
    );
  }

  static ProviderAppointmentStatus _parse(String s) {
    switch (s) {
      case 'confirmed':
        return ProviderAppointmentStatus.confirmed;
      case 'completed':
        return ProviderAppointmentStatus.completed;
      case 'cancelled':
        return ProviderAppointmentStatus.cancelled;
      case 'no_show':
        return ProviderAppointmentStatus.noShow;
      default:
        return ProviderAppointmentStatus.requested;
    }
  }

  String get statusLabel {
    switch (status) {
      case ProviderAppointmentStatus.requested:
        return 'Angefragt';
      case ProviderAppointmentStatus.confirmed:
        return 'Bestätigt';
      case ProviderAppointmentStatus.completed:
        return 'Abgeschlossen';
      case ProviderAppointmentStatus.cancelled:
        return 'Abgesagt';
      case ProviderAppointmentStatus.noShow:
        return 'Nicht erschienen';
    }
  }

  String get timeLabel =>
      '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

  String get dateLabel {
    final m = [
      '', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return '${scheduledAt.day}. ${m[scheduledAt.month]} ${scheduledAt.year}';
  }
}

class ProviderAppointmentProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderAppointmentProvider({required ApiService api}) : _api = api;

  List<ProviderAppointment> _appointments = [];
  bool _loading = false;
  String? _error;

  List<ProviderAppointment> get appointments => _appointments;
  bool get loading => _loading;
  String? get error => _error;

  List<ProviderAppointment> get pending => _appointments
      .where((a) => a.status == ProviderAppointmentStatus.requested)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<ProviderAppointment> get confirmed => _appointments
      .where((a) => a.status == ProviderAppointmentStatus.confirmed)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  List<ProviderAppointment> get past => _appointments
      .where((a) =>
          a.status == ProviderAppointmentStatus.completed ||
          a.status == ProviderAppointmentStatus.cancelled ||
          a.status == ProviderAppointmentStatus.noShow)
      .toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/appointments');
      final list = data['appointments'] as List<dynamic>? ?? [];
      _appointments = list
          .map((e) =>
              ProviderAppointment.fromJson(e as Map<String, dynamic>))
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
      _replace(ProviderAppointment.fromJson(
          data['appointment'] as Map<String, dynamic>));
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
      _replace(ProviderAppointment.fromJson(
          data['appointment'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _replace(ProviderAppointment updated) {
    _appointments =
        _appointments.map((a) => a.id == updated.id ? updated : a).toList();
    notifyListeners();
  }
}
