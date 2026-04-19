import 'dart:convert';
import '../database/database.dart';

/// Service zum Protokollieren sensibler Aktionen
class AuditService {
  final Database _db;

  AuditService(this._db);

  Future<void> log({
    required String? userId,
    required String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    try {
      await _db.queryAll(
        '''
        INSERT INTO audit_log (user_id, action, resource_type, resource_id, details, ip_address)
        VALUES (@user_id::uuid, @action, @resource_type, @resource_id::uuid, @details::jsonb, @ip_address)
        ''',
        parameters: {
          'user_id': userId,
          'action': action,
          'resource_type': resourceType,
          'resource_id': resourceId,
          'details': details != null ? jsonEncode(details) : null,
          'ip_address': ipAddress,
        },
      );
    } catch (e) {
      // Audit-Fehler nicht nach oben weitergeben
      print('⚠️ Audit-Log Fehler: $e');
    }
  }
}
