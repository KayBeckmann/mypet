import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mypet_shared/shared.dart';
import '../config/theme.dart';
import '../providers/customers_provider.dart';

/// Leistungen dokumentieren = medical records für freigegebene Tiere
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String? _selectedPetId;
  String? _selectedPetName;
  List<Map<String, dynamic>> _records = [];
  bool _loadingRecords = false;
  String? _recordsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().load();
    });
  }

  Future<void> _loadRecords(String petId) async {
    setState(() {
      _loadingRecords = true;
      _recordsError = null;
      _records = [];
    });
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/$petId/records');
      setState(() {
        _records = (data['records'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _loadingRecords = false;
      });
    } catch (e) {
      setState(() {
        _recordsError = e.toString();
        _loadingRecords = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();
    final pets = provider.pets;

    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Leistungen',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Erbrachte Leistungen dokumentieren',
                        style: TextStyle(color: ProviderTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (_selectedPetId != null)
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Leistung erfassen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProviderTheme.primary,
                      foregroundColor: ProviderTheme.onPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (pets.isEmpty)
              const Expanded(
                child: Center(child: Text('Keine freigegebenen Tiere.')),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _selectedPetId,
                decoration: const InputDecoration(
                  labelText: 'Tier auswählen',
                  border: OutlineInputBorder(),
                ),
                items: pets
                    .map((p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(
                              '${p['name']} (${p['owner_name'] ?? ''})'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _selectedPetId = v;
                    _selectedPetName = pets.firstWhere(
                            (p) => p['id'] == v,
                            orElse: () => {})['name'] as String?;
                  });
                  _loadRecords(v);
                },
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _selectedPetId == null
                    ? Center(
                        child: Text(
                          'Tier auswählen, um Leistungen anzuzeigen.',
                          style: TextStyle(
                              color: ProviderTheme.onSurfaceVariant),
                        ),
                      )
                    : _loadingRecords
                        ? const Center(child: CircularProgressIndicator())
                        : _recordsError != null
                            ? Center(
                                child: Text(_recordsError!,
                                    style: const TextStyle(
                                        color: ProviderTheme.error)),
                              )
                            : _records.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.build_outlined,
                                            size: 56,
                                            color: ProviderTheme.onSurfaceVariant
                                                .withValues(alpha: 0.3)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Noch keine Leistungen für $_selectedPetName.',
                                          style: TextStyle(
                                              color: ProviderTheme
                                                  .onSurfaceVariant),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _showAddDialog(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                ProviderTheme.primary,
                                            foregroundColor:
                                                ProviderTheme.onPrimary,
                                          ),
                                          child: const Text(
                                              'Erste Leistung erfassen'),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _records.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (_, i) => _ServiceEntry(
                                        record: _records[i]),
                                  ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'treatment';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text('Leistung für $_selectedPetName'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Art der Leistung',
                    border: OutlineInputBorder(),
                  ),
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
                  onChanged: (v) => setDs(() => type = v ?? 'treatment'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Titel *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            ElevatedButton(
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
        await api.post('/pets/$_selectedPetId/records', body: {
          'record_type': type,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim().isNotEmpty
              ? descCtrl.text.trim()
              : null,
          'is_private': false,
        });
        await _loadRecords(_selectedPetId!);
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
}

class _ServiceEntry extends StatelessWidget {
  final Map<String, dynamic> record;
  const _ServiceEntry({required this.record});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    final rawDate = record['recorded_at'] as String?;
    String dateStr = '—';
    if (rawDate != null) {
      try {
        dateStr = fmt.format(DateTime.parse(rawDate));
      } catch (_) {}
    }

    final typeLabels = <String, String>{
      'treatment': 'Behandlung',
      'checkup': 'Untersuchung',
      'surgery': 'Eingriff',
      'diagnosis': 'Diagnose',
      'observation': 'Beobachtung',
      'other': 'Sonstiges',
    };
    final typeLabel = typeLabels[record['record_type']] ??
        (record['record_type'] as String? ?? 'Sonstiges');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: ProviderTheme.primary, width: 4),
          right: BorderSide(color: ProviderTheme.outlineVariant),
          top: BorderSide(color: ProviderTheme.outlineVariant),
          bottom: BorderSide(color: ProviderTheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProviderTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                            fontSize: 11,
                            color: ProviderTheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record['title'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if ((record['description'] as String? ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      record['description'] as String,
                      style: TextStyle(color: ProviderTheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            dateStr,
            style: TextStyle(
                fontSize: 12, color: ProviderTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
