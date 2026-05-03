import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/medication_provider.dart';
import '../models/appointment.dart';
import '../widgets/pet_card.dart';
import '../widgets/appointment_card.dart';
import '../widgets/quick_action_chip.dart';

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
    final auth = context.watch<AuthProvider>();
    final petProvider = context.watch<PetProvider>();
    final appointmentProvider = context.watch<AppointmentProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final medicationProvider = context.watch<MedicationProvider>();
    final userName = auth.user?.name ?? 'Tierfreund';
    final activeMeds = petProvider.pets
        .expand((p) => medicationProvider.forPet(p.id))
        .where((m) => m.isActive && !m.isExpired)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Content Area ──
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  _greeting(userName),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Alles im Blick auf dem Living Ledger. '
                  'Deine Tiere sind heute bestens versorgt.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    QuickActionChip(
                      icon: Icons.vaccines_rounded,
                      label: 'Impfpass',
                      onTap: () => context.go('/animals'),
                    ),
                    QuickActionChip(
                      icon: Icons.restaurant_rounded,
                      label: 'Fütterung',
                      onTap: () => context.go('/feeding'),
                    ),
                    QuickActionChip(
                      icon: Icons.alarm_rounded,
                      label: 'Erinnerungen',
                      onTap: () => context.go('/reminders'),
                    ),
                    QuickActionChip(
                      icon: Icons.storefront_rounded,
                      label: 'Tierärzte finden',
                      onTap: () => context.go('/marketplace'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Ablaufende Impfungen
                if (_expiringVaccinations.isNotEmpty) ...[
                  _ExpiringVaccinationsPanel(
                      vaccinations: _expiringVaccinations),
                  const SizedBox(height: 24),
                ],

                // Pet Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deine Tiere',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/animals'),
                      child: Text(
                        'Alle ansehen →',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: LivingLedgerTheme.onSurfaceVariant,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pet Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth > 700 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: petProvider.pets.length,
                      itemBuilder: (context, index) {
                        final pet = petProvider.pets[index];
                        return PetCard(
                          pet: pet,
                          imageBaseUrl: petProvider.apiBaseUrl,
                          onTap: () =>
                              context.go('/animals/${pet.id}'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // ── Right Panel: Appointments + Meds + Reminders ──
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _AppointmentsPanel(
                  appointments: appointmentProvider.upcoming,
                ),
                if (activeMeds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _MedicationsPanel(medications: activeMeds),
                ],
                const SizedBox(height: 20),
                _RemindersPanel(
                  reminders: reminderProvider.upcoming,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen, $name.';
    if (hour < 18) return 'Guten Tag, $name.';
    return 'Guten Abend, $name.';
  }
}

class _AppointmentsPanel extends StatelessWidget {
  final List<Appointment> appointments;

  const _AppointmentsPanel({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 20,
                color: LivingLedgerTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Termine',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Appointment List
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 40,
                      color: LivingLedgerTheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keine anstehenden Termine',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LivingLedgerTheme.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...appointments.map((appointment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppointmentCard(appointment: appointment),
                )),

          const SizedBox(height: 12),

          // Link
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.go('/appointments'),
              child: const Text('Alle Termine →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersPanel extends StatelessWidget {
  final List<Reminder> reminders;

  const _RemindersPanel({required this.reminders});

  // Needed to call ReminderProvider from a StatelessWidget
  void _dismiss(BuildContext context, String id) {
    context.read<ReminderProvider>().dismiss(id);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM. HH:mm');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_rounded,
                  size: 20, color: LivingLedgerTheme.tertiary),
              const SizedBox(width: 8),
              Text('Erinnerungen',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),

          if (reminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Keine ausstehenden Erinnerungen',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...reminders.take(4).map((r) {
              final isPast = r.isPast;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPast
                            ? LivingLedgerTheme.tertiary
                            : LivingLedgerTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                isPast
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule_rounded,
                                size: 11,
                                color: isPast
                                    ? LivingLedgerTheme.tertiary
                                    : LivingLedgerTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                fmt.format(r.remindAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isPast
                                          ? LivingLedgerTheme.tertiary
                                          : null,
                                    ),
                              ),
                              if (r.petName != null) ...[
                                const Text(' · ',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            LivingLedgerTheme.onSurfaceVariant)),
                                Text(r.petName!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isPast)
                      GestureDetector(
                        onTap: () => _dismiss(context, r.id),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: LivingLedgerTheme.tertiary,
                        ),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.go('/reminders'),
              child: const Text('Alle Erinnerungen →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationsPanel extends StatelessWidget {
  final List<Medication> medications;
  const _MedicationsPanel({required this.medications});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Aktive Medikamente',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/medications'),
                style: TextButton.styleFrom(
                    minimumSize: Size.zero, padding: EdgeInsets.zero),
                child: Text('Alle →',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LivingLedgerTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...medications.take(4).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (m.endsSoon
                                ? LivingLedgerTheme.tertiary
                                : LivingLedgerTheme.primary)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        size: 16,
                        color: m.endsSoon
                            ? LivingLedgerTheme.tertiary
                            : LivingLedgerTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (m.dosage != null)
                            Text(m.dosage!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: LivingLedgerTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Text(
                      m.frequencyLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: m.endsSoon
                              ? LivingLedgerTheme.tertiary
                              : LivingLedgerTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )),
          if (medications.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${medications.length - 4} weitere',
                style: TextStyle(
                    fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant),
              ),
            ),
        ],
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
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
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
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/animals'),
                child: const Text('Zum Impfpass →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...vaccinations.map((v) {
            final validUntil = v['valid_until'] as String?;
            DateTime? date;
            if (validUntil != null) date = DateTime.tryParse(validUntil);
            final daysLeft =
                date != null ? date.difference(DateTime.now()).inDays : null;
            final urgent = daysLeft != null && daysLeft <= 7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: urgent ? LivingLedgerTheme.error : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${v['pet_name'] ?? '—'} · ${v['vaccine_name'] ?? '—'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (date != null)
                    Text(
                      '${fmt.format(date)}${daysLeft != null ? ' ($daysLeft T)' : ''}',
                      style: TextStyle(
                          fontSize: 12,
                          color: urgent
                              ? LivingLedgerTheme.error
                              : Colors.amber.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
