import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

enum MobileApptStatus { requested, confirmed, completed, cancelled, noShow }

class MobileAppointment {
  final String id;
  final String? petName;
  final String title;
  final String? description;
  final MobileApptStatus status;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? organizationName;

  const MobileAppointment({
    required this.id,
    this.petName,
    required this.title,
    this.description,
    required this.status,
    required this.scheduledAt,
    required this.durationMinutes,
    this.location,
    this.organizationName,
  });

  factory MobileAppointment.fromJson(Map<String, dynamic> j) =>
      MobileAppointment(
        id: j['id'] as String,
        petName: j['pet_name'] as String?,
        title: j['title'] as String,
        description: j['description'] as String?,
        status: _parse(j['status'] as String),
        scheduledAt: DateTime.parse(j['scheduled_at'] as String),
        durationMinutes: j['duration_minutes'] as int? ?? 30,
        location: j['location'] as String?,
        organizationName: j['organization_name'] as String?,
      );

  static MobileApptStatus _parse(String s) {
    switch (s) {
      case 'confirmed': return MobileApptStatus.confirmed;
      case 'completed': return MobileApptStatus.completed;
      case 'cancelled': return MobileApptStatus.cancelled;
      case 'no_show': return MobileApptStatus.noShow;
      default: return MobileApptStatus.requested;
    }
  }

  String get statusLabel {
    switch (status) {
      case MobileApptStatus.requested: return 'Angefragt';
      case MobileApptStatus.confirmed: return 'Bestätigt';
      case MobileApptStatus.completed: return 'Abgeschlossen';
      case MobileApptStatus.cancelled: return 'Abgesagt';
      case MobileApptStatus.noShow: return 'Nicht erschienen';
    }
  }

  String get dateTimeLabel {
    final months = ['', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
        'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
    final h = scheduledAt.hour.toString().padLeft(2, '0');
    final m = scheduledAt.minute.toString().padLeft(2, '0');
    return '${scheduledAt.day}. ${months[scheduledAt.month]} · $h:$m Uhr';
  }
}

class MobileAppointmentProvider extends ChangeNotifier {
  final ApiService _api;

  MobileAppointmentProvider({required ApiService api}) : _api = api;

  List<MobileAppointment> _appointments = [];
  bool _loading = false;

  List<MobileAppointment> get appointments => _appointments;
  List<MobileAppointment> get upcoming => _appointments
      .where((a) =>
          a.scheduledAt.isAfter(DateTime.now()) &&
          (a.status == MobileApptStatus.confirmed ||
              a.status == MobileApptStatus.requested))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.get('/appointments');
      _appointments = (data['appointments'] as List<dynamic>? ?? [])
          .map((j) => MobileAppointment.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<bool> cancel(String id, {String? reason}) async {
    try {
      await _api.put('/appointments/$id/cancel',
          body: {if (reason != null) 'reason': reason});
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
