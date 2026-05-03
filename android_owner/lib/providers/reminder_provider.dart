import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class MobileReminder {
  final String id;
  final String? petId;
  final String? petName;
  final String type;
  final String title;
  final String message;
  final DateTime remindAt;
  final String status;

  const MobileReminder({
    required this.id,
    this.petId,
    this.petName,
    required this.type,
    required this.title,
    required this.message,
    required this.remindAt,
    required this.status,
  });

  factory MobileReminder.fromJson(Map<String, dynamic> j) => MobileReminder(
        id: j['id'] as String,
        petId: j['pet_id'] as String?,
        petName: j['pet_name'] as String?,
        type: j['reminder_type'] as String? ?? 'custom',
        title: j['title'] as String,
        message: j['message'] as String? ?? '',
        remindAt: DateTime.parse(j['remind_at'] as String),
        status: j['status'] as String? ?? 'pending',
      );

  bool get isOverdue => remindAt.isBefore(DateTime.now()) && status == 'pending';
  bool get isPending => status == 'pending';
}

class MobileReminderProvider extends ChangeNotifier {
  final ApiService _api;

  MobileReminderProvider({required ApiService api}) : _api = api;

  List<MobileReminder> _reminders = [];
  bool _loading = false;
  String? _error;

  List<MobileReminder> get reminders => _reminders;
  List<MobileReminder> get pending =>
      _reminders.where((r) => r.isPending).toList();
  List<MobileReminder> get overdue =>
      _reminders.where((r) => r.isOverdue).toList();
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/reminders');
      _reminders = (data['reminders'] as List<dynamic>? ?? [])
          .map((j) => MobileReminder.fromJson(j as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
    } catch (_) {
      _error = 'Erinnerungen konnten nicht geladen werden';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> create({
    required String title,
    required DateTime remindAt,
    String? petId,
    String type = 'custom',
    String message = '',
  }) async {
    try {
      final data = await _api.post('/reminders', body: {
        'title': title,
        'remind_at': remindAt.toIso8601String(),
        if (petId != null) 'pet_id': petId,
        'reminder_type': type,
        'message': message,
      });
      final r = MobileReminder.fromJson(
          data['reminder'] as Map<String, dynamic>);
      _reminders = [r, ..._reminders]
        ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dismiss(String id) async {
    try {
      await _api.put('/reminders/$id', body: {'status': 'dismissed'});
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
