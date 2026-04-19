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
      final orgProvider = context.read<OrganizationProvider>();
      final auth = context.read<VetAuthProvider>();
      if (auth.activeOrganizationId != null) {
        orgProvider.loadMembers(auth.activeOrganizationId!);
      }
    });
  }

  Future<void> _inviteMember() async {
    final auth = context.read<VetAuthProvider>();
    final orgId = auth.activeOrganizationId;
    if (orgId == null) return;

    final emailCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    String selectedRole = 'member';
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mitarbeiter einladen'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Ungültige E-Mail' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: positionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Position (optional)',
                    hintText: 'z.B. TFA, Tierarzt, Azubi',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rolle'),
                  items: const [
                    DropdownMenuItem(value: 'member', child: Text('Mitarbeiter')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'readonly', child: Text('Nur lesen')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Einladen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await context.read<OrganizationProvider>().inviteMember(
            orgId,
            emailCtrl.text.trim(),
            selectedRole,
            positionCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ok ? 'Einladung gesendet' : 'Einladung fehlgeschlagen')),
        );
      }
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final auth = context.read<VetAuthProvider>();
    final orgId = auth.activeOrganizationId;
    if (orgId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mitarbeiter entfernen'),
        content: Text(
            '${member['name'] ?? member['email']} aus dem Team entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: VetTheme.secondary,
                foregroundColor: VetTheme.onSecondary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<OrganizationProvider>()
          .removeMember(orgId, member['user_id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    final auth = context.watch<VetAuthProvider>();

    if (auth.activeOrganizationId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VetTheme.spacingXl),
          child: Text(
            'Erst eine Praxis unter „Meine Praxis" anlegen.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(VetTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Team-Verwaltung',
                  style: Theme.of(context).textTheme.headlineMedium),
              ElevatedButton.icon(
                onPressed: _inviteMember,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Einladen'),
              ),
            ],
          ),
          const SizedBox(height: VetTheme.spacingLg),

          if (orgProvider.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VetTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(VetTheme.radiusMd),
              ),
              child: Text(orgProvider.error!,
                  style: const TextStyle(color: VetTheme.secondary)),
            ),

          if (orgProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (orgProvider.members.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Text('Noch keine Teammitglieder'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: orgProvider.members.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: VetTheme.spacingSm),
                itemBuilder: (context, i) {
                  final member = orgProvider.members[i];
                  return _MemberCard(
                    member: member,
                    onRemove: () => _removeMember(member),
                    onRoleChange: (role) async {
                      final orgId = auth.activeOrganizationId!;
                      await context.read<OrganizationProvider>().changeMemberRole(
                            orgId,
                            member['user_id'].toString(),
                            role,
                          );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onRemove;
  final ValueChanged<String> onRoleChange;

  const _MemberCard({
    required this.member,
    required this.onRemove,
    required this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? 'Unbekannt';
    final email = member['email'] as String? ?? '';
    final role = member['role'] as String? ?? 'member';
    final position = member['position'] as String?;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: VetTheme.spacingMd, vertical: VetTheme.spacingSm),
        leading: CircleAvatar(
          backgroundColor: VetTheme.primaryContainer,
          child: Text(name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (position != null && position.isNotEmpty)
              Text(position,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: role,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'member', child: Text('Mitarbeiter')),
                DropdownMenuItem(value: 'readonly', child: Text('Nur lesen')),
              ],
              onChanged: (v) {
                if (v != null && v != role) onRoleChange(v);
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.person_remove_outlined,
                  color: VetTheme.secondary),
              tooltip: 'Entfernen',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
