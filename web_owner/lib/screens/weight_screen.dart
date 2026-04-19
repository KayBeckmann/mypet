import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/pet_provider.dart';
import '../providers/weight_provider.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      final wp = context.read<WeightProvider>();
      if (pets.isNotEmpty && wp.selectedPetId == null) {
        wp.loadForPet(pets.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final wp = context.watch<WeightProvider>();
    final pets = petProvider.pets;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gewichtsverlauf',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Verfolge das Gewicht deiner Tiere über die Zeit.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          if (pets.isEmpty)
            const Text('Noch keine Tiere vorhanden.')
          else
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: pets
                      .map((p) => ChoiceChip(
                            label: Text(p.name),
                            selected: wp.selectedPetId == p.id,
                            onSelected: (_) => wp.loadForPet(p.id),
                          ))
                      .toList(),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Gewicht eintragen'),
                  onPressed: wp.selectedPetId == null
                      ? null
                      : () => _showAddDialog(context, wp),
                ),
              ],
            ),
          const SizedBox(height: 24),

          if (wp.loading)
            const Center(child: CircularProgressIndicator())
          else if (wp.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LivingLedgerTheme.outlineVariant),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.monitor_weight_outlined,
                        size: 56,
                        color: LivingLedgerTheme.onSurfaceVariant
                            .withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('Noch keine Gewichtseinträge',
                        style: TextStyle(
                            color: LivingLedgerTheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else ...[
            // Stats row
            Row(
              children: [
                _StatCard(
                    label: 'Aktuell',
                    value:
                        '${wp.latestWeight?.toStringAsFixed(1) ?? '—'} kg',
                    color: LivingLedgerTheme.primary),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Min',
                    value:
                        '${wp.minWeight?.toStringAsFixed(1) ?? '—'} kg',
                    color: LivingLedgerTheme.secondary),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Max',
                    value:
                        '${wp.maxWeight?.toStringAsFixed(1) ?? '—'} kg',
                    color: LivingLedgerTheme.tertiary),
                const SizedBox(width: 12),
                _StatCard(
                    label: 'Einträge',
                    value: '${wp.entries.length}',
                    color: Colors.grey),
              ],
            ),
            const SizedBox(height: 20),

            // Chart
            Container(
              height: 240,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LivingLedgerTheme.outlineVariant),
              ),
              child: _WeightChart(entries: wp.entries),
            ),
            const SizedBox(height: 20),

            // Table
            Container(
              decoration: BoxDecoration(
                color: LivingLedgerTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LivingLedgerTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Text('VERLAUF',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  color: LivingLedgerTheme.onSurfaceVariant,
                                )),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...wp.entries.reversed.take(20).map((e) => ListTile(
                        leading: const Icon(Icons.monitor_weight_outlined,
                            size: 18),
                        title: Text(
                            '${e.weightKg.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: e.notes != null ? Text(e.notes!) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fmtDate(e.recordedAt),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: LivingLedgerTheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16,
                                  color: LivingLedgerTheme.onSurfaceVariant),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => wp.delete(e.id),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  Future<void> _showAddDialog(BuildContext context, WeightProvider wp) async {
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Gewicht eintragen'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Gewicht (kg) *',
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notizen (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
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
                final weight = double.tryParse(
                    weightCtrl.text.replaceAll(',', '.'));
                if (weight == null || weight <= 0) return;
                Navigator.pop(ctx);
                await wp.add(
                  weightKg: weight,
                  notes: notesCtrl.text,
                  recordedAt: selectedDate,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const _WeightChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return const Center(
        child: Text('Mindestens 2 Einträge für Diagramm nötig'),
      );
    }
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _ChartPainter(
        entries: entries,
        lineColor: LivingLedgerTheme.primary,
        gridColor: LivingLedgerTheme.outlineVariant,
        textColor: LivingLedgerTheme.onSurfaceVariant,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _ChartPainter({
    required this.entries,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final weights = entries.map((e) => e.weightKg).toList();
    final minW = weights.reduce(min);
    final maxW = weights.reduce(max);
    final range = max(maxW - minW, 0.5);

    const padLeft = 48.0;
    const padRight = 16.0;
    const padTop = 8.0;
    const padBottom = 28.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Grid lines (4 horizontal)
    for (int i = 0; i <= 4; i++) {
      final y = padTop + chartH - (i / 4) * chartH;
      canvas.drawLine(
          Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
      final wVal = minW + (i / 4) * range;
      final tp = TextPainter(
        text: TextSpan(
          text: wVal.toStringAsFixed(1),
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.2), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, padTop, size.width, chartH));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < entries.length; i++) {
      final x = padLeft + (i / (entries.length - 1)) * chartW;
      final y = padTop + chartH -
          ((entries[i].weightKg - minW) / range) * chartH;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, padTop + chartH);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Dot
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = Colors.white);
    }

    fillPath.lineTo(
        padLeft + chartW, padTop + chartH);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // X axis labels (first, last, and a few in between)
    final labelIndices = [0, entries.length ~/ 2, entries.length - 1];
    for (final idx in labelIndices.toSet()) {
      if (idx >= entries.length) continue;
      final x = padLeft + (idx / (entries.length - 1)) * chartW;
      final dt = entries[idx].recordedAt;
      final label = '${dt.day}.${dt.month}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas,
          Offset(x - tp.width / 2, size.height - padBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.entries != entries;
}
