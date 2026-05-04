import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/health_provider.dart';
import '../models/media.dart';
import '../providers/media_provider.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/feeding_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/weight_provider.dart';
import '../providers/prescription_provider.dart';
import '../providers/owner_notes_provider.dart';
import '../providers/allergy_provider.dart';
import '../services/file_picker_service.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String petId;

  const AnimalDetailScreen({super.key, required this.petId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  bool _isUploadingPhoto = false;
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OwnerHealthProvider>().loadForPet(widget.petId);
      context.read<MediaProvider>().selectPet(widget.petId);
      context.read<MedicationProvider>().loadForPet(widget.petId);
      final wp = context.read<WeightProvider>();
      if (wp.selectedPetId != widget.petId) wp.loadForPet(widget.petId);
    });
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

    final hasPhoto = pet.imageUrl != null && pet.imageUrl!.isNotEmpty;
    final photoUrl = hasPhoto
        ? '${petProvider.apiBaseUrl}${pet.imageUrl}'
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + pet switcher
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/animals'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Zurück'),
              ),
              if (petProvider.pets.length > 1) ...[
                const Spacer(),
                DropdownButton<String>(
                  value: widget.petId,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.pets_rounded, size: 16),
                  items: petProvider.pets.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name),
                  )).toList(),
                  onChanged: (id) {
                    if (id != null && id != widget.petId) {
                      context.go('/animals/$id');
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Hero Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPetImage(pet, photoUrl),
              const SizedBox(width: 32),

              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusBadge(
                          label: 'ACTIVE RECORD',
                          color: LivingLedgerTheme.success,
                        ),
                        const SizedBox(width: 8),
                        if (pet.healthStatus == HealthStatus.attention)
                          _StatusBadge(
                            label: 'ACHTUNG',
                            color: LivingLedgerTheme.tertiary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      pet.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.breed} • ${pet.ageYears != null ? "${pet.ageYears} Jahre" : ""}'
                      '${pet.weightKg != null ? " • ${pet.weightKg} kg" : ""}',
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: LivingLedgerTheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/animals/${pet.id}/edit'),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Bearbeiten'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showShareWithVetDialog(context, pet),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Teilen mit TA'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showQrDialog(context, pet),
                          icon: const Icon(Icons.qr_code_rounded, size: 18),
                          label: const Text('QR-Code'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Detail Cards Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailCard(
                  title: 'CORE BIO-METRICS',
                  children: [
                    if (pet.microchipId != null)
                      _DetailRow(
                          label: 'Microchip-ID', value: pet.microchipId!),
                    if (pet.ownerName != null)
                      _DetailRow(label: 'Besitzer', value: pet.ownerName!),
                    if (pet.weightKg != null)
                      _DetailRow(
                          label: 'Gewicht', value: '${pet.weightKg} kg'),
                    _DetailRow(label: 'Spezies', value: pet.speciesLabel),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              Expanded(
                child: _DetailCard(
                  title: 'GESUNDHEITSSTATUS',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _healthBgColor(pet.healthStatus),
                        borderRadius: BorderRadius.circular(
                            LivingLedgerTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: _healthColor(pet.healthStatus),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            pet.healthStatusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: _healthColor(pet.healthStatus),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              Expanded(
                child: _DetailCard(
                  title: 'FÜTTERUNG',
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _feedingBgColor(pet.feedingStatus),
                        borderRadius: BorderRadius.circular(
                            LivingLedgerTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            color: _feedingColor(pet.feedingStatus),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.feedingStatusLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color:
                                          _feedingColor(pet.feedingStatus),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (pet.feedingNote != null)
                                Text(
                                  pet.feedingNote!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _feedingColor(
                                            pet.feedingStatus),
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context
                              .read<FeedingProvider>()
                              .selectPet(pet.id);
                          context.go('/feeding');
                        },
                        child: const Text('Zum Futterplan →'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Vaccination + Media Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _VaccinationCard(petId: widget.petId)),
              const SizedBox(width: 20),
              Expanded(
                child: _MediaCard(
                  petId: widget.petId,
                  apiBaseUrl: petProvider.apiBaseUrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Medical Records (full width)
          _MedicalRecordsCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Medications (full width)
          _MedicationsCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Allergies & Intolerances
          _AllergiesCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Prescriptions from vet
          _PrescriptionsCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Weight trend (full width)
          _WeightCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Upcoming appointments for this pet
          _AppointmentsCard(petId: widget.petId),
          const SizedBox(height: 20),

          // Owner notes
          _NotesCard(petId: widget.petId),
          const SizedBox(height: 32),

          // Transfer & Delete buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showTransferDialog(context, pet),
                icon: Icon(Icons.swap_horiz_rounded,
                    size: 18, color: LivingLedgerTheme.secondary),
                label: Text(
                  'Besitz übertragen',
                  style: TextStyle(color: LivingLedgerTheme.secondary),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _showDeleteDialog(context, pet),
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: LivingLedgerTheme.error),
                label: Text(
                  'Tier löschen',
                  style: TextStyle(color: LivingLedgerTheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Pet Image ──────────────────────────────────────────────────────────────

  Widget _buildPetImage(Pet pet, String? photoUrl) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LivingLedgerTheme.surfaceContainerLow,
            boxShadow: LivingLedgerTheme.ambientShadow,
          ),
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        pet.speciesIcon,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      pet.speciesIcon,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ),
          ),
        ),
        if (_isUploadingPhoto)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LivingLedgerTheme.onSurface.withValues(alpha: 0.5),
            ),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        if (!_isUploadingPhoto)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickAndUploadPhoto(pet.id),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LivingLedgerTheme.primary,
                  boxShadow: LivingLedgerTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto(String petId) async {
    final result = await FilePickerService.pickImage();
    if (result == null) return;

    setState(() => _isUploadingPhoto = true);

    final petProvider = context.read<PetProvider>();
    await petProvider.uploadPhoto(petId, result.bytes, result.name);

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
    }
  }

  // ── QR-Code ──────────────────────────────────────────────────────────────

  void _showQrDialog(BuildContext context, Pet pet) {
    final lines = [
      pet.name,
      '${pet.speciesLabel}${pet.breed.isNotEmpty ? ' · ${pet.breed}' : ''}',
      if (pet.microchipId != null && pet.microchipId!.isNotEmpty)
        'Chip: ${pet.microchipId}',
    ];
    final qrData = lines.join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR-Code: ${pet.name}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LivingLedgerTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LivingLedgerTheme.outlineVariant),
                ),
                child: Column(
                  children: lines.map((l) => Text(l,
                    style: const TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Zeige diesen Code am Tierarzt oder drucke ihn\nfür den Impfpass aus.',
                style: TextStyle(
                  fontSize: 12,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrData));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Info kopiert')),
              );
            },
            child: const Text('Kopieren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  // ── Teilen mit TA ──────────────────────────────────────────────────────────

  Future<void> _showShareWithVetDialog(BuildContext context, Pet pet) async {
    final emailCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedPermission = 'read';
    DateTime? endsAt;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.share_rounded, size: 20),
              const SizedBox(width: 8),
              Text('${pet.name} teilen'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Erteile einem Tierarzt, Dienstleister oder einer '
                    'Vertretung Zugriff auf ${pet.name}. '
                    'Die Person muss bereits bei MyPet registriert sein.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail der Person *',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@'))
                            ? 'Ungültige E-Mail'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPermission,
                    decoration:
                        const InputDecoration(labelText: 'Zugriffsstufe'),
                    items: const [
                      DropdownMenuItem(
                          value: 'read',
                          child: Text('Lesen — Profil & Akte einsehen')),
                      DropdownMenuItem(
                          value: 'write',
                          child: Text('Schreiben — Einträge hinzufügen')),
                      DropdownMenuItem(
                          value: 'manage',
                          child: Text('Verwalten — voller Zugriff')),
                    ],
                    onChanged: (v) =>
                        setDs(() => selectedPermission = v!),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event_busy, size: 16),
                    label: Text(endsAt != null
                        ? 'Bis: ${_dateFormat.format(endsAt!)}'
                        : 'Gültig bis (optional)'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365 * 3)),
                      );
                      if (date != null) setDs(() => endsAt = date);
                    },
                  ),
                  if (endsAt != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setDs(() => endsAt = null),
                        child: const Text('Datum entfernen'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notiz (optional)',
                      hintText: 'z.B. Urlaubsvertretung, Impftermin …',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Zugriff erteilen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final permProvider = context.read<PermissionProvider>();
      final ok = await permProvider.grantPermission(
        petId: pet.id,
        subjectType: 'user',
        subjectEmail: emailCtrl.text.trim(),
        permission: selectedPermission,
        endsAt: endsAt,
        note: noteCtrl.text.trim().isNotEmpty ? noteCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Zugriff auf ${pet.name} erteilt.'
                : permProvider.error ?? 'Fehler beim Erteilen'),
            backgroundColor:
                ok ? null : LivingLedgerTheme.error,
          ),
        );
      }
    }
  }

  // ── Transfer & Delete ──────────────────────────────────────────────────────

  Future<void> _showTransferDialog(BuildContext context, Pet pet) async {
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final transferProvider = context.read<TransferProvider>();

    await transferProvider.loadForPet(pet.id);
    final transfers = transferProvider.transfersForPet(pet.id);
    final pending = transfers.where((t) => t.status == 'pending').toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 20),
              const SizedBox(width: 8),
              Text('${pet.name} übertragen'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pending.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ausstehender Transfer:',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        ...pending.map((t) => Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        'An: ${t.toEmail}',
                                        style: const TextStyle(
                                            fontSize: 13))),
                                TextButton(
                                  onPressed: () async {
                                    await transferProvider.cancel(
                                        pet.id, t.id);
                                    setDs(() {});
                                  },
                                  child: const Text('Abbrechen'),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (pending.isEmpty) ...[
                  Text(
                    'Übertrage "${pet.name}" an eine andere Person. '
                    'Diese erhält eine Einladung per E-Mail.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail des neuen Besitzers *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nachricht (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Schließen'),
            ),
            if (pending.isEmpty)
              FilledButton(
                onPressed: () async {
                  if (emailCtrl.text.trim().isEmpty) return;
                  final ok = await transferProvider.initiate(
                    pet.id,
                    toEmail: emailCtrl.text.trim(),
                    message: messageCtrl.text,
                  );
                  if (ok && ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Übertragungsanfrage gesendet.')),
                    );
                  } else if (!ok && ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(transferProvider.error ?? 'Fehler')),
                    );
                  }
                },
                child: const Text('Übertragung starten'),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        ),
        title: Text('${pet.name} löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden. '
          'Alle Daten dieses Tieres werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<PetProvider>().removePet(pet.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) context.go('/animals');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LivingLedgerTheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  // ── Color helpers ──────────────────────────────────────────────────────────

  Color _healthColor(HealthStatus s) {
    switch (s) {
      case HealthStatus.optimal:
        return LivingLedgerTheme.success;
      case HealthStatus.good:
        return LivingLedgerTheme.primary;
      case HealthStatus.attention:
        return LivingLedgerTheme.tertiary;
      case HealthStatus.critical:
        return LivingLedgerTheme.error;
    }
  }

  Color _healthBgColor(HealthStatus s) =>
      _healthColor(s).withValues(alpha: 0.08);

  Color _feedingColor(FeedingStatus s) {
    switch (s) {
      case FeedingStatus.done:
        return LivingLedgerTheme.success;
      case FeedingStatus.upcoming:
        return LivingLedgerTheme.secondary;
      case FeedingStatus.overdue:
        return LivingLedgerTheme.error;
    }
  }

  Color _feedingBgColor(FeedingStatus s) =>
      _feedingColor(s).withValues(alpha: 0.08);
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? action;

  const _DetailCard(
      {required this.title, required this.children, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        boxShadow: LivingLedgerTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Vaccination Card ──────────────────────────────────────────────────────────

class _VaccinationCard extends StatelessWidget {
  final String petId;
  const _VaccinationCard({required this.petId});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<OwnerHealthProvider>();
    final vaccinations = health.vaccinationsForPet(petId);
    final loading = health.isLoading(petId);

    return _DetailCard(
      title: 'IMPFPASS',
      action: IconButton(
        icon: const Icon(Icons.add_rounded, size: 20),
        tooltip: 'Impfung eintragen',
        color: LivingLedgerTheme.primary,
        onPressed: () => _addVaccination(context, petId, health),
      ),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (vaccinations.isEmpty)
          _EmptyState(
            icon: Icons.vaccines_rounded,
            label: 'Noch keine Impfungen eingetragen',
          )
        else
          ...vaccinations.take(5).map((v) {
            final daysLeft = v.validUntil != null
                ? v.validUntil!.difference(DateTime.now()).inDays
                : null;
            final showReminder =
                daysLeft != null && daysLeft >= 0 && daysLeft <= 60;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: v.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.vaccineName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (v.validUntil != null)
                          Text(
                            '${v.statusLabel} bis '
                            '${v.validUntil!.day}.${v.validUntil!.month}.${v.validUntil!.year}'
                            '${daysLeft != null && daysLeft >= 0 ? ' (noch $daysLeft T)' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: v.statusColor),
                          ),
                      ],
                    ),
                  ),
                  if (showReminder)
                    Tooltip(
                      message: 'Erinnerung anlegen',
                      child: InkWell(
                        onTap: () => _quickReminder(
                            context, petId, v.vaccineName, v.validUntil!),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.alarm_add_rounded,
                              size: 16, color: v.statusColor),
                        ),
                      ),
                    ),
                  Tooltip(
                    message: 'Löschen',
                    child: InkWell(
                      onTap: () async {
                        final ok = await health.deleteVaccination(petId, v.id);
                        if (context.mounted && !ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fehler beim Löschen')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16,
                            color: LivingLedgerTheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

Future<void> _addVaccination(BuildContext context, String petId,
    OwnerHealthProvider health) async {
  final nameCtrl = TextEditingController();
  final batchCtrl = TextEditingController();
  final manuCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  DateTime? validFrom;
  DateTime? validUntil;
  final fmt = DateFormat('dd.MM.yyyy');
  final formKey = GlobalKey<FormState>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDs) => AlertDialog(
        title: const Text('Impfung eintragen'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Impfstoff *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pflichtfeld'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: batchCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Chargennummer'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: manuCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Hersteller'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event, size: 16),
                          label: Text(validFrom != null
                              ? fmt.format(validFrom!)
                              : 'Geimpft am'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (d != null) setDs(() => validFrom = d);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available, size: 16),
                          label: Text(validUntil != null
                              ? fmt.format(validUntil!)
                              : 'Gültig bis'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2040),
                            );
                            if (d != null) setDs(() => validUntil = d);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Notizen'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Eintragen'),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && context.mounted) {
    final ok = await health.addVaccination(petId, {
      'vaccine_name': nameCtrl.text.trim(),
      if (batchCtrl.text.trim().isNotEmpty) 'batch_number': batchCtrl.text.trim(),
      if (manuCtrl.text.trim().isNotEmpty) 'manufacturer': manuCtrl.text.trim(),
      if (validFrom != null) 'valid_from': validFrom!.toIso8601String().split('T').first,
      if (validUntil != null) 'valid_until': validUntil!.toIso8601String().split('T').first,
      if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Impfung eingetragen' : 'Fehler beim Eintragen'),
      ));
    }
  }
}

Future<void> _quickReminder(BuildContext context, String petId,
    String vaccineName, DateTime validUntil) async {
  final remindAt = validUntil.subtract(const Duration(days: 14));
  final effectiveRemindAt =
      remindAt.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(days: 1)) : remindAt;

  final ok = await context.read<ReminderProvider>().create(
        title: 'Impfung auffrischen: $vaccineName',
        message: 'Läuft ab am ${validUntil.day}.${validUntil.month}.${validUntil.year}',
        type: 'vaccination',
        petId: petId,
        remindAt: effectiveRemindAt,
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Erinnerung angelegt' : 'Fehler beim Anlegen'),
    ));
  }
}

