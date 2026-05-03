import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/medication_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../models/pet.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      final medProvider = context.read<MedicationProvider>();
      if (pets.isNotEmpty) {
          // Use already-selected pet if available, otherwise first pet
        final preselected = medProvider.selectedPetId;
        final target = preselected != null &&
                pets.any((p) => p.id == preselected)
            ? preselected
            : pets.first.id;
        _selectPet(target);
      }
    });
  }

  void _selectPet(String petId) {
    setState(() => _selectedPetId = petId);
    context.read<MedicationProvider>().loadForPet(petId);
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final medProvider = context.watch<MedicationProvider>();
    final pets = petProvider.pets;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Text('Medikamente',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Verordnete Medikamente protokollieren und als gegeben markieren.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),

          // ── Pet Selector ────────────────────────────────────────────────
          if (pets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(Icons.pets_rounded,
                        size: 64, color: LivingLedgerTheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text('Noch keine Tiere vorhanden',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            )
          else ...[
            _PetSelector(
              pets: pets,
              selectedId: _selectedPetId,
              onSelect: _selectPet,
            ),
            const SizedBox(height: 28),

            // ── Medications ────────────────────────────────────────────
            if (_selectedPetId != null) ...[
              if (medProvider.isLoading(_selectedPetId!))
                const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(),
                ))
              else if (medProvider.error(_selectedPetId!) != null)
                _ErrorBanner(message: medProvider.error(_selectedPetId!)!)
              else
                _MedicationList(
                  petId: _selectedPetId!,
                  medications: medProvider.forPet(_selectedPetId!),
                  provider: medProvider,
                ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Pet Selector ─────────────────────────────────────────────────────────────

class _PetSelector extends StatelessWidget {
  final List<Pet> pets;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _PetSelector({
    required this.pets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pets.map((pet) {
        final isSelected = pet.id == selectedId;
        return FilterChip(
          label: Text(pet.name),
          avatar: Text(pet.speciesIcon,
              style: const TextStyle(fontSize: 14)),
          selected: isSelected,
          selectedColor: LivingLedgerTheme.primary.withValues(alpha: 0.1),
          checkmarkColor: LivingLedgerTheme.primary,
          side: BorderSide(
            color: isSelected
                ? LivingLedgerTheme.primary.withValues(alpha: 0.4)
                : LivingLedgerTheme.outlineVariant,
          ),
          labelStyle: TextStyle(
            color: isSelected
                ? LivingLedgerTheme.primary
                : LivingLedgerTheme.onSurface,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) => onSelect(pet.id),
        );
      }).toList(),
    );
  }
}

// ── Medication List ───────────────────────────────────────────────────────────

class _MedicationList extends StatelessWidget {
  final String petId;
  final List<Medication> medications;
  final MedicationProvider provider;

  const _MedicationList({
    required this.petId,
    required this.medications,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    if (medications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication_outlined,
                  size: 64, color: LivingLedgerTheme.outlineVariant),
              const SizedBox(height: 16),
              Text('Keine Medikamente verordnet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LivingLedgerTheme.onSurfaceVariant,
                      )),
              const SizedBox(height: 8),
              Text(
                'Medikamente werden vom Tierarzt eingetragen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final active = medications.where((m) => m.isActive && !m.isExpired).toList();
    final inactive = medications.where((m) => !m.isActive || m.isExpired).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (active.isNotEmpty) ...[
          Text(
            'AKTIVE MEDIKAMENTE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...active.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MedicationCard(
                  petId: petId,
                  medication: m,
                  provider: provider,
                ),
              )),
        ],
        if (inactive.isNotEmpty) ...[
          if (active.isNotEmpty) const SizedBox(height: 16),
          Text(
            'INAKTIV / ABGESCHLOSSEN',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ...inactive.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MedicationCard(
                  petId: petId,
                  medication: m,
                  provider: provider,
                  dimmed: true,
                ),
              )),
        ],
      ],
    );
  }
}

