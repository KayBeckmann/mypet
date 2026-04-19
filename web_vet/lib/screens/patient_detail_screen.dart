import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/medical_provider.dart';

class PatientDetailScreen extends StatefulWidget {
  final String petId;
  const PatientDetailScreen({super.key, required this.petId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalProvider>().loadForPet(widget.petId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Medizinischer Eintrag anlegen ──
  Future<void> _addRecord() async {
    final titleCtrl = TextEditingController();
    final diagCtrl = TextEditingController();
    final treatCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String recordType = 'checkup';
    bool isPrivate = false;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neuer Eintrag'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: recordType,
                      decoration: const InputDecoration(labelText: 'Typ'),
                      items: const [
                        DropdownMenuItem(value: 'checkup', child: Text('Untersuchung')),
                        DropdownMenuItem(value: 'diagnosis', child: Text('Diagnose')),
                        DropdownMenuItem(value: 'treatment', child: Text('Behandlung')),
                        DropdownMenuItem(value: 'surgery', child: Text('Operation')),
                        DropdownMenuItem(value: 'lab_result', child: Text('Laborbefund')),
                        DropdownMenuItem(value: 'prescription', child: Text('Rezept')),
                        DropdownMenuItem(value: 'observation', child: Text('Beobachtung')),
                        DropdownMenuItem(value: 'other', child: Text('Sonstiges')),
                      ],
                      onChanged: (v) => setDs(() => recordType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Titel *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Titel erforderlich'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Beschreibung'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: diagCtrl,
                        decoration: const InputDecoration(labelText: 'Diagnose'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: treatCtrl,
                        decoration: const InputDecoration(labelText: 'Behandlung'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Privat (nur für Tierärzte)'),
                      value: isPrivate,
                      onChanged: (v) => setDs(() => isPrivate = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Eintragen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MedicalProvider>().createRecord(widget.petId, {
        'title': titleCtrl.text.trim(),
        'record_type': recordType,
        'description': descCtrl.text.trim(),
        'diagnosis': diagCtrl.text.trim(),
        'treatment': treatCtrl.text.trim(),
        'is_private': isPrivate,
      });
    }
  }

  // ── Impfung eintragen ──
  Future<void> _addVaccination() async {
    final nameCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final manuCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? validUntil;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Impfung eintragen'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Impfstoff *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pflichtfeld'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: batchCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Chargennummer')),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: manuCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Hersteller')),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(validUntil != null
                          ? 'Gültig bis: ${DateFormat('dd.MM.yyyy').format(validUntil!)}'
                          : 'Gültig bis (optional)'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now()
                              .add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 10)),
                        );
                        if (d != null) setDs(() => validUntil = d);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: notesCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Notizen'),
                        maxLines: 2),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Eintragen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MedicalProvider>().createVaccination(widget.petId, {
        'vaccine_name': nameCtrl.text.trim(),
        'batch_number': batchCtrl.text.trim(),
        'manufacturer': manuCtrl.text.trim(),
        if (validUntil != null)
          'valid_until': validUntil!.toIso8601String().substring(0, 10),
        'notes': notesCtrl.text.trim(),
      });
    }
  }

  // ── Medikament verordnen ──
  Future<void> _addMedication() async {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
    String frequency = 'daily';
    DateTime? endDate;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Medikament verordnen'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration:
                          const InputDecoration(labelText: 'Medikament *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Pflichtfeld'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: dosageCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Dosierung',
                            hintText: 'z.B. 1 Tablette à 50mg')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: frequency,
                      decoration: const InputDecoration(labelText: 'Häufigkeit'),
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Einmalig')),
                        DropdownMenuItem(value: 'daily', child: Text('Täglich')),
                        DropdownMenuItem(value: 'twice_daily', child: Text('2x täglich')),
                        DropdownMenuItem(value: 'three_times_daily', child: Text('3x täglich')),
                        DropdownMenuItem(value: 'weekly', child: Text('Wöchentlich')),
                        DropdownMenuItem(value: 'as_needed', child: Text('Bei Bedarf')),
                      ],
                      onChanged: (v) => setDs(() => frequency = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: instrCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Anweisungen',
                            hintText: 'z.B. mit Futter verabreichen'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event_busy, size: 16),
                      label: Text(endDate != null
                          ? 'Bis: ${DateFormat('dd.MM.yyyy').format(endDate!)}'
                          : 'Enddatum (optional)'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (d != null) setDs(() => endDate = d);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Verordnen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MedicalProvider>().createMedication(widget.petId, {
        'name': nameCtrl.text.trim(),
        'dosage': dosageCtrl.text.trim(),
        'frequency': frequency,
        'instructions': instrCtrl.text.trim(),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medical = context.watch<MedicalProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: VetTheme.primary,
        foregroundColor: VetTheme.onPrimary,
        title: const Text('Patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patients'),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Akte'),
            Tab(text: 'Impfungen'),
            Tab(text: 'Medikamente'),
          ],
        ),
      ),
      body: medical.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _RecordsTab(
                    records: medical.records,
                    dateFormat: _dateFormat,
                    onAdd: _addRecord),
                _VaccinationsTab(
                    vaccinations: medical.vaccinations,
                    dateFormat: _dateFormat,
                    onAdd: _addVaccination),
                _MedicationsTab(
                    medications: medical.medications,
                    onAdd: _addMedication),
              ],
            ),
    );
  }
}