// ── Media Card ────────────────────────────────────────────────────────────────

class _MediaCard extends StatelessWidget {
  final String petId;
  final String apiBaseUrl;

  const _MediaCard({required this.petId, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.watch<MediaProvider>();
    final loading = mediaProvider.loading;
    final items = mediaProvider.selectedPetId == petId
        ? mediaProvider.media.take(4).toList()
        : <PetMedia>[];

    return _DetailCard(
      title: 'DOKUMENTE & BILDER',
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (items.isEmpty)
          _EmptyState(
            icon: Icons.folder_open_rounded,
            label: 'Noch keine Dokumente hochgeladen',
          )
        else ...[
          ...items.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _mediaIcon(m.mediaType),
                      size: 18,
                      color: LivingLedgerTheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.displayName,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      m.sizeLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/records'),
              child: const Text('Alle Dokumente →'),
            ),
          ),
        ],
      ],
    );
  }

  IconData _mediaIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'xray':
        return Icons.biotech_outlined;
      case 'document':
      default:
        return Icons.description_outlined;
    }
  }
}

// ── Medical Records Card ──────────────────────────────────────────────────────

class _MedicalRecordsCard extends StatelessWidget {
  final String petId;
  const _MedicalRecordsCard({required this.petId});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<OwnerHealthProvider>();
    final records = health.recordsForPet(petId);
    final loading = health.isLoading(petId);
    final fmt = DateFormat('dd.MM.yyyy');