// ── Medication Card ───────────────────────────────────────────────────────────

class _MedicationCard extends StatelessWidget {
  final String petId;
  final Medication medication;
  final MedicationProvider provider;
  final bool dimmed;

  const _MedicationCard({
    required this.petId,
    required this.medication,
    required this.provider,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final m = medication;
    final fmt = DateFormat('dd.MM.yyyy');

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: LivingLedgerTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
          boxShadow: LivingLedgerTheme.cardShadow,
          border: m.endsSoon
              ? Border.all(
                  color: LivingLedgerTheme.tertiary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: LivingLedgerTheme.primary.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(LivingLedgerTheme.radiusMd),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 22,
                color: LivingLedgerTheme.primary,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _FrequencyBadge(label: m.frequencyLabel),
                    ],
                  ),
                  if (m.dosage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      m.dosage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  if (m.instructions != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      m.instructions!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (m.vetName != null)
                        _MetaChip(
                          icon: Icons.medical_services_outlined,
                          label: m.vetName!,
                        ),
                      if (m.startDate != null)
                        _MetaChip(
                          icon: Icons.play_arrow_rounded,
                          label: 'Ab ${fmt.format(m.startDate!)}',
                        ),
                      if (m.endDate != null)
                        _MetaChip(
                          icon: Icons.event_rounded,
                          label: 'Bis ${fmt.format(m.endDate!)}',
                          warning: m.endsSoon,
                        ),
                    ],
                  ),
                  if (m.endsSoon && m.endDate != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final ok = await context
                            .read<ReminderProvider>()
                            .create(
                              title: 'Medikament aufbrauchen: ${m.name}',
                              message:
                                  'Endet am ${fmt.format(m.endDate!)}',
                              type: 'medication',
                              petId: petId,
                              remindAt: m.endDate!
                                  .subtract(const Duration(days: 1)),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? 'Erinnerung angelegt'
                                : 'Fehler'),
                          ));
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LivingLedgerTheme.tertiary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.alarm_add_rounded,
                                size: 13,
                                color: LivingLedgerTheme.tertiary),
                            const SizedBox(width: 4),
                            Text(
                              'Erinnerung anlegen',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: LivingLedgerTheme.tertiary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Action buttons
            if (!dimmed) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.check_rounded,
                    label: 'Gegeben',
                    color: LivingLedgerTheme.success,
                    onTap: () => _confirmAction(
                      context,
                      title: '${m.name} gegeben?',
                      confirmLabel: 'Gegeben',
                      color: LivingLedgerTheme.success,
                      onConfirm: (notes) =>
                          provider.administer(petId, m.id, notes: notes),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ActionButton(
                    icon: Icons.close_rounded,
                    label: 'Übersprungen',
                    color: LivingLedgerTheme.onSurfaceVariant,
                    onTap: () => _confirmAction(
                      context,
                      title: '${m.name} überspringen?',
                      confirmLabel: 'Überspringen',
                      color: LivingLedgerTheme.tertiary,
                      onConfirm: (notes) =>
                          provider.skip(petId, m.id, notes: notes),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required Color color,
    required Future<bool> Function(String? notes) onConfirm,
  }) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notiz (optional)',
            hintText: 'z.B. mit dem Frühstück gegeben',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await onConfirm(
          notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? '$confirmLabel protokolliert.' : 'Fehler beim Speichern'),
            backgroundColor: ok ? null : LivingLedgerTheme.error,
          ),
        );
      }
    }
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _FrequencyBadge extends StatelessWidget {
  final String label;
  const _FrequencyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LivingLedgerTheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool warning;
  const _MetaChip({required this.icon, required this.label, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? LivingLedgerTheme.tertiary
        : LivingLedgerTheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 20, color: LivingLedgerTheme.error),
          const SizedBox(width: 12),
          Expanded(
              child: Text(message,
                  style: const TextStyle(color: LivingLedgerTheme.error))),
        ],
      ),
    );
  }
}
