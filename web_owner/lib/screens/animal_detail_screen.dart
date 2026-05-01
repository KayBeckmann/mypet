import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/pet.dart';
import '../providers/pet_provider.dart';
import '../providers/transfer_provider.dart';
import '../providers/health_provider.dart';
import '../models/media.dart';
import '../providers/media_provider.dart';
import '../providers/permission_provider.dart';
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
          // Back button
          TextButton.icon(
            onPressed: () => context.go('/animals'),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Zurück'),
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

  const _DetailCard({required this.title, required this.children});

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
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
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
          ...vaccinations.take(5).map((v) => Padding(
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
                              '${v.validUntil!.day}.${v.validUntil!.month}.${v.validUntil!.year}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: v.statusColor),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
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
              child: Text(
                '+ ${records.length - 5} weitere Einträge',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
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
