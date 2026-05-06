import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/users_provider.dart';
import '../widgets/role_badge.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/admin/users/${widget.userId}');
      setState(() {
        _user = data['user'] as Map<String, dynamic>?;
        _isLoading = false;
        if (_user == null) _error = 'Benutzer nicht gefunden';
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeRole(String newRole) async {
    final ok = await context.read<UsersProvider>().updateUser(
          widget.userId,
          {'role': newRole},
        );
    if (ok && mounted) {
      setState(() => _user = {..._user!, 'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rolle geändert')),
      );
    }
  }

  Future<void> _toggleActive() async {
    final current = _user?['is_active'] as bool? ?? false;
    final ok = await context.read<UsersProvider>().updateUser(
          widget.userId,
          {'is_active': !current},
        );
    if (ok && mounted) {
      setState(() => _user = {..._user!, 'is_active': !current});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(current ? 'Benutzer deaktiviert' : 'Benutzer aktiviert')),
      );
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Passwort zurücksetzen'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Neues Passwort',
                suffixIcon: IconButton(
                  icon: Icon(obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setDialogState(() => obscure = !obscure),
                ),
              ),
              obscureText: obscure,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Mindestens 8 Zeichen' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Zurücksetzen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context
          .read<UsersProvider>()
          .resetPassword(widget.userId, controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Passwort erfolgreich geändert' : 'Fehler beim Passwort-Reset'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Benutzer deaktivieren'),
        content: const Text(
            'Der Benutzer kann sich danach nicht mehr anmelden. Fortfahren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.secondary,
                foregroundColor: AdminTheme.onSecondary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _toggleActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        title: Text(_user?['name'] as String? ?? 'Benutzer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final user = _user!;
    final isActive = user['is_active'] as bool? ?? false;
    final role = user['role'] as String? ?? '';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profil-Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminTheme.spacingLg),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isActive
                            ? AdminTheme.primaryContainer
                            : AdminTheme.surfaceContainerHigh,
                        child: Text(
                          (user['name'] as String? ?? '?')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AdminTheme.onPrimary
                                : AdminTheme.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] as String? ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AdminTheme.spacingXs),
                            Text(user['email'] as String? ?? ''),
                            const SizedBox(height: AdminTheme.spacingSm),
                            Row(
                              children: [
                                RoleBadge(role: role),
                                if (!isActive) ...[
                                  const SizedBox(width: AdminTheme.spacingSm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(
                                          AdminTheme.radiusFull),
                                    ),
                                    child: const Text(
                                      'Deaktiviert',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AdminTheme.outline),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AdminTheme.spacingMd),

              // Statistiken & Aktivität
              if (user['stats'] != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statistiken',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AdminTheme.spacingMd),
                        Row(
                          children: [
                            _StatTile(
                              label: 'Tiere',
                              value: '${(user['stats'] as Map)['pet_count'] ?? 0}',
                              icon: Icons.pets_rounded,
                            ),
                            const SizedBox(width: 12),
                            _StatTile(
                              label: 'Termine',
                              value: '${(user['stats'] as Map)['appointment_count'] ?? 0}',
                              icon: Icons.event_rounded,
                            ),
                          ],
                        ),
                        if (user['recent_activity'] != null &&
                            (user['recent_activity'] as List).isNotEmpty) ...[
                          const SizedBox(height: AdminTheme.spacingMd),
                          Text('Letzte Aktivität',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          ...(user['recent_activity'] as List).map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 6, color: AdminTheme.outline),
                                const SizedBox(width: 8),
                                Text('${a['action']} ${a['resource_type']}',
                                    style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                Text(
                                  _fmtDate(a['created_at'] as String?),
                                  style: TextStyle(fontSize: 11, color: AdminTheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AdminTheme.spacingMd),
              ],

              // Rolle ändern
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rolle ändern',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminTheme.spacingMd),
                      Wrap(
                        spacing: AdminTheme.spacingSm,
                        children: ['owner', 'vet', 'provider'].map((r) {
                          return ChoiceChip(
                            label: Text(_roleLabel(r)),
                            selected: role == r,
                            onSelected: (_) => _changeRole(r),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AdminTheme.spacingMd),

              // Aktionen
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Aktionen',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminTheme.spacingMd),
                      OutlinedButton.icon(
                        onPressed: _showPasswordResetDialog,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Passwort zurücksetzen'),
                      ),
                      const SizedBox(height: AdminTheme.spacingSm),
                      if (isActive)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.secondary,
                            foregroundColor: AdminTheme.onSecondary,
                          ),
                          onPressed: _confirmDeactivate,
                          icon: const Icon(Icons.block),
                          label: const Text('Benutzer deaktivieren'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _toggleActive,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Benutzer aktivieren'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Tierbesitzer';
      case 'vet':
        return 'Tierarzt';
      case 'provider':
        return 'Dienstleister';
      case 'superadmin':
        return 'Superadmin';
      default:
        return role;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminTheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AdminTheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(label, style: const TextStyle(fontSize: 11, color: AdminTheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
