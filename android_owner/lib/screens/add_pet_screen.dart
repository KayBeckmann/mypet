import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

/// Formular zum Anlegen eines neuen Tieres.
///
/// Bislang gab es in der Android-App keinen Weg, ein Tier anzulegen —
/// PetsScreen zeigte nur die vorhandene Liste an. Web_owner hat dafür
/// AddAnimalScreen; dieses Formular deckt dieselbe Kernfunktion mobil ab
/// (ohne Foto-Upload, das ist hier bewusst nicht Teil des Fixes).
class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  String _species = 'dog';
  DateTime? _birthDate;
  bool _saving = false;

  static const _speciesOptions = <String, String>{
    'dog': 'Hund',
    'cat': 'Katze',
    'horse': 'Pferd',
    'bird': 'Vogel',
    'rabbit': 'Kaninchen',
    'reptile': 'Reptil',
    'other': 'Sonstiges',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 2),
      firstDate: DateTime(now.year - 40),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final weight = _weightCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));

    final ok = await context.read<MobilePetProvider>().create(
          name: _nameCtrl.text.trim(),
          species: _species,
          breed: _breedCtrl.text.trim(),
          birthDate: _birthDate,
          weightKg: weight,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_nameCtrl.text.trim()} wurde angelegt ✓')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tier konnte nicht angelegt werden'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neues Tier')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name *'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _species,
              decoration: const InputDecoration(labelText: 'Tierart *'),
              items: _speciesOptions.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _species = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _breedCtrl,
              decoration: const InputDecoration(labelText: 'Rasse'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(
                labelText: 'Gewicht',
                suffixText: 'kg',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Geburtsdatum'),
                child: Text(
                  _birthDate != null
                      ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'
                      : 'Nicht angegeben',
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Wird gespeichert…' : 'Tier anlegen'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
