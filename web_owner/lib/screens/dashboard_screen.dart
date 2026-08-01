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

  /// Leichtgewichtiger Wellness-Indikator aus bereits geladenen
  /// Dashboard-Daten (keine zusätzlichen API-Calls je Tier). Kein Ersatz für
  /// den serverseitigen Health-Score pro Tier (siehe AnimalDetailScreen),
  /// sondern eine grobe Gesamt-Einschätzung für den Dashboard-Header.
  int _wellnessScore({
    required List<Map<String, dynamic>> expiringVaccinations,
    required List<Reminder> overdueReminders,
    required List<Medication> endingSoonMeds,
  }) {
    var score = 100;
    for (final v in expiringVaccinations) {
      final validUntil = v['valid_until'] as String?;
      final date = validUntil != null ? DateTime.tryParse(validUntil) : null;
      final daysLeft =
          date != null ? date.difference(DateTime.now()).inDays : null;
      score -= (daysLeft != null && daysLeft <= 0) ? 10 : 4;
    }
    score -= overdueReminders.length * 5;
    score -= endingSoonMeds.length * 3;
    return score.clamp(0, 100);
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
    final endingSoonMeds = activeMeds.where((m) => m.endsSoon).toList();
    final overdueReminders =
        reminderProvider.upcoming.where((r) => r.isPast).toList();
    final wellness = _wellnessScore(
      expiringVaccinations: _expiringVaccinations,
      overdueReminders: overdueReminders,
      endingSoonMeds: endingSoonMeds,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome & Wellness Score ──
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(userName),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hier ist der aktuelle Stand deiner tierischen Familie.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (petProvider.pets.isNotEmpty)
                  _WellnessScoreCard(score: wellness),
              ],
            ),
            const SizedBox(height: 24),

            // ── Quick Action Chips ──
            _QuickActionChipsRow(),

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
            const SizedBox(height: 24),

            // ── Bento Grid: links breiter, rechts schmaler ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final left = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activeMeds.isNotEmpty) ...[
                      _ActiveMedicationsCard(medications: activeMeds),
                      const SizedBox(height: 24),
                    ],
                    if (petProvider.pets.isNotEmpty) ...[
                      _VaccinationTrafficLightCard(
                        vaccinations: _expiringVaccinations,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (upcomingBirthdays.isNotEmpty) ...[
                      _BirthdayPanel(pets: upcomingBirthdays),
                      const SizedBox(height: 24),
                    ],
                    if (petProvider.pets.isNotEmpty) ...[
                      _PetStatsSummary(pets: petProvider.pets),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deine Tiere',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('/animals'),
                          child: const Text('Alle ansehen →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final crossAxisCount =
                            gridConstraints.maxWidth > 700 ? 2 : 1;
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
                              onTap: () => context.go('/animals/${pet.id}'),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );

                final right = Column(
                  children: [
                    _RemindersTimelineCard(
                      reminders: reminderProvider.upcoming,
                    ),
                    const SizedBox(height: 24),
                    _AppointmentsPanel(
                      appointments: appointmentProvider.upcoming,
                    ),
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [left, const SizedBox(height: 24), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 8, child: left),
                    const SizedBox(width: 24),
                    SizedBox(width: 340, child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen, $name';
    if (hour < 18) return 'Guten Tag, $name';
    return 'Guten Abend, $name';
  }
}

// ── Wellness Score Card (kreisförmiger Fortschrittsring, Header rechts) ──

class _WellnessScoreCard extends StatelessWidget {
  final int score;
  const _WellnessScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    backgroundColor:
                        LivingLedgerTheme.primaryContainer.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(
                        LivingLedgerTheme.primary),
                  ),
                ),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LivingLedgerTheme.primary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gesamt-Wellness',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                score >= 85
                    ? 'Alles im grünen Bereich'
                    : score >= 60
                        ? 'Ein paar Dinge brauchen Aufmerksamkeit'
                        : 'Mehrere offene Punkte',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LivingLedgerTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Chips (horizontal scrollbare Pill-Buttons) ──

class _QuickActionChipsRow extends StatelessWidget {
  _QuickActionChipsRow();

  final List<_QuickAction> _actions = [
    _QuickAction(Icons.medication_rounded, 'Medikament geben', '/medications',
        emphasis: true),
    _QuickAction(Icons.monitor_weight_rounded, 'Gewicht eintragen', '/weight'),
    _QuickAction(
        Icons.calendar_month_rounded, 'Termin buchen', '/appointments'),
    _QuickAction(Icons.notifications_active_rounded, 'Erinnerung anlegen',
        '/reminders'),
    _QuickAction(Icons.restaurant_rounded, 'Fütterung protokollieren',
        '/feeding'),
    _QuickAction(Icons.vaccines_rounded, 'Impfungen ansehen', '/animals'),
    _QuickAction(Icons.emergency_rounded, 'Notfallkontakte',
        '/emergency-contacts',
        danger: true),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final a = _actions[index];
          final color = a.danger
              ? LivingLedgerTheme.error
              : a.emphasis
                  ? LivingLedgerTheme.primary
                  : LivingLedgerTheme.onSurface;
          final bg = a.danger
              ? LivingLedgerTheme.error.withValues(alpha: 0.1)
              : a.emphasis
                  ? LivingLedgerTheme.primary.withValues(alpha: 0.1)
                  : LivingLedgerTheme.surfaceContainerLowest;
          return Material(
            color: bg,
            borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusFull),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusFull),
              onTap: () => context.go(a.route),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(LivingLedgerTheme.radiusFull),
                  border: Border.all(
                    color: a.danger
                        ? LivingLedgerTheme.error.withValues(alpha: 0.2)
                        : a.emphasis
                            ? LivingLedgerTheme.primary.withValues(alpha: 0.2)
                            : LivingLedgerTheme.outlineVariant
                                .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(a.icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(a.label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: color)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  final bool emphasis;
  final bool danger;
  _QuickAction(this.icon, this.label, this.route,
      {this.emphasis = false, this.danger = false});
}

// ── Active Medications Card (2-Spalten Grid, Bento-Stil) ──

class _ActiveMedicationsCard extends StatelessWidget {
  final List<Medication> medications;
  const _ActiveMedicationsCard({required this.medications});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Aktive Medikamente',
                  style: Theme.of(context).textTheme.headlineSmall),
              TextButton(
                onPressed: () => context.go('/medications'),
                child: const Text('Alle ansehen'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 500 ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.6,
              ),
              itemCount: medications.length > 4 ? 4 : medications.length,
              itemBuilder: (context, index) {
                final m = medications[index];
                final urgent = m.endsSoon;
                final tint =
                    urgent ? LivingLedgerTheme.tertiary : LivingLedgerTheme.secondary;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(LivingLedgerTheme.radiusLg),
                    border: Border.all(
                        color: LivingLedgerTheme.outlineVariant
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(LivingLedgerTheme.radiusMd),
                        ),
                        child: Icon(Icons.medication_rounded,
                            color: tint, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (m.dosage != null)
                              Text(m.dosage!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.frequencyLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                            color: LivingLedgerTheme
                                                .onSurfaceVariant)),
                                SizedBox(
                                  height: 26,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      minimumSize: Size.zero,
                                      backgroundColor:
                                          LivingLedgerTheme.primary,
                                      foregroundColor:
                                          LivingLedgerTheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            LivingLedgerTheme.radiusMd),
                                      ),
                                    ),
                                    onPressed: m.petId.isNotEmpty
                                        ? () => context
                                            .read<MedicationProvider>()
                                            .administer(m.petId, m.id)
                                        : null,
                                    child: const Text('Gegeben',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
          if (medications.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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

// ── Vaccination Traffic Light Card (rot/gelb/grün, wie Mockup) ──

class _VaccinationTrafficLightCard extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;
  const _VaccinationTrafficLightCard({required this.vaccinations});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    final entries = vaccinations.map((v) {
      final validUntil = v['valid_until'] as String?;
      final date = validUntil != null ? DateTime.tryParse(validUntil) : null;
      final daysLeft =
          date != null ? date.difference(DateTime.now()).inDays : null;
      return (v: v, date: date, daysLeft: daysLeft);
    }).toList()
      ..sort((a, b) => (a.daysLeft ?? 9999).compareTo(b.daysLeft ?? 9999));

    final expired = entries.where((e) => (e.daysLeft ?? 1) <= 0).toList();
    final soon =
        entries.where((e) => (e.daysLeft ?? 99) > 0 && (e.daysLeft ?? 99) <= 14).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Impfstatus',
                  style: Theme.of(context).textTheme.headlineSmall),
              Icon(Icons.info_outline_rounded,
                  color: LivingLedgerTheme.onSurfaceVariant, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          for (final e in expired) ...[
            _TrafficLightRow(
              color: LivingLedgerTheme.error,
              icon: Icons.warning_rounded,
              title: '${e.v['vaccine_name'] ?? '—'}',
              subtitle:
                  '${e.v['pet_name'] ?? '—'} • Abgelaufen${e.date != null ? ' (${fmt.format(e.date!)})' : ''}',
              actionLabel: 'Jetzt buchen',
              actionColor: LivingLedgerTheme.error,
              onTap: () => context.go('/appointments'),
            ),
            const SizedBox(height: 10),
          ],
          for (final e in soon) ...[
            _TrafficLightRow(
              color: LivingLedgerTheme.secondary,
              icon: Icons.error_rounded,
              title: '${e.v['vaccine_name'] ?? '—'}',
              subtitle:
                  '${e.v['pet_name'] ?? '—'} • läuft in ${e.daysLeft} Tagen ab',
              actionLabel: 'Termin planen',
              actionColor: LivingLedgerTheme.secondary,
              onTap: () => context.go('/appointments'),
            ),
            const SizedBox(height: 10),
          ],
          if (expired.isEmpty && soon.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
                border: Border.all(
                    color:
                        LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: LivingLedgerTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        color: LivingLedgerTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Alle Impfungen sind aktuell.',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrafficLightRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onTap;

  const _TrafficLightRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: actionColor),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ── Reminders Timeline Card ("Needs Attention", wie Mockup) ──

class _RemindersTimelineCard extends StatelessWidget {
  final List<Reminder> reminders;
  const _RemindersTimelineCard({required this.reminders});

  void _dismiss(BuildContext context, String id) {
    context.read<ReminderProvider>().dismiss(id);
  }

  Future<void> _quickAddReminder(BuildContext context) async {
    final titleCtrl = TextEditingController();
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
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
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
    final items = reminders.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
        border: Border(
          top: BorderSide(color: LivingLedgerTheme.tertiary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  size: 20, color: LivingLedgerTheme.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Braucht Aufmerksamkeit',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
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
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Keine ausstehenden Erinnerungen',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            Stack(
              children: [
                Positioned(
                  left: 13,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    width: 2,
                    color: LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                Column(
                  children: items.map((r) {
                    final isPast = r.isPast;
                    final dotColor = isPast
                        ? LivingLedgerTheme.tertiary
                        : LivingLedgerTheme.secondary;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            alignment: Alignment.center,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: LivingLedgerTheme.surfaceContainerLowest,
                                shape: BoxShape.circle,
                                border: Border.all(color: dotColor, width: 2),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: dotColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(
                                    LivingLedgerTheme.radiusMd),
                                border: Border.all(
                                    color: dotColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        Text(
                                          isPast
                                              ? 'Überfällig • ${fmt.format(r.remindAt)}'
                                              : fmt.format(r.remindAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isPast
                                                    ? LivingLedgerTheme.tertiary
                                                    : LivingLedgerTheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPast)
                                    GestureDetector(
                                      onTap: () => _dismiss(context, r.id),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 18,
                                        color: LivingLedgerTheme.tertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/reminders'),
              child: const Text('Erinnerungen verwalten'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Appointments Panel ──

class _AppointmentsPanel extends StatelessWidget {
  final List<Appointment> appointments;

  const _AppointmentsPanel({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 36,
                      color: LivingLedgerTheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 10),
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
          const SizedBox(height: 4),
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

class _BirthdayPanel extends StatelessWidget {
  final List<Pet> pets;
  const _BirthdayPanel({required this.pets});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
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
            if (next.isBefore(now)) {
              next = DateTime(now.year + 1, bd.month, bd.day);
            }
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

// ── Pet Stats Summary ──

class _PetStatsSummary extends StatelessWidget {
  final List<Pet> pets;
  const _PetStatsSummary({required this.pets});

  @override
  Widget build(BuildContext context) {
    final speciesCounts = <String, int>{};
    for (final pet in pets) {
      speciesCounts[pet.speciesLabel] =
          (speciesCounts[pet.speciesLabel] ?? 0) + 1;
    }

    final ages =
        pets.where((p) => p.ageYears != null).map((p) => p.ageYears!).toList();
    final avgAge = ages.isEmpty ? null : ages.reduce((a, b) => a + b) / ages.length;

    return Container(
      width: double.infinity,
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
