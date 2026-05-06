import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';
import '../services/api_service.dart';

class PetComparisonScreen extends StatefulWidget {
  const PetComparisonScreen({super.key});

  @override
  State<PetComparisonScreen> createState() => _PetComparisonScreenState();
}

class _PetComparisonScreenState extends State<PetComparisonScreen> {
  final Set<String> _selectedIds = {};
  final Map<String, Map<String, dynamic>> _stats = {};

  Future<void> _loadStats(String petId) async {
    if (_stats.containsKey(petId)) return;
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/pets/$petId/stats');
      if (mounted) {
        setState(() => _stats[petId] = data['stats'] as Map<String, dynamic>? ?? {});
      }
    } catch (_) {}
  }

  void _togglePet(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 3) {
        _selectedIds.add(id);
        _loadStats(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = petProvider.pets;
    final selectedPets = pets.where((p) => _selectedIds.contains(p.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tier-Vergleich', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Wähle bis zu 3 Tiere für den Vergleich.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),

          // Pet selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pets.map((p) {
              final selected = _selectedIds.contains(p.id);
              final disabled = !selected && _selectedIds.length >= 3;
              return Opacity(
                opacity: disabled ? 0.5 : 1.0,
                child: FilterChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: disabled ? null : (_) => _togglePet(p.id),
                  avatar: selected ? const Icon(Icons.check_rounded, size: 16) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          if (selectedPets.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.compare_arrows_rounded,
                      size: 48,
                      color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'Wähle Tiere aus um sie zu vergleichen',
                    style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            _ComparisonTable(pets: selectedPets, stats: _stats),
        ],
      ),
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final List<Pet> pets;
  final Map<String, Map<String, dynamic>> stats;

  const _ComparisonTable({required this.pets, required this.stats});

  String _age(Pet p) {
    if (p.birthDate == null) return '—';
    final years = DateTime.now().difference(p.birthDate!).inDays ~/ 365;
    final months = (DateTime.now().difference(p.birthDate!).inDays % 365) ~/ 30;
    if (years == 0) return '$months Mo.';
    return '$years J. $months Mo.';
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: const FlexColumnWidth(),
      border: TableBorder.all(color: LivingLedgerTheme.outline.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: LivingLedgerTheme.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          children: [
            const _TableCell(text: '', isHeader: true),
            ...pets.map((p) => _TableCell(text: p.name, isHeader: true, onTap: () => context.go('/animals/${p.id}'))),
          ],
        ),

        // Tier-Icon
        TableRow(children: [
          const _TableCell(text: 'Tierart'),
          ...pets.map((p) => _TableCell(text: '${p.speciesIcon} ${p.species?.name ?? '—'}')),
        ]),

        // Rasse
        TableRow(children: [
          const _TableCell(text: 'Rasse'),
          ...pets.map((p) => _TableCell(text: p.breed.isNotEmpty ? p.breed : '—')),
        ]),

        // Alter
        TableRow(children: [
          const _TableCell(text: 'Alter'),
          ...pets.map((p) => _TableCell(text: _age(p))),
        ]),

        // Gewicht
        TableRow(children: [
          const _TableCell(text: 'Gewicht'),
          ...pets.map((p) => _TableCell(text: p.weightKg != null ? '${p.weightKg!.toStringAsFixed(1)} kg' : '—')),
        ]),

        // Impfungen
        TableRow(children: [
          const _TableCell(text: 'Impfungen'),
          ...pets.map((p) {
            final s = stats[p.id];
            return _TableCell(text: s != null ? '${s['vaccinations_total'] ?? '—'}' : '…');
          }),
        ]),

        // Aktive Medikamente
        TableRow(children: [
          const _TableCell(text: 'Medikamente (aktiv)'),
          ...pets.map((p) {
            final s = stats[p.id];
            return _TableCell(text: s != null ? '${s['active_medications'] ?? '—'}' : '…');
          }),
        ]),

        // Termine gesamt
        TableRow(children: [
          const _TableCell(text: 'Termine gesamt'),
          ...pets.map((p) {
            final s = stats[p.id];
            return _TableCell(text: s != null ? '${s['appointments_total'] ?? '—'}' : '…');
          }),
        ]),

        // Allergien
        TableRow(children: [
          const _TableCell(text: 'Allergien'),
          ...pets.map((p) {
            final s = stats[p.id];
            return _TableCell(text: s != null ? '${s['allergies_total'] ?? '—'}' : '…');
          }),
        ]),

        // Chip-Nr
        TableRow(children: [
          const _TableCell(text: 'Chip-Nr.'),
          ...pets.map((p) => _TableCell(text: p.microchipId ?? '—')),
        ]),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final VoidCallback? onTap;
  const _TableCell({required this.text, this.isHeader = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
              fontSize: isHeader ? 14 : 13,
              color: isHeader ? LivingLedgerTheme.primary : null,
              decoration: onTap != null ? TextDecoration.underline : null,
            ),
            textAlign: isHeader ? TextAlign.center : TextAlign.center,
          ),
        ),
      ),
    );
  }
}
