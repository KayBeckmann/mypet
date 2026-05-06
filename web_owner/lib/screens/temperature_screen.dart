import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/pet_provider.dart';
import '../providers/temperature_provider.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      final tp = context.read<TemperatureProvider>();
      if (pets.isNotEmpty && tp.selectedPetId == null) {
        tp.loadForPet(pets.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final tp = context.watch<TemperatureProvider>();
    final pets = petProvider.pets;

    final selectedPet = tp.selectedPetId != null
        ? pets.where((p) => p.id == tp.selectedPetId).firstOrNull
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Körpertemperatur',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Verfolge die Körpertemperatur deiner Tiere.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Pet selector
          if (pets.isEmpty)
            const Text('Keine Tiere vorhanden.')
          else ...[
            DropdownButtonFormField<String>(
              value: tp.selectedPetId ?? pets.first.id,
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
                if (id != null) tp.loadForPet(id);
              },
            ),
            const SizedBox(height: 24),

            if (tp.loading)
              const Center(child: CircularProgressIndicator())
            else if (selectedPet != null) ...[
              // Stats row
              if (tp.entries.isNotEmpty) ...[
                _StatsRow(entries: tp.entries),
                const SizedBox(height: 16),
              ],

              // Chart
              if (tp.entries.length >= 2) ...[
                _TemperatureChart(entries: tp.entries),
                const SizedBox(height: 24),
              ],

              // Add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Einträge (${tp.entries.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FilledButton.icon(
                    onPressed: () => _addEntry(context, selectedPet.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Messen'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (tp.entries.isEmpty)
                _EmptyState(
                  onAdd: () => _addEntry(context, selectedPet.id),
                )
              else
                _EntryList(
                  petId: selectedPet.id,
                  entries: List.from(tp.entries.reversed),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _addEntry(BuildContext context, String petId) async {
    final tempCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? method;
    final methods = ['Rektal', 'Ohren', 'Infrarot', 'Sonstige'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Temperatur eintragen'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tempCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Temperatur (°C) *',
                    border: OutlineInputBorder(),
                    hintText: 'z.B. 38.5',
                    suffixText: '°C',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                    labelText: 'Messmethode',
                    border: OutlineInputBorder(),
                  ),
                  items: methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setDs(() => method = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notiz',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(tempCtrl.text.replaceAll(',', '.'));
                if (v == null || v < 25 || v > 45) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Ungültige Temperatur (25–45 °C)')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final v = double.parse(tempCtrl.text.replaceAll(',', '.'));
      await context.read<TemperatureProvider>().add(
            petId: petId,
            temperatureCelsius: v,
            measurementMethod: method,
            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          );
    }
  }
}

class _StatsRow extends StatelessWidget {
  final List<TemperatureEntry> entries;
  const _StatsRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final latest = entries.last.temperatureCelsius;
    final avg = entries.map((e) => e.temperatureCelsius).reduce((a, b) => a + b) /
        entries.length;
    final min = entries.map((e) => e.temperatureCelsius).reduce((a, b) => a < b ? a : b);
    final max = entries.map((e) => e.temperatureCelsius).reduce((a, b) => a > b ? a : b);

    Color latestColor = LivingLedgerTheme.success;
    if (latest >= 39.5) latestColor = LivingLedgerTheme.error;
    if (latest < 37.5) latestColor = Colors.blue;

    return Row(
      children: [
        _StatCard(label: 'Aktuell', value: '${latest.toStringAsFixed(1)} °C', color: latestColor),
        const SizedBox(width: 12),
        _StatCard(label: 'Ø Durchschnitt', value: '${avg.toStringAsFixed(1)} °C'),
        const SizedBox(width: 12),
        _StatCard(label: 'Min', value: '${min.toStringAsFixed(1)} °C'),
        const SizedBox(width: 12),
        _StatCard(label: 'Max', value: '${max.toStringAsFixed(1)} °C'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LivingLedgerTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color ?? LivingLedgerTheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _TemperatureChart extends StatelessWidget {
  final List<TemperatureEntry> entries;
  const _TemperatureChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.3)),
      ),
      child: CustomPaint(
        painter: _TempChartPainter(entries: entries),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TempChartPainter extends CustomPainter {
  final List<TemperatureEntry> entries;
  const _TempChartPainter({required this.entries});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.length < 2) return;

    final temps = entries.map((e) => e.temperatureCelsius).toList();
    final minTemp = temps.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b) + 0.5;
    final range = (maxTemp - minTemp).clamp(1.0, double.infinity);

    double xOf(int i) => i * size.width / (entries.length - 1);
    double yOf(double t) => size.height - (t - minTemp) / range * size.height;

    // Normal zone shading (37.5–39.5)
    final normalTop = yOf(39.5).clamp(0.0, size.height);
    final normalBottom = yOf(37.5).clamp(0.0, size.height);
    canvas.drawRect(
      Rect.fromLTRB(0, normalTop, size.width, normalBottom),
      Paint()..color = LivingLedgerTheme.success.withValues(alpha: 0.08),
    );

    final linePaint = Paint()
      ..color = LivingLedgerTheme.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final x = xOf(i);
      final y = yOf(entries[i].temperatureCelsius);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < entries.length; i++) {
      final t = entries[i].temperatureCelsius;
      dotPaint.color = t >= 39.5
          ? LivingLedgerTheme.error
          : t < 37.5
              ? Colors.blue
              : LivingLedgerTheme.success;
      canvas.drawCircle(Offset(xOf(i), yOf(t)), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.thermostat_outlined, size: 48, color: LivingLedgerTheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Noch keine Einträge',
              style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Erste Messung eintragen'),
          ),
        ],
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  final String petId;
  final List<TemperatureEntry> entries;
  const _EntryList({required this.petId, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.map((e) {
        Color color = LivingLedgerTheme.success;
        String status = 'Normal';
        if (e.isHigh) {
          color = LivingLedgerTheme.error;
          status = 'Erhöht';
        } else if (e.isLow) {
          color = Colors.blue;
          status = 'Niedrig';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: LivingLedgerTheme.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.thermostat_rounded, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${e.temperatureCelsius.toStringAsFixed(1)} °C',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (e.measurementMethod != null) ...[
                          const SizedBox(width: 8),
                          Text(e.measurementMethod!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: LivingLedgerTheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                    Text(e.label,
                        style: TextStyle(
                            fontSize: 12,
                            color: LivingLedgerTheme.onSurfaceVariant)),
                    if (e.note != null)
                      Text(e.note!,
                          style: TextStyle(
                              fontSize: 12,
                              color: LivingLedgerTheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: LivingLedgerTheme.error, size: 20),
                onPressed: () async {
                  final ok = await context
                      .read<TemperatureProvider>()
                      .delete(petId, e.id);
                  if (context.mounted && !ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Löschen fehlgeschlagen')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
