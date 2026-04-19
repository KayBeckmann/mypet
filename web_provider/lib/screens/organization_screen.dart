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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

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
    final org = orgProvider.organization;

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
                  child: Text(
                    'Mein Betrieb',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (org == null && auth.activeOrganizationId == null)
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Betrieb erstellen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProviderTheme.primary,
                      foregroundColor: ProviderTheme.onPrimary,
                    ),
                  )
                else if (org != null && !_editing)
                  OutlinedButton.icon(
                    onPressed: _startEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Bearbeiten'),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (orgProvider.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (org == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_rounded,
                          size: 64,
                          color: ProviderTheme.onSurfaceVariant
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      const Text('Noch kein Betrieb angelegt.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showCreateDialog(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: ProviderTheme.primary,
                            foregroundColor: ProviderTheme.onPrimary),
                        child: const Text('Betrieb erstellen'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_editing)
              Expanded(
                child: SingleChildScrollView(
                  child: _EditForm(
                    formKey: _formKey,
                    nameCtrl: _nameCtrl,
                    descCtrl: _descCtrl,
                    websiteCtrl: _websiteCtrl,
                    phoneCtrl: _phoneCtrl,
                    addressCtrl: _addressCtrl,
                    saving: _saving,
                    onCancel: () => setState(() => _editing = false),
                    onSave: () => _save(context, org['id'] as String),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: _OrgCard(org: org),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startEdit() {
    final org = context.read<ProviderOrganizationProvider>().organization;
    if (org == null) return;
    _nameCtrl.text = org['name'] as String? ?? '';
    _descCtrl.text = org['description'] as String? ?? '';
    _websiteCtrl.text = org['website'] as String? ?? '';
    _phoneCtrl.text = org['phone'] as String? ?? '';
    _addressCtrl.text = org['address'] as String? ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save(BuildContext context, String orgId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<ProviderOrganizationProvider>().update(
      orgId,
      {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'website':
            _websiteCtrl.text.trim().isEmpty ? null : _websiteCtrl.text.trim(),
        'phone':
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'address':
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      },
    );
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Betrieb erstellen'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              child: const Text('Erstellen')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      if (nameCtrl.text.trim().isEmpty) return;
      await context.read<ProviderOrganizationProvider>().createOrganization(
            name: nameCtrl.text.trim(),
            description: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
    }
  }
}

class _OrgCard extends StatelessWidget {
  final Map<String, dynamic> org;
  const _OrgCard({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ProviderTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: ProviderTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.store_rounded,
                    color: ProviderTheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org['name'] as String? ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (org['description'] != null)
                      Text(
                        org['description'] as String,
                        style: TextStyle(
                            color: ProviderTheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (org['website'] != null)
            _InfoRow(icon: Icons.language_rounded, text: org['website'] as String),
          if (org['phone'] != null)
            _InfoRow(icon: Icons.phone_rounded, text: org['phone'] as String),
          if (org['address'] != null)
            _InfoRow(
                icon: Icons.location_on_rounded,
                text: org['address'] as String),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ProviderTheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController addressCtrl;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _EditForm({
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.websiteCtrl,
    required this.phoneCtrl,
    required this.addressCtrl,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Name', border: OutlineInputBorder()),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descCtrl,
            decoration: const InputDecoration(
                labelText: 'Beschreibung', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: websiteCtrl,
            decoration: const InputDecoration(
                labelText: 'Website', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            decoration: const InputDecoration(
                labelText: 'Telefon', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressCtrl,
            decoration: const InputDecoration(
                labelText: 'Adresse', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Abbrechen')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                    backgroundColor: ProviderTheme.primary,
                    foregroundColor: ProviderTheme.onPrimary),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Speichern'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
