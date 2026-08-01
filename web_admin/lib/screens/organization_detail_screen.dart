import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final String orgId;
  const OrganizationDetailScreen({super.key, required this.orgId});

  @override
  State<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  Map<String, dynamic>? _org;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/admin/organizations/${widget.orgId}');
      setState(() {
        _org = data['organization'] as Map<String, dynamic>?;
        _isLoading = false;
        if (_org == null) _error = 'Organisation nicht gefunden';
      });
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleActive() async {
    final current = _org?['is_active'] as bool? ?? false;
    try {
      final api = context.read<ApiService>();
      await api.put('/admin/organizations/${widget.orgId}',
          body: {'is_active': !current});
      if (!mounted) return;
      setState(() => _org = {..._org!, 'is_active': !current});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              current ? 'Organisation deaktiviert' : 'Organisation reaktiviert'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _confirmDeactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Organisation deaktivieren'),
        content: const Text(
            'Mitglieder dieser Organisation verlieren den Zugriff auf ihre Praxis-/Firmen-Funktionen. Fortfahren?'),
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
        title: Text(_org?['name'] as String? ?? 'Organisation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/organizations'),
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
    final org = _org!;
    final isActive = org['is_active'] as bool? ?? false;
    final type = org['type'] as String? ?? '';
    final members = (org['members'] as List? ?? []).cast<Map<String, dynamic>>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                        child: Icon(
                          _typeIcon(type),
                          color: isActive
                              ? AdminTheme.onPrimary
                              : AdminTheme.outline,
                        ),
                      ),
                      const SizedBox(width: AdminTheme.spacingLg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org['name'] as String? ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AdminTheme.spacingXs),
                            Text(_typeLabel(type)),
                            if ((org['email'] as String? ?? '').isNotEmpty)
                              Text(org['email'] as String,
                                  style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: AdminTheme.spacingSm),
                            if (!isActive)
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
                                      fontSize: 12, color: AdminTheme.outline),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AdminTheme.spacingMd),

              // Mitglieder
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminTheme.spacingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mitglieder (${members.length})',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminTheme.spacingMd),
                      if (members.isEmpty)
                        const Text('Keine Mitglieder')
                      else
                        ...members.map((m) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(m['name'] as String? ?? '—',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(m['email'] as String? ?? '',
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AdminTheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          AdminTheme.radiusFull),
                                    ),
                                    child: Text(
                                      m['role'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AdminTheme.primary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            )),
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
                      if (isActive)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.secondary,
                            foregroundColor: AdminTheme.onSecondary,
                          ),
                          onPressed: _confirmDeactivate,
                          icon: const Icon(Icons.block),
                          label: const Text('Organisation deaktivieren'),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.success,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _toggleActive,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Organisation reaktivieren'),
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
