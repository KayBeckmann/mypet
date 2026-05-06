import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/family_invitation_provider.dart';
import '../providers/family_provider.dart';
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
      _loadMedications();
    });
  }

  void _loadMedications() {
    final pets = context.read<PetProvider>().pets;
    final medProvider = context.read<MedicationProvider>();
    for (final pet in pets) {
      medProvider.loadForPet(pet.id);
    }
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
    final familyInvitations = context.watch<FamilyInvitationProvider>();
    final userName = auth.user?.name ?? 'Tierfreund';

    // Upcoming birthdays (next 14 days)
    final now = DateTime.now();
    DateTime nextBirthday(DateTime bd) {
      var n = DateTime(now.year, bd.month, bd.day);
      if (n.isBefore(now)) n = DateTime(now.year + 1, bd.month, bd.day);
      return n;
    }
    final upcomingBirthdays = petProvider.pets.where((p) {
      if (p.birthDate == null) return false;
      return nextBirthday(p.birthDate!).difference(now).inDays <= 14;
    }).toList()
      ..sort((a, b) =>
          nextBirthday(a.birthDate!).compareTo(nextBirthday(b.birthDate!)));
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
                    QuickActionChip(
                      icon: Icons.calendar_month_rounded,
                      label: 'Kalender',
                      onTap: () => context.go('/calendar'),
                    ),
                    QuickActionChip(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Gesundheitspass',
                      onTap: () => context.go('/health-passport'),
                    ),
                    QuickActionChip(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Tier-Vergleich',
                      onTap: () => context.go('/compare'),
                    ),
                  ],
                ),
                // Familien-Einladungen
                if (familyInvitations.invitations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...familyInvitations.invitations.map((inv) =>
                      _FamilyInvitationBanner(
                        invitation: inv,
                        onAccept: () async {
                          final ok = await familyInvitations.accept(inv.id);
                          if (ok && context.mounted) {
                            context.read<FamilyProvider>().loadFamilies();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Du bist jetzt Mitglied von "${inv.familyName}"'),
                            ));
                          }
                        },
                        onReject: () => familyInvitations.reject(inv.id),
                      )),
                ],

                // Geburtstage
                if (upcomingBirthdays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _BirthdayPanel(pets: upcomingBirthdays),
                ],

                const SizedBox(height: 24),

                // Ablaufende Impfungen
                if (_expiringVaccinations.isNotEmpty) ...[
                  _ExpiringVaccinationsPanel(
                      vaccinations: _expiringVaccinations),
                  const SizedBox(height: 24),
                ],

                // Impfstatus-Ampel
                if (petProvider.pets.isNotEmpty) ...[
                  _VaccinationStatusRow(
                    pets: petProvider.pets,
                    expiringVaccinations: _expiringVaccinations,
                  ),
                  const SizedBox(height: 24),
                ],

                // Pet Stats Summary
                if (petProvider.pets.isNotEmpty) ...[
                  _PetStatsSummary(pets: petProvider.pets),
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

  void _dismiss(BuildContext context, String id) {
    context.read<ReminderProvider>().dismiss(id);
  }

  Future<void> _quickAddReminder(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    DateTime? selectedDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Schnell-Erinnerung'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Titel *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(selectedDate != null
                      ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}'
                      : 'Datum wählen'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDs(() => selectedDate = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<ReminderProvider>();
      await provider.create(
        title: titleCtrl.text.trim(),
        remindAt: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      );
    }
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
              Expanded(child: Text('Erinnerungen',
                  style: Theme.of(context).textTheme.headlineSmall)),
              IconButton(
                icon: const Icon(Icons.add_alarm_rounded, size: 18),
                tooltip: 'Schnell-Erinnerung',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _quickAddReminder(context),
              ),
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
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                      color: LivingLedgerTheme.success,
                      tooltip: 'Gegeben',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: m.petId.isNotEmpty
                          ? () => context.read<MedicationProvider>().administer(m.petId, m.id)
                          : null,
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

class _FamilyInvitationBanner extends StatelessWidget {
  final FamilyInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FamilyInvitationBanner({
    required this.invitation,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(
            color: LivingLedgerTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LivingLedgerTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom_rounded,
                color: LivingLedgerTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${invitation.invitedByName} lädt dich zur Familie ein',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '"${invitation.familyName}" · ${invitation.memberCount} Mitglieder',
                  style: TextStyle(
                      fontSize: 13,
                      color: LivingLedgerTheme.onSurfaceVariant),
                ),
                if (invitation.message != null &&
                    invitation.message!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '"${invitation.message}"',
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: LivingLedgerTheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
                backgroundColor: LivingLedgerTheme.primary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8)),
            child: const Text('Annehmen'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
                foregroundColor: LivingLedgerTheme.error,
                side: BorderSide(
                    color: LivingLedgerTheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8)),
            child: const Text('Ablehnen'),
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

class _BirthdayPanel extends StatelessWidget {
  final List<Pet> pets;
  const _BirthdayPanel({required this.pets});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_rounded, color: Colors.pink, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bevorstehende Geburtstage',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.pink.shade700,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pets.map((p) {
            final bd = p.birthDate!;
            var next = DateTime(now.year, bd.month, bd.day);
            if (next.isBefore(now)) next = DateTime(now.year + 1, bd.month, bd.day);
            final daysLeft = next.difference(now).inDays;
            final years = next.year - bd.year;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(p.speciesIcon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.name} wird $years',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    daysLeft == 0
                        ? 'Heute! 🎂'
                        : daysLeft == 1
                            ? 'Morgen'
                            : 'in $daysLeft Tagen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysLeft <= 1
                          ? Colors.pink.shade700
                          : Colors.pink.shade400,
                    ),
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

// ── Pet Stats Summary ─────────────────────────────────────────────────────────

class _PetStatsSummary extends StatelessWidget {
  final List<Pet> pets;
  const _PetStatsSummary({required this.pets});

  @override
  Widget build(BuildContext context) {
    final speciesCounts = <String, int>{};
    for (final pet in pets) {
      speciesCounts[pet.speciesLabel] = (speciesCounts[pet.speciesLabel] ?? 0) + 1;
    }

    final ages = pets.where((p) => p.ageYears != null).map((p) => p.ageYears!).toList();
    final avgAge = ages.isEmpty ? null : ages.reduce((a, b) => a + b) / ages.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÜBERSICHT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(
                icon: Icons.pets_rounded,
                value: '${pets.length}',
                label: pets.length == 1 ? 'Tier' : 'Tiere',
              ),
              if (avgAge != null)
                _StatChip(
                  icon: Icons.cake_outlined,
                  value: '⌀ ${avgAge.toStringAsFixed(1)} J',
                  label: 'Alter',
                ),
              ...speciesCounts.entries.take(4).map((e) => _StatChip(
                    icon: Icons.category_outlined,
                    value: '${e.value}×',
                    label: e.key,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatChip({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LivingLedgerTheme.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _VaccinationStatusRow extends StatelessWidget {
  final List<Pet> pets;
  final List<Map<String, dynamic>> expiringVaccinations;
  const _VaccinationStatusRow({required this.pets, required this.expiringVaccinations});

  @override
  Widget build(BuildContext context) {
    final expiringPetIds = expiringVaccinations
        .map((v) => v['pet_id']?.toString())
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Impfstatus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pets.map((p) {
            final isExpiring = expiringPetIds.contains(p.id);
            final color = isExpiring ? LivingLedgerTheme.tertiary : LivingLedgerTheme.success;
            final icon = isExpiring ? Icons.warning_amber_rounded : Icons.check_circle_rounded;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(p.name, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
