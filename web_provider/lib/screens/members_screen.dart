import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<ProviderAuthProvider>();
      final orgId = auth.activeOrganizationId;
      if (orgId != null) {
        context.read<ProviderOrganizationProvider>().load(orgId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<ProviderOrganizationProvider>();
    final auth = context.watch<ProviderAuthProvider>();
    final orgId = auth.activeOrganizationId;

    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Mitarbeiter',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (orgId != null)
                  ElevatedButton.icon(
                    onPressed: () => _showInviteDialog(context, orgId),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Einladen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProviderTheme.primary,
                      foregroundColor: ProviderTheme.onPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (orgProvider.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (orgId == null)
              const Expanded(
                child: Center(child: Text('Bitte zuerst einen Betrieb anlegen.')),
              )
            else if (orgProvider.members.isEmpty)
              const Expanded(
                child: Center(child: Text('Noch keine Mitarbeiter.')),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: orgProvider.members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = orgProvider.members[i];
                    return _MemberCard(
                      member: m,
                      orgId: orgId,
                      onChangeRole: (role) => orgProvider.changeRole(
                          orgId, m['user_id'].toString(), role),
                      onRemove: () => _confirmRemove(
                          context, orgId, m['user_id'].toString(),
                          m['name'] as String? ?? ''),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, String orgId) async {
    final emailCtrl = TextEditingController();
    String role = 'member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Mitarbeiter einladen'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'E-Mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Rolle',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'member', child: Text('Mitarbeiter')),
                    DropdownMenuItem(value: 'viewer', child: Text('Betrachter')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'member'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Einladen')),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      if (emailCtrl.text.trim().isEmpty) return;
      final ok = await context
          .read<ProviderOrganizationProvider>()
          .invite(orgId, emailCtrl.text.trim(), role);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Einladung gesendet' : 'Fehler beim Einladen'),
        ));
      }
    }
  }

  Future<void> _confirmRemove(
      BuildContext context, String orgId, String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitarbeiter entfernen'),
        content: Text('$name aus dem Betrieb entfernen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ProviderTheme.error),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProviderOrganizationProvider>().removeMember(orgId, userId);
    }
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final String orgId;
  final ValueChanged<String> onChangeRole;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.orgId,
    required this.onChangeRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '—';
    final email = member['email'] as String? ?? '';
    final role = member['role'] as String? ?? 'member';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProviderTheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                ProviderTheme.primary.withValues(alpha: 0.12),
            child: Text(initials,
                style: const TextStyle(
                    color: ProviderTheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(email,
                    style: TextStyle(
                        color: ProviderTheme.onSurfaceVariant,
                        fontSize: 13)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: role,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(value: 'member', child: Text('Mitarbeiter')),
              DropdownMenuItem(value: 'viewer', child: Text('Betrachter')),
            ],
            onChanged: (v) {
              if (v != null && v != role) onChangeRole(v);
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            color: ProviderTheme.error,
            onPressed: onRemove,
            tooltip: 'Entfernen',
          ),
        ],
      ),
    );
  }
}
