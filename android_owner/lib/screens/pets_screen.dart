import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/health_provider.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MobilePetProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MobilePetProvider>();
    final pets = provider.pets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Tiere'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: provider.load,
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : pets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pets_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Keine Tiere vorhanden',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: pets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _PetCard(pet: pets[i]),
                  ),
                ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final MobilePet pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(pet.speciesEmoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pet.speciesLabel}${pet.breed.isNotEmpty ? ' · ${pet.breed}' : ''}',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if (pet.ageYears != null || pet.weightKg != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (pet.ageYears != null)
                            _Tag(
                                icon: Icons.cake_outlined,
                                label: '${pet.ageYears} J.',
                                color: cs.secondary),
                          if (pet.weightKg != null)
                            _Tag(
                                icon: Icons.monitor_weight_outlined,
                                label:
                                    '${pet.weightKg!.toStringAsFixed(1)} kg',
                                color: cs.tertiary),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

// ── Pet Detail Screen ──────────────────────────────────────────────────────

class PetDetailScreen extends StatefulWidget {
  final MobilePet pet;
  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  final _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final petProvider = context.read<MobilePetProvider>();
    final medProvider = context.read<MobileMedicationProvider>();
    final weightProvider = context.read<MobileWeightProvider>();
    final healthProvider = context.read<MobileHealthProvider>();
    final petId = widget.pet.id;

    final results = await Future.wait([
      petProvider.loadVaccinations(petId),
      petProvider.loadRecords(petId),
    ]);

    await Future.wait([
      medProvider.loadForPet(petId),
      weightProvider.loadForPet(petId),
      healthProvider.loadForPet(petId),
    ]);

