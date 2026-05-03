import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MobileAppointmentProvider>();
    final appointments = provider.appointments
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final upcoming = appointments
        .where((a) =>
            a.scheduledAt.isAfter(DateTime.now()) &&
            a.status != MobileApptStatus.cancelled)
        .toList();
    final past = appointments
        .where((a) =>
            a.scheduledAt.isBefore(DateTime.now()) ||
            a.status == MobileApptStatus.cancelled ||
            a.status == MobileApptStatus.completed)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Termine')),
      body: RefreshIndicator(
        onRefresh: provider.load,
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    Text(
                      'Bevorstehend (${upcoming.length})',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...upcoming.map((a) => _ApptCard(appt: a)),
                    const SizedBox(height: 16),
                  ],
                  if (past.isNotEmpty) ...[
                    Text(
                      'Vergangen',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    ...past.take(10).map((a) => _ApptCard(appt: a)),
                  ],
                  if (appointments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_outlined,
                                size: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text('Keine Termine',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final MobileAppointment appt;
  const _ApptCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (appt.status) {
      MobileApptStatus.confirmed => cs.secondary,
      MobileApptStatus.requested => cs.tertiary,
      MobileApptStatus.completed => Colors.green,
      MobileApptStatus.cancelled => cs.error,
      MobileApptStatus.noShow => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.calendar_today_rounded, color: color, size: 20),
        ),
        title: Text(appt.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appt.dateTimeLabel),
            if (appt.petName != null) Text(appt.petName!),
            if (appt.organizationName != null) Text(appt.organizationName!),
            if (appt.location != null) Text(appt.location!),
          ],
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(appt.statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ),
        isThreeLine: true,
      ),
    );
  }
}
