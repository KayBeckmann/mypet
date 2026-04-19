import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().load();
      context.read<ProviderAppointmentProvider>().load();
    });
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
            const SizedBox(height: 32),

            // Summary cards
            Row(
              children: [
                _SummaryCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Offene Anfragen',
                  value: '${appointmentProvider.pending.length}',
                  color: Colors.orange,
                ),
                const SizedBox(width: 16),
                _SummaryCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Bestätigte Termine',
                  value: '${appointmentProvider.confirmed.length}',
                  color: ProviderTheme.secondary,
                ),
                const SizedBox(width: 16),
                _SummaryCard(
                  icon: Icons.pets_rounded,
                  label: 'Kunden (Tiere)',
                  value: '${customersProvider.pets.length}',
                  color: ProviderTheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 32),

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
