import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class EditAnimalScreen extends StatefulWidget {
  final String petId;

  const EditAnimalScreen({super.key, required this.petId});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  final _notesController = TextEditingController();
  PetSpecies _selectedSpecies = PetSpecies.dog;
  DateTime? _birthDate;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initialize(Pet pet) {
    if (_initialized) return;
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _weightController.text = pet.weightKg?.toString() ?? '';
    _microchipController.text = pet.microchipId ?? '';
    _notesController.text = pet.notes ?? '';
    _selectedSpecies = pet.species;
    _birthDate = pet.birthDate;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pet = petProvider.getPetById(widget.petId);

    if (pet == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: LivingLedgerTheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Tier nicht gefunden',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/animals'),
              child: const Text('Zurück zur Übersicht'),
            ),
          ],
        ),
      );
    }

    _initialize(pet);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/animals/${widget.petId}'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Zurück'),
          ),
          const SizedBox(height: 16),
          Text(
            '${pet.name} bearbeiten',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Aktualisiere die Angaben für dein Tier.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 36),
          Container(
            constraints: const BoxConstraints(maxWidth: 640),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: LivingLedgerTheme.surfaceContainerLowest,
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusXl),
              boxShadow: LivingLedgerTheme.cardShadow,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tierart',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: PetSpecies.values.map((species) {
                      final isSelected = species == _selectedSpecies;
                      return ChoiceChip(
                        label: Text(_speciesLabel(species)),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedSpecies = species),
                        selectedColor: LivingLedgerTheme.primary
                            .withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? LivingLedgerTheme.primary
                              : LivingLedgerTheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              LivingLedgerTheme.radiusFull),
                          side: BorderSide(
                            color: isSelected
                                ? LivingLedgerTheme.primary
                                : LivingLedgerTheme.outlineVariant
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Text('Name',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(hintText: 'Name des Tieres'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Bitte Name eingeben'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  Text('Rasse',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(
                        hintText: 'z.B. Golden Retriever'),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Geburtsdatum',
                                style:
                                    Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _pickDate(context),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                decoration: BoxDecoration(
                                  color: LivingLedgerTheme
                                      .surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                      LivingLedgerTheme.radiusMd),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _birthDate != null
                                      ? _formatDate(_birthDate!)
                                      : 'Datum wählen',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: _birthDate != null
                                            ? LivingLedgerTheme.onSurface
                                            : LivingLedgerTheme
                                                .onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gewicht (kg)',
                                style:
                                    Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  hintText: 'z.B. 32.5'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Microchip-ID (optional)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _microchipController,
                    decoration: const InputDecoration(
                        hintText: 'z.B. DE-276-02-123456'),
                  ),
                  const SizedBox(height: 20),

                  Text('Notizen (optional)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: 'Besonderheiten, Futterplan-Hinweise, ...',
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () =>
                                    context.go('/animals/${widget.petId}'),
                            child: const Text('Abbrechen'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _handleSubmit(pet),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Änderungen speichern'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: LivingLedgerTheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSubmit(Pet currentPet) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.'));
    final petProvider = context.read<PetProvider>();

    final updated = Pet(
      id: currentPet.id,
      name: _nameController.text.trim(),
      breed: _breedController.text.trim(),
      species: _selectedSpecies,
      birthDate: _birthDate,
      weightKg: weight,
      microchipId: _microchipController.text.trim().isEmpty
          ? null
          : _microchipController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      imageUrl: currentPet.imageUrl,
    );

    final success = await petProvider.updatePet(updated);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updated.name} wurde aktualisiert!'),
          backgroundColor: LivingLedgerTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
          ),
        ),
      );
      context.go('/animals/${widget.petId}');
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              petProvider.error ?? 'Fehler beim Aktualisieren des Tieres'),
          backgroundColor: LivingLedgerTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day.$month.${d.year}';
  }

  String _speciesLabel(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return '🐕 Hund';
      case PetSpecies.cat:
        return '🐈 Katze';
      case PetSpecies.horse:
        return '🐎 Pferd';
      case PetSpecies.bird:
        return '🐦 Vogel';
      case PetSpecies.rabbit:
        return '🐇 Kaninchen';
      case PetSpecies.reptile:
        return '🦎 Reptil';
      case PetSpecies.other:
        return '🐾 Sonstiges';
    }
  }
}
