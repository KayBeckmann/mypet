// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/pet_provider.dart';
import '../services/api_service.dart';

class HealthPassportScreen extends StatefulWidget {
  const HealthPassportScreen({super.key});

  @override
  State<HealthPassportScreen> createState() => _HealthPassportScreenState();
}

class _HealthPassportScreenState extends State<HealthPassportScreen> {
  String? _selectedPetId;
  Map<String, dynamic>? _passport;
  bool _loading = false;
  String? _error;

  final _dateFmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      if (pets.isNotEmpty) {
        setState(() => _selectedPetId = pets.first.id);
        _loadPassport(pets.first.id);
      }
    });
  }

  Future<void> _loadPassport(String petId) async {
    setState(() {
      _loading = true;
      _error = null;
      _passport = null;
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/$petId/health-passport');
      setState(() => _passport = data['passport'] as Map<String, dynamic>?);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _printPassport() {
    if (_passport == null) return;
    final pet = _passport!['pet'] as Map<String, dynamic>;
    final owner = _passport!['owner'] as Map<String, dynamic>;
    final vaccinations =
        (_passport!['vaccinations'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final allergies =
        (_passport!['allergies'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final medications =
        (_passport!['active_medications'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final labResults =
        (_passport!['lab_results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final contacts =
        (_passport!['emergency_contacts'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final latestWeight = _passport!['latest_weight'] as Map<String, dynamic>?;

    String _fmtDate(String? iso) {
      if (iso == null) return '—';
      try {
        return _dateFmt.format(DateTime.parse(iso));
      } catch (_) {
        return iso;
      }
    }

    final vacc = vaccinations.map((v) => '''
      <tr>
        <td>${v['vaccine_name'] ?? '—'}</td>
        <td>${_fmtDate(v['vaccinated_at'] as String?)}</td>
        <td>${_fmtDate(v['valid_until'] as String?)}</td>
        <td>${v['vet_name'] ?? '—'}</td>
        <td>${v['batch_number'] ?? '—'}</td>
      </tr>
    ''').join('');

    final alg = allergies.map((a) => '''
      <tr>
        <td>${a['allergen'] ?? '—'}</td>
        <td>${a['category'] ?? '—'}</td>
        <td style="color:${_severityColor(a['severity'] as String?)}">${a['severity'] ?? '—'}</td>
        <td>${a['reaction'] ?? '—'}</td>
      </tr>
    ''').join('');

    final meds = medications.map((m) => '''
      <tr>
        <td>${m['medication_name'] ?? '—'}</td>
        <td>${m['dosage'] ?? '—'}</td>
        <td>${m['frequency']?.toString().replaceAll('_', ' ') ?? '—'}</td>
        <td>${_fmtDate(m['end_date'] as String?)}</td>
      </tr>
    ''').join('');

    final labs = labResults.map((l) => '''
      <tr>
        <td>${l['test_name'] ?? '—'}</td>
        <td>${l['test_category'] ?? '—'}</td>
        <td style="${(l['is_abnormal'] as bool? ?? false) ? 'color:red;font-weight:bold' : ''}">${l['result_value'] ?? '—'}${l['unit'] != null ? ' ${l['unit']}' : ''}</td>
        <td>${l['reference_range'] ?? '—'}</td>
        <td>${_fmtDate(l['tested_at'] as String?)}</td>
      </tr>
    ''').join('');

    final ctcts = contacts.map((c) => '''
      <tr>
        <td>${c['name'] ?? '—'}${(c['is_primary'] as bool? ?? false) ? ' ⭐' : ''}</td>
        <td>${c['relationship'] ?? '—'}</td>
        <td>${c['phone'] ?? '—'}</td>
        <td>${c['email'] ?? '—'}</td>
      </tr>
    ''').join('');

    final html_ = '''
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>Gesundheitspass — ${pet['name']}</title>
<style>
  body { font-family: Arial, sans-serif; font-size: 12px; margin: 20px; color: #222; }
  h1 { color: #204E2B; font-size: 20px; margin-bottom: 4px; }
  h2 { color: #204E2B; font-size: 14px; border-bottom: 1px solid #204E2B; padding-bottom: 3px; margin-top: 20px; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; }
  .pet-info { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 24px; margin-bottom: 16px; }
  .pet-info span { font-size: 11px; color: #555; }
  .pet-info b { font-size: 12px; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 11px; }
  th { background: #204E2B; color: white; padding: 4px 6px; text-align: left; }
  td { border-bottom: 1px solid #eee; padding: 3px 6px; }
  tr:nth-child(even) td { background: #f9f9f9; }
  .generated { font-size: 10px; color: #999; margin-top: 24px; text-align: right; }
  @media print { body { margin: 0; } }
</style>
</head>
<body>
<div class="header">
  <div>
    <h1>🐾 Gesundheitspass</h1>
    <div style="font-size:18px;font-weight:bold;">${pet['name'] ?? '—'}</div>
  </div>
  <div style="text-align:right;font-size:11px;color:#555">
    Besitzer: ${owner['name'] ?? '—'}<br>
    ${owner['email'] ?? ''}
  </div>
</div>

<h2>Tier-Informationen</h2>
<div class="pet-info">
  <span>Tierart</span><b>${pet['species'] ?? '—'}</b>
  <span>Rasse</span><b>${pet['breed'] ?? '—'}</b>
  <span>Geburtsdatum</span><b>${_fmtDate(pet['birth_date'] as String?)}</b>
  <span>Chipnummer</span><b>${pet['chip_number'] ?? '—'}</b>
  <span>Farbe / Fell</span><b>${pet['color'] ?? '—'}</b>
  <span>Gewicht</span><b>${latestWeight != null ? '${latestWeight['weight_kg']} kg (${_fmtDate(latestWeight['recorded_at'] as String?)})' : (pet['weight_kg'] != null ? '${pet['weight_kg']} kg' : '—')}</b>
</div>

<h2>Impfungen (${vaccinations.length})</h2>
${vaccinations.isEmpty ? '<p style="color:#999">Keine Impfungen eingetragen</p>' : '''
<table>
  <tr><th>Impfstoff</th><th>Datum</th><th>Gültig bis</th><th>Tierarzt</th><th>Charge</th></tr>
  $vacc
</table>'''}

${allergies.isNotEmpty ? '''
<h2>Allergien &amp; Unverträglichkeiten (${allergies.length})</h2>
<table>
  <tr><th>Allergen</th><th>Kategorie</th><th>Schweregrad</th><th>Reaktion</th></tr>
  $alg
</table>''' : ''}

${medications.isNotEmpty ? '''
<h2>Aktive Medikamente (${medications.length})</h2>
<table>
  <tr><th>Medikament</th><th>Dosierung</th><th>Häufigkeit</th><th>Bis</th></tr>
  $meds
</table>''' : ''}

${labResults.isNotEmpty ? '''
<h2>Laborbefunde (letzte ${labResults.length})</h2>
<table>
  <tr><th>Test</th><th>Kategorie</th><th>Ergebnis</th><th>Referenz</th><th>Datum</th></tr>
  $labs
</table>''' : ''}

${contacts.isNotEmpty ? '''
<h2>Notfallkontakte</h2>
<table>
  <tr><th>Name</th><th>Beziehung</th><th>Telefon</th><th>E-Mail</th></tr>
  $ctcts
</table>''' : ''}

<div class="generated">Erstellt am: ${_fmtDate(_passport!['generated_at'] as String?)} — MyPet Living Ledger</div>
</body>
</html>''';

    final blob = html.Blob([html_], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final window = html.window.open(url, '_blank');
    Future.delayed(const Duration(milliseconds: 500), () {
      window?.print();
      html.Url.revokeObjectUrl(url);
    });
  }

  String _severityColor(String? severity) {
    switch (severity?.toString()) {
      case 'severe':
        return 'red';
      case 'moderate':
        return 'orange';
      default:
        return 'green';
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;

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
                    Text('Gesundheitspass',
                        style: Theme.of(context).textTheme.displaySmall),
                    Text(
                      'Druckfertige Übersicht aller Gesundheitsdaten.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (_passport != null)
                FilledButton.icon(
                  onPressed: _printPassport,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('Drucken / PDF'),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (pets.isEmpty)
            const Text('Keine Tiere vorhanden.')
          else ...[
            DropdownButtonFormField<String>(
              value: _selectedPetId ?? pets.first.id,
              decoration: const InputDecoration(
                labelText: 'Tier wählen',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: pets
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  setState(() => _selectedPetId = id);
                  _loadPassport(id);
                }
              },
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text('Fehler: $_error',
                  style: const TextStyle(color: Colors.red))
            else if (_passport != null)
              _PassportPreview(passport: _passport!, dateFmt: _dateFmt),
          ],
        ],
      ),
    );
  }
}

class _PassportPreview extends StatelessWidget {
  final Map<String, dynamic> passport;
  final DateFormat dateFmt;

  const _PassportPreview({required this.passport, required this.dateFmt});

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      return dateFmt.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = passport['pet'] as Map<String, dynamic>;
    final owner = passport['owner'] as Map<String, dynamic>;
    final vaccinations = (passport['vaccinations'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final allergies =
        (passport['allergies'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final medications = (passport['active_medications'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final labResults =
        (passport['lab_results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final contacts = (passport['emergency_contacts'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final latestWeight = passport['latest_weight'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LivingLedgerTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  (pet['species'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet['name'] as String? ?? '—',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    Text(
                        '${pet['species'] ?? ''} · ${pet['breed'] ?? ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14)),
                    if (pet['chip_number'] != null)
                      Text('Chip: ${pet['chip_number']}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Besitzer: ${owner['name'] ?? '—'}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12)),
                  if (pet['birth_date'] != null)
                    Text('Geb.: ${_fmtDate(pet['birth_date'] as String?)}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12)),
                  if (latestWeight != null)
                    Text(
                        '${latestWeight['weight_kg']} kg',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Vaccinations
        _Section(
          title: 'Impfungen',
          icon: Icons.vaccines_rounded,
          count: vaccinations.length,
          children: vaccinations.isEmpty
              ? [
                  const Text('Keine Impfungen eingetragen.',
                      style: TextStyle(color: Colors.grey))
                ]
              : vaccinations
                  .map((v) => _InfoRow(
                        leading: Icon(
                          DateTime.now().isBefore(
                                  DateTime.tryParse(
                                          v['valid_until'] as String? ?? '') ??
                                      DateTime(1970))
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          color: DateTime.now().isBefore(
                                  DateTime.tryParse(
                                          v['valid_until'] as String? ?? '') ??
                                      DateTime(1970))
                              ? LivingLedgerTheme.success
                              : LivingLedgerTheme.error,
                          size: 18,
                        ),
                        title: v['vaccine_name'] as String? ?? '—',
                        subtitle:
                            '${_fmtDate(v['vaccinated_at'] as String?)} · gültig bis ${_fmtDate(v['valid_until'] as String?)}',
                        trailing: v['vet_name'] as String?,
                      ))
                  .toList(),
        ),

        // Allergies
        if (allergies.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Allergien',
            icon: Icons.warning_amber_rounded,
            count: allergies.length,
            color: LivingLedgerTheme.error,
            children: allergies
                .map((a) => _InfoRow(
                      leading: Icon(Icons.dangerous_outlined,
                          color: LivingLedgerTheme.error, size: 18),
                      title: a['allergen'] as String? ?? '—',
                      subtitle:
                          '${a['severity'] ?? '—'} · ${a['reaction'] ?? ''}',
                    ))
                .toList(),
          ),
        ],

        // Medications
        if (medications.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Aktive Medikamente',
            icon: Icons.medication_rounded,
            count: medications.length,
            children: medications
                .map((m) => _InfoRow(
                      leading: const Icon(Icons.medication_liquid_outlined,
                          size: 18),
                      title: m['medication_name'] as String? ?? '—',
                      subtitle:
                          '${m['dosage'] ?? ''} · bis ${_fmtDate(m['end_date'] as String?)}',
                    ))
                .toList(),
          ),
        ],

        // Lab results
        if (labResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Laborbefunde',
            icon: Icons.biotech_outlined,
            count: labResults.length,
            children: labResults
                .map((l) => _InfoRow(
                      leading: Icon(
                        (l['is_abnormal'] as bool? ?? false)
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        color: (l['is_abnormal'] as bool? ?? false)
                            ? LivingLedgerTheme.error
                            : LivingLedgerTheme.success,
                        size: 18,
                      ),
                      title:
                          '${l['test_name']}: ${l['result_value']}${l['unit'] != null ? ' ${l['unit']}' : ''}',
                      subtitle: _fmtDate(l['tested_at'] as String?),
                    ))
                .toList(),
          ),
        ],

        // Emergency contacts
        if (contacts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Notfallkontakte',
            icon: Icons.emergency_rounded,
            count: contacts.length,
            children: contacts
                .map((c) => _InfoRow(
                      leading: Icon(
                        (c['is_primary'] as bool? ?? false)
                            ? Icons.star_rounded
                            : Icons.person_outline_rounded,
                        color: (c['is_primary'] as bool? ?? false)
                            ? Colors.amber
                            : null,
                        size: 18,
                      ),
                      title:
                          '${c['name']}${c['relationship'] != null ? ' (${c['relationship']})' : ''}',
                      subtitle: c['phone'] as String? ?? '—',
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final int count;
  final Color? color;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.count,
    this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? LivingLedgerTheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(icon, color: c, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: c, fontSize: 14)),
                const Spacer(),
                Text('$count',
                    style: TextStyle(
                        color: LivingLedgerTheme.onSurfaceVariant,
                        fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 16, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final String? trailing;

  const _InfoRow(
      {required this.leading,
      required this.title,
      this.subtitle,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11,
                          color: LivingLedgerTheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (trailing != null)
            Text(trailing!,
                style: TextStyle(
                    fontSize: 11,
                    color: LivingLedgerTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