    if (mounted) {
      setState(() {
        _vaccinations = results[0];
        _records = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pet = widget.pet;
    final medications = context.watch<MobileMedicationProvider>().forPet(pet.id);
    final weightEntries = context.watch<MobileWeightProvider>().forPet(pet.id);
    final healthProvider = context.watch<MobileHealthProvider>();
    final stats = healthProvider.statsForPet(pet.id);
    final healthScore = stats?['health_score'] as int?;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 60),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 18)),
                  if (healthScore != null)
                    Text(
                      'Gesundheits-Score: $healthScore/100',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.secondary],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 24,
                      top: 48,
                      child: Text(pet.speciesEmoji,
                          style: const TextStyle(fontSize: 72)),
                    ),
                    if (pet.breed.isNotEmpty)
                      Positioned(
                        left: 16,
                        bottom: 72,
                        child: Text(pet.breed,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ),
                    if (pet.ageYears != null)
                      Positioned(
                        left: 16,
                        bottom: 55,
                        child: Text('${pet.ageYears} Jahre',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12)),
                      ),
                    if (healthScore != null)
                      Positioned(
                        left: 16,
                        bottom: 68,
                        right: 16,
                        child: LinearProgressIndicator(
                          value: healthScore / 100,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(
                            healthScore >= 80
                                ? Colors.greenAccent
                                : healthScore >= 50
                                    ? Colors.orangeAccent
                                    : Colors.redAccent,
                          ),
                          minHeight: 4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: const [
                Tab(icon: Icon(Icons.vaccines_rounded, size: 18), text: 'Impfungen'),
                Tab(icon: Icon(Icons.medication_rounded, size: 18), text: 'Medikamente'),
                Tab(icon: Icon(Icons.folder_rounded, size: 18), text: 'Akte'),
                Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Allergien'),
                Tab(icon: Icon(Icons.biotech_outlined, size: 18), text: 'Labor'),
                Tab(icon: Icon(Icons.monitor_weight_rounded, size: 18), text: 'Gewicht'),
                Tab(icon: Icon(Icons.notes_rounded, size: 18), text: 'Notizen'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _VaccinationsTab(vaccinations: _vaccinations, fmt: _fmt),
                  _MedicationsTab(
                    pet: pet,
                    medications: medications,
                    fmt: _fmt,
                  ),
                  _RecordsTab(records: _records, fmt: _fmt),
                  _AllergiesTab(
                    allergies: healthProvider.allergiesForPet(pet.id),
                  ),
                  _LabResultsTab(
                    labResults: healthProvider.labResultsForPet(pet.id),
                    fmt: _fmt,
                  ),
                  _WeightTab(
                    pet: pet,
                    entries: weightEntries,
                    fmt: _fmt,
                  ),
                  _NotesTab(
                    pet: pet,
                    notes: healthProvider.notesForPet(pet.id),
                    fmt: _fmt,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Tab: Impfungen ────────────────────────────────────────────────────────

class _VaccinationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;
  final DateFormat fmt;
  const _VaccinationsTab({required this.vaccinations, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (vaccinations.isEmpty) {
      return const Center(child: Text('Keine Impfungen eingetragen'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vaccinations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final v = vaccinations[i];
        final validUntil = v['valid_until'] != null
            ? DateTime.tryParse(v['valid_until'] as String)
            : null;
        final daysLeft =
            validUntil?.difference(DateTime.now()).inDays;
        final isExpired = daysLeft != null && daysLeft < 0;
        final isExpiring =
            daysLeft != null && daysLeft >= 0 && daysLeft <= 30;

        Color statusColor = Colors.green;
        if (isExpired) statusColor = Colors.red;
        if (isExpiring) statusColor = Colors.orange;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Icon(Icons.vaccines_rounded, color: statusColor, size: 20),
          ),
          title: Text(v['vaccine_name'] as String? ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (v['manufacturer'] != null)
                Text(v['manufacturer'] as String,
                    style: const TextStyle(fontSize: 12)),
              Text(
                [
                  'Am: ${fmt.format(DateTime.parse(v['vaccinated_at'] as String))}',
                  if (validUntil != null)
                    isExpired
                        ? 'Abgelaufen!'
                        : 'Bis: ${fmt.format(validUntil)}',
                ].join(' · '),
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
          ),
          trailing: daysLeft != null && !isExpired
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired ? 'Abgelaufen' : '${daysLeft}d',
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ── Tab: Medikamente ──────────────────────────────────────────────────────

class _MedicationsTab extends StatelessWidget {
  final MobilePet pet;
  final List<MobileMedication> medications;
  final DateFormat fmt;
  const _MedicationsTab({
    required this.pet,
    required this.medications,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final active = medications.where((m) => m.isActive).toList();
    final inactive = medications.where((m) => !m.isActive).toList();

    if (medications.isEmpty) {
      return const Center(child: Text('Keine Medikamente verordnet'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Text('Aktiv',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary)),
          const SizedBox(height: 8),
          ...active.map((m) => _MedCard(pet: pet, med: m, fmt: fmt)),
          const SizedBox(height: 16),
        ],
        if (inactive.isNotEmpty) ...[
          Text('Abgeschlossen',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...inactive.map((m) => _MedCard(pet: pet, med: m, fmt: fmt)),
        ],
      ],
    );
  }
}

class _MedCard extends StatefulWidget {
  final MobilePet pet;
  final MobileMedication med;
  final DateFormat fmt;
  const _MedCard({required this.pet, required this.med, required this.fmt});

  @override
  State<_MedCard> createState() => _MedCardState();
}

class _MedCardState extends State<_MedCard> {
  bool _administering = false;

  Future<void> _administer() async {
    setState(() => _administering = true);
    final ok = await context
        .read<MobileMedicationProvider>()
        .administer(widget.pet.id, widget.med.id);
    setState(() => _administering = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '${widget.med.name} als gegeben markiert ✓'
              : 'Fehler beim Speichern'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = widget.med;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  child: const Icon(Icons.medication_rounded,
                      color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(
                        [
                          if (m.dosage != null) m.dosage!,
                          m.frequencyLabel,
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (m.endsSoon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Bald fertig',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            if (m.endDate != null || m.instructions != null) ...[
              const SizedBox(height: 8),
              if (m.endDate != null)
                Text('Bis: ${widget.fmt.format(m.endDate!)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              if (m.instructions != null)
                Text(m.instructions!,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
            if (m.isActive) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _administering ? null : _administer,
                      icon: _administering
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 16),
                      label:
                          Text(_administering ? 'Wird gespeichert…' : 'Gegeben'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await context
                          .read<MobileMedicationProvider>()
                          .skip(widget.pet.id, m.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Übersprungen')),
                        );
                      }
                    },
                    child: const Text('Übersprungen'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab: Medizinische Akte ────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final DateFormat fmt;
  const _RecordsTab({required this.records, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('Keine Einträge vorhanden'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final r = records[i];
        final type = r['record_type'] as String? ?? 'other';
        final (icon, color) = _typeStyle(type);
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(r['title'] as String? ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeLabel(type),
                    style:
                        TextStyle(fontSize: 12, color: color)),
                if (r['diagnosis'] != null)
                  Text('Diagnose: ${r['diagnosis']}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (r['recorded_at'] != null)
                  Text(fmt.format(DateTime.parse(r['recorded_at'] as String)),
                      style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }

  (IconData, Color) _typeStyle(String type) {
    return switch (type) {
      'checkup' => (Icons.medical_services_rounded, Colors.blue),
      'diagnosis' => (Icons.biotech_rounded, Colors.orange),
      'treatment' => (Icons.healing_rounded, Colors.green),
      'surgery' => (Icons.cut_rounded, Colors.red),
      'lab_result' => (Icons.science_rounded, Colors.purple),
      'vaccination' => (Icons.vaccines_rounded, Colors.teal),
      _ => (Icons.description_rounded, Colors.grey),
    };
  }

  String _typeLabel(String type) => switch (type) {
        'checkup' => 'Untersuchung',
        'diagnosis' => 'Diagnose',
        'treatment' => 'Behandlung',
        'surgery' => 'Operation',
        'lab_result' => 'Laborbefund',
        'vaccination' => 'Impfung',
        _ => 'Sonstiges',
      };
}

// ── Tab: Allergien ────────────────────────────────────────────────────────

class _AllergiesTab extends StatelessWidget {
  final List<Map<String, dynamic>> allergies;
  const _AllergiesTab({required this.allergies});

  @override
  Widget build(BuildContext context) {
    if (allergies.isEmpty) {
      return const Center(child: Text('Keine Allergien eingetragen'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allergies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final a = allergies[i];
        final severity = a['severity']?.toString() ?? 'mild';
        final color = switch (severity) {
          'severe' => Colors.red,
          'moderate' => Colors.orange,
          _ => Colors.green,
        };
        final label = switch (severity) {
          'severe' => 'Schwerwiegend',
          'moderate' => 'Moderat',
          _ => 'Leicht',
        };
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
            ),
            title: Text(a['allergen'] as String? ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([
              if (a['category'] != null) a['category'] as String,
              if (a['reaction'] != null) a['reaction'] as String,
            ].join(' · ')),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab: Laborbefunde ─────────────────────────────────────────────────────

class _LabResultsTab extends StatelessWidget {
  final List<Map<String, dynamic>> labResults;
  final DateFormat fmt;
  const _LabResultsTab({required this.labResults, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (labResults.isEmpty) {
      return const Center(child: Text('Keine Laborbefunde vorhanden'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: labResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final l = labResults[i];
        final isAbnormal = l['is_abnormal'] as bool? ?? false;
        final color = isAbnormal ? Colors.red : Colors.green;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isAbnormal
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Text(l['test_name'] as String? ?? '—',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([
              '${l['result_value'] ?? '—'}${l['unit'] != null ? ' ${l['unit']}' : ''}',
              if (l['reference_range'] != null) 'Ref: ${l['reference_range']}',
              if (l['tested_at'] != null)
                fmt.format(DateTime.parse(l['tested_at'] as String)),
            ].join(' · ')),
            trailing: isAbnormal
                ? const Icon(Icons.warning_rounded, color: Colors.red)
                : null,
          ),
        );
      },
    );
  }
}

// ── Tab: Gewicht ──────────────────────────────────────────────────────────

class _WeightTab extends StatefulWidget {
  final MobilePet pet;
  final List<MobileWeightEntry> entries;
  final DateFormat fmt;
  const _WeightTab({
    required this.pet,
    required this.entries,
    required this.fmt,
  });

  @override
  State<_WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<_WeightTab> {
  Future<void> _addWeight() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gewicht eintragen — ${widget.pet.name}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Gewicht in kg',
            hintText: 'z.B. 24.5',
            suffixText: 'kg',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final v = double.parse(ctrl.text.replaceAll(',', '.'));
      final ok = await context
          .read<MobileWeightProvider>()
          .addEntry(petId: widget.pet.id, weightKg: v);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '${v.toStringAsFixed(1)} kg gespeichert ✓' : 'Fehler'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (entries.isNotEmpty) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entries.last.weightKg.toStringAsFixed(1)} kg',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (entries.length >= 2)
                        Builder(builder: (context) {
                          final diff = entries.last.weightKg - entries[entries.length - 2].weightKg;
                          final color = diff > 0 ? Colors.red : diff < 0 ? Colors.blue : cs.onSurfaceVariant;
                          return Text(
                            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg seit letzter Messung',
                            style: TextStyle(color: color, fontSize: 13),
                          );
                        }),
                    ],
                  ),
                ),
              ] else
                Expanded(child: Text('Noch keine Messungen', style: TextStyle(color: cs.onSurfaceVariant))),
              FilledButton.icon(
                onPressed: _addWeight,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Messen'),
              ),
            ],
          ),
        ),
        if (entries.length >= 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 80,
              child: _WeightSparkline(entries: entries),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_weight_outlined,
                          size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Tippe auf „Messen" um eine Messung hinzuzufügen',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.reversed.toList().length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = entries.reversed.toList()[i];
                    return ListTile(
                      leading: const Icon(Icons.monitor_weight_outlined),
                      title: Text('${e.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(e.dateLabel),
                      trailing: e.notes != null
                          ? Text(e.notes!,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant))
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WeightSparkline extends StatelessWidget {
  final List<MobileWeightEntry> entries;
  const _WeightSparkline({required this.entries});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: entries.map((e) => e.weightKg).toList(),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a, b) => a < b ? a : b) - 0.5;
    final max = values.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = (max - min).clamp(0.1, double.infinity);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] - min) / range * size.height;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (var i = 0; i < values.length; i++) {
      final x = i * size.width / (values.length - 1);
      final y = size.height - (values[i] - min) / range * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ── Tab: Notizen ──────────────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  final MobilePet pet;
  final List<Map<String, dynamic>> notes;
  final DateFormat fmt;
  const _NotesTab({required this.pet, required this.notes, required this.fmt});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  Future<void> _addNote() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Notiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Inhalt'),
              maxLines: 3,
            ),
          ],
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
    );

    if (confirmed == true && context.mounted) {
      final ok = await context.read<MobileHealthProvider>().addNote(
            petId: widget.pet.id,
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Notiz gespeichert' : 'Fehler'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${widget.notes.length} Notiz${widget.notes.length == 1 ? '' : 'en'}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              FilledButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Notiz'),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notes_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text('Keine Notizen vorhanden',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = widget.notes[i];
                    final createdAt = n['created_at'] != null
                        ? widget.fmt.format(DateTime.parse(n['created_at'] as String))
                        : null;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'] as String? ?? '—',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if ((n['content'] as String?)?.isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(n['content'] as String,
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 13)),
                            ],
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(createdAt,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
