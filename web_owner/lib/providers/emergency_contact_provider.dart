import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String? relationship;
  final String phone;
  final String? email;
  final String? notes;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    this.relationship,
    required this.phone,
    this.email,
    this.notes,
    required this.isPrimary,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
        id: j['id'] as String,
        name: j['name'] as String,
        relationship: j['relationship'] as String?,
        phone: j['phone'] as String,
        email: j['email'] as String?,
        notes: j['notes'] as String?,
        isPrimary: j['is_primary'] as bool? ?? false,
      );
}

class EmergencyContactProvider extends ChangeNotifier {
  final ApiService _api;

  EmergencyContactProvider({required ApiService api}) : _api = api;

  List<EmergencyContact> _contacts = [];
  bool _loading = false;
  String? _error;

  List<EmergencyContact> get contacts => _contacts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/emergency-contacts');
      _contacts = (data['contacts'] as List<dynamic>? ?? [])
          .map((j) => EmergencyContact.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _error = 'Notfallkontakte konnten nicht geladen werden';
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> add(Map<String, dynamic> body) async {
    try {
      final data = await _api.post('/emergency-contacts', body: body);
      final contact = EmergencyContact.fromJson(data['contact'] as Map<String, dynamic>);
      if (contact.isPrimary) {
        _contacts = _contacts.map((c) => EmergencyContact(
          id: c.id,
          name: c.name,
          relationship: c.relationship,
          phone: c.phone,
          email: c.email,
          notes: c.notes,
          isPrimary: false,
        )).toList();
      }
      _contacts.insert(0, contact);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(String contactId, Map<String, dynamic> body) async {
    try {
      final data = await _api.put('/emergency-contacts/$contactId', body: body);
      final updated = EmergencyContact.fromJson(data['contact'] as Map<String, dynamic>);
      if (updated.isPrimary) {
        _contacts = _contacts.map((c) => c.id == contactId
            ? updated
            : EmergencyContact(
                id: c.id,
                name: c.name,
                relationship: c.relationship,
                phone: c.phone,
                email: c.email,
                notes: c.notes,
                isPrimary: false,
              )).toList();
      } else {
        final idx = _contacts.indexWhere((c) => c.id == contactId);
        if (idx != -1) _contacts[idx] = updated;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String contactId) async {
    try {
      await _api.delete('/emergency-contacts/$contactId');
      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
