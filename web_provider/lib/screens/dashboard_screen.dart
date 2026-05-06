import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/customers_provider.dart';

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
      context.read<CustomersProvider>().load();
      context.read<ProviderAppointmentProvider>().load();
      _loadExpiringVaccinations();
    });
  }

  Future<void> _loadExpiringVaccinations() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/vaccinations/expiring?days=30');
      if (mounted) {
        setState(() {
          _expiringVaccinations =
              (data['vaccinations'] as List? ?? []).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ProviderAuthProvider>();
    final appointmentProvider = context.watch<ProviderAppointmentProvider>();
    final customersProvider = context.watch<CustomersProvider>();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Guten Morgen'
        : hour < 18
            ? 'Guten Tag'
            : 'Guten Abend';

    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, ${auth.user?.name ?? 'Dienstleister'}!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              'Hier ist eine Übersicht Ihrer aktuellen Aktivitäten.',
              style: TextStyle(color: ProviderTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            if (auth.activeOrganizationId == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Kein Betrieb verbunden. Lege einen Betrieb an oder '
                        'nimm eine Einladung an, um Kunden zu verwalten.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/organization'),
                      child: const Text('Zum Betrieb'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // Summary cards
            Builder(builder: (context) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final thisMonth = appointmentProvider.past
                  .where((a) =>
                      a.status == ProviderAppointmentStatus.completed &&
                      a.scheduledAt.year == now.year &&
                      a.scheduledAt.month == now.month)
                  .toList();

              final todayAppts = appointmentProvider.appointments
                  .where((a) {
                    final d = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
                    return d == today;
                  })
                  .length;

              final revenueCents = thisMonth
                  .where((a) => a.serviceFeeCents != null)
                  .fold(0, (sum, a) => sum + a.serviceFeeCents!);
              final revenueFormatted = revenueCents > 0
                  ? '${(revenueCents / 100).toStringAsFixed(2).replaceAll('.', ',')} €'
                  : '–';
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SummaryCard(
                    icon: Icons.today_rounded,
                    label: 'Heute',
                    value: '$todayAppts',
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Offene Anfragen',
                    value: '${appointmentProvider.pending.length}',
                    color: Colors.orange,
                  ),
                  _SummaryCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'Bestätigt',
                    value: '${appointmentProvider.confirmed.length}',
                    color: ProviderTheme.secondary,
                  ),
                  _SummaryCard(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Abgeschl. (Monat)',
                    value: '${thisMonth.length}',
                    color: Colors.teal,
                  ),
                  _SummaryCard(
                    icon: Icons.pets_rounded,
                    label: 'Kunden',
                    value: '${customersProvider.pets.length}',
                    color: ProviderTheme.primary,
                  ),
                  _SummaryCard(
                    icon: Icons.euro_rounded,
                    label: 'Umsatz (Monat)',
                    value: revenueFormatted,
                    color: Colors.green.shade700,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),

            if (_expiringVaccinations.isNotEmpty) ...[
              _ExpiringVaccinationsPanel(
                  vaccinations: _expiringVaccinations),
              const SizedBox(height: 24),
            ],

            // Today's agenda
            Builder(builder: (context) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final todayList = appointmentProvider.appointments
                  .where((a) {
                    final d = DateTime(a.scheduledAt.year, a.scheduledAt.month, a.scheduledAt.day);
                    return d == today;
                  })
                  .toList()
                ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

              if (todayList.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tages-Agenda (${todayList.length})',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: ProviderTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: ProviderTheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: todayList.asMap().entries.map((entry) {
                        final i = entry.key;
                        final a = entry.value;
                        final isPast = a.scheduledAt.isBefore(now);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isPast
                                ? ProviderTheme.onSurfaceVariant.withValues(alpha: 0.04)
                                : null,
                            border: i > 0
                                ? Border(
                                    top: BorderSide(
                                        color: ProviderTheme.outline
                                            .withValues(alpha: 0.15)))
                                : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  a.timeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isPast
                                        ? ProviderTheme.onSurfaceVariant
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isPast
                                            ? ProviderTheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                    if (a.petName != null || a.ownerName != null)
                                      Text(
                                        [
                                          if (a.petName != null) a.petName,
                                          if (a.ownerName != null)
                                            '(${a.ownerName})',
                                        ].join(' '),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: ProviderTheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: a.status ==
                                          ProviderAppointmentStatus.completed
                                      ? ProviderTheme.primary.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  a.statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: a.status ==
                                            ProviderAppointmentStatus.completed
                                        ? ProviderTheme.primary
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),

            // Upcoming appointments
            Text(
              'Nächste Termine',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (appointmentProvider.confirmed.isEmpty &&
                appointmentProvider.pending.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ProviderTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Keine anstehenden Termine',
                    style: TextStyle(color: ProviderTheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...([
                ...appointmentProvider.confirmed,
                ...appointmentProvider.pending,
              ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)))
                  .take(5)
                  .map((a) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: ProviderTheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: a.status ==
                                      ProviderAppointmentStatus.confirmed
                                  ? ProviderTheme.secondary
                                  : Colors.orange,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.timeLabel,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  Text(
                                    '${a.scheduledAt.day}.${a.scheduledAt.month}.',
                                    style: TextStyle(
                                        color: ProviderTheme.onSurfaceVariant,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (a.petName != null)
                                    Text(a.petName!,
                                        style: TextStyle(
                                            color:
                                                ProviderTheme.onSurfaceVariant,
                                            fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (a.status ==
                                            ProviderAppointmentStatus.confirmed
                                        ? ProviderTheme.secondary
                                        : Colors.orange)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(a.statusLabel,
                                  style: TextStyle(
                                    color: a.status ==
                                            ProviderAppointmentStatus.confirmed
                                        ? ProviderTheme.secondary
                                        : Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ],
                        ),
                      )),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ProviderTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ProviderTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                  Text(label,
                      style: TextStyle(
                          color: ProviderTheme.onSurfaceVariant,
                          fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vaccines_rounded, color: Colors.amber, size: 18),
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
                onTap: () => context.go('/customers/${v['pet_id']}'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        v['pet_name'] as String? ?? '—',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          v['vaccine_name'] as String? ?? '—',
                          style: const TextStyle(
                              color: ProviderTheme.onSurfaceVariant,
                              fontSize: 13),
                        ),
                      ),
                      if (date != null) ...[  
                        Text(
                          fmt.format(date),
                          style: TextStyle(
                              fontSize: 12,
                              color: daysLeft != null && daysLeft <= 7
                                  ? ProviderTheme.error
                                  : Colors.amber.shade700,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($daysLeft T)',
                          style: TextStyle(
                              fontSize: 11,
                              color: daysLeft != null && daysLeft <= 7
                                  ? ProviderTheme.error
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
