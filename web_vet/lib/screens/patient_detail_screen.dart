import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/medical_provider.dart';
import '../providers/media_provider.dart';
import '../providers/notes_provider.dart';

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
    _tabs = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalProvider>().loadForPet(widget.petId);
      context.read<VetMediaProvider>().loadForPet(widget.petId);
      context.read<VetNotesProvider>().loadForPet(widget.petId);
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
    final mediaProvider = context.watch<VetMediaProvider>();
    final notesProvider = context.watch<VetNotesProvider>();

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
            Tab(text: 'Bildarchiv'),
            Tab(text: 'Notizen'),
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
                _MediaTab(provider: mediaProvider, petId: widget.petId),
                _NotesTab(provider: notesProvider),
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

// ── Bildarchiv Tab ──
class _MediaTab extends StatelessWidget {
  final VetMediaProvider provider;
  final String petId;

  const _MediaTab({required this.provider, required this.petId});

  static const _apiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

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
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('Bild hochladen'),
                onPressed: () => _showUploadDialog(context),
              ),
            ],
          ),
        ),
        if (provider.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (provider.media.isEmpty)
          const Expanded(
            child: Center(child: Text('Keine Bilder vorhanden')),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: VetTheme.spacingMd,
                  vertical: VetTheme.spacingSm),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: provider.media.length,
              itemBuilder: (_, i) {
                final m = provider.media[i];
                final isXray = m.mediaType == 'xray';
                return Container(
                  decoration: BoxDecoration(
                    color: VetTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VetTheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(9)),
                          child: m.isImage
                              ? Image.network(
                                  '$_apiBase${m.url}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(isXray),
                                )
                              : _placeholder(isXray),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Bild löschen?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Abbrechen'),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Löschen'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (ok) provider.delete(m.id);
                              },
                              child: const Icon(Icons.delete_outline,
                                  size: 15,
                                  color: VetTheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _placeholder(bool isXray) {
    return Container(
      color: (isXray ? Colors.purple : VetTheme.primary)
          .withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          isXray
              ? Icons.medical_information_rounded
              : Icons.image_rounded,
          size: 44,
          color: (isXray ? Colors.purple : VetTheme.primary)
              .withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _showUploadDialog(BuildContext ctx2) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String mediaType = 'xray';
    bool isPrivate = true;
    List<int>? bytes;
    String? filename;

    await showDialog(
      context: ctx2,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Bild hochladen'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: mediaType,
                  decoration: const InputDecoration(labelText: 'Typ'),
                  items: const [
                    DropdownMenuItem(value: 'xray', child: Text('Röntgenbild')),
                    DropdownMenuItem(value: 'image', child: Text('Foto')),
                    DropdownMenuItem(value: 'document', child: Text('Dokument')),
                    DropdownMenuItem(value: 'other', child: Text('Sonstiges')),
                  ],
                  onChanged: (v) => setDs(() => mediaType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Privat'),
                  value: isPrivate,
                  onChanged: (v) => setDs(() => isPrivate = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(filename ?? 'Datei auswählen'),
                  onPressed: () async {
                    final result = await FilePicker.platform
                        .pickFiles(withData: true);
                    if (result != null && result.files.isNotEmpty) {
                      final f = result.files.first;
                      setDs(() {
                        filename = f.name;
                        bytes = f.bytes?.toList();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: bytes == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await provider.upload(
                        bytes: bytes!,
                        filename: filename!,
                        mediaType: mediaType,
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        isPrivate: isPrivate,
                      );
                    },
              child: const Text('Hochladen'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notizen Tab ──
class _NotesTab extends StatelessWidget {
  final VetNotesProvider provider;

  const _NotesTab({required this.provider});

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
                icon: const Icon(Icons.note_add_rounded, size: 18),
                label: const Text('Neue Notiz'),
                onPressed: () => _showCreateDialog(context),
              ),
            ],
          ),
        ),
        if (provider.loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (provider.notes.isEmpty)
          const Expanded(
            child: Center(child: Text('Keine Notizen vorhanden')),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: VetTheme.spacingMd,
                  vertical: VetTheme.spacingSm),
              itemCount: provider.notes.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: VetTheme.spacingSm),
              itemBuilder: (_, i) {
                final note = provider.notes[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(VetTheme.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                note.title ?? 'Notiz',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            _VisibilityChip(note.visibility),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18,
                                  color: VetTheme.onSurfaceVariant),
                              tooltip: 'Löschen',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Notiz löschen?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                                context, false),
                                            child: const Text('Abbrechen'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(
                                                context, true),
                                            child: const Text('Löschen'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (ok) provider.delete(note.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(note.content,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '${note.authorName ?? 'Unbekannt'} · '
                          '${note.createdAt.day}.${note.createdAt.month}.${note.createdAt.year}',
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

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String visibility = 'private';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neue Notiz'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titel (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: visibility,
                  decoration:
                      const InputDecoration(labelText: 'Sichtbarkeit'),
                  items: const [
                    DropdownMenuItem(
                        value: 'private', child: Text('Nur ich')),
                    DropdownMenuItem(
                        value: 'colleagues', child: Text('Meine Kollegen')),
                    DropdownMenuItem(
                        value: 'all_professionals',
                        child: Text('Alle Fachkräfte')),
                  ],
                  onChanged: (v) => setDs(() => visibility = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await provider.create(
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  visibility: visibility,
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final String visibility;
  const _VisibilityChip(this.visibility);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (visibility) {
      'private' => ('Privat', Colors.grey),
      'colleagues' => ('Kollegen', VetTheme.secondary),
      'all_professionals' => ('Alle', VetTheme.primary),
      _ => (visibility, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VetTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
