import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/appointment_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();
    final pets = context.watch<MobilePetProvider>().pets;
    final overdue = context.watch<MobileReminderProvider>().overdue;
    final upcoming = context.watch<MobileAppointmentProvider>().upcoming;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<MobilePetProvider>().load();
              context.read<MobileReminderProvider>().load();
              context.read<MobileAppointmentProvider>().load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<MobilePetProvider>().load(),
            context.read<MobileReminderProvider>().load(),
            context.read<MobileAppointmentProvider>().load(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting
            Text(
              '$greeting, ${auth.user?.name ?? 'Tierfreund'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${pets.length} Tier${pets.length == 1 ? '' : 'e'} registriert',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatChip(
                    icon: Icons.pets_rounded,
                    label: 'Tiere',
                    value: '${pets.length}',
                    color: cs.primary),
                const SizedBox(width: 12),
                _StatChip(
                    icon: Icons.alarm_rounded,
                    label: 'Überfällig',
                    value: '${overdue.length}',
                    color: overdue.isNotEmpty ? cs.error : cs.primary),
                const SizedBox(width: 12),
                _StatChip(
                    icon: Icons.calendar_month_rounded,
                    label: 'Termine',
                    value: '${upcoming.length}',
                    color: cs.secondary),
              ],
            ),
            const SizedBox(height: 24),

            // Overdue reminders alert
            if (overdue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm_rounded, color: cs.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${overdue.length} überfällige Erinnerung${overdue.length == 1 ? '' : 'en'}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: cs.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upcoming appointments
            if (upcoming.isNotEmpty) ...[
              Text('Nächste Termine',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...upcoming.take(3).map((a) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.secondaryContainer,
                        child: Icon(Icons.calendar_today_rounded,
                            color: cs.secondary, size: 20),
                      ),
                      title: Text(a.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(a.dateTimeLabel),
                      trailing: _ApptStatusChip(status: a.status),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Pets overview
            if (pets.isNotEmpty) ...[
              Text('Meine Tiere',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...pets.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Text(p.speciesEmoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${p.speciesLabel}${p.breed.isNotEmpty ? ' · ${p.breed}' : ''}'
                          '${p.ageYears != null ? ' · ${p.ageYears} J.' : ''}'),
                      trailing: p.weightKg != null
                          ? Text('${p.weightKg!.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant, fontSize: 13))
                          : null,
                    ),
                  )),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.pets_outlined,
                          size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Noch keine Tiere',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 18)),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }
}

class _ApptStatusChip extends StatelessWidget {
  final MobileApptStatus status;
  const _ApptStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      MobileApptStatus.confirmed => ('Bestätigt', cs.secondary),
      MobileApptStatus.requested => ('Angefragt', cs.tertiary),
      _ => ('', Colors.grey),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
