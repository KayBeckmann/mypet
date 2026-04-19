import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Reminder {
  final String id;
  final String? petId;
  final String? petName;
  final String reminderType;
  final String title;
  final String message;
  final DateTime remindAt;
  final String status;
  final bool emailSent;
  final DateTime createdAt;

  const Reminder({
    required this.id,
    this.petId,
    this.petName,
    required this.reminderType,
    required this.title,
    required this.message,
    required this.remindAt,
    required this.status,
    required this.emailSent,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        petId: j['pet_id'] as String?,
        petName: j['pet_name'] as String?,
        reminderType: j['reminder_type'] as String? ?? 'custom',
        title: j['title'] as String,
        message: j['message'] as String? ?? '',
        remindAt: DateTime.parse(j['remind_at'] as String),
        status: j['status'] as String? ?? 'pending',
        emailSent: j['email_sent'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isPast => remindAt.isBefore(DateTime.now());
  bool get isPending => status == 'pending';
}

class ReminderProvider extends ChangeNotifier {
  final ApiService _api;

  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  ReminderProvider({required ApiService api}) : _api = api;

  List<Reminder> get reminders => _reminders;
  List<Reminder> get pending =>
      _reminders.where((r) => r.status == 'pending').toList();
  List<Reminder> get upcoming => _reminders
      .where((r) => r.status == 'pending' && !r.isPast)
      .toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('/reminders');
      _reminders = (res['reminders'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Reminder.fromJson)
          .toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Erinnerungen konnten nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String title,
    required DateTime remindAt,
    String message = '',
    String type = 'custom',
    String? petId,
  }) async {
    try {
      final res = await _api.post('/reminders', body: {
        'title': title,
        'message': message,
        'reminder_type': type,
        'remind_at': remindAt.toIso8601String(),
        if (petId != null) 'pet_id': petId,
      });
      _reminders.insert(0, Reminder.fromJson(res['reminder'] as Map<String, dynamic>));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erinnerung konnte nicht erstellt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> dismiss(String id) async {
    try {
      await _api.post('/reminders/$id/dismiss', body: {});
      final idx = _reminders.indexWhere((r) => r.id == id);
      if (idx != -1) {
        _reminders[idx] = Reminder(
          id: _reminders[idx].id,
          petId: _reminders[idx].petId,
          petName: _reminders[idx].petName,
          reminderType: _reminders[idx].reminderType,
          title: _reminders[idx].title,
          message: _reminders[idx].message,
          remindAt: _reminders[idx].remindAt,
          status: 'dismissed',
          emailSent: _reminders[idx].emailSent,
          createdAt: _reminders[idx].createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _api.delete('/reminders/$id');
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
