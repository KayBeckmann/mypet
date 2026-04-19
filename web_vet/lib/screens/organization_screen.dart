import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/organization_provider.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _hoursCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _specCtrl = TextEditingController();
    _hoursCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final orgProvider = context.read<OrganizationProvider>();
    final auth = context.read<VetAuthProvider>();

    if (orgProvider.organizations.isEmpty) {
      orgProvider.loadOrganizations();
    } else {
      _populateFields(orgProvider.activeOrg);
    }

    orgProvider.addListener(_onOrgChanged);
  }

  void _onOrgChanged() {
    if (mounted) _populateFields(context.read<OrganizationProvider>().activeOrg);
  }

  void _populateFields(Map<String, dynamic>? org) {
    if (org == null) return;
    _nameCtrl.text = org['name'] as String? ?? '';
    _descCtrl.text = org['description'] as String? ?? '';
    _addressCtrl.text = org['address'] as String? ?? '';
    _phoneCtrl.text = org['phone'] as String? ?? '';
    _emailCtrl.text = org['email'] as String? ?? '';
    _websiteCtrl.text = org['website'] as String? ?? '';
    _specCtrl.text = org['specialization'] as String? ?? '';
    _hoursCtrl.text = org['opening_hours'] as String? ?? '';
  }

  @override
  void dispose() {
    context.read<OrganizationProvider>().removeListener(_onOrgChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _specCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final orgProvider = context.read<OrganizationProvider>();
    final org = orgProvider.activeOrg;
    if (org == null) return;

    final ok = await orgProvider.updateOrganization(org['id'] as String, {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'specialization': _specCtrl.text.trim(),
      'opening_hours': _hoursCtrl.text.trim(),
    });

    if (ok && mounted) {
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Praxis-Profil gespeichert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = context.watch<OrganizationProvider>();
    final auth = context.watch<VetAuthProvider>();
    final org = orgProvider.activeOrg;

    if (orgProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (auth.organizations.isEmpty) {
      return _NoOrgView(
        onCreate: () => _showCreateDialog(context, auth),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VetTheme.spacingLg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Org-Selektor (falls mehrere)
              if (auth.organizations.length > 1)
                DropdownButtonFormField<String>(
                  value: auth.activeOrganizationId,
                  decoration: const InputDecoration(labelText: 'Aktive Praxis'),
                  items: auth.organizations
                      .map((o) => DropdownMenuItem(
                            value: o['id'] as String,
                            child: Text(o['name'] as String),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      auth.switchOrganization(id);
                      orgProvider.selectOrganization(id);
                    }
                  },
                ),
              if (auth.organizations.length > 1) const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Praxis-Profil',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (!_editing)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _editing = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Bearbeiten'),
                    )
                  else
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() => _editing = false);
                            _populateFields(org);
                          },
                          child: const Text('Abbrechen'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Speichern'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),

              if (orgProvider.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VetTheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(VetTheme.radiusMd),
                  ),
                  child: Text(orgProvider.error!,
                      style: const TextStyle(color: VetTheme.secondary)),
                ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(VetTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Field('Name der Praxis', _nameCtrl, enabled: _editing),
                      _Field('Spezialisierung', _specCtrl, enabled: _editing),
                      _Field('Beschreibung', _descCtrl,
                          enabled: _editing, maxLines: 3),
                      const Divider(height: 32),
                      _Field('Adresse', _addressCtrl,
                          enabled: _editing, maxLines: 2),
                      _Field('Telefon', _phoneCtrl, enabled: _editing),
                      _Field('E-Mail', _emailCtrl, enabled: _editing),
                      _Field('Website', _websiteCtrl, enabled: _editing),
                      const Divider(height: 32),
                      _Field('Öffnungszeiten', _hoursCtrl,
                          enabled: _editing, maxLines: 3),
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

  Future<void> _showCreateDialog(
      BuildContext context, VetAuthProvider auth) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Tierarzt-Praxis anlegen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name der Praxis'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final ok = await auth.createOrganization(
                  name: name, type: 'vet_practice');
              if (ok && ctx.mounted) {
                Navigator.pop(ctx);
                context.read<OrganizationProvider>().loadOrganizations();
              }
            },
            child: const Text('Anlegen'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final int maxLines;

  const _Field(this.label, this.controller,
      {this.enabled = false, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VetTheme.spacingMd),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _NoOrgView extends StatelessWidget {
  final VoidCallback onCreate;
  const _NoOrgView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VetTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_business_outlined,
                size: 72, color: VetTheme.primary),
            const SizedBox(height: VetTheme.spacingMd),
            Text('Noch keine Praxis',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: VetTheme.spacingSm),
            Text(
              'Lege deine Praxis oder Organisation an, um loszulegen.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: VetTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VetTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Praxis anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
