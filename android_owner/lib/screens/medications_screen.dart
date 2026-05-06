import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../providers/medication_provider.dart';

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<MobilePetProvider>().pets;
    final medProv = context.watch<MobileMedicationProvider>();

    final allActive = <_PetMed>[];
    for (final pet in pets) {
      for (final med in medProv.activeForPet(pet.id)) {
        allActive.add(_PetMed(pet: pet, med: med));
      }
    }

    final endingSoon = allActive.where((e) => e.med.endsSoon).toList();
    final regular = allActive.where((e) => !e.med.endsSoon).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medikamente'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${allActive.length} aktiv',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: allActive.isEmpty
          ? _EmptyState(isLoading: pets.any((p) => medProv.isLoading(p.id)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (endingSoon.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.warning_amber_rounded,
                    label: 'Läuft bald ab',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  ...endingSoon.map((e) => _MedTile(pm: e)),
                  const SizedBox(height: 16),
                ],
                if (regular.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.medication_rounded,
                    label: 'Aktive Medikamente',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  ...regular.map((e) => _MedTile(pm: e)),
                ],
              ],
            ),
    );
  }
}

class _PetMed {
  final MobilePet pet;
  final MobileMedication med;
  const _PetMed({required this.pet, required this.med});
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MedTile extends StatefulWidget {
  final _PetMed pm;
  const _MedTile({required this.pm});

  @override
  State<_MedTile> createState() => _MedTileState();
}

class _MedTileState extends State<_MedTile> {
  bool _administering = false;

  Future<void> _administer(BuildContext ctx) async {
    setState(() => _administering = true);
    final ok = await ctx
        .read<MobileMedicationProvider>()
        .administer(widget.pm.pet.id, widget.pm.med.id);
    if (!mounted) return;
    setState(() => _administering = false);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(ok ? '${widget.pm.med.name} gegeben ✓' : 'Fehler beim Speichern'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.pm.med;
    final pet = widget.pm.pet;
    final cs = Theme.of(context).colorScheme;
    final endsSoon = med.endsSoon;
    final daysLeft = med.endDate?.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pet.name,
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (endsSoon && daysLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysLeft <= 0 ? 'Heute!' : 'Noch $daysLeft Tage',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.repeat_rounded, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  med.frequencyLabel,
                  style: TextStyle(fontSize: 13, color: cs.outline),
                ),
                if (med.dosage != null) ...[
                  Text('  ·  ', style: TextStyle(color: cs.outline)),
                  Text(
                    med.dosage!,
                    style: TextStyle(fontSize: 13, color: cs.outline),
                  ),
                ],
              ],
            ),
            if (med.instructions != null && med.instructions!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                med.instructions!,
                style: TextStyle(fontSize: 12, color: cs.outline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _administering ? null : () => _administer(context),
                child: _administering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gegeben'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isLoading;
  const _EmptyState({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Keine aktiven Medikamente',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