    return _DetailCard(
      title: 'MEDIZINISCHE AKTE',
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (records.isEmpty)
          _EmptyState(
            icon: Icons.medical_services_outlined,
            label: 'Noch keine Einträge in der Akte',
          )
        else ...[
          ...records.take(5).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: LivingLedgerTheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(
                            LivingLedgerTheme.radiusFull),
                      ),
                      child: Text(
                        r.typeLabel,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: LivingLedgerTheme.onSecondaryContainer,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (r.vetName != null || r.recordedAt != null)
                            Text(
                              [
                                if (r.vetName != null) r.vetName!,
                                if (r.recordedAt != null)
                                  fmt.format(r.recordedAt!),
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (r.diagnosis != null &&
                              r.diagnosis!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                r.diagnosis!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (records.length > 5)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showAllRecords(context, records, fmt),
                child: Text(
                  '+ ${records.length - 5} weitere →',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: LivingLedgerTheme.primary,
                      ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  void _showAllRecords(BuildContext context, List<MedicalRecord> records, DateFormat fmt) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Medizinische Akte'),
        content: SizedBox(
          width: 600,
          height: 500,
          child: ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final r = records[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LivingLedgerTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusMd),
                  border: Border.all(color: LivingLedgerTheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: LivingLedgerTheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                                LivingLedgerTheme.radiusFull),
                          ),
                          child: Text(
                            r.typeLabel,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (r.recordedAt != null)
                          Text(
                            fmt.format(r.recordedAt!),
                            style: const TextStyle(
                                fontSize: 11,
                                color: LivingLedgerTheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                    if (r.vetName != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        r.vetName!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: LivingLedgerTheme.onSurfaceVariant),
                      ),
                    ],
                    if (r.diagnosis != null && r.diagnosis!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        r.diagnosis!,
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: LivingLedgerTheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }
}

// ── Medications Card ──────────────────────────────────────────────────────────

class _MedicationsCard extends StatelessWidget {
  final String petId;
  const _MedicationsCard({required this.petId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final loading = provider.isLoading(petId);
    final active = provider.activeForPet(petId);

    return _DetailCard(
      title: 'MEDIKAMENTE',
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (active.isEmpty)
          _EmptyState(
            icon: Icons.medication_outlined,
            label: 'Keine aktiven Medikamente',
          )
        else ...[
          ...active.take(4).map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: LivingLedgerTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                            LivingLedgerTheme.radiusFull),
                      ),
                      child: Text(
                        m.frequencyLabel,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: LivingLedgerTheme.primary,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (m.dosage != null)
                            Text(m.dosage!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: LivingLedgerTheme.secondary)),
                        ],
                      ),
                    ),
                    _QuickAdministerButton(petId: petId, medication: m),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.read<MedicationProvider>().loadForPet(petId);
                context.go('/medications');
              },
              child: const Text('Alle Medikamente →'),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAdministerButton extends StatefulWidget {
  final String petId;
  final Medication medication;
  const _QuickAdministerButton(
      {required this.petId, required this.medication});

  @override
  State<_QuickAdministerButton> createState() =>
      _QuickAdministerButtonState();
}

class _QuickAdministerButtonState extends State<_QuickAdministerButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return _busy
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Tooltip(
            message: 'Gegeben',
            child: InkWell(
              onTap: () => _administer(context),
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusFull),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      LivingLedgerTheme.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: LivingLedgerTheme.success,
                ),
              ),
            ),
          );
  }

  Future<void> _administer(BuildContext context) async {
    setState(() => _busy = true);
    final ok = await context
        .read<MedicationProvider>()
        .administer(widget.petId, widget.medication.id);
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '${widget.medication.name} als gegeben protokolliert.'
              : 'Fehler beim Speichern'),
          backgroundColor: ok ? null : LivingLedgerTheme.error,
        ),
      );
    }
  }
}