// ── Akte Tab ──
class _RecordsTab extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final DateFormat dateFormat;
  final VoidCallback onAdd;

  const _RecordsTab(
      {required this.records, required this.dateFormat, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Eintrag'),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('Keine Einträge vorhanden'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: VetTheme.spacingMd),
                  itemCount: records.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: VetTheme.spacingSm),
                  itemBuilder: (context, i) {
                    final r = records[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(VetTheme.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _RecordTypeBadge(r['record_type'] as String?),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(r['title'] as String? ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ),
                                if (r['is_private'] == true)
                                  const Icon(Icons.lock_outline,
                                      size: 16,
                                      color: VetTheme.onSurfaceVariant),
                              ],
                            ),
                            if (r['diagnosis'] != null &&
                                (r['diagnosis'] as String).isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Diagnose: ${r['diagnosis']}',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                            if (r['treatment'] != null &&
                                (r['treatment'] as String).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Behandlung: ${r['treatment']}',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${r['vet_name'] ?? 'Unbekannt'} · ${_fmtDate(r['recorded_at'], dateFormat)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: VetTheme.onSurfaceVariant),
                            ),
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

  String _fmtDate(dynamic raw, DateFormat fmt) {
    if (raw == null) return '';
    try {
      return fmt.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString().substring(0, 10);
    }
  }
}

class _RecordTypeBadge extends StatelessWidget {
  final String? type;
  const _RecordTypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'checkup' => 'Untersuchung',
      'diagnosis' => 'Diagnose',
      'treatment' => 'Behandlung',
      'surgery' => 'OP',
      'lab_result' => 'Labor',
      'prescription' => 'Rezept',
      'observation' => 'Beobachtung',
      _ => 'Sonstiges',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: VetTheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(VetTheme.radiusFull),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: VetTheme.primary)),
    );
  }
}

// ── Impfungen Tab ──
class _VaccinationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;
  final DateFormat dateFormat;
  final VoidCallback onAdd;

  const _VaccinationsTab(
      {required this.vaccinations,
      required this.dateFormat,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.vaccines, size: 18),
                label: const Text('Impfung'),
              ),
            ],
          ),
        ),
        Expanded(
          child: vaccinations.isEmpty
              ? const Center(child: Text('Keine Impfungen eingetragen'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: VetTheme.spacingMd),
                  itemCount: vaccinations.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: VetTheme.spacingSm),
                  itemBuilder: (context, i) {
                    final v = vaccinations[i];
                    final validUntil = v['valid_until'];
                    final isExpired = validUntil != null &&
                        DateTime.tryParse(validUntil.toString())
                                ?.isBefore(DateTime.now()) ==
                            true;
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.vaccines,
                            color: isExpired
                                ? VetTheme.tertiary
                                : VetTheme.secondary),
                        title: Text(v['vaccine_name'] as String? ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (v['manufacturer'] != null)
                              Text(v['manufacturer'] as String),
                            Text(
                              validUntil != null
                                  ? 'Gültig bis: ${_fmtDate(validUntil, dateFormat)}'
                                      '${isExpired ? ' (abgelaufen)' : ''}'
                                  : 'Unbegrenzt gültig',
                              style: TextStyle(
                                color: isExpired
                                    ? VetTheme.tertiary
                                    : VetTheme.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          _fmtDate(v['administered_at'], dateFormat),
                          style: const TextStyle(
                              fontSize: 12,
                              color: VetTheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _fmtDate(dynamic raw, DateFormat fmt) {
    if (raw == null) return '';
    try {
      return fmt.format(DateTime.parse(raw.toString()));
    } catch (_) {
      return raw.toString().length >= 10
          ? raw.toString().substring(0, 10)
          : raw.toString();
    }
  }
}

// ── Medikamente Tab ──
class _MedicationsTab extends StatelessWidget {
  final List<Map<String, dynamic>> medications;
  final VoidCallback onAdd;

  const _MedicationsTab(
      {required this.medications, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final active = medications.where((m) => m['is_active'] == true).toList();
    final inactive =
        medications.where((m) => m['is_active'] != true).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.medication, size: 18),
                label: const Text('Medikament'),
              ),
            ],
          ),
        ),
        Expanded(
          child: medications.isEmpty
              ? const Center(
                  child: Text('Keine Medikamente verordnet'))
              : ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: VetTheme.spacingMd),
                  children: [
                    if (active.isNotEmpty) ...[
                      Text('Aktiv',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: VetTheme.secondary,
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...active.map((m) => _MedCard(med: m)),
                      const SizedBox(height: 16),
                    ],
                    if (inactive.isNotEmpty) ...[
                      Text('Abgeschlossen',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: VetTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...inactive.map((m) => _MedCard(med: m)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _MedCard extends StatelessWidget {
  final Map<String, dynamic> med;
  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    final freq = _freqLabel(med['frequency'] as String? ?? '');
    return Card(
      margin: const EdgeInsets.only(bottom: VetTheme.spacingSm),
      child: ListTile(
        leading: const Icon(Icons.medication, color: VetTheme.primary),
        title: Text(med['name'] as String? ?? ''),
        subtitle: Text([
          if (med['dosage'] != null) med['dosage'] as String,
          freq,
        ].join(' · ')),
        trailing: med['is_active'] == true
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VetTheme.secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(VetTheme.radiusFull),
                ),
                child: const Text('Aktiv',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: VetTheme.secondary)),
              )
            : null,
      ),
    );
  }

  String _freqLabel(String f) {
    return switch (f) {
      'once' => 'Einmalig',
      'daily' => 'Täglich',
      'twice_daily' => '2x täglich',
      'three_times_daily' => '3x täglich',
      'weekly' => 'Wöchentlich',
      'biweekly' => '2-wöchentlich',
      'monthly' => 'Monatlich',
      'as_needed' => 'Bei Bedarf',
      _ => f,
    };
  }
}
