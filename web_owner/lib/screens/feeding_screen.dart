import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/feeding.dart';
import '../models/pet.dart';
import '../providers/feeding_provider.dart';
import '../providers/pet_provider.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      if (pets.isNotEmpty) {
        final feedingProvider = context.read<FeedingProvider>();
        if (feedingProvider.selectedPetId == null) {
          feedingProvider.selectPet(pets.first.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final feedingProvider = context.watch<FeedingProvider>();
    final pets = petProvider.pets;

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
              if (pets.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _showCreatePlanDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Futterplan erstellen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LivingLedgerTheme.primary,
                    foregroundColor: LivingLedgerTheme.onPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Überwache die tägliche Nährstoffzufuhr deiner Tiere.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          if (pets.isEmpty)
            _EmptyState(
              icon: Icons.restaurant_menu_rounded,
              text: 'Lege zuerst ein Tier an.',
            )
          else ...[
            // Pet selector
            _PetSelector(
              pets: pets,
              selectedId: feedingProvider.selectedPetId,
              onSelect: feedingProvider.selectPet,
            ),
            const SizedBox(height: 24),

            if (feedingProvider.loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Plan + Meals
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (feedingProvider.plans.isEmpty)
                          _EmptyState(
                            icon: Icons.restaurant_menu_rounded,
                            text: 'Noch kein Futterplan erstellt.',
                            action: ElevatedButton(
                              onPressed: () => _showCreatePlanDialog(context),
                              child: const Text('Ersten Plan erstellen'),
                            ),
                          )
                        else ...[
                          // Plan selector tabs
                          if (feedingProvider.plans.length > 1)
                            _PlanTabs(
                              plans: feedingProvider.plans,
                              selectedId: feedingProvider.selectedPlan?.id,
                              onSelect: feedingProvider.loadPlanDetail,
                            ),

                          // Meals display
                          if (feedingProvider.selectedPlan != null)
                            _PlanView(
                              plan: feedingProvider.selectedPlan!,
                              onAddMeal: () =>
                                  _showAddMealDialog(context, feedingProvider.selectedPlan!.id),
                              onLogFeeding: (mealId) =>
                                  _logFeeding(context, mealId),
                              onAddComponent: (mealId) =>
                                  _showAddComponentDialog(
                                      context,
                                      feedingProvider.selectedPlan!.id,
                                      mealId),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right: Feeding log
                  SizedBox(
                    width: 300,
                    child: _FeedingLogPanel(log: feedingProvider.log),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _showCreatePlanDialog(BuildContext context) async {
    final provider = context.read<FeedingProvider>();
    if (provider.selectedPetId == null) {
      final pets = context.read<PetProvider>().pets;
      if (pets.isEmpty) return;
      await provider.selectPet(pets.first.id);
    }
    if (!context.mounted) return;

    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futterplan erstellen'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
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
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Erstellen')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (nameCtrl.text.trim().isEmpty) return;
      await provider.createPlan(
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      );
    }
  }

  Future<void> _showAddMealDialog(
      BuildContext context, String planId) async {
    final nameCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mahlzeit hinzufügen'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name (z.B. Frühstück)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Uhrzeit (z.B. 07:30)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notizen (optional)',
                  border: OutlineInputBorder(),
                ),
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
              child: const Text('Hinzufügen')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      if (nameCtrl.text.trim().isEmpty) return;
      await context.read<FeedingProvider>().addMeal(
            planId: planId,
            name: nameCtrl.text.trim(),
            timeOfDay: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
    }
  }

  Future<void> _showAddComponentDialog(
      BuildContext context, String planId, String mealId) async {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String unit = 'g';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Futter-Komponente hinzufügen'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Futterbezeichnung',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Menge',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: unit,
                      items: ['g', 'kg', 'ml', 'l', 'Stück', 'EL', 'TL']
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => unit = v ?? 'g'),
                    ),
                  ],
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
                child: const Text('Hinzufügen')),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      if (nameCtrl.text.trim().isEmpty) return;
      await context.read<FeedingProvider>().addComponent(
            planId: planId,
            mealId: mealId,
            foodName: nameCtrl.text.trim(),
            amountGrams:
                double.tryParse(amountCtrl.text.replaceAll(',', '.')),
            unit: unit,
          );
    }
  }

  Future<void> _logFeeding(BuildContext context, String? mealId) async {
    final notesCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fütterung protokollieren'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tatsächliche Menge in g (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notizen (optional)',
                  border: OutlineInputBorder(),
                ),
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
              child: const Text('Protokollieren')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<FeedingProvider>().logFeeding(
            mealId: mealId,
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            amountFedGrams:
                double.tryParse(amountCtrl.text.replaceAll(',', '.')),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fütterung protokolliert!')),
        );
      }
    }
  }
}

