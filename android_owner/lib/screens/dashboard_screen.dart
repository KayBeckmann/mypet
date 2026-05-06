import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/health_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<MobileAuthProvider>();
    final pets = context.watch<MobilePetProvider>().pets;
    final overdue = context.watch<MobileReminderProvider>().overdue;
    final upcoming = context.watch<MobileAppointmentProvider>().upcoming;
    final medProv = context.watch<MobileMedicationProvider>();
    final weightProv = context.watch<MobileWeightProvider>();
    final healthProv = context.watch<MobileHealthProvider>();

    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Guten Morgen' : hour < 18 ? 'Guten Tag' : 'Guten Abend';
    final cs = Theme.of(context).colorScheme;

    final endingSoonMeds = <_PetMed>[];
    for (final pet in pets) {
      for (final med in medProv.activeForPet(pet.id)) {
        if (med.endsSoon) endingSoonMeds.add(_PetMed(pet: pet, med: med));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final petProv = context.read<MobilePetProvider>();
              context.read<MobileReminderProvider>().load();
              context.read<MobileAppointmentProvider>().load();
              await petProv.load();
              for (final pet in petProv.pets) {
                context.read<MobileMedicationProvider>().loadForPet(pet.id);
                context.read<MobileWeightProvider>().loadForPet(pet.id);
                context.read<MobileHealthProvider>().loadForPet(pet.id);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final petProv = context.read<MobilePetProvider>();
          await Future.wait([
            petProv.load(),
            context.read<MobileReminderProvider>().load(),
            context.read<MobileAppointmentProvider>().load(),
          ]);
          for (final pet in petProv.pets) {
            context.read<MobileMedicationProvider>().loadForPet(pet.id);
            context.read<MobileWeightProvider>().loadForPet(pet.id);
            context.read<MobileHealthProvider>().loadForPet(pet.id);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Greeting
            Text(
              '$greeting, ${auth.user?.name ?? 'Tierfreund'}!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${pets.length} Tier${pets.length == 1 ? '' : 'e'} registriert',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _StatChip(
                  icon: Icons.pets_rounded,
                  label: 'Tiere',
                  value: '${pets.length}',
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.alarm_rounded,
                  label: 'Überfällig',
                  value: '${overdue.length}',
                  color: overdue.isNotEmpty ? cs.error : cs.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.calendar_month_rounded,
                  label: 'Termine',
                  value: '${upcoming.length}',
                  color: cs.secondary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.medication_rounded,
                  label: 'Ablaufend',
                  value: '${endingSoonMeds.length}',
                  color: endingSoonMeds.isNotEmpty ? Colors.orange : cs.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Medication expiry alert
            if (endingSoonMeds.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Medikamente laufen bald ab',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...endingSoonMeds.take(3).map((pm) {
                      final days =
                          pm.med.endDate!.difference(DateTime.now()).inDays;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(pm.pet.speciesEmoji),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${pm.pet.name} – ${pm.med.name}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              days <= 0 ? 'Heute!' : 'Noch $days Tage',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Overdue reminders alert
            if (overdue.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.alarm_rounded, color: cs.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${overdue.length} überfällige '
                        'Erinnerung${overdue.length == 1 ? '' : 'en'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pet health overview cards
            if (pets.isNotEmpty) ...[
              Text(
                'Gesundheitsübersicht',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...pets.map((pet) {
                final stats = healthProv.statsForPet(pet.id);
                final score =
                    (stats?['health_score'] as num?)?.toInt() ?? 0;
                final weight = weightProv.latestForPet(pet.id);
                final isLoadingHealth = healthProv.isLoading(pet.id);
                return _PetHealthCard(
                  pet: pet,
                  score: score,
                  weight: weight,
                  isLoading: isLoadingHealth,
                );
              }),
              const SizedBox(height: 16),
            ],

            // Upcoming appointments
            if (upcoming.isNotEmpty) ...[
              Text(
                'Nächste Termine',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...upcoming.take(3).map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.secondaryContainer,
                          child: Icon(Icons.calendar_today_rounded,
                              color: cs.secondary, size: 20),
                        ),
                        title: Text(a.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(a.dateTimeLabel),
                        trailing: _ApptStatusChip(status: a.status),
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
            ],

            // Empty state when no pets
            if (pets.isEmpty)
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PetMed {
  final MobilePet pet;
  final MobileMedication med;
  const _PetMed({required this.pet, required this.med});
}

class _PetHealthCard extends StatelessWidget {
  final MobilePet pet;
  final int score;
  final MobileWeightEntry? weight;
  final bool isLoading;

  const _PetHealthCard({
    required this.pet,
    required this.score,
    required this.weight,
    required this.isLoading,
  });

  Color _scoreColor(int s) {
    if (s >= 70) return Colors.green;
    if (s >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor(score);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(pet.speciesEmoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  if (isLoading)
                    const SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation(scoreColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scoreColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  if (weight != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${weight!.weightKg.toStringAsFixed(1)} kg · ${weight!.dateLabel}',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16),
            ),
            Text(
              label,
              style:
                  TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
              textAlign: TextAlign.center,
            ),
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
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
