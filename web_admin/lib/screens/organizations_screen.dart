import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AdminOrganizationsScreen extends StatefulWidget {
  const AdminOrganizationsScreen({super.key});

  @override
  State<AdminOrganizationsScreen> createState() =>
      _AdminOrganizationsScreenState();
}

class _AdminOrganizationsScreenState extends State<AdminOrganizationsScreen> {
  final _searchCtrl = TextEditingController();
  String _typeFilter = '';
  List<Map<String, dynamic>> _orgs = [];
  int _total = 0;
  int _page = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    try {
      final api = context.read<ApiService>();
      final q = _searchCtrl.text.trim();
      var url = '/admin/organizations?page=$page&limit=20';
      if (q.isNotEmpty) url += '&search=${Uri.encodeQueryComponent(q)}';
      if (_typeFilter.isNotEmpty) url += '&type=$_typeFilter';

      final data = await api.get(url);
      setState(() {
        _orgs = (data['organizations'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _total = (data['pagination']?['total'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AdminTheme.primary,
        foregroundColor: AdminTheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.dashboard_outlined),
          tooltip: 'Dashboard',
          onPressed: () => context.go('/'),
        ),
        title: const Text('Organisationen'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AdminTheme.spacingMd),
            child: Center(
              child: Text(auth.user?.name ?? '',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AdminTheme.surfaceContainerLowest,
            padding: const EdgeInsets.all(AdminTheme.spacingMd),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Name oder E-Mail suchen...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: AdminTheme.spacingMd),
                DropdownButton<String>(
                  value: _typeFilter.isEmpty ? null : _typeFilter,
                  hint: const Text('Alle Typen'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Alle Typen')),
                    DropdownMenuItem(
                        value: 'vet_practice', child: Text('Tierarztpraxis')),
                    DropdownMenuItem(
                        value: 'service_provider',
                        child: Text('Dienstleister')),
                    DropdownMenuItem(
                        value: 'shelter', child: Text('Tierheim')),
                    DropdownMenuItem(value: 'other', child: Text('Sonstiges')),
                  ],
                  onChanged: (v) {
                    setState(() => _typeFilter = v ?? '');
                    _load();
                  },
                ),
                const SizedBox(width: AdminTheme.spacingSm),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => _load(),
                ),
              ],
            ),
          ),

          // Stats
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AdminTheme.spacingMd,
                  vertical: AdminTheme.spacingSm),
              child: Row(
                children: [
                  Text('$_total Organisation${_total == 1 ? '' : 'en'} gefunden',
                      style: TextStyle(color: AdminTheme.onSurfaceVariant)),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Fehler: $_error',
                                style:
                                    TextStyle(color: AdminTheme.error)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      )
                    : _orgs.isEmpty
                        ? const Center(
                            child: Text('Keine Organisationen gefunden'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(
                                AdminTheme.spacingMd),
                            itemCount: _orgs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (_, i) =>
                                _OrgTile(org: _orgs[i]),
                          ),
          ),

          // Pagination
          if (_total > 20 && !_loading)
            Container(
              color: AdminTheme.surfaceContainerLowest,
              padding: const EdgeInsets.all(AdminTheme.spacingMd),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _page > 1
                        ? () => _load(page: _page - 1)
                        : null,
                  ),
                  Text(
                    'Seite $_page von ${(_total / 20).ceil()}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _page < (_total / 20).ceil()
                        ? () => _load(page: _page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OrgTile extends StatelessWidget {
  final Map<String, dynamic> org;
  const _OrgTile({required this.org});

  @override
  Widget build(BuildContext context) {
    final type = org['type'] as String? ?? '';
    final memberCount = org['member_count'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AdminTheme.primary.withValues(alpha: 0.1),
          child: Icon(
            _typeIcon(type),
            color: AdminTheme.primary,
            size: 20,
          ),
        ),
        title: Text(org['name'] as String? ?? '—',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            _typeLabel(type),
            if ((org['email'] as String? ?? '').isNotEmpty) org['email'] as String,
          ].join(' · '),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TypeChip(type: type),
            const SizedBox(width: 8),
            Text(
              '$memberCount Mitglied${memberCount == 1 ? '' : 'er'}',
              style: const TextStyle(
                  fontSize: 11, color: AdminTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
        'vet_practice' => Icons.medical_services_rounded,
        'service_provider' => Icons.store_rounded,
        'shelter' => Icons.home_rounded,
        _ => Icons.business_rounded,
      };

  String _typeLabel(String type) => switch (type) {
        'vet_practice' => 'Tierarztpraxis',
        'service_provider' => 'Dienstleister',
        'shelter' => 'Tierheim',
        _ => 'Sonstiges',
      };
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      'vet_practice' => ('Tierarzt', const Color(0xFF1565C0)),
      'service_provider' => ('Dienstleister', const Color(0xFF6A1B9A)),
      'shelter' => ('Tierheim', const Color(0xFF2E7D32)),
      _ => ('Sonstiges', AdminTheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminTheme.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
