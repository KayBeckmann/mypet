import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _microchipController = TextEditingController();
  PetSpecies _selectedSpecies = PetSpecies.dog;
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _microchipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
          TextButton.icon(
            onPressed: () => context.go('/animals'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Zurück'),
          ),
          const SizedBox(height: 16),

          Text(
            'Neues Tier hinzufügen',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fülle die Grunddaten deines Tieres aus.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 36),

          // Form
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
                  // Species selection
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
                        selectedColor:
                            LivingLedgerTheme.primary.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? LivingLedgerTheme.primary
                              : LivingLedgerTheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
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

                  // Name
                  Text('Name',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(hintText: 'Name des Tieres'),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Bitte Name eingeben' : null,
                  ),
                  const SizedBox(height: 20),

                  // Breed
                  Text('Rasse',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _breedController,
                    decoration: const InputDecoration(
                        hintText: 'z.B. Golden Retriever'),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Bitte Rasse eingeben'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Birth Date & Weight Row
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
                                  color:
                                      LivingLedgerTheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                      LivingLedgerTheme.radiusMd),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _birthDate != null
                                      ? '${_birthDate!.day.toString().padLeft(2, '0')}.${_birthDate!.month.toString().padLeft(2, '0')}.${_birthDate!.year}'
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

                  // Microchip
                  Text('Microchip-ID (optional)',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _microchipController,
                    decoration: const InputDecoration(
                        hintText: 'z.B. DE-276-02-123456'),
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => context.go('/animals'),
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
                            onPressed: _handleSubmit,
                            child: const Text('Tier hinzufügen'),
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

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));

    final pet = Pet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      breed: _breedController.text.trim(),
      species: _selectedSpecies,
      birthDate: _birthDate,
      weightKg: weight,
      microchipId: _microchipController.text.isNotEmpty
          ? _microchipController.text.trim()
          : null,
    );

    context.read<PetProvider>().addPet(pet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pet.name} wurde hinzugefügt!'),
        backgroundColor: LivingLedgerTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
        ),
      ),
    );

    context.go('/animals/${pet.id}');
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
