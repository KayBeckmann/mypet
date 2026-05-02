import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/admin/stats');
      final raw = data['stats'] as Map<String, dynamic>;
      setState(() {
        _stats = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
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
      backgroundColor: AdminTheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Superadmin Dashboard',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          'Eingeloggt als ${auth.user?.email ?? '—'}',
                          style: TextStyle(
                              color: AdminTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadStats,
                    tooltip: 'Aktualisieren',
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _ErrorCard(message: _error!, onRetry: _loadStats)
              else if (_stats != null) ...[
                // Stats grid
                _StatsGrid(stats: _stats!),
                const SizedBox(height: 32),

                // Quick actions
                Text('Schnellzugriff',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickAction(
                      icon: Icons.group_outlined,
                      label: 'Benutzer verwalten',
                      onTap: () => context.go('/users'),
                    ),
                    _QuickAction(
                      icon: Icons.person_add_outlined,
                      label: 'Benutzer anlegen',
                      onTap: () => context.go('/users/create'),
                    ),
                    _QuickAction(
                      icon: Icons.business_outlined,
                      label: 'Organisationen',
                      onTap: () => context.go('/organizations'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatDef('Benutzer gesamt', stats['users_total'] ?? 0,
          Icons.people_rounded, AdminTheme.primary),
      _StatDef('Besitzer', stats['users_owner'] ?? 0,
          Icons.person_rounded, const Color(0xFF1565C0)),
      _StatDef('Tierärzte', stats['users_vet'] ?? 0,
          Icons.medical_services_rounded, const Color(0xFF2E7D32)),
      _StatDef('Dienstleister', stats['users_provider'] ?? 0,
          Icons.store_rounded, const Color(0xFF6A1B9A)),
      _StatDef('Tiere', stats['pets_total'] ?? 0,
          Icons.pets_rounded, const Color(0xFFE65100)),
      _StatDef('Organisationen', stats['organizations_total'] ?? 0,
          Icons.business_rounded, const Color(0xFF00695C)),
      _StatDef('Neue Nutzer (7T)', stats['new_users_7d'] ?? 0,
          Icons.person_add_rounded, const Color(0xFF1565C0)),
      _StatDef('Neue Tiere (7T)', stats['new_pets_7d'] ?? 0,
          Icons.add_circle_rounded, const Color(0xFFE65100)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 700
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) => _StatCard(def: cards[i]),
        );
      },
    );
  }
}

class _StatDef {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatDef(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatDef def;
  const _StatCard({required this.def});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: def.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(def.icon, color: def.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${def.value}',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: def.color),
                ),
                Text(
                  def.label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AdminTheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AdminTheme.error, size: 40),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(color: AdminTheme.error), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Erneut versuchen'),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
