import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/customers_provider.dart';

/// Leistungen dokumentieren = Behandlungen/Notizen als medical records
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final List<Map<String, dynamic>> _entries = [];
  String? _selectedPetId;
  String? _selectedPetName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().load();
    });
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
                        style: TextStyle(
                            color: ProviderTheme.onSurfaceVariant),
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
                child: Center(child: Text('Keine Tiere gefunden.')),
              )
            else ...[
              // Pet selector
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
                  setState(() {
                    _selectedPetId = v;
                    _selectedPetName = pets
                        .firstWhere((p) => p['id'] == v,
                            orElse: () => {})['name'] as String?;
                    // In real impl: load records for this pet
                  });
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
                    : _entries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_outlined,
                                    size: 56,
                                    color: ProviderTheme.onSurfaceVariant
                                        .withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  'Noch keine Leistungen für $_selectedPetName.',
                                  style: TextStyle(
                                      color: ProviderTheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _showAddDialog(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ProviderTheme.primary,
                                    foregroundColor: ProviderTheme.onPrimary,
                                  ),
                                  child: const Text('Erste Leistung erfassen'),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final e = _entries[i];
                              return _ServiceEntry(entry: e);
                            },
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
        builder: (ctx, setState) => AlertDialog(
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
                  onChanged: (v) => setState(() => type = v ?? 'treatment'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
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
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Erfassen')),
          ],
        ),
      ),
    );

    if (confirmed == true && titleCtrl.text.trim().isNotEmpty) {
      setState(() {
        _entries.insert(0, {
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'type': type,
          'date': DateTime.now(),
          'pet': _selectedPetName,
        });
      });
      // TODO: POST to /pets/:petId/records
    }
  }
}

class _ServiceEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _ServiceEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dt = entry['date'] as DateTime;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

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
                Text(entry['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                if ((entry['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entry['description'] as String,
                      style:
                          TextStyle(color: ProviderTheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(dateStr,
              style: TextStyle(
                  color: ProviderTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
