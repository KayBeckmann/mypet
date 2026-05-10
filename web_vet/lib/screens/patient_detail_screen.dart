// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/medical_provider.dart';
import '../providers/media_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/patients_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/allergy_provider.dart';
import '../providers/lab_result_provider.dart';

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
  List<Map<String, dynamic>> _weightEntries = [];
  List<Map<String, dynamic>> _feedingPlans = [];
  Map<String, dynamic>? _assignment;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 12, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicalProvider>().loadForPet(widget.petId);
      context.read<VetMediaProvider>().loadForPet(widget.petId);
      context.read<VetNotesProvider>().loadForPet(widget.petId);
      context.read<PrescriptionProvider>().loadForPet(widget.petId);
      context.read<VetAllergyProvider>().loadForPet(widget.petId);
      context.read<VetLabResultProvider>().loadForPet(widget.petId);
      _loadWeight();
      _loadFeeding();
      _loadAssignment();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadWeight() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/${widget.petId}/weight');
      if (mounted) {
        setState(() {
          _weightEntries = (data['entries'] as List? ?? [])
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAssignment() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/${widget.petId}/assignment');
      if (mounted) setState(() => _assignment = data['assignment'] as Map<String, dynamic>?);
    } catch (_) {}
  }

  Future<void> _loadFeeding() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/${widget.petId}/feeding-plans');
      if (mounted) {
        setState(() {
          _feedingPlans = (data['feeding_plans'] as List? ?? [])
              .cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  // ── Patientenzuweisung ──
  Future<void> _showAssignDialog(BuildContext context) async {
    final auth = context.read<VetAuthProvider>();
    final orgId = auth.activeOrganizationId;
    if (orgId == null) return;

    // Lade Teammitglieder
    List<Map<String, dynamic>> members = [];
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/organizations/$orgId/members');
      members = (data['members'] as List? ?? []).cast<Map<String, dynamic>>();
    } catch (_) {}

    if (!context.mounted) return;

    String? selectedUserId = _assignment?['assigned_to'] as String?;
    final noteCtrl = TextEditingController(text: _assignment?['note'] as String? ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Patient zuweisen'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: 'Zuständig',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Keine Zuweisung —')),
                    ...members.map((m) => DropdownMenuItem(
                          value: m['user_id'] as String?,
                          child: Text('${m['name'] ?? m['email'] ?? '?'} (${m['role'] ?? ''})'),
                        )),
                  ],
                  onChanged: (v) => setDs(() => selectedUserId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = context.read<ApiService>();
        if (selectedUserId == null) {
          await api.delete('/pets/${widget.petId}/assignment');
          setState(() => _assignment = null);
        } else {
          final data = await api.put('/pets/${widget.petId}/assignment', body: {
            'assigned_to': selectedUserId,
            if (noteCtrl.text.trim().isNotEmpty) 'note': noteCtrl.text.trim(),
          });
          setState(() => _assignment = data['assignment'] as Map<String, dynamic>?);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
        }
      }
    }
  }

  // ── Dossier drucken ──
  void _printDossier(BuildContext context, String petName, String? ownerName, MedicalProvider medical) {
    final vaccs = medical.vaccinations;
    final meds = medical.medications;
    final records = medical.records;

    String _fmtDate(dynamic d) {
      if (d == null) return '—';
      final dt = d is DateTime ? d : DateTime.tryParse(d.toString());
      if (dt == null) return d.toString();
      return '${dt.day}.${dt.month}.${dt.year}';
    }

    final vaccRows = vaccs.map((v) => '<tr><td>${v['vaccine_name'] ?? '—'}</td><td>${_fmtDate(v['vaccinated_at'])}</td><td>${_fmtDate(v['valid_until'])}</td></tr>').join('');
    final medRows = meds.map((m) => '<tr><td>${m['name'] ?? '—'}</td><td>${m['dosage'] ?? '—'}</td><td>${m['frequency'] ?? '—'}</td><td>${(m['is_active'] as bool? ?? true) ? 'Aktiv' : 'Beendet'}</td></tr>').join('');
    final recRows = records.take(10).map((r) => '<tr><td>${r['record_type'] ?? '—'}</td><td>${r['title'] ?? '—'}</td><td>${r['diagnosis'] ?? '—'}</td><td>${_fmtDate(r['created_at'])}</td></tr>').join('');

    final html_ = '''<!DOCTYPE html>
<html lang="de">
<head><meta charset="UTF-8"><title>Dossier — $petName</title>
<style>
body{font-family:Arial,sans-serif;font-size:12px;margin:20px}
h1{color:#386641;font-size:18px}h2{color:#386641;font-size:14px;border-bottom:1px solid #386641;padding-bottom:2px;margin-top:16px}
table{width:100%;border-collapse:collapse;margin-top:6px;font-size:11px}
th{background:#386641;color:white;padding:4px 6px;text-align:left}
td{border-bottom:1px solid #eee;padding:3px 6px}
.meta{font-size:11px;color:#666;margin-bottom:12px}
@media print{body{margin:0}}
</style></head>
<body>
<h1>🐾 Patientendossier — $petName</h1>
<div class="meta">Besitzer: ${ownerName ?? '—'} · Erstellt: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}</div>

<h2>Impfungen (${vaccs.length})</h2>
${vaccs.isEmpty ? '<p style="color:#999">Keine Impfungen</p>' : '<table><tr><th>Impfstoff</th><th>Datum</th><th>Gültig bis</th></tr>$vaccRows</table>'}

<h2>Aktive Medikamente (${meds.where((m) => m['is_active'] as bool? ?? true).length})</h2>
${meds.isEmpty ? '<p style="color:#999">Keine Medikamente</p>' : '<table><tr><th>Medikament</th><th>Dosierung</th><th>Häufigkeit</th><th>Status</th></tr>$medRows</table>'}

<h2>Med. Akte (letzte ${records.take(10).length} Einträge)</h2>
${records.isEmpty ? '<p style="color:#999">Keine Einträge</p>' : '<table><tr><th>Typ</th><th>Titel</th><th>Diagnose</th><th>Datum</th></tr>$recRows</table>'}

<div style="font-size:10px;color:#999;margin-top:24px;text-align:right">MyPet Vet — ${DateTime.now().year}</div>
</body></html>''';

    final blob = html.Blob([html_], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(milliseconds: 500), () {
      html.Url.revokeObjectUrl(url);
    });
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
      final provider = context.read<MedicalProvider>();
      await provider.createMedication(widget.petId, {
        'name': nameCtrl.text.trim(),
        'dosage': dosageCtrl.text.trim(),
        'frequency': frequency,
        'instructions': instrCtrl.text.trim(),
        if (endDate != null)
          'end_date': endDate!.toIso8601String().substring(0, 10),
      });
      if (provider.medicationWarning != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.medicationWarning!),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medical = context.watch<MedicalProvider>();
    final mediaProvider = context.watch<VetMediaProvider>();
    final notesProvider = context.watch<VetNotesProvider>();
    final prescProvider = context.watch<PrescriptionProvider>();
    final patientsProvider = context.watch<PatientsProvider>();
    final apptProvider = context.watch<VetAppointmentProvider>();
    final petAppointments = apptProvider.appointments
        .where((a) => a.petId == widget.petId)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final petData = patientsProvider.patients
        .where((p) => p['id'] == widget.petId)
        .firstOrNull;
    final petName = petData?['name'] as String? ?? 'Patient';
    final ownerName = petData?['owner_name'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: VetTheme.primary,
        foregroundColor: VetTheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(petName,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            if (ownerName != null)
              Text(
                'Besitzer: $ownerName',
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patients'),
        ),
        actions: [
          if (_assignment != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Chip(
                label: Text(_assignment!['assigned_to_name'] as String? ?? '?',
                    style: const TextStyle(fontSize: 11)),
                avatar: const Icon(Icons.person_rounded, size: 14),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                labelStyle: const TextStyle(color: Colors.white),
                side: BorderSide.none,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.assignment_ind_outlined),
            tooltip: 'Zuweisen',
            onPressed: () => _showAssignDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Dossier drucken',
            onPressed: () => _printDossier(context, petName, ownerName, medical),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Akte'),
            Tab(text: 'Impfungen'),
            Tab(text: 'Medikamente'),
            Tab(text: 'Rezepte'),
            Tab(text: 'Allergien'),
            Tab(text: 'Bildarchiv'),
            Tab(text: 'Notizen'),
            Tab(text: 'Compliance'),
            Tab(text: 'Termine'),
            Tab(text: 'Gewicht'),
            Tab(text: 'Fütterung'),
            Tab(text: 'Labor'),
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
                _PrescriptionsTab(
                    provider: prescProvider, petId: widget.petId),
                _AllergiesTab(petId: widget.petId),
                _MediaTab(provider: mediaProvider, petId: widget.petId),
                _NotesTab(provider: notesProvider),
                _ComplianceTab(medical: medical, petId: widget.petId),
                _AppointmentsTab(appointments: petAppointments),
                _WeightTab(
                    entries: _weightEntries,
                    dateFormat: _dateFormat,
                    onRefresh: _loadWeight),
                _FeedingTab(
                    plans: _feedingPlans, onRefresh: _loadFeeding),
                _LabResultsTab(petId: widget.petId),
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
              if (vaccinations.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _printVaccCert(context),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('Zertifikat'),
                ),
              const SizedBox(width: 8),
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

  void _printVaccCert(BuildContext context) {
    final rows = vaccinations.map((v) => '''
      <tr>
        <td>${v['vaccine_name'] ?? '—'}</td>
        <td>${v['manufacturer'] ?? '—'}</td>
        <td>${v['batch_number'] ?? '—'}</td>
        <td>${_fmtDate(v['vaccinated_at'], dateFormat)}</td>
        <td>${_fmtDate(v['valid_until'], dateFormat)}</td>
        <td>${v['vet_name'] ?? '—'}</td>
      </tr>
    ''').join('');

    final html_ = '<!DOCTYPE html><html lang="de"><head><meta charset="UTF-8"><title>Impf-Zertifikat</title>'
        '<style>body{font-family:Arial,sans-serif;font-size:12px;margin:24px}'
        'h1{color:#386641;font-size:18px}h2{font-size:14px;color:#386641;margin-top:16px;border-bottom:1px solid #386641}'
        'table{width:100%;border-collapse:collapse;margin-top:8px}'
        'th{background:#386641;color:white;padding:4px 8px;text-align:left}'
        'td{border-bottom:1px solid #eee;padding:4px 8px}</style></head><body>'
        '<h1>Impfbuch / Zertifikat</h1>'
        '<p style="font-size:11px;color:#666">Ausgestellt: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}</p>'
        '<h2>Impfungen (${vaccinations.length})</h2>'
        '<table><tr><th>Impfstoff</th><th>Hersteller</th><th>Charge</th><th>Datum</th><th>Gültig bis</th><th>Tierarzt</th></tr>'
        '$rows</table>'
        '<div style="margin-top:40px;font-size:10px;color:#999">MyPet Living Ledger</div>'
        '</body></html>';

    final blob = html.Blob([html_], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(milliseconds: 500), () {
      html.Url.revokeObjectUrl(url);
    });
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
                              onTap: () {
                                html.window.open(
                                    '$_apiBase${m.url}', '_blank');
                              },
                              child: Icon(
                                m.isImage
                                    ? Icons.open_in_new_rounded
                                    : Icons.download_rounded,
                                size: 14,
                                color: VetTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
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

// ── Compliance Tab ──
class _ComplianceTab extends StatefulWidget {
  final MedicalProvider medical;
  final String petId;

  const _ComplianceTab({required this.medical, required this.petId});

  @override
  State<_ComplianceTab> createState() => _ComplianceTabState();
}

class _ComplianceTabState extends State<_ComplianceTab> {
  @override
  void initState() {
    super.initState();
    // Load schedules for all active medications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final med in widget.medical.medications) {
        if (med['is_active'] == true) {
          final id = med['id'] as String?;
          if (id != null) {
            widget.medical.loadSchedule(widget.petId, id);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.medical.medications
        .where((m) => m['is_active'] == true)
        .toList();

    if (active.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 56, color: VetTheme.secondary),
            SizedBox(height: 16),
            Text('Keine aktiven Medikamente',
                style: TextStyle(fontSize: 16, color: VetTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(VetTheme.spacingMd),
      itemCount: active.length,
      separatorBuilder: (_, __) => const SizedBox(height: VetTheme.spacingMd),
      itemBuilder: (_, i) {
        final med = active[i];
        final medId = med['id'] as String? ?? '';
        final schedule = widget.medical.schedules[medId] ?? [];
        return _ComplianceCard(med: med, schedule: schedule);
      },
    );
  }
}

class _ComplianceCard extends StatelessWidget {
  final Map<String, dynamic> med;
  final List<Map<String, dynamic>> schedule;

  const _ComplianceCard({required this.med, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final given = schedule.where((s) => s['status'] == 'given').length;
    final total = schedule.length;
    final adherence = total > 0 ? (given / total * 100).round() : null;

    final Color adherenceColor;
    if (adherence == null) {
      adherenceColor = VetTheme.onSurfaceVariant;
    } else if (adherence >= 80) {
      adherenceColor = VetTheme.secondary;
    } else if (adherence >= 50) {
      adherenceColor = Colors.orange;
    } else {
      adherenceColor = VetTheme.tertiary;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(VetTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.medication, size: 20, color: VetTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med['name'] as String? ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      if (med['dosage'] != null)
                        Text(
                          med['dosage'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: VetTheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (adherence != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: adherenceColor.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(VetTheme.radiusFull),
                    ),
                    child: Text(
                      '$adherence%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: adherenceColor,
                      ),
                    ),
                  ),
              ],
            ),

            if (total > 0) ...[
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: given / total,
                  minHeight: 6,
                  backgroundColor: VetTheme.outlineVariant,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(adherenceColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$given von $total Gaben verabreicht',
                style: const TextStyle(
                    fontSize: 12, color: VetTheme.onSurfaceVariant),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Kein Verabreichungsprotokoll vorhanden',
                style: TextStyle(
                    fontSize: 12, color: VetTheme.onSurfaceVariant),
              ),
            ],

            // Last 7 schedule entries
            if (schedule.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text('Letzte Einträge',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: VetTheme.onSurfaceVariant,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              ...schedule.take(7).map((s) {
                final wasGiven = s['status'] == 'given';
                final scheduled = s['scheduled_at'] as String?;
                DateTime? dt;
                try {
                  if (scheduled != null) dt = DateTime.parse(scheduled);
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        wasGiven
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: wasGiven ? VetTheme.secondary : VetTheme.tertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dt != null
                            ? '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
                            : scheduled ?? '—',
                        style:
                            const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        wasGiven ? 'Gegeben' : 'Ausgelassen',
                        style: TextStyle(
                          fontSize: 11,
                          color: wasGiven
                              ? VetTheme.secondary
                              : VetTheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Termine Tab ──
class _AppointmentsTab extends StatelessWidget {
  final List<VetAppointment> appointments;
  const _AppointmentsTab({required this.appointments});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: VetTheme.onSurfaceVariant),
            SizedBox(height: 12),
            Text('Keine Termine',
                style: TextStyle(color: VetTheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(VetTheme.spacingMd),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = appointments[i];
        final statusColor = _apptColor(a.status);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: VetTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.timeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(a.dateLabel,
                        style: const TextStyle(
                            color: VetTheme.onSurfaceVariant, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(a.statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _apptColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.requested:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return VetTheme.secondary;
      case AppointmentStatus.completed:
        return VetTheme.primary;
      case AppointmentStatus.cancelled:
        return VetTheme.error;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}

// ── Gewicht Tab ──
class _WeightTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final DateFormat dateFormat;
  final VoidCallback onRefresh;

  const _WeightTab(
      {required this.entries,
      required this.dateFormat,
      required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monitor_weight_outlined,
                size: 48, color: VetTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Keine Gewichtsdaten',
                style: TextStyle(color: VetTheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Aktualisieren'),
              onPressed: onRefresh,
            ),
          ],
        ),
      );
    }

    final sorted = [...entries]
      ..sort((a, b) {
        final da = DateTime.tryParse(a['measured_at'] as String? ?? '') ??
            DateTime(0);
        final db = DateTime.tryParse(b['measured_at'] as String? ?? '') ??
            DateTime(0);
        return db.compareTo(da);
      });

    final weights = sorted
        .map((e) => (e['weight_kg'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final latestKg = weights.isNotEmpty ? weights.first : null;

    return Column(
      children: [
        if (latestKg != null)
          Container(
            margin: const EdgeInsets.all(VetTheme.spacingMd),
            padding: const EdgeInsets.all(VetTheme.spacingMd),
            decoration: BoxDecoration(
              color: VetTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(VetTheme.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_weight_rounded,
                    color: VetTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Aktuell: ${latestKg.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: VetTheme.primary),
                ),
                if (weights.length >= 2) ...[
                  const SizedBox(width: 16),
                  Builder(builder: (ctx) {
                    final diff = weights.first - weights[1];
                    final isUp = diff > 0;
                    return Row(
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 16,
                          color: isUp ? Colors.orange : VetTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? '+' : ''}${diff.toStringAsFixed(2)} kg',
                          style: TextStyle(
                              fontSize: 13,
                              color:
                                  isUp ? Colors.orange : VetTheme.secondary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: VetTheme.spacingMd),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = sorted[i];
              final kg = (e['weight_kg'] as num?)?.toDouble();
              final dt =
                  DateTime.tryParse(e['measured_at'] as String? ?? '');
              final note = e['notes'] as String?;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: VetTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monitor_weight_rounded,
                      size: 18, color: VetTheme.primary),
                ),
                title: Text(
                  kg != null ? '${kg.toStringAsFixed(2)} kg' : '—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: dt != null
                    ? Text(dateFormat.format(dt),
                        style: const TextStyle(fontSize: 12))
                    : null,
                trailing: note != null && note.isNotEmpty
                    ? Tooltip(
                        message: note,
                        child: const Icon(Icons.notes_rounded,
                            size: 16, color: VetTheme.onSurfaceVariant),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Labor Tab ──
class _LabResultsTab extends StatefulWidget {
  final String petId;
  const _LabResultsTab({required this.petId});

  @override
  State<_LabResultsTab> createState() => _LabResultsTabState();
}

class _LabResultsTabState extends State<_LabResultsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VetLabResultProvider>().loadForPet(widget.petId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VetLabResultProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Befund eintragen'),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : provider.results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.biotech_outlined,
                              size: 48, color: VetTheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('Keine Laborbefunde vorhanden',
                              style: TextStyle(
                                  color: VetTheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: VetTheme.spacingMd),
                      itemCount: provider.results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = provider.results[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: VetTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: r.isAbnormal
                                  ? VetTheme.error.withValues(alpha: 0.5)
                                  : VetTheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                r.isAbnormal
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: r.isAbnormal
                                    ? VetTheme.error
                                    : VetTheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(r.testName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        if (r.testCategory != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: VetTheme.secondary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(r.testCategory!,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: VetTheme.secondary)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: r.resultValue,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: r.isAbnormal
                                                    ? VetTheme.error
                                                    : VetTheme.onSurface),
                                          ),
                                          if (r.unit != null)
                                            TextSpan(
                                              text: ' ${r.unit}',
                                              style: TextStyle(
                                                  color: VetTheme
                                                      .onSurfaceVariant),
                                            ),
                                          if (r.referenceRange != null)
                                            TextSpan(
                                              text:
                                                  ' (Ref: ${r.referenceRange})',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: VetTheme
                                                      .onSurfaceVariant),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(r.dateLabel,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: VetTheme.onSurfaceVariant)),
                                    if (r.notes != null) ...[
                                      const SizedBox(height: 2),
                                      Text(r.notes!,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  VetTheme.onSurfaceVariant)),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                onPressed: () async {
                                  final ok = await provider.delete(
                                      widget.petId, r.id);
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content:
                                                Text('Fehler beim Löschen')));
                                  }
                                },
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

  Future<void> _showAddDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isAbnormal = false;
    DateTime selectedDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Laborbefund eintragen'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Test / Untersuchung *',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. Blutbild, Kreatinin',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Kategorie',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. Hämatologie, Nierenwerte',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: valueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ergebnis *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Einheit',
                            border: OutlineInputBorder(),
                            hintText: 'mg/dl',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Referenzbereich',
                      border: OutlineInputBorder(),
                      hintText: 'z.B. 0.5–1.2',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isAbnormal,
                    onChanged: (v) => setDs(() => isAbnormal = v ?? false),
                    title: const Text('Auffälliger Wert'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${selectedDate.day}.${selectedDate.month}.${selectedDate.year}'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setDs(() => selectedDate = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notizen',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty ||
                    valueCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Test und Ergebnis erforderlich')));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Eintragen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<VetLabResultProvider>().create(
            petId: widget.petId,
            testName: nameCtrl.text.trim(),
            testCategory: categoryCtrl.text.trim().isEmpty
                ? null
                : categoryCtrl.text.trim(),
            resultValue: valueCtrl.text.trim(),
            unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
            referenceRange:
                refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
            isAbnormal: isAbnormal,
            notes:
                notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            testedAt: selectedDate,
          );
    }
  }
}

// ── Fütterung Tab ──
class _FeedingTab extends StatelessWidget {
  final List<Map<String, dynamic>> plans;
  final VoidCallback onRefresh;

  const _FeedingTab({required this.plans, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final activePlans = plans.where((p) => p['is_active'] == true).toList();

    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu_rounded,
                size: 48, color: VetTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Kein Futterplan vorhanden',
                style: TextStyle(color: VetTheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Aktualisieren'),
              onPressed: onRefresh,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(VetTheme.spacingMd),
      itemCount: activePlans.isEmpty ? plans.length : activePlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final plan = activePlans.isEmpty ? plans[i] : activePlans[i];
        final meals = (plan['meals'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        return Container(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          decoration: BoxDecoration(
            color: VetTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(VetTheme.radiusMd),
            border: Border.all(color: VetTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded,
                      size: 18, color: VetTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan['name'] as String? ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (plan['is_active'] == true
                              ? VetTheme.secondary
                              : VetTheme.onSurfaceVariant)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan['is_active'] == true ? 'Aktiv' : 'Inaktiv',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: plan['is_active'] == true
                              ? VetTheme.secondary
                              : VetTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if ((plan['description'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(plan['description'] as String,
                    style: const TextStyle(
                        color: VetTheme.onSurfaceVariant, fontSize: 13)),
              ],
              if (meals.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...meals.map((meal) {
                  final components = (meal['components'] as List?)
                          ?.cast<Map<String, dynamic>>() ??
                      [];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 13,
                                color: VetTheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              meal['name'] as String? ?? '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if ((meal['time_of_day'] as String?)
                                    ?.isNotEmpty ==
                                true) ...[
                              const SizedBox(width: 8),
                              Text(
                                meal['time_of_day'] as String,
                                style: const TextStyle(
                                    color: VetTheme.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        ...components.map((c) => Padding(
                              padding: const EdgeInsets.only(left: 20, top: 2),
                              child: Text(
                                '• ${c['food_name']} '
                                '${c['amount_grams'] != null ? '${c['amount_grams']} ${c['unit'] ?? 'g'}' : ''}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: VetTheme.onSurfaceVariant),
                              ),
                            )),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Rezepte Tab ──
class _PrescriptionsTab extends StatefulWidget {
  final PrescriptionProvider provider;
  final String petId;

  const _PrescriptionsTab({required this.provider, required this.petId});

  @override
  State<_PrescriptionsTab> createState() => _PrescriptionsTabState();
}

class _PrescriptionsTabState extends State<_PrescriptionsTab> {
  Future<void> _showAddDialog() async {
    final drugCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int? durationDays;
    DateTime? validUntil;
    int refills = 0;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Rezept ausstellen'),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: drugCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Medikament *',
                        hintText: 'z.B. Amoxicillin 250mg',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dosageCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Dosierung',
                              hintText: 'z.B. 1 Tablette à 250mg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: freqCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Häufigkeit',
                              hintText: 'z.B. 2x täglich',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: durationDays?.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Dauer (Tage)',
                              hintText: 'z.B. 7',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) =>
                                durationDays = int.tryParse(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: refills.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Wiederholungen',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) =>
                                refills = int.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event, size: 16),
                      label: Text(validUntil != null
                          ? 'Gültig bis: ${validUntil!.day.toString().padLeft(2, '0')}.${validUntil!.month.toString().padLeft(2, '0')}.${validUntil!.year}'
                          : 'Gültigkeitsdatum (optional)'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 2)),
                        );
                        if (d != null) setDs(() => validUntil = d);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: instrCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Anwendungshinweise',
                        hintText: 'z.B. Nach dem Fressen geben',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notizen (intern)',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Rezept ausstellen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await widget.provider.create(
        petId: widget.petId,
        drugName: drugCtrl.text.trim(),
        dosage: dosageCtrl.text.trim().isNotEmpty
            ? dosageCtrl.text.trim()
            : null,
        frequency: freqCtrl.text.trim().isNotEmpty
            ? freqCtrl.text.trim()
            : null,
        durationDays: durationDays,
        instructions: instrCtrl.text.trim().isNotEmpty
            ? instrCtrl.text.trim()
            : null,
        validUntil: validUntil?.toIso8601String(),
        refillsRemaining: refills,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Rezept ausgestellt' : (widget.provider.error ?? 'Fehler')),
          backgroundColor: ok ? null : VetTheme.error,
        ));
      }
    }
  }

  Future<void> _confirmDelete(Prescription p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen'),
        content: Text('Rezept für „${p.drugName}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VetTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.provider.delete(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = widget.provider.prescriptions;
    final df = DateFormat('dd.MM.yyyy');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VetTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Rezept ausstellen'),
              ),
            ],
          ),
        ),
        if (widget.provider.isLoading)
          const Expanded(
              child: Center(child: CircularProgressIndicator()))
        else if (prescriptions.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48,
                      color: VetTheme.onSurfaceVariant
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('Keine Rezepte ausgestellt',
                      style: TextStyle(color: VetTheme.onSurfaceVariant)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: VetTheme.spacingMd,
                  vertical: VetTheme.spacingSm),
              itemCount: prescriptions.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: VetTheme.spacingSm),
              itemBuilder: (_, i) {
                final p = prescriptions[i];
                final expired = p.isExpired;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.receipt_long,
                      color: expired
                          ? VetTheme.onSurfaceVariant
                          : VetTheme.primary,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.drugName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: expired
                                  ? VetTheme.onSurfaceVariant
                                  : null,
                              decoration: expired
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (expired)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: VetTheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Abgelaufen',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: VetTheme.error)),
                          ),
                      ],
                    ),
                    subtitle: Text([
                      if (p.dosage != null) p.dosage!,
                      if (p.frequency != null) p.frequency!,
                      if (p.durationDays != null)
                        '${p.durationDays} Tage',
                      'Ausgestellt: ${df.format(p.issuedAt)}',
                      if (p.issuedByName != null) 'Dr. ${p.issuedByName}',
                      if (p.validUntil != null)
                        'Gültig bis: ${df.format(p.validUntil!)}',
                      if (p.refillsRemaining > 0)
                        '${p.refillsRemaining}× Wiederholung',
                    ].join(' · ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: VetTheme.error,
                      tooltip: 'Löschen',
                      onPressed: () => _confirmDelete(p),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Allergies Tab ─────────────────────────────────────────────────────────────

class _AllergiesTab extends StatelessWidget {
  final String petId;
  const _AllergiesTab({required this.petId});

  Future<void> _showAddDialog(BuildContext context) async {
    final allergenCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final reactionCtrl = TextEditingController();
    final diagCtrl = TextEditingController();
    String severity = 'moderate';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Allergie dokumentieren'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: allergenCtrl,
                  decoration: const InputDecoration(labelText: 'Allergen *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    hintText: 'Futter, Umwelt, Medikament ...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Schweregrad'),
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Leicht')),
                    DropdownMenuItem(value: 'moderate', child: Text('Mittel')),
                    DropdownMenuItem(value: 'severe', child: Text('Stark')),
                  ],
                  onChanged: (v) => setSt(() => severity = v ?? severity),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reactionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reaktion',
                    hintText: 'z.B. Juckreiz, Erbrechen, Atemnot',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: diagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosedatum (YYYY-MM-DD)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                final allergen = allergenCtrl.text.trim();
                if (allergen.isEmpty) return;
                final ok = await context.read<VetAllergyProvider>().add(
                      petId: petId,
                      allergen: allergen,
                      category: categoryCtrl.text.trim().isEmpty ? null : categoryCtrl.text.trim(),
                      severity: severity,
                      reaction: reactionCtrl.text.trim().isEmpty ? null : reactionCtrl.text.trim(),
                      diagnosedAt: diagCtrl.text.trim().isEmpty ? null : diagCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fehler beim Speichern')));
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VetAllergyProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Allergien & Unverträglichkeiten',
                  style: Theme.of(context).textTheme.titleMedium),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Eintragen'),
                onPressed: () => _showAddDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (provider.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (provider.allergies.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Keine Allergien dokumentiert',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.allergies.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final a = provider.allergies[i];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: a.severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      a.severityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: a.severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(a.allergen,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([
                    if (a.category != null) a.category!,
                    if (a.reaction != null) a.reaction!,
                    if (a.diagnosedAt != null) 'Diagnose: ${a.diagnosedAt}',
                    if (a.recordedByName != null) 'Eingetragen von ${a.recordedByName}',
                  ].join(' · ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final ok = await provider.delete(a.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fehler beim Löschen')));
                      }
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
