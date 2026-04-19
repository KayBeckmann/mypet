import '../database/database.dart';

/// Prüft ob ein Benutzer Zugriff auf ein Tier hat.
/// Gibt true zurück wenn:
/// - Benutzer ist Superadmin
/// - Benutzer ist Eigentümer des Tieres
/// - Benutzer hat eine aktive Zugriffsberechtigung (direkt oder via Organisation)
Future<bool> petHasAccess(
  Database db,
  String petId,
  String userId,
  String userRole, {
  bool requireWrite = false,
  String? orgId,
}) async {
  if (userRole == 'superadmin') return true;

  final pet = await db.queryOne(
    'SELECT owner_id FROM pets WHERE id = @id::uuid AND is_active = true',
    parameters: {'id': petId},
  );
  if (pet == null) return false;
  if (pet['owner_id'].toString() == userId) return true;

  final permLevel =
      requireWrite ? "'write', 'manage'" : "'read', 'write', 'manage'";
  final orgCondition = orgId != null
      ? "OR (subject_type = 'organization' AND subject_organization_id = @org_id::uuid)"
      : '';
  final params = <String, dynamic>{'pet_id': petId, 'user_id': userId};
  if (orgId != null) params['org_id'] = orgId;

  final perm = await db.queryOne(
    '''
    SELECT id FROM access_permissions
    WHERE pet_id = @pet_id::uuid
      AND permission IN ($permLevel)
      AND is_active = true
      AND (starts_at IS NULL OR starts_at <= NOW())
      AND (ends_at IS NULL OR ends_at >= NOW())
      AND (
        (subject_type = 'user' AND subject_user_id = @user_id::uuid)
        $orgCondition
      )
    ''',
    parameters: params,
  );
  return perm != null;
}
