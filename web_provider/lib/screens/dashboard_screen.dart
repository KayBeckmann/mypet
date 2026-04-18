import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProviderAuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPet Provider'),
        backgroundColor: ProviderTheme.primary,
        foregroundColor: ProviderTheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: auth.logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(ProviderTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Willkommen, ${auth.user?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: ProviderTheme.spacingSm),
            Text(
              auth.organizations.isEmpty
                  ? 'Noch keine Organisation. Lege einen Shop, eine Kette, ein Makler-Büro oder einen Züchter-Betrieb an.'
                  : 'Aktive Organisation: ${_activeOrgName(auth) ?? '–'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: ProviderTheme.spacingLg),
            if (auth.organizations.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Organisation anlegen'),
                  onPressed: () => _showCreateOrganizationDialog(context),
                ),
              )
            else
              _OrganizationSwitcher(auth: auth),
            const SizedBox(height: ProviderTheme.spacingXl),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(ProviderTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nächste Schritte',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: ProviderTheme.spacingMd),
                      const _TodoItem(text: 'Produkte und Dienstleistungen pflegen'),
                      const _TodoItem(text: 'Bestellungen empfangen'),
                      const _TodoItem(text: 'Tiere (Züchter) verwalten'),
                      const _TodoItem(text: 'Vermittlungen dokumentieren'),
                      const _TodoItem(text: 'Team einladen'),
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

  String? _activeOrgName(ProviderAuthProvider auth) {
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
    String type = 'shop';
    final auth = context.read<ProviderAuthProvider>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderCtx, setState) => AlertDialog(
          title: const Text('Neue Organisation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: ProviderTheme.spacingMd),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Art'),
                items: const [
                  DropdownMenuItem(value: 'shop', child: Text('Shop / Einzelhandel')),
                  DropdownMenuItem(value: 'chain', child: Text('Kette')),
                  DropdownMenuItem(value: 'breeder', child: Text('Züchter')),
                  DropdownMenuItem(value: 'broker', child: Text('Makler')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'shop'),
              ),
            ],
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
                  type: type,
                );
                if (ok && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizationSwitcher extends StatelessWidget {
  final ProviderAuthProvider auth;
  const _OrganizationSwitcher({required this.auth});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: auth.activeOrganizationId,
      decoration: const InputDecoration(labelText: 'Aktive Organisation'),
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
      padding: const EdgeInsets.symmetric(vertical: ProviderTheme.spacingSm),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, size: 18),
          const SizedBox(width: ProviderTheme.spacingMd),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
