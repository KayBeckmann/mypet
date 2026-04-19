import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AccessPermission {
  final String id;
  final String petId;
  final String petName;
  final String subjectType;
  final String? subjectUserId;
  final String? subjectUserName;
  final String? subjectUserEmail;
  final String? subjectOrganizationId;
  final String? subjectOrganizationName;
  final String permission;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? note;
  final bool isActive;

  const AccessPermission({
    required this.id,
    required this.petId,
    required this.petName,
    required this.subjectType,
    this.subjectUserId,
    this.subjectUserName,
    this.subjectUserEmail,
    this.subjectOrganizationId,
    this.subjectOrganizationName,
    required this.permission,
    this.startsAt,
    this.endsAt,
    this.note,
    required this.isActive,
  });

  factory AccessPermission.fromJson(Map<String, dynamic> json) {
    return AccessPermission(
      id: json['id'].toString(),
      petId: json['pet_id']?.toString() ?? '',
      petName: json['pet_name'] as String? ?? '',
      subjectType: json['subject_type'] as String? ?? 'user',
      subjectUserId: json['subject_user_id']?.toString(),
      subjectUserName: json['subject_user_name'] as String?,
      subjectUserEmail: json['subject_user_email'] as String?,
      subjectOrganizationId: json['subject_organization_id']?.toString(),
      subjectOrganizationName: json['subject_organization_name'] as String?,
      permission: json['permission'] as String? ?? 'read',
      startsAt: json['starts_at'] != null
          ? DateTime.tryParse(json['starts_at'].toString())
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.tryParse(json['ends_at'].toString())
          : null,
      note: json['note'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  bool get isExpired => endsAt != null && endsAt!.isBefore(DateTime.now());
}

class PermissionProvider extends ChangeNotifier {
  final ApiService _api;
  List<AccessPermission> _permissions = [];
  bool _isLoading = false;
  String? _error;

  PermissionProvider({required ApiService api}) : _api = api;

  List<AccessPermission> get permissions => _permissions;
  List<AccessPermission> get active =>
      _permissions.where((p) => p.isActive && !p.isExpired).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/permissions');
      final list = response['permissions'] as List<dynamic>? ?? [];
      _permissions = list
          .map((j) => AccessPermission.fromJson(j as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Berechtigungen konnten nicht geladen werden';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> grantPermission({
    required String petId,
    required String subjectType,
    String? subjectUserId,
    String? subjectOrganizationId,
    required String permission,
    DateTime? startsAt,
    DateTime? endsAt,
    String? note,
  }) async {
    try {
      await _api.post('/permissions', body: {
        'pet_id': petId,
        'subject_type': subjectType,
        if (subjectUserId != null) 'subject_user_id': subjectUserId,
        if (subjectOrganizationId != null)
          'subject_organization_id': subjectOrganizationId,
        'permission': permission,
        if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
        if (note != null && note.isNotEmpty) 'note': note,
      });
      await loadPermissions();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Berechtigung konnte nicht erteilt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> revokePermission(String id) async {
    try {
      await _api.delete('/permissions/$id');
      await loadPermissions();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Berechtigung konnte nicht widerrufen werden';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
