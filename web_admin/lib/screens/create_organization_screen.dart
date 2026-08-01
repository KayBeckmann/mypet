import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

/// Legt eine Organisation (Praxis/Firma) an und weist sie einem
/// bestehenden Tierarzt-/Dienstleister-Benutzer als Admin zu.
///
/// Der Benutzer muss vorher über "Benutzer anlegen" existieren — hier wird
/// nur aus den passenden, noch keiner Organisation zugehörigen Konten
/// ausgewählt.
class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _type = 'vet_practice';
  String? _selectedUserId;
  List<Map<String, dynamic>> _eligibleUsers = [];
  bool _loadingUsers = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEligibleUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String get _role => _type == 'vet_practice' ? 'vet' : 'provider';

  Future<void> _loadEligibleUsers() async {
    setState(() {
      _loadingUsers = true;
      _selectedUserId = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/admin/users?role=$_role&limit=100');
      final users = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
      setState(() {
        _eligibleUsers = users;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Benutzer konnten nicht geladen werden: $e';
        _loadingUsers = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserId == null) {
      setState(() => _error = 'Bitte einen Benutzer auswählen');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      await api.post('/admin/organizations', body: {
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'admin_user_id': _selectedUserId,
      });
      if (!mounted) return;
      context.go('/organizations');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation angelegt')),
      );
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        title: const Text('Organisation anlegen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizations'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AdminTheme.spacingLg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Typ',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AdminTheme.spacingSm),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'vet_practice',
                        label: Text('Tierarztpraxis'),
                        icon: Icon(Icons.medical_services_rounded),
                      ),
                      ButtonSegment(
                        value: 'provider_company',
                        label: Text('Dienstleister'),
                        icon: Icon(Icons.store_rounded),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) {
                      setState(() => _type = s.first);
                      _loadEligibleUsers();
                    },
                  ),
                  const SizedBox(height: AdminTheme.spacingLg),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                  ),
                  const SizedBox(height: AdminTheme.spacingLg),
                  Text(
                    _type == 'vet_practice'
                        ? 'Admin-Benutzer (Rolle: Tierarzt)'
                        : 'Admin-Benutzer (Rolle: Dienstleister)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AdminTheme.spacingSm),
                  if (_loadingUsers)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_eligibleUsers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AdminTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AdminTheme.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(AdminTheme.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _type == 'vet_practice'
                                ? 'Kein freier Tierarzt-Benutzer verfügbar.'
                                : 'Kein freier Dienstleister-Benutzer verfügbar.',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Entweder gibt es noch keinen Benutzer mit '
                            'dieser Rolle, oder alle sind bereits einer '
                            'Organisation zugeordnet. Erst unter '
                            '"Benutzer anlegen" einen neuen Account mit '
                            'passender Rolle erstellen.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AdminTheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AdminTheme.spacingSm),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/users/create'),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Benutzer anlegen'),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUserId,
                      decoration: const InputDecoration(
                          labelText: 'Benutzer auswählen'),
                      items: _eligibleUsers
                          .map((u) => DropdownMenuItem(
                                value: u['id'] as String,
                                child: Text(
                                    '${u['name']} (${u['email']})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUserId = v),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: AdminTheme.spacingMd),
                    Text(_error!,
                        style: const TextStyle(color: AdminTheme.error)),
                  ],
                  const SizedBox(height: AdminTheme.spacingXl),
                  FilledButton.icon(
                    onPressed: (_saving || _eligibleUsers.isEmpty)
                        ? null
                        : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                        _saving ? 'Wird gespeichert…' : 'Organisation anlegen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