class _PetSelector extends StatelessWidget {
  final List<Pet> pets;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _PetSelector(
      {required this.pets,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: pets
          .map((p) => ChoiceChip(
                label: Text(p.name),
                selected: p.id == selectedId,
                onSelected: (_) => onSelect(p.id),
                selectedColor:
                    LivingLedgerTheme.primary.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: p.id == selectedId
                      ? LivingLedgerTheme.primary
                      : LivingLedgerTheme.onSurface,
                  fontWeight: p.id == selectedId
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ))
          .toList(),
    );
  }
}

class _PlanTabs extends StatelessWidget {
  final List<FeedingPlan> plans;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _PlanTabs(
      {required this.plans,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: plans.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final plan = plans[i];
          final isSelected = plan.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(plan.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? LivingLedgerTheme.primary
                    : LivingLedgerTheme.surfaceContainerLow,
                borderRadius:
                    BorderRadius.circular(LivingLedgerTheme.radiusFull),
              ),
              child: Text(
                plan.name,
                style: TextStyle(
                  color: isSelected
                      ? LivingLedgerTheme.onPrimary
                      : LivingLedgerTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final FeedingPlan plan;
  final VoidCallback onAddMeal;
  final ValueChanged<String?> onLogFeeding;
  final ValueChanged<String> onAddComponent;

  const _PlanView({
    required this.plan,
    required this.onAddMeal,
    required this.onLogFeeding,
    required this.onAddComponent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
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
                      plan.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (plan.description != null)
                      Text(
                        plan.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LivingLedgerTheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAddMeal,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Mahlzeit'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (plan.meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Noch keine Mahlzeiten. Füge eine hinzu.',
                  style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...plan.meals.map((meal) => _MealCard(
                  meal: meal,
                  onLog: () => onLogFeeding(meal.id),
                  onAddComponent: () => onAddComponent(meal.id),
                )),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final FeedingMeal meal;
  final VoidCallback onLog;
  final VoidCallback onAddComponent;

  const _MealCard(
      {required this.meal, required this.onLog, required this.onAddComponent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (meal.timeOfDay != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: LivingLedgerTheme.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(LivingLedgerTheme.radiusFull),
                  ),
                  child: Text(
                    meal.timeOfDay!,
                    style: TextStyle(
                        color: LivingLedgerTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              if (meal.timeOfDay != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meal.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddComponent,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Komponente'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onLog,
                icon: const Icon(Icons.check, size: 14),
                label: const Text('Gefüttert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LivingLedgerTheme.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          if (meal.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              meal.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
            ),
          ],

          if (meal.components.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: meal.components
                  .map((c) => Chip(
                        label: Text(
                          c.amountGrams != null
                              ? '${c.foodName} (${c.amountGrams!.toStringAsFixed(c.amountGrams! % 1 == 0 ? 0 : 1)} ${c.unit})'
                              : c.foodName,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor:
                            LivingLedgerTheme.surfaceContainerLowest,
                        side: BorderSide(
                            color: LivingLedgerTheme.outlineVariant),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedingLogPanel extends StatelessWidget {
  final List<FeedingLogEntry> log;

  const _FeedingLogPanel({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protokoll',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          if (log.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Noch keine Einträge',
                  style:
                      TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
                ),
              ),
            )
          else
            ...log.take(20).map((e) => _LogEntry(entry: e)),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final FeedingLogEntry entry;

  const _LogEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dt = entry.fedAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: entry.skipped
            ? LivingLedgerTheme.error.withValues(alpha: 0.06)
            : LivingLedgerTheme.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            entry.skipped
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            size: 16,
            color: entry.skipped
                ? LivingLedgerTheme.error
                : LivingLedgerTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.mealName ?? (entry.skipped ? 'Übersprungen' : 'Gefüttert'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                      fontSize: 11,
                      color: LivingLedgerTheme.onSurfaceVariant),
                ),
                if (entry.notes != null)
                  Text(entry.notes!,
                      style: TextStyle(
                          fontSize: 11,
                          color: LivingLedgerTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _EmptyState({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon,
                size: 56,
                color: LivingLedgerTheme.onSurfaceVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(text,
                style: TextStyle(
                    color: LivingLedgerTheme.onSurfaceVariant)),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
