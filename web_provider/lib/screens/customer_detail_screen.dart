import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mypet_shared/shared.dart';
import '../config/theme.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/allergy_provider.dart';

/// Detailansicht eines Kunden-Tieres für den Dienstleister.
/// Zeigt Gesundheitsinfos (read-only) sowie eigene Notizen und Leistungen.
class CustomerDetailScreen extends StatefulWidget {
  final String petId;
  final String petName;

  const CustomerDetailScreen({
    super.key,
    required this.petId,
    required this.petName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _fmt = DateFormat('dd.MM.yyyy');

  // loaded data
  Map<String, dynamic>? _pet;
  List<Map<String, dynamic>> _vaccinations = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _feedingPlans = [];
  List<Map<String, dynamic>> _weightEntries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      context.read<ProviderNotesProvider>().loadForPet(widget.petId);
      context.read<ProviderAllergyProvider>().loadForPet(widget.petId);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.get('/pets/${widget.petId}/vaccinations'),
        api.get('/pets/${widget.petId}/medications'),
        api.get('/pets/${widget.petId}/records'),
        api.get('/pets/${widget.petId}/feeding-plans'),
        api.get('/pets/${widget.petId}/weight'),
      ]);
      setState(() {
        _vaccinations = (results[0]['vaccinations'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _medications = (results[1]['medications'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _records = (results[2]['records'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _feedingPlans = (results[3]['feeding_plans'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _weightEntries = (results[4]['entries'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      appBar: AppBar(
        backgroundColor: ProviderTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/customers'),
        ),
        title: Text(
          widget.petName,
          style: const TextStyle(
              fontWeight: FontWeight.w700, color: ProviderTheme.onSurface),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: ProviderTheme.primary,
          unselectedLabelColor: ProviderTheme.onSurfaceVariant,
          indicatorColor: ProviderTheme.primary,
          tabs: const [
            Tab(text: 'Übersicht'),
            Tab(text: 'Allergien'),
            Tab(text: 'Akte'),
            Tab(text: 'Meine Notizen'),
            Tab(text: 'Meine Leistungen'),
            Tab(text: 'Termine'),
            Tab(text: 'Gewicht'),
            Tab(text: 'Fütterung'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: ProviderTheme.error),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(
                      vaccinations: _vaccinations,
                      medications: _medications,
                      fmt: _fmt,
                    ),
                    _ProviderAllergiesTab(petId: widget.petId),
                    _RecordsTab(records: _records, fmt: _fmt),
                    _NotesTab(petId: widget.petId),
                    _ServicesTab(petId: widget.petId, fmt: _fmt),
                    _AppointmentsTab(petId: widget.petId),
                    _ProviderWeightTab(
                        entries: _weightEntries, fmt: _fmt),
                    _ProviderFeedingTab(plans: _feedingPlans),
                  ],
                ),
    );
  }
}

// ── Übersicht Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> vaccinations;
  final List<Map<String, dynamic>> medications;
  final DateFormat fmt;

  const _OverviewTab({
    required this.vaccinations,
    required this.medications,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final activeVacc = vaccinations
        .where((v) {
          final until = v['valid_until'] as String?;
          if (until == null) return true;
          return DateTime.tryParse(until)?.isAfter(DateTime.now()) ?? true;
        })
        .toList();

    final activeMeds = medications
        .where((m) => m['is_active'] == true)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ProviderTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vaccinations
          _SectionHeader(
            icon: Icons.vaccines_rounded,
            title: 'Impfungen (${activeVacc.length} gültig)',
          ),
          const SizedBox(height: 12),
          if (vaccinations.isEmpty)
            _EmptyHint(text: 'Keine Impfungen eingetragen')
          else
            ...vaccinations.map((v) {
              final until = v['valid_until'] as String?;
              DateTime? untilDt;
              if (until != null) untilDt = DateTime.tryParse(until);
              final expired = untilDt != null &&
                  untilDt.isBefore(DateTime.now());
              final soonExpiry = untilDt != null &&
                  !expired &&
                  untilDt.isBefore(
                      DateTime.now().add(const Duration(days: 30)));

              final color = expired
                  ? ProviderTheme.error
                  : soonExpiry
                      ? Colors.orange
                      : ProviderTheme.secondary;

              return _InfoRow(
                icon: Icons.circle,
                iconColor: color,
                iconSize: 8,
                title: v['vaccine_name'] as String? ?? '—',
                subtitle: untilDt != null
                    ? '${expired ? "Abgelaufen" : "Gültig"} bis ${fmt.format(untilDt)}'
                    : 'Kein Ablaufdatum',
              );
            }),

          const SizedBox(height: ProviderTheme.spacingXl),

          // Active Medications
          _SectionHeader(
            icon: Icons.medication_rounded,
            title: 'Aktive Medikamente (${activeMeds.length})',
          ),
          const SizedBox(height: 12),
          if (activeMeds.isEmpty)
            _EmptyHint(text: 'Keine aktiven Medikamente')
          else
            ...activeMeds.map((m) => _InfoRow(
                  icon: Icons.medication_rounded,
                  iconColor: ProviderTheme.primary,
                  title: '${m['name']} ${m['dosage'] != null ? '· ${m['dosage']}' : ''}',
                  subtitle: _freqLabel(m['frequency'] as String? ?? ''),
                )),
        ],
      ),
    );
  }

  String _freqLabel(String f) {
    const map = {
      'once': 'Einmalig',
      'daily': '1× täglich',
      'twice_daily': '2× täglich',
      'three_times_daily': '3× täglich',
      'weekly': 'Wöchentlich',
      'biweekly': '2-wöchentlich',
      'monthly': 'Monatlich',
      'as_needed': 'Bei Bedarf',
    };
    return map[f] ?? f;
  }
}

// ── Akte Tab ──────────────────────────────────────────────────────────────────

class _RecordsTab extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final DateFormat fmt;

  const _RecordsTab({required this.records, required this.fmt});

  @override
  Widget build(BuildContext context) {
    // Only show non-private records
    final visible = records
        .where((r) => r['is_private'] != true)
        .toList();

    if (visible.isEmpty) {
      return const Center(
        child: _EmptyHint(text: 'Keine sichtbaren Einträge vorhanden'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ProviderTheme.spacingLg),
      itemCount: visible.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: ProviderTheme.spacingSm),
      itemBuilder: (_, i) {
        final r = visible[i];
        final rawDate = r['recorded_at'] as String?;
        final date = rawDate != null
            ? fmt.format(DateTime.parse(rawDate))
            : '—';

        return Container(
          padding: const EdgeInsets.all(ProviderTheme.spacingMd),
          decoration: BoxDecoration(
            color: ProviderTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ProviderTheme.radiusMd),
            border: Border.all(color: ProviderTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TypeBadge(type: r['record_type'] as String? ?? 'other'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['title'] as String? ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                        fontSize: 12,
                        color: ProviderTheme.onSurfaceVariant),
                  ),
                ],
              ),
              if ((r['description'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  r['description'] as String,
                  style: const TextStyle(
                      color: ProviderTheme.onSurfaceVariant),
                ),
              ],
              if (r['vet_name'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${r['vet_name']}${r['organization_name'] != null ? ' · ${r['organization_name']}' : ''}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: ProviderTheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final String petId;
  const _NotesTab({required this.petId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderNotesProvider>();

    return Padding(
      padding: const EdgeInsets.all(ProviderTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meine Notizen',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Notiz'),
                onPressed: () => _showAddNoteDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: ProviderTheme.spacingMd),

          if (provider.loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (provider.notes.isEmpty)
            const Expanded(
              child: Center(
                  child: _EmptyHint(text: 'Noch keine Notizen vorhanden')),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: provider.notes.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ProviderTheme.spacingSm),
                itemBuilder: (_, i) {
                  final n = provider.notes[i];
                  return _NoteCard(note: n, provider: provider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddNoteDialog(
      BuildContext context, ProviderNotesProvider provider) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String visibility = 'private';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neue Notiz'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Titel (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Inhalt *'),
                  maxLines: 4,
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
                        value: 'colleagues', child: Text('Kollegen')),
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && contentCtrl.text.trim().isNotEmpty) {
      await provider.create(
        title: titleCtrl.text.trim().isNotEmpty
            ? titleCtrl.text.trim()
            : null,
        content: contentCtrl.text.trim(),
        visibility: visibility,
      );
    }
  }
}

class _NoteCard extends StatelessWidget {
  final ProviderNote note;
  final ProviderNotesProvider provider;

  const _NoteCard({required this.note, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Container(
      padding: const EdgeInsets.all(ProviderTheme.spacingMd),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ProviderTheme.radiusMd),
        border: Border.all(color: ProviderTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.title != null && note.title!.isNotEmpty)
                Expanded(
                  child: Text(
                    note.title!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ProviderTheme.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(ProviderTheme.radiusFull),
                ),
                child: Text(
                  note.visibilityLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      color: ProviderTheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: ProviderTheme.error,
                onPressed: () => provider.delete(note.id),
                tooltip: 'Löschen',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(note.content),
          const SizedBox(height: 4),
          Text(
            fmt.format(note.createdAt),
            style: const TextStyle(
                fontSize: 11, color: ProviderTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Services Tab (own records for this pet) ───────────────────────────────────

class _ServicesTab extends StatefulWidget {
  final String petId;
  final DateFormat fmt;

  const _ServicesTab({required this.petId, required this.fmt});

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ApiService>();
      final auth = context.read<ProviderAuthProvider>();
      final data = await api.get('/pets/${widget.petId}/records');
      final myId = auth.user?.id;
      final all = (data['records'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        // Only show records created by the current user
        _services = myId != null
            ? all.where((r) => r['vet_id'] == myId).toList()
            : all;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addService(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'treatment';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Leistung erfassen'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration:
                      const InputDecoration(labelText: 'Art der Leistung'),
                  items: const [
                    DropdownMenuItem(
                        value: 'treatment', child: Text('Behandlung')),
                    DropdownMenuItem(
                        value: 'checkup', child: Text('Untersuchung')),
                    DropdownMenuItem(
                        value: 'surgery', child: Text('Eingriff')),
                    DropdownMenuItem(
                        value: 'other', child: Text('Sonstiges')),
                  ],
                  onChanged: (v) => setDs(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Titel *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Beschreibung'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: titleCtrl.text.trim().isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Erfassen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && titleCtrl.text.trim().isNotEmpty && mounted) {
      try {
        final api = context.read<ApiService>();
        await api.post('/pets/${widget.petId}/records', body: {
          'record_type': type,
          'title': titleCtrl.text.trim(),
          if (descCtrl.text.trim().isNotEmpty)
            'description': descCtrl.text.trim(),
          'is_private': false,
        });
        await _loadServices();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leistung gespeichert.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: ProviderTheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ProviderTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Erbrachte Leistungen',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Leistung'),
                onPressed: () => _addService(context),
              ),
            ],
          ),
          const SizedBox(height: ProviderTheme.spacingMd),

          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_services.isEmpty)
            const Expanded(
              child: Center(
                child: _EmptyHint(
                    text: 'Noch keine Leistungen für dieses Tier'),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _services.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: ProviderTheme.spacingSm),
                itemBuilder: (_, i) {
                  final r = _services[i];
                  final rawDate = r['recorded_at'] as String?;
                  final date = rawDate != null
                      ? widget.fmt.format(DateTime.parse(rawDate))
                      : '—';
                  return Container(
                    padding: const EdgeInsets.all(ProviderTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: ProviderTheme.surfaceContainerLowest,
                      borderRadius:
                          BorderRadius.circular(ProviderTheme.radiusMd),
                      border: Border(
                        left: BorderSide(
                            color: ProviderTheme.primary, width: 3),
                        right:
                            BorderSide(color: ProviderTheme.outlineVariant),
                        top: BorderSide(color: ProviderTheme.outlineVariant),
                        bottom:
                            BorderSide(color: ProviderTheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _TypeBadge(
                                      type: r['record_type'] as String? ??
                                          'other'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r['title'] as String? ?? '—',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              if ((r['description'] as String? ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  r['description'] as String,
                                  style: const TextStyle(
                                      color: ProviderTheme.onSurfaceVariant),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(date,
                            style: const TextStyle(
                                fontSize: 12,
                                color: ProviderTheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ProviderTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: ProviderTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  static const _labels = <String, String>{
    'checkup': 'Untersuchung',
    'diagnosis': 'Diagnose',
    'treatment': 'Behandlung',
    'surgery': 'Eingriff/OP',
    'lab_result': 'Laborergebnis',
    'prescription': 'Rezept',
    'observation': 'Beobachtung',
    'other': 'Sonstiges',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[type] ?? type;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ProviderTheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            color: ProviderTheme.tertiary,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        text,
        style: const TextStyle(color: ProviderTheme.onSurfaceVariant),
      ),
    );
  }
}

// ── Termine Tab ───────────────────────────────────────────────────────────────

class _AppointmentsTab extends StatelessWidget {
  final String petId;
  const _AppointmentsTab({required this.petId});

  @override
  Widget build(BuildContext context) {
    final apptProvider = context.watch<ProviderAppointmentProvider>();
    final appointments = apptProvider.appointments
        .where((a) => a.petId == petId)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    if (appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: ProviderTheme.onSurfaceVariant),
            SizedBox(height: 12),
            Text('Keine Termine',
                style: TextStyle(color: ProviderTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final fmt = DateFormat('dd.MM.yyyy');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = appointments[i];
        final statusColor = _color(a.status);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ProviderTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.timeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(fmt.format(a.scheduledAt),
                        style: const TextStyle(
                            color: ProviderTheme.onSurfaceVariant,
                            fontSize: 11)),
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

  Color _color(ProviderAppointmentStatus s) {
    switch (s) {
      case ProviderAppointmentStatus.requested:
        return Colors.orange;
      case ProviderAppointmentStatus.confirmed:
        return ProviderTheme.secondary;
      case ProviderAppointmentStatus.completed:
        return ProviderTheme.primary;
      case ProviderAppointmentStatus.cancelled:
        return ProviderTheme.error;
      case ProviderAppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}

// ── Gewicht Tab ───────────────────────────────────────────────────────────────

class _ProviderWeightTab extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final DateFormat fmt;
  const _ProviderWeightTab({required this.entries, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight_outlined,
                size: 48, color: ProviderTheme.onSurfaceVariant),
            SizedBox(height: 12),
            Text('Keine Gewichtsdaten',
                style: TextStyle(color: ProviderTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final sorted = [...entries]
      ..sort((a, b) {
        final da =
            DateTime.tryParse(a['measured_at'] as String? ?? '') ?? DateTime(0);
        final db =
            DateTime.tryParse(b['measured_at'] as String? ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });

    final weights =
        sorted.map((e) => (e['weight_kg'] as num?)?.toDouble() ?? 0.0).toList();
    final latestKg = weights.isNotEmpty ? weights.first : null;

    return Column(
      children: [
        if (latestKg != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProviderTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_weight_rounded,
                    color: ProviderTheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Aktuell: ${latestKg.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ProviderTheme.primary),
                ),
                if (weights.length >= 2) ...[
                  const SizedBox(width: 16),
                  Builder(builder: (ctx) {
                    final diff = weights.first - weights[1];
                    final isUp = diff > 0;
                    return Row(
                      children: [
                        Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: isUp ? Colors.orange : ProviderTheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? '+' : ''}${diff.toStringAsFixed(2)} kg',
                          style: TextStyle(
                              fontSize: 13,
                              color: isUp
                                  ? Colors.orange
                                  : ProviderTheme.secondary,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final e = sorted[i];
              final kg = (e['weight_kg'] as num?)?.toDouble();
              final dt = DateTime.tryParse(e['measured_at'] as String? ?? '');
              final note = e['notes'] as String?;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ProviderTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monitor_weight_rounded,
                      size: 18, color: ProviderTheme.primary),
                ),
                title: Text(
                  kg != null ? '${kg.toStringAsFixed(2)} kg' : '—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: dt != null
                    ? Text(fmt.format(dt),
                        style: const TextStyle(fontSize: 12))
                    : null,
                trailing: note != null && note.isNotEmpty
                    ? Tooltip(
                        message: note,
                        child: const Icon(Icons.notes_rounded,
                            size: 16,
                            color: ProviderTheme.onSurfaceVariant),
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

// ── Fütterung Tab ─────────────────────────────────────────────────────────────

class _ProviderFeedingTab extends StatelessWidget {
  final List<Map<String, dynamic>> plans;
  const _ProviderFeedingTab({required this.plans});

  @override
  Widget build(BuildContext context) {
    final activePlans = plans.where((p) => p['is_active'] == true).toList();
    final displayPlans = activePlans.isEmpty ? plans : activePlans;

    if (plans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_rounded,
                size: 48, color: ProviderTheme.onSurfaceVariant),
            SizedBox(height: 12),
            Text('Kein Futterplan vorhanden',
                style: TextStyle(color: ProviderTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayPlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final plan = displayPlans[i];
        final meals = (plan['meals'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ProviderTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ProviderTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded,
                      size: 18, color: ProviderTheme.primary),
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
                              ? ProviderTheme.secondary
                              : ProviderTheme.onSurfaceVariant)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      plan['is_active'] == true ? 'Aktiv' : 'Inaktiv',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: plan['is_active'] == true
                              ? ProviderTheme.secondary
                              : ProviderTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              if ((plan['description'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(plan['description'] as String,
                    style: const TextStyle(
                        color: ProviderTheme.onSurfaceVariant, fontSize: 13)),
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
                                color: ProviderTheme.onSurfaceVariant),
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
                                    color: ProviderTheme.onSurfaceVariant,
                                    fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        ...components.map((c) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, top: 2),
                              child: Text(
                                '• ${c['food_name']} '
                                '${c['amount_grams'] != null ? '${c['amount_grams']} ${c['unit'] ?? 'g'}' : ''}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: ProviderTheme.onSurfaceVariant),
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

// ── Allergies Tab (read-only für Dienstleister) ───────────────────────────────

class _ProviderAllergiesTab extends StatelessWidget {
  final String petId;
  const _ProviderAllergiesTab({required this.petId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderAllergyProvider>();
    final allergies = provider.forPet(petId);

    if (provider.isLoading(petId)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allergies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Keine Allergien dokumentiert',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: allergies.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final a = allergies[i];
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
          ].join(' · ')),
        );
      },
    );
  }
}
