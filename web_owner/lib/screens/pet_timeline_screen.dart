import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/appointment_provider.dart';
import '../providers/health_provider.dart';
import '../providers/lab_result_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/weight_provider.dart';

enum _TLType { appointment, vaccination, weight, labResult }

class _TLEvent {
  final _TLType type;
  final DateTime date;
  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _TLEvent({
    required this.type,
    required this.date,
    required this.title,
    this.subtitle,
    required this.color,
    required this.icon,
  });
}

class PetTimelineScreen extends StatefulWidget {
  const PetTimelineScreen({super.key});

  @override
  State<PetTimelineScreen> createState() => _PetTimelineScreenState();
}

class _PetTimelineScreenState extends State<PetTimelineScreen> {
  String? _selectedPetId;
  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      if (pets.isNotEmpty) {
        _selectPet(pets.first);
      }
    });
  }

  void _selectPet(Pet p) {
    setState(() => _selectedPetId = p.id);
    context.read<OwnerHealthProvider>().loadForPet(p.id);
    context.read<WeightProvider>().loadForPet(p.id);
    context.read<OwnerLabResultProvider>().loadForPet(p.id);
  }

  List<_TLEvent> _buildTimeline(BuildContext context) {
    final events = <_TLEvent>[];
    final petId = _selectedPetId;
    if (petId == null) return events;

    // Appointments
    final apptProvider = context.read<AppointmentProvider>();
    for (final a in apptProvider.appointments) {
      if (a.petId != petId) continue;
      events.add(_TLEvent(
        type: _TLType.appointment,
        date: a.scheduledAt,
        title: a.title,
        subtitle: '${a.statusLabel}${a.organizationName != null ? ' · ${a.organizationName}' : ''}',
        color: LivingLedgerTheme.primary,
        icon: Icons.event_rounded,
      ));
    }

    // Vaccinations
    final healthProvider = context.read<OwnerHealthProvider>();
    if (healthProvider.selectedPetId == petId) {
      for (final v in healthProvider.vaccinations) {
        final dateRaw = v['vaccinated_at'];
        final date = dateRaw is DateTime ? dateRaw : DateTime.tryParse(dateRaw.toString());
        if (date == null) continue;
        events.add(_TLEvent(
          type: _TLType.vaccination,
          date: date,
          title: 'Impfung: ${v['vaccine_name'] ?? '?'}',
          subtitle: v['manufacturer'] as String?,
          color: Colors.teal,
          icon: Icons.vaccines_rounded,
        ));
      }
    }

    // Weight entries
    final weightProvider = context.read<WeightProvider>();
    if (weightProvider.selectedPetId == petId) {
      for (final w in weightProvider.entries) {
        events.add(_TLEvent(
          type: _TLType.weight,
          date: w.recordedAt,
          title: '${w.weightKg.toStringAsFixed(1)} kg',
          subtitle: 'Gewicht gemessen',
          color: Colors.blue,
          icon: Icons.monitor_weight_rounded,
        ));
      }
    }

    // Lab results
    final labProvider = context.read<OwnerLabResultProvider>();
    if (labProvider.selectedPetId == petId) {
      for (final l in labProvider.results) {
        events.add(_TLEvent(
          type: _TLType.labResult,
          date: l.testedAt,
          title: '${l.testName}: ${l.resultValue}${l.unit != null ? ' ${l.unit}' : ''}',
          subtitle: l.isAbnormal ? 'Auffälliger Wert!' : l.testCategory,
          color: l.isAbnormal ? LivingLedgerTheme.error : Colors.deepPurple,
          icon: Icons.biotech_outlined,
        ));
      }
    }

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;

    final events = _buildTimeline(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tier-Timeline', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Chronologische Übersicht aller Ereignisse für dein Tier.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          if (pets.isEmpty)
            const Text('Keine Tiere vorhanden.')
          else ...[
            // Pet selector
            Wrap(
              spacing: 8,
              children: pets.map((p) {
                final selected = _selectedPetId == p.id;
                return FilterChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (_) => _selectPet(p),
                  avatar: selected
                      ? const Icon(Icons.pets_rounded, size: 16)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Filter legend
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: const [
                _LegendDot(color: LivingLedgerTheme.primary, label: 'Termine'),
                _LegendDot(color: Colors.teal, label: 'Impfungen'),
                _LegendDot(color: Colors.blue, label: 'Gewicht'),
                _LegendDot(color: Colors.deepPurple, label: 'Labor'),
              ],
            ),
            const SizedBox(height: 20),

            if (events.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Icon(Icons.timeline_rounded,
                        size: 48,
                        color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'Noch keine Einträge',
                      style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              _Timeline(events: events, dateFmt: _dateFmt),
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final List<_TLEvent> events;
  final DateFormat dateFmt;

  const _Timeline({required this.events, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final isLast = i == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: e.color, width: 1.5),
                      ),
                      child: Icon(e.icon, size: 16, color: e.color),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: LivingLedgerTheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Text(
                            dateFmt.format(e.date),
                            style: TextStyle(
                                fontSize: 11,
                                color: LivingLedgerTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (e.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          e.subtitle!,
                          style: TextStyle(
                              fontSize: 12,
                              color: e.type == _TLType.labResult &&
                                      e.subtitle == 'Auffälliger Wert!'
                                  ? LivingLedgerTheme.error
                                  : LivingLedgerTheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
