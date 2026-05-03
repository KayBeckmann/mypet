import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

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
                                label: '${pet.weightKg!.toStringAsFixed(1)} kg',
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
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  final _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<MobilePetProvider>();
    final results = await Future.wait([
      provider.loadVaccinations(widget.pet.id),
      provider.loadMedications(widget.pet.id),
      provider.loadRecords(widget.pet.id),
    ]);
    if (mounted) {
      setState(() {
        _vaccinations = results[0];
        _medications = results[1];
        _records = results[2];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pet = widget.pet;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(pet.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(pet.speciesEmoji,
                      style: const TextStyle(fontSize: 64)),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Impfungen'),
                Tab(text: 'Medikamente'),
                Tab(text: 'Akte'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                children: [
                  _VaccinationsTab(
                      vaccinations: _vaccinations, fmt: _fmt),
                  _MedicationsTab(
                      medications: _medications, fmt: _fmt),
                  _RecordsTab(records: _records, fmt: _fmt),
                ],
              ),
      ),
    );
  }
}

class _VaccinationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;
  final DateFormat fmt;
  const _VaccinationsTab(
      {required this.vaccinations, required this.fmt});

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
        final isExpiring =
            validUntil != null &&
            validUntil.difference(DateTime.now()).inDays <= 30;
        return ListTile(
          leading: Icon(
            Icons.vaccines_rounded,
            color: isExpiring
                ? Theme.of(context).colorScheme.error
                : Colors.green,
          ),
          title: Text(v['vaccine_name'] as String? ?? '—'),
          subtitle: Text([
            if (v['manufacturer'] != null) v['manufacturer'] as String,
            'Am: ${fmt.format(DateTime.parse(v['administered_at'] as String))}',
            if (validUntil != null) 'Bis: ${fmt.format(validUntil)}',
          ].join(' · ')),
          trailing: isExpiring
              ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
              : null,
        );
      },
    );
  }
}

class _MedicationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> medications;
  final DateFormat fmt;
  const _MedicationsTab(
      {required this.medications, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final active = medications.where((m) => m['is_active'] == true).toList();
    final inactive = medications.where((m) => m['is_active'] != true).toList();

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
          ...active.map((m) => _MedTile(med: m, fmt: fmt)),
          const SizedBox(height: 16),
        ],
        if (inactive.isNotEmpty) ...[
          Text('Abgeschlossen',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...inactive.map((m) => _MedTile(med: m, fmt: fmt)),
        ],
      ],
    );
  }
}

class _MedTile extends StatelessWidget {
  final Map<String, dynamic> med;
  final DateFormat fmt;
  const _MedTile({required this.med, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.medication_rounded, color: Colors.purple),
      title: Text(med['name'] as String? ?? '—',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        if (med['dosage'] != null) med['dosage'] as String,
        if (med['frequency'] != null) med['frequency'] as String,
      ].join(' · ')),
      trailing: med['end_date'] != null
          ? Text(
              fmt.format(DateTime.parse(med['end_date'] as String)),
              style: TextStyle(
                  fontSize: 11,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
            )
          : null,
    );
  }
}

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
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final r = records[i];
        final type = r['record_type'] as String? ?? 'other';
        return ListTile(
          leading: _typeIcon(type),
          title: Text(r['title'] as String? ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text([
            _typeLabel(type),
            if (r['recorded_at'] != null)
              fmt.format(DateTime.parse(r['recorded_at'] as String)),
          ].join(' · ')),
        );
      },
    );
  }

  Widget _typeIcon(String type) {
    final (icon, color) = switch (type) {
      'checkup' => (Icons.medical_services_rounded, Colors.blue),
      'diagnosis' => (Icons.biotech_rounded, Colors.orange),
      'treatment' => (Icons.healing_rounded, Colors.green),
      'surgery' => (Icons.cut_rounded, Colors.red),
      'lab_result' => (Icons.science_rounded, Colors.purple),
      'vaccination' => (Icons.vaccines_rounded, Colors.teal),
      _ => (Icons.description_rounded, Colors.grey),
    };
    return Icon(icon, color: color);
  }

  String _typeLabel(String type) {
    return switch (type) {
      'checkup' => 'Untersuchung',
      'diagnosis' => 'Diagnose',
      'treatment' => 'Behandlung',
      'surgery' => 'Operation',
      'lab_result' => 'Laborbefund',
      'vaccination' => 'Impfung',
      'prescription' => 'Rezept',
      'observation' => 'Beobachtung',
      _ => 'Sonstiges',
    };
  }
}
