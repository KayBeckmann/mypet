import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/health_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';

enum _CalEntryType { appointment, vaccinationExpiry, medicationEnd, reminder }

class _CalEntry {
  final String title;
  final _CalEntryType type;
  final DateTime date;
  final Color color;

  const _CalEntry({
    required this.title,
    required this.type,
    required this.date,
    required this.color,
  });
}

class PetCalendarScreen extends StatefulWidget {
  const PetCalendarScreen({super.key});

  @override
  State<PetCalendarScreen> createState() => _PetCalendarScreenState();
}

class _PetCalendarScreenState extends State<PetCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  String? _selectedPetId;

  List<_CalEntry> _buildEntries(BuildContext context) {
    final entries = <_CalEntry>[];
    final petId = _selectedPetId;

    // Appointments
    final apptProvider = context.read<AppointmentProvider>();
    for (final a in apptProvider.appointments) {
      if (petId != null && a.petId != petId) continue;
      entries.add(_CalEntry(
        title: a.title,
        type: _CalEntryType.appointment,
        date: a.scheduledAt,
        color: a.status == AppointmentStatus.completed
            ? LivingLedgerTheme.success
            : a.status == AppointmentStatus.cancelled
                ? LivingLedgerTheme.error
                : LivingLedgerTheme.primary,
      ));
    }

    // Vaccinations expiry
    final healthProvider = context.read<OwnerHealthProvider>();
    if (petId == null || healthProvider.selectedPetId == petId) {
      for (final v in healthProvider.vaccinations) {
        if (v.validUntil != null) {
          entries.add(_CalEntry(
            title: 'Impfung läuft ab: ${v.vaccineName}',
            type: _CalEntryType.vaccinationExpiry,
            date: v.validUntil!,
            color: v.validUntil!.isBefore(DateTime.now())
                ? LivingLedgerTheme.error
                : Colors.orange,
          ));
        }
      }
    }

    // Medication end dates
    final medProvider = context.read<MedicationProvider>();
    if (petId == null || medProvider.selectedPetId == petId) {
      for (final m in medProvider.medications.where((m) => m.isActive && m.endDate != null)) {
        entries.add(_CalEntry(
          title: 'Medikament endet: ${m.name}',
          type: _CalEntryType.medicationEnd,
          date: m.endDate!,
          color: Colors.purple,
        ));
      }
    }

    // Reminders
    final reminderProvider = context.read<ReminderProvider>();
    for (final r in reminderProvider.reminders) {
      entries.add(_CalEntry(
        title: r.title,
        type: _CalEntryType.reminder,
        date: r.remindAt,
        color: r.isPast ? LivingLedgerTheme.error : Colors.teal,
      ));
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    final entries = _buildEntries(context);

    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday =
        DateTime(_month.year, _month.month, 1).weekday; // 1=Mon

    final entriesByDay = <int, List<_CalEntry>>{};
    for (final e in entries) {
      if (e.date.year == _month.year && e.date.month == _month.month) {
        entriesByDay.putIfAbsent(e.date.day, () => []).add(e);
      }
    }

    final selectedEntries = _selectedDay != null
        ? (entriesByDay[_selectedDay!.day] ?? [])
        : <_CalEntry>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kalender', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Übersicht aller Termine, Impfungen und Erinnerungen.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Pet filter
          if (pets.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Alle Tiere'),
                  selected: _selectedPetId == null,
                  onSelected: (_) => setState(() => _selectedPetId = null),
                ),
                ...pets.map((p) => FilterChip(
                      label: Text(p.name),
                      selected: _selectedPetId == p.id,
                      onSelected: (_) {
                        setState(() => _selectedPetId = p.id);
                        context.read<OwnerHealthProvider>().loadForPet(p.id);
                        context.read<MedicationProvider>().loadForPet(p.id);
                      },
                    )),
              ],
            ),
          const SizedBox(height: 16),

          // Month navigation
          Container(
            decoration: BoxDecoration(
              color: LivingLedgerTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: LivingLedgerTheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => setState(() {
                          _month = DateTime(_month.year, _month.month - 1);
                          _selectedDay = null;
                        }),
                      ),
                      Text(
                        _monthLabel(_month),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => setState(() {
                          _month = DateTime(_month.year, _month.month + 1);
                          _selectedDay = null;
                        }),
                      ),
                    ],
                  ),
                ),

                // Weekday headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                        .map((d) => Expanded(
                              child: Center(
                                child: Text(d,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: LivingLedgerTheme
                                            .onSurfaceVariant)),
                              ),
                            ))
                        .toList(),
                  ),
                ),

                // Calendar grid
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: (firstWeekday - 1) + daysInMonth,
                    itemBuilder: (_, i) {
                      if (i < firstWeekday - 1) return const SizedBox.shrink();
                      final day = i - (firstWeekday - 2);
                      final dayEntries = entriesByDay[day] ?? [];
                      final isToday = DateTime.now().year == _month.year &&
                          DateTime.now().month == _month.month &&
                          DateTime.now().day == day;
                      final isSelected = _selectedDay?.day == day;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDay = DateTime(_month.year, _month.month, day);
                        }),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LivingLedgerTheme.primary.withValues(alpha: 0.15)
                                : isToday
                                    ? LivingLedgerTheme.primary.withValues(alpha: 0.06)
                                    : null,
                            borderRadius: BorderRadius.circular(6),
                            border: isToday
                                ? Border.all(
                                    color: LivingLedgerTheme.primary,
                                    width: 1.5)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: isToday
                                      ? LivingLedgerTheme.primary
                                      : null,
                                ),
                              ),
                              if (dayEntries.isNotEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: dayEntries
                                      .take(3)
                                      .map((e) => Container(
                                            width: 5,
                                            height: 5,
                                            margin: const EdgeInsets.only(
                                                top: 2, left: 1),
                                            decoration: BoxDecoration(
                                              color: e.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Wrap(
                    spacing: 12,
                    children: const [
                      _LegendDot(
                          color: LivingLedgerTheme.primary, label: 'Termine'),
                      _LegendDot(color: Colors.orange, label: 'Impfungen'),
                      _LegendDot(color: Colors.purple, label: 'Medikamente'),
                      _LegendDot(color: Colors.teal, label: 'Erinnerungen'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Selected day entries
          if (_selectedDay != null) ...[
            const SizedBox(height: 20),
            Text(
              '${_selectedDay!.day}. ${_monthName(_selectedDay!.month)} ${_selectedDay!.year}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (selectedEntries.isEmpty)
              Text('Keine Ereignisse',
                  style:
                      TextStyle(color: LivingLedgerTheme.onSurfaceVariant))
            else
              ...selectedEntries.map((e) => _EntryTile(entry: e)),
          ],
        ],
      ),
    );
  }

  String _monthLabel(DateTime d) {
    const months = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];
    return '${months[d.month]} ${d.year}';
  }

  String _monthName(int m) {
    const months = [
      '',
      'Jan.',
      'Feb.',
      'Mär.',
      'Apr.',
      'Mai',
      'Jun.',
      'Jul.',
      'Aug.',
      'Sep.',
      'Okt.',
      'Nov.',
      'Dez.'
    ];
    return months[m];
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: LivingLedgerTheme.onSurfaceVariant)),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final _CalEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final icon = switch (entry.type) {
      _CalEntryType.appointment => Icons.event_rounded,
      _CalEntryType.vaccinationExpiry => Icons.vaccines_rounded,
      _CalEntryType.medicationEnd => Icons.medication_rounded,
      _CalEntryType.reminder => Icons.alarm_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: entry.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: entry.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: entry.color.withValues(alpha: 0.9)),
            ),
          ),
          Text(
            '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
                fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
