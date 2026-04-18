import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<VetAuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPet Vet'),
        backgroundColor: VetTheme.primary,
        foregroundColor: VetTheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(VetTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Willkommen, ${auth.user?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: VetTheme.spacingSm),
            Text(
              auth.organizations.isEmpty
                  ? 'Keine Praxis verbunden. Lege eine Organisation an, um loszulegen.'
                  : 'Aktive Praxis: '
                      '${_activeOrgName(auth) ?? '–'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: VetTheme.spacingLg),
            if (auth.organizations.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Praxis anlegen'),
                  onPressed: () => _showCreateOrganizationDialog(context),
                ),
              )
            else
              _OrganizationSwitcher(auth: auth),
            const SizedBox(height: VetTheme.spacingXl),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(VetTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nächste Schritte',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: VetTheme.spacingMd),
                      const _TodoItem(text: 'Patient:innen-Liste anzeigen'),
                      const _TodoItem(text: 'Termin-Kalender integrieren'),
                      const _TodoItem(text: 'Behandlungen dokumentieren'),
                      const _TodoItem(text: 'Rezepte ausstellen'),
                      const _TodoItem(text: 'Team verwalten'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _activeOrgName(VetAuthProvider auth) {
    final id = auth.activeOrganizationId;
    if (id == null) return null;
    final org = auth.organizations.firstWhere(
      (o) => o['id'] == id,
      orElse: () => const {},
    );
    return org['name'] as String?;
  }

  Future<void> _showCreateOrganizationDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final auth = context.read<VetAuthProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Neue Tierarzt-Praxis'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name der Praxis'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final ok = await auth.createOrganization(
                name: name,
                type: 'vet_practice',
              );
              if (ok && dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
  }
}

class _OrganizationSwitcher extends StatelessWidget {
  final VetAuthProvider auth;
  const _OrganizationSwitcher({required this.auth});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: auth.activeOrganizationId,
      decoration: const InputDecoration(labelText: 'Aktive Praxis'),
      items: auth.organizations
          .map((org) => DropdownMenuItem(
                value: org['id'] as String,
                child: Text(org['name'] as String),
              ))
          .toList(),
      onChanged: (id) {
        if (id != null) auth.switchOrganization(id);
      },
    );
  }
}

class _TodoItem extends StatelessWidget {
  final String text;
  const _TodoItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VetTheme.spacingSm),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, size: 18),
          const SizedBox(width: VetTheme.spacingMd),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
