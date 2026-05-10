import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/appointment.dart';
import '../models/pet.dart';
import '../providers/appointment_provider.dart';
import '../providers/health_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/weight_provider.dart';

class YearReviewScreen extends StatefulWidget {
  const YearReviewScreen({super.key});

  @override
  State<YearReviewScreen> createState() => _YearReviewScreenState();
}

class _YearReviewScreenState extends State<YearReviewScreen> {
  int _year = DateTime.now().year;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      if (pets.isNotEmpty) {
        setState(() => _selectedPetId = pets.first.id);
        context.read<OwnerHealthProvider>().loadForPet(pets.first.id);
        context.read<WeightProvider>().loadForPet(pets.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    final selectedPet = _selectedPetId != null
        ? pets.where((p) => p.id == _selectedPetId).firstOrNull
        : null;

    final apptProvider = context.watch<AppointmentProvider>();
    final healthProvider = context.watch<OwnerHealthProvider>();
    final weightProvider = context.watch<WeightProvider>();

    // Filterung auf ausgewähltes Jahr
    final yearAppts = apptProvider.appointments.where((a) {
      return a.petId == _selectedPetId && a.scheduledAt.year == _year;
    }).toList();

    final yearVaccinations = healthProvider.selectedPetId == _selectedPetId
        ? healthProvider.vaccinations.where((v) {
            final dt = v.administeredAt;
            return dt?.year == _year;
          }).toList()
        : [];

    final yearWeights = weightProvider.selectedPetId == _selectedPetId
        ? weightProvider.entries.where((w) => w.recordedAt.year == _year).toList()
        : <WeightEntry>[];

    final completedAppts = yearAppts
        .where((a) => a.status == AppointmentStatus.completed)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jahresrückblick', style: Theme.of(context).textTheme.displaySmall),
                    Text(
                      'Ein Überblick über das Tierjahr $_year.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              // Year selector
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text('$_year',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _year < DateTime.now().year
                        ? () => setState(() => _year++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pet selector
          if (pets.isNotEmpty)
            Wrap(
              spacing: 8,
              children: pets.map((p) => FilterChip(
                    label: Text(p.name),
                    selected: _selectedPetId == p.id,
                    onSelected: (_) {
                      setState(() => _selectedPetId = p.id);
                      context.read<OwnerHealthProvider>().loadForPet(p.id);
                      context.read<WeightProvider>().loadForPet(p.id);
                    },
                  )).toList(),
            ),
          const SizedBox(height: 24),

          if (selectedPet == null)
            const Text('Kein Tier gewählt.')
          else ...[
            // Hero-Stats
            _HeroStats(
              pet: selectedPet,
              year: _year,
              appointmentCount: yearAppts.length,
              completedCount: completedAppts,
              vaccinationCount: yearVaccinations.length,
              weightMeasurements: yearWeights.length,
            ),
            const SizedBox(height: 24),

            // Monthly appointment calendar
            if (yearAppts.isNotEmpty) ...[
              Text('Termine nach Monat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _MonthlyBarChart(appointments: yearAppts, year: _year),
              const SizedBox(height: 24),
            ],

            // Weight progress
            if (yearWeights.length >= 2) ...[
              Text('Gewichtsverlauf',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _WeightSummary(entries: yearWeights),
              const SizedBox(height: 24),
            ],

            // Summary text
            _SummaryText(
              pet: selectedPet,
              year: _year,
              appointmentCount: yearAppts.length,
              completedCount: completedAppts,
              vaccinationCount: yearVaccinations.length,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  final Pet pet;
  final int year;
  final int appointmentCount;
  final int completedCount;
  final int vaccinationCount;
  final int weightMeasurements;

  const _HeroStats({
    required this.pet,
    required this.year,
    required this.appointmentCount,
    required this.completedCount,
    required this.vaccinationCount,
    required this.weightMeasurements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LivingLedgerTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pet.speciesIcon} ${pet.name} in $year',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _HeroChip(value: '$appointmentCount', label: 'Termine'),
              _HeroChip(value: '$completedCount', label: 'Abgeschlossen'),
              _HeroChip(value: '$vaccinationCount', label: 'Impfungen'),
              _HeroChip(value: '$weightMeasurements', label: 'Gewichtsmessungen'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final String value;
  final String label;
  const _HeroChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style:
                  TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
        ],
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List appointments;
  final int year;

  const _MonthlyBarChart({required this.appointments, required this.year});

  @override
  Widget build(BuildContext context) {
    final byMonth = List.filled(12, 0);
    for (final a in appointments) {
      byMonth[a.scheduledAt.month - 1]++;
    }
    final maxVal = byMonth.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (i) {
          final count = byMonth[i];
          final height = maxVal == 0 ? 0.0 : (count / maxVal * 50).toDouble();
          final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                    height: height.clamp(4.0, 50.0),
                    decoration: BoxDecoration(
                      color: LivingLedgerTheme.primary
                          .withValues(alpha: count == 0 ? 0.1 : 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(months[i],
                      style: TextStyle(
                          fontSize: 9, color: LivingLedgerTheme.onSurfaceVariant)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WeightSummary extends StatelessWidget {
  final List<WeightEntry> entries;
  const _WeightSummary({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries.first;
    final last = entries.last;
    final diff = last.weightKg - first.weightKg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_rounded,
              color: LivingLedgerTheme.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${first.weightKg.toStringAsFixed(1)} kg → ${last.weightKg.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg im Jahr · ${entries.length} Messungen',
                style: TextStyle(
                    fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final Pet pet;
  final int year;
  final int appointmentCount;
  final int completedCount;
  final int vaccinationCount;

  const _SummaryText({
    required this.pet,
    required this.year,
    required this.appointmentCount,
    required this.completedCount,
    required this.vaccinationCount,
  });

  @override
  Widget build(BuildContext context) {
    String text;
    if (appointmentCount == 0 && vaccinationCount == 0) {
      text = '${pet.name} hatte in $year ein ruhiges Jahr ohne Tierarztbesuche. 🌟';
    } else if (appointmentCount > 5) {
      text = 'Ein aktives Jahr für ${pet.name}! $appointmentCount Termine sprechen für sich. 💪';
    } else {
      text = '${pet.name} hat $year gut überstanden: $appointmentCount Termine, $vaccinationCount Impfungen. Gut gemacht! 🐾';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
    );
  }
}
