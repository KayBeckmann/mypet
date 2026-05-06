import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/patients_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _expiringVaccinations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VetAppointmentProvider>().load();
      context.read<PatientsProvider>().loadPatients();
      _loadExpiringVaccinations();
    });
  }

  Future<void> _loadExpiringVaccinations() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/vaccinations/expiring?days=30');
      if (mounted) {
        setState(() {
          _expiringVaccinations = (data['vaccinations'] as List? ?? [])
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<VetAuthProvider>();
    final apptProvider = context.watch<VetAppointmentProvider>();
    final patientsProvider = context.watch<PatientsProvider>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final todayAppts = apptProvider.appointments.where((a) {
      final d = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
      return d == today;
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final upcomingAppts = apptProvider.appointments.where((a) {
      return a.scheduledAt.isAfter(now) &&
          (a.status == AppointmentStatus.confirmed ||
              a.status == AppointmentStatus.requested);
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final pendingCount = apptProvider.pending.length;
    final confirmedCount = apptProvider.confirmed.length;
    final patientCount = patientsProvider.patients.length;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VetTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Willkommen, ${auth.user?.name ?? ''}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: VetTheme.spacingSm),
            Text(
              auth.organizations.isEmpty
                  ? 'Keine Praxis verbunden.'
                  : 'Aktive Praxis: ${_activeOrgName(auth) ?? '–'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (auth.organizations.isEmpty) ...[
              const SizedBox(height: VetTheme.spacingMd),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Praxis anlegen'),
                  onPressed: () => _showCreateOrganizationDialog(context),
                ),
              ),
            ] else ...[
              const SizedBox(height: VetTheme.spacingMd),
              _OrganizationSwitcher(auth: auth),
            ],
            const SizedBox(height: VetTheme.spacingXl),

            // Stats row
            _StatsRow(
              patientCount: patientCount,
              todayCount: todayAppts.length,
              pendingCount: pendingCount,
              confirmedCount: confirmedCount,
              loading: apptProvider.loading || patientsProvider.isLoading,
            ),
            const SizedBox(height: VetTheme.spacingXl),

            // Two-column layout: today's appointments + upcoming
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 800) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TodayAppointments(appointments: todayAppts),
                      ),
                      const SizedBox(width: VetTheme.spacingLg),
                      Expanded(
                        child: _UpcomingAppointments(
                          appointments: upcomingAppts.take(5).toList(),
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _TodayAppointments(appointments: todayAppts),
                    const SizedBox(height: VetTheme.spacingLg),
                    _UpcomingAppointments(
                      appointments: upcomingAppts.take(5).toList(),
                    ),
                  ],
                );
              },
            ),

            if (_expiringVaccinations.isNotEmpty) ...[
              const SizedBox(height: VetTheme.spacingXl),
              _ExpiringVaccinationsPanel(vaccinations: _expiringVaccinations),
            ],

            // Recently seen patients
            Builder(builder: (context) {
              final recentPets = <String, Map<String, dynamic>>{};
              for (final a in apptProvider.past) {
                if (a.petId.isNotEmpty && !recentPets.containsKey(a.petId)) {
                  recentPets[a.petId] = {
                    'id': a.petId,
                    'name': a.petName ?? '—',
                    'owner': a.ownerName ?? '—',
                    'date': a.scheduledAt,
                  };
                }
                if (recentPets.length >= 5) break;
              }
              if (recentPets.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: VetTheme.spacingXl),
                  Text('Zuletzt gesehen',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: recentPets.values.map((p) {
                      final d = p['date'] as DateTime;
                      return ActionChip(
                        avatar: const Icon(Icons.pets_rounded, size: 16),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${p['owner']} · ${d.day}.${d.month}.${d.year}',
                                style: TextStyle(fontSize: 11, color: VetTheme.onSurfaceVariant)),
                          ],
                        ),
                        onPressed: () => context.go('/patients/${p['id']}'),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
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

class _StatsRow extends StatelessWidget {
  final int patientCount;
  final int todayCount;
  final int pendingCount;
  final int confirmedCount;
  final bool loading;

  const _StatsRow({
    required this.patientCount,
    required this.todayCount,
    required this.pendingCount,
    required this.confirmedCount,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VetTheme.spacingMd,
      runSpacing: VetTheme.spacingMd,
      children: [
        _StatCard(
          icon: Icons.pets,
          label: 'Patient:innen',
          value: loading ? '…' : '$patientCount',
          color: VetTheme.primary,
        ),
        _StatCard(
          icon: Icons.today,
          label: 'Heute',
          value: loading ? '…' : '$todayCount',
          color: Colors.blue,
        ),
        _StatCard(
          icon: Icons.pending_actions,
          label: 'Ausstehend',
          value: loading ? '…' : '$pendingCount',
          color: Colors.orange,
        ),
        _StatCard(
          icon: Icons.check_circle_outline,
          label: 'Bestätigt',
          value: loading ? '…' : '$confirmedCount',
          color: Colors.green,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(VetTheme.spacingLg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: VetTheme.spacingSm),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _TodayAppointments extends StatelessWidget {
  final List<VetAppointment> appointments;
  const _TodayAppointments({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VetTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.today, size: 20),
                const SizedBox(width: VetTheme.spacingSm),
                Text(
                  'Termine heute',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${appointments.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: VetTheme.spacingLg),
            if (appointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: VetTheme.spacingMd),
                child: Text(
                  'Keine Termine heute',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              )
            else
              ...appointments.map((a) => _AppointmentRow(appointment: a)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingAppointments extends StatelessWidget {
  final List<VetAppointment> appointments;
  const _UpcomingAppointments({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VetTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, size: 20),
                const SizedBox(width: VetTheme.spacingSm),
                Text(
                  'Nächste Termine',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: VetTheme.spacingLg),
            if (appointments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: VetTheme.spacingMd),
                child: Text(
                  'Keine anstehenden Termine',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
              )
            else
              ...appointments.map((a) => _AppointmentRow(appointment: a, showDate: true)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final VetAppointment appointment;
  final bool showDate;

  const _AppointmentRow({required this.appointment, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (appointment.status) {
      AppointmentStatus.confirmed => Colors.green,
      AppointmentStatus.requested => Colors.orange,
      AppointmentStatus.completed => Colors.grey,
      AppointmentStatus.cancelled => Colors.red,
      AppointmentStatus.noShow => Colors.red,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VetTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: VetTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${appointment.petName ?? '–'} • ${appointment.ownerName ?? '–'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                showDate
                    ? '${appointment.dateLabel}, ${appointment.timeLabel}'
                    : appointment.timeLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: statusColor),
                ),
              ),
            ],
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

class _ExpiringVaccinationsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;

  const _ExpiringVaccinationsPanel({required this.vaccinations});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');

    return Container(
      padding: const EdgeInsets.all(VetTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(VetTheme.radiusLg),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vaccines_rounded,
                  color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Ablaufende Impfungen (nächste 30 Tage)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...vaccinations.map((v) {
            final validUntil = v['valid_until'] as String?;
            DateTime? date;
            if (validUntil != null) date = DateTime.tryParse(validUntil);
            final daysLeft = date != null
                ? date.difference(DateTime.now()).inDays
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => context.go('/patients/${v['pet_id']}'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        v['pet_name'] as String? ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          v['vaccine_name'] as String? ?? '—',
                          style: const TextStyle(
                              color: VetTheme.onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ),
                      if (date != null) ...[
                        Text(
                          fmt.format(date),
                          style: TextStyle(
                              fontSize: 12,
                              color: daysLeft != null && daysLeft <= 7
                                  ? VetTheme.error
                                  : Colors.amber.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($daysLeft T)',
                          style: TextStyle(
                              fontSize: 11,
                              color: daysLeft != null && daysLeft <= 7
                                  ? VetTheme.error
                                  : Colors.amber.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