// ── Weight Card ───────────────────────────────────────────────────────────────

class _WeightCard extends StatelessWidget {
  final String petId;
  const _WeightCard({required this.petId});

  Future<void> _showGoalDialog(BuildContext context, WeightProvider provider, Pet pet) async {
    final goalCtrl = TextEditingController(
      text: pet.weightGoalKg?.toStringAsFixed(1) ?? '',
    );
    final noteCtrl = TextEditingController(text: pet.weightGoalNote ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gewichtsziel setzen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: goalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Zielgewicht (kg)',
                hintText: 'z.B. 25.0',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Notiz',
                hintText: 'z.B. Tierarzt-Empfehlung',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.setGoal(goalKg: null, goalNote: null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Ziel entfernen'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () async {
              final goal = double.tryParse(goalCtrl.text.trim());
              await provider.setGoal(
                goalKg: goal,
                goalNote: noteCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeightProvider>();
    final petProvider = context.watch<PetProvider>();
    final loading = provider.loading;
    final entries = provider.selectedPetId == petId ? provider.entries : <WeightEntry>[];
    final pet = petProvider.pets.where((p) => p.id == petId).firstOrNull;

    return _DetailCard(
      title: 'GEWICHTSVERLAUF',
      action: IconButton(
        icon: const Icon(Icons.flag_outlined, size: 18),
        tooltip: 'Gewichtsziel setzen',
        onPressed: pet != null ? () => _showGoalDialog(context, provider, pet) : null,
      ),
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (entries.isEmpty)
          Row(
            children: [
              Expanded(
                child: _EmptyState(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Noch kein Gewicht eingetragen',
                ),
              ),
              _AddWeightButton(provider: provider),
            ],
          )
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Current weight + trend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entries.last.weightKg.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (entries.length >= 2)
                      _TrendBadge(
                        current: entries.last.weightKg,
                        previous: entries[entries.length - 2].weightKg,
                      ),
                    if (pet?.weightGoalKg != null)
                      _WeightGoalBadge(
                        current: entries.last.weightKg,
                        goal: pet!.weightGoalKg!,
                      ),
                  ],
                ),
              ),
              // Mini sparkline
              if (entries.length >= 2)
                SizedBox(
                  width: 120,
                  height: 48,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                      values: entries
                        .skip(math.max(0, entries.length - 8))
                        .map((e) => e.weightKg)
                        .toList(),
                      color: LivingLedgerTheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              _AddWeightButton(provider: provider),
            ],
          ),
          const SizedBox(height: 12),
          // Last 3 entries
          ...entries.reversed.take(3).map((e) {
            final fmt = DateFormat('dd.MM.yy');
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    fmt.format(e.recordedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${e.weightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (e.notes != null && e.notes!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.notes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/weight'),
              child: const Text('Vollständiger Verlauf →'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double current;
  final double previous;
  const _TrendBadge({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    final up = diff > 0;
    final color = up ? LivingLedgerTheme.tertiary : LivingLedgerTheme.success;
    final sign = up ? '+' : '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          '$sign${diff.toStringAsFixed(1)} kg',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _WeightGoalBadge extends StatelessWidget {
  final double current;
  final double goal;
  const _WeightGoalBadge({required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    final diff = current - goal;
    final reached = diff.abs() < 0.2;
    final aboveGoal = diff > 0;
    final color = reached
        ? LivingLedgerTheme.success
        : aboveGoal
            ? LivingLedgerTheme.tertiary
            : LivingLedgerTheme.primary;
    final label = reached
        ? 'Ziel erreicht!'
        : '${aboveGoal ? '' : ''}${diff.toStringAsFixed(1)} kg zum Ziel (${goal.toStringAsFixed(1)} kg)';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AddWeightButton extends StatelessWidget {
  final WeightProvider provider;
  const _AddWeightButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('Erfassen'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: () => _showAddDialog(context),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gewicht erfassen'),
        content: SizedBox(
          width: 340,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: weightCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Gewicht (kg) *',
                    hintText: '4.5',
                    suffixText: 'kg',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Ungültiger Wert';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notiz (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final kg = double.parse(weightCtrl.text.trim().replaceAll(',', '.'));
      final ok = await provider.add(
        weightKg: kg,
        notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Gewicht gespeichert.' : 'Fehler beim Speichern'),
            backgroundColor: ok ? null : LivingLedgerTheme.error,
          ),
        );
      }
    }
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = maxV - minV;
    final effectiveRange = range < 0.01 ? 1.0 : range;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final step = size.width / (values.length - 1);
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = i * step;
      final y = size.height -
          ((values[i] - minV) / effectiveRange) * size.height * 0.85 -
          size.height * 0.075;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Dot for last value
    final lastX = (values.length - 1) * step;
    final lastY = size.height -
        ((values.last - minV) / effectiveRange) * size.height * 0.85 -
        size.height * 0.075;
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.5,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// ── Notes Card ───────────────────────────────────────────────────────────────

class _NotesCard extends StatefulWidget {
  final String petId;
  const _NotesCard({required this.petId});

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OwnerNotesProvider>().loadForPet(widget.petId);
      });
    }
  }

  Future<void> _showAddDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notiz hinzufügen'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<OwnerNotesProvider>().create(
            widget.petId,
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim().isNotEmpty
                ? contentCtrl.text.trim()
                : null,
          );
    }
  }

  Future<void> _showEditDialog(PetNote note) async {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notiz bearbeiten'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<OwnerNotesProvider>().update(
            widget.petId,
            note.id,
            title: titleCtrl.text.trim(),
            content: contentCtrl.text.trim().isNotEmpty
                ? contentCtrl.text.trim()
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerNotesProvider>();
    final notes = provider.forPet(widget.petId);
    final df = DateFormat('dd.MM.yyyy');

    return _DetailCard(
      title: 'NOTIZEN',
      action: IconButton(
        icon: const Icon(Icons.add_rounded, size: 18),
        onPressed: _showAddDialog,
        tooltip: 'Notiz hinzufügen',
        color: LivingLedgerTheme.primary,
      ),
      children: [
        if (provider.isLoading(widget.petId))
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (notes.isEmpty)
          const _EmptyState(
            icon: Icons.sticky_note_2_outlined,
            label: 'Noch keine Notizen',
          )
        else
          ...notes.map((note) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.sticky_note_2_outlined,
                          size: 18, color: LivingLedgerTheme.primary),
                      title: Text(note.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: note.content != null && note.content!.isNotEmpty
                          ? Text(
                              note.content!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: LivingLedgerTheme.onSurfaceVariant),
                            )
                          : Text(
                              df.format(note.updatedAt),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: LivingLedgerTheme.onSurfaceVariant),
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            tooltip: 'Bearbeiten',
                            onPressed: () => _showEditDialog(note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            color: LivingLedgerTheme.error,
                            tooltip: 'Löschen',
                            onPressed: () async {
                              final ok = await context
                                  .read<OwnerNotesProvider>()
                                  .delete(widget.petId, note.id);
                              if (!ok && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Löschen fehlgeschlagen')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
      ],
    );
  }
}

// ── Prescriptions Card ───────────────────────────────────────────────────────

class _PrescriptionsCard extends StatefulWidget {
  final String petId;
  const _PrescriptionsCard({required this.petId});

  @override
  State<_PrescriptionsCard> createState() => _PrescriptionsCardState();
}

class _PrescriptionsCardState extends State<_PrescriptionsCard> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OwnerPrescriptionProvider>().loadForPet(widget.petId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerPrescriptionProvider>();
    final prescriptions = provider.forPet(widget.petId);
    final df = DateFormat('dd.MM.yyyy');

    return _DetailCard(
      title: 'REZEPTE',
      children: [
        if (provider.isLoading(widget.petId))
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (prescriptions.isEmpty)
          const _EmptyState(
            icon: Icons.receipt_long_outlined,
            label: 'Keine Rezepte vorhanden',
          )
        else
          ...prescriptions.take(5).map((p) {
            final expired = p.isExpired;
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: expired
                            ? LivingLedgerTheme.onSurfaceVariant
                            : LivingLedgerTheme.primary,
                      ),
                      title: Text(
                        p.drugName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: expired
                              ? LivingLedgerTheme.onSurfaceVariant
                              : null,
                          decoration:
                              expired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (p.dosage != null) p.dosage!,
                          if (p.frequency != null) p.frequency!,
                          if (p.issuedByName != null) 'Dr. ${p.issuedByName}',
                          df.format(p.issuedAt),
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: expired
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: LivingLedgerTheme.error
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Abgelaufen',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: LivingLedgerTheme.error,
                                ),
                              ),
                            )
                          : null,
                    );
                  }),
      ],
    );
  }
}

// ── Allergies Card ────────────────────────────────────────────────────────────

class _AllergiesCard extends StatefulWidget {
  final String petId;
  const _AllergiesCard({required this.petId});

  @override
  State<_AllergiesCard> createState() => _AllergiesCardState();
}

class _AllergiesCardState extends State<_AllergiesCard> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AllergyProvider>().loadForPet(widget.petId);
      });
    }
  }

  Future<void> _showAddDialog([PetAllergy? existing]) async {
    final allergenCtrl = TextEditingController(text: existing?.allergen);
    final categoryCtrl = TextEditingController(text: existing?.category);
    final reactionCtrl = TextEditingController(text: existing?.reaction);
    final notesCtrl = TextEditingController(text: existing?.notes);
    final diagCtrl = TextEditingController(text: existing?.diagnosedAt?.substring(0, 10));
    String severity = existing?.severity ?? 'moderate';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'Allergie eintragen' : 'Allergie bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: allergenCtrl,
                  decoration: const InputDecoration(labelText: 'Allergen / Auslöser *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    hintText: 'z.B. Futter, Umwelt, Medikament',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Schweregrad'),
                  items: const [
                    DropdownMenuItem(value: 'mild', child: Text('Leicht')),
                    DropdownMenuItem(value: 'moderate', child: Text('Mittel')),
                    DropdownMenuItem(value: 'severe', child: Text('Stark')),
                  ],
                  onChanged: (v) => setSt(() => severity = v ?? severity),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reactionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reaktion',
                    hintText: 'z.B. Juckreiz, Erbrechen, Atemnot',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: diagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Datum der Diagnose',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notizen'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            FilledButton(
              onPressed: () async {
                final allergen = allergenCtrl.text.trim();
                if (allergen.isEmpty) return;
                final body = {
                  'allergen': allergen,
                  if (categoryCtrl.text.trim().isNotEmpty) 'category': categoryCtrl.text.trim(),
                  'severity': severity,
                  if (reactionCtrl.text.trim().isNotEmpty) 'reaction': reactionCtrl.text.trim(),
                  if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
                  if (diagCtrl.text.trim().isNotEmpty) 'diagnosed_at': diagCtrl.text.trim(),
                };
                bool ok;
                if (existing == null) {
                  ok = await context.read<AllergyProvider>().addAllergy(widget.petId, body);
                } else {
                  ok = await context.read<AllergyProvider>().updateAllergy(widget.petId, existing.id, body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fehler beim Speichern')));
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(PetAllergy allergy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allergie löschen'),
        content: Text('„${allergy.allergen}" wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LivingLedgerTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<AllergyProvider>().deleteAllergy(widget.petId, allergy.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AllergyProvider>();
    final allergies = provider.forPet(widget.petId);

    return _DetailCard(
      title: 'ALLERGIEN & UNVERTRÄGLICHKEITEN',
      action: IconButton(
        icon: const Icon(Icons.add, size: 18),
        onPressed: () => _showAddDialog(),
        tooltip: 'Allergie eintragen',
      ),
      children: [
        if (provider.isLoading(widget.petId))
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (allergies.isEmpty)
          const _EmptyState(
            icon: Icons.warning_amber_outlined,
            label: 'Keine Allergien eingetragen',
          )
        else
          ...allergies.map((a) => ListTile(
                dense: true,
                leading: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.severityColor,
                  ),
                ),
                title: Text(
                  a.allergen,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    if (a.category != null) a.category!,
                    a.severityLabel,
                    if (a.reaction != null) a.reaction!,
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: a.severityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.severityLabel,
                        style: TextStyle(fontSize: 10, color: a.severityColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: () => _showAddDialog(a),
                      tooltip: 'Bearbeiten',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: LivingLedgerTheme.error),
                      onPressed: () => _delete(a),
                      tooltip: 'Löschen',
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon,
                size: 36,
                color: LivingLedgerTheme.onSurfaceVariant
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointments Card ─────────────────────────────────────────────────────────

class _AppointmentsCard extends StatelessWidget {
  final String petId;
  const _AppointmentsCard({required this.petId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final upcoming = provider.appointments
        .where((a) =>
            a.petId == petId &&
            (a.status == AppointmentStatus.requested ||
                a.status == AppointmentStatus.confirmed))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return _DetailCard(
      title: 'ANSTEHENDE TERMINE',
      children: [
        ...upcoming.take(3).map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: a.status == AppointmentStatus.confirmed
                          ? LivingLedgerTheme.secondary.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(LivingLedgerTheme.radiusFull),
                    ),
                    child: Text(
                      '${a.scheduledAt.day}.${a.scheduledAt.month}. ${a.scheduledAt.hour.toString().padLeft(2, '0')}:${a.scheduledAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: a.status == AppointmentStatus.confirmed
                            ? LivingLedgerTheme.secondary
                            : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.title,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/appointments'),
            child: const Text('Alle Termine →'),
          ),
        ),
      ],
    );
  }
}
