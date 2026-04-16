import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Fütterungsplan & Management Screen
/// Placeholder matching mockup 2.png structure
class FeedingScreen extends StatelessWidget {
  const FeedingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fütterungsplan &',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Text(
                    'Management',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: LivingLedgerTheme.primary,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.beach_access_rounded, size: 18),
                label: const Text('Urlaubsvertretung festlegen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LivingLedgerTheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Überwache die tägliche Nährstoffzufuhr und Routineaufgaben. '
            'Organisiere das Tierfutter effizient und einfacher.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 36),

          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main schedule area
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Week Calendar placeholder
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: LivingLedgerTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                            LivingLedgerTheme.radiusXl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Zeitplan für heute',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Fütterung'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Empty schedule
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.restaurant_menu_rounded,
                                    size: 48,
                                    color: LivingLedgerTheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Noch kein Fütterungsplan angelegt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: LivingLedgerTheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {},
                                    child: const Text(
                                        'Ersten Plan erstellen'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Stock indicators
                    Row(
                      children: [
                        Expanded(
                            child: _StockCard(
                          label: 'LAGERBESTAND',
                          title: 'Heu-Vorrat',
                          value: '-- kg',
                          subtitle: 'Kein Bestand erfasst',
                          color: LivingLedgerTheme.primary,
                        )),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _StockCard(
                          label: 'LAGERBESTAND',
                          title: 'Kraftfutter Mix',
                          value: '-- kg',
                          subtitle: 'Kein Bestand erfasst',
                          color: LivingLedgerTheme.tertiary,
                        )),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _StockCard(
                          label: 'STATUS',
                          title: 'Hygiene-Index',
                          value: '--',
                          subtitle: 'Keine Daten',
                          color: LivingLedgerTheme.secondary,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Sidebar - Routine Checklist
              SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(LivingLedgerTheme.radiusXl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Routine-Checkliste',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _ChecklistItem(label: 'Wassernapf prüfen'),
                      _ChecklistItem(label: 'Medikamentengabe'),
                      _ChecklistItem(label: 'Baumrinde Soll'),
                      _ChecklistItem(label: 'Käfig reinigen'),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('DETAILS BEARBEITEN'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final String label;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StockCard({
    required this.label,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatefulWidget {
  final String label;

  const _ChecklistItem({required this.label});

  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _checked = !_checked),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius:
                BorderRadius.circular(LivingLedgerTheme.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _checked
                      ? LivingLedgerTheme.success
                      : Colors.transparent,
                  border: Border.all(
                    color: _checked
                        ? LivingLedgerTheme.success
                        : LivingLedgerTheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: _checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration:
                          _checked ? TextDecoration.lineThrough : null,
                      color: _checked
                          ? LivingLedgerTheme.onSurfaceVariant
                          : LivingLedgerTheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
