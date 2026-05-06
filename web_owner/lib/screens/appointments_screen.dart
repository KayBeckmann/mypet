import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/pet_provider.dart';
import '../models/pet.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  bool _showAllPast = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    return Scaffold(
      backgroundColor: LivingLedgerTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Termine',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Kommende und vergangene Termine',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LivingLedgerTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showBookDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Termin anfragen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LivingLedgerTheme.primary,
                    foregroundColor: LivingLedgerTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(LivingLedgerTheme.radiusFull),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (provider.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (provider.error != null)
              Expanded(
                child: Center(
                  child: Text('Fehler: ${provider.error}',
                      style: TextStyle(color: LivingLedgerTheme.error)),
                ),
              )
            else
              Expanded(
                child: Builder(builder: (context) {
                  final pending = provider.upcoming
                      .where((a) => a.status == AppointmentStatus.requested)
                      .toList();
                  final confirmedAppts = provider.upcoming
                      .where((a) => a.status == AppointmentStatus.confirmed)
                      .toList();
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Ausstehend
                      if (pending.isNotEmpty) ...[
                        _SectionHeader(
                            title: 'Ausstehend', count: pending.length),
                        const SizedBox(height: 12),
                        ...pending.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AppointmentTile(
                                appointment: a,
                                onCancel: () => _confirmCancel(context, a),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      // Bestätigt
                      if (confirmedAppts.isNotEmpty) ...[
                        _SectionHeader(
                            title: 'Bestätigt', count: confirmedAppts.length),
                        const SizedBox(height: 12),
                        ...confirmedAppts.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AppointmentTile(
                                appointment: a,
                                onCancel: () => _confirmCancel(context, a),
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],

                      if (provider.upcoming.isEmpty)
                        _EmptyHint(
                          icon: Icons.event_available_rounded,
                          text: 'Keine kommenden Termine',
                        ),

                      // Vergangen
                      if (provider.past.isNotEmpty) ...[
                        _SectionHeader(
                            title: 'Vergangen', count: provider.past.length),
                        const SizedBox(height: 12),
                        ...(_showAllPast
                                ? provider.past
                                : provider.past.take(5).toList())
                            .map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _AppointmentTile(
                                    appointment: a,
                                    onRate: a.status == AppointmentStatus.completed &&
                                            a.organizationId != null
                                        ? () => _showRatingDialog(context, a)
                                        : null,
                                  ),
                                )),
                        if (provider.past.length > 5) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              icon: Icon(_showAllPast
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              label: Text(_showAllPast
                                  ? 'Weniger anzeigen'
                                  : 'Alle ${provider.past.length} anzeigen'),
                              onPressed: () =>
                                  setState(() => _showAllPast = !_showAllPast),
                            ),
                          ),
                        ],
                      ],
                    ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBookDialog(BuildContext context) async {
    final pets = context.read<PetProvider>().pets;
    if (pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte zuerst ein Tier anlegen.')),
      );
      return;
    }
    await showDialog(
      context: context,
      builder: (ctx) => BookAppointmentDialog(pets: pets),
    );
  }

  Future<void> _showRatingDialog(BuildContext context, Appointment a) async {
    int selectedRating = 5;
    final reviewCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: Text('${a.organizationName ?? 'Praxis'} bewerten'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wie war dein Termin?',
                    style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setDs(() => selectedRating = star),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reviewCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kommentar (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Deine Erfahrung...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Bewertung abgeben')),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final api = context.read<ApiService>();
        await api.post('/organizations/${a.organizationId}/ratings', body: {
          'rating': selectedRating,
          'appointment_id': a.id,
          if (reviewCtrl.text.trim().isNotEmpty) 'review': reviewCtrl.text.trim(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bewertung gespeichert. Danke!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmCancel(BuildContext context, Appointment a) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin absagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Termin "${a.title}" wirklich absagen?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Grund (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: LivingLedgerTheme.error),
            child: const Text('Absagen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<AppointmentProvider>()
          .cancel(a.id, reason: reasonController.text.trim().isEmpty
              ? null
              : reasonController.text.trim());
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: LivingLedgerTheme.onSurfaceVariant,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: LivingLedgerTheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: LivingLedgerTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(text,
                style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;

  const _AppointmentTile({required this.appointment, this.onCancel, this.onRate});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    final isCancelled =
        appointment.status == AppointmentStatus.cancelled ||
        appointment.status == AppointmentStatus.noShow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Date/time
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.dateLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                    Text(
                      appointment.timeLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${appointment.durationMinutes} min',
                      style: TextStyle(
                          fontSize: 11,
                          color: LivingLedgerTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Title + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (appointment.petName != null)
                          _MetaChip(
                              icon: Icons.pets_rounded,
                              text: appointment.petName!),
                        if (appointment.organizationName != null)
                          _MetaChip(
                              icon: Icons.business_rounded,
                              text: appointment.organizationName!)
                        else if (appointment.providerName != null)
                          _MetaChip(
                              icon: Icons.person_outline_rounded,
                              text: appointment.providerName!),
                        if (appointment.location != null)
                          _MetaChip(
                              icon: Icons.location_on_outlined,
                              text: appointment.location!),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                          LivingLedgerTheme.radiusFull),
                    ),
                    child: Text(
                      appointment.statusLabel,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (onCancel != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onCancel,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 13,
                                color: LivingLedgerTheme.error),
                            const SizedBox(width: 3),
                            Text('Absagen',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: LivingLedgerTheme.error)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // Description
          if (appointment.description != null &&
              appointment.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              appointment.description!,
              style: TextStyle(
                  fontSize: 13,
                  color: LivingLedgerTheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Treatment notes (for completed appointments)
          if (appointment.status == AppointmentStatus.completed &&
              (appointment.diagnosis != null || appointment.treatmentNotes != null)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: LivingLedgerTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: LivingLedgerTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_information_outlined, size: 13, color: LivingLedgerTheme.primary),
                      const SizedBox(width: 4),
                      Text('Behandlungsbericht', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LivingLedgerTheme.primary)),
                    ],
                  ),
                  if (appointment.diagnosis != null) ...[
                    const SizedBox(height: 4),
                    Text('Diagnose: ${appointment.diagnosis}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                  if (appointment.treatmentNotes != null) ...[
                    const SizedBox(height: 2),
                    Text(appointment.treatmentNotes!, style: TextStyle(fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],

          // Rate button for completed appointments
          if (onRate != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.star_border_rounded, size: 16, color: Colors.amber),
                label: const Text('Bewerten', style: TextStyle(fontSize: 12, color: Colors.amber)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
            ),
          ],

          // Cancellation reason
          if (isCancelled && appointment.cancelledReason != null &&
              appointment.cancelledReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Grund: ${appointment.cancelledReason}',
                      style:
                          TextStyle(fontSize: 12, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.requested:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return LivingLedgerTheme.primary;
      case AppointmentStatus.completed:
        return LivingLedgerTheme.success;
      case AppointmentStatus.cancelled:
        return LivingLedgerTheme.error;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: LivingLedgerTheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: LivingLedgerTheme.onSurfaceVariant)),
      ],
    );
  }
}

class BookAppointmentDialog extends StatefulWidget {
  final List<Pet> pets;
  final Map<String, dynamic>? preselectedOrg;
  const BookAppointmentDialog({required this.pets, this.preselectedOrg});

  @override
  State<BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<BookAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Pet? _selectedPet;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  int _duration = 30;
  bool _saving = false;

  // Provider/Org selection
  List<Map<String, dynamic>> _organizations = [];
  Map<String, dynamic>? _selectedOrg;
  bool _loadingOrgs = false;

  @override
  void initState() {
    super.initState();
    if (widget.pets.isNotEmpty) _selectedPet = widget.pets.first;
    if (widget.preselectedOrg != null) {
      _selectedOrg = widget.preselectedOrg;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrganizations());
  }

  Future<void> _loadOrganizations() async {
    setState(() => _loadingOrgs = true);
    try {
      final api = context.read<ApiService>();
      final data = await api.get('/organizations/search?type=vet_practice');
      final orgs = (data['organizations'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      // Also load service providers
      final data2 = await api.get('/organizations/search?type=service_provider');
      final orgs2 = (data2['organizations'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      final all = [...orgs, ...orgs2];
      setState(() {
        _organizations = all;
        _loadingOrgs = false;
        // Re-match preselected org with loaded data (uses same ID)
        if (widget.preselectedOrg != null && _selectedOrg != null) {
          final preId = widget.preselectedOrg!['id'];
          final match = all.where((o) => o['id'] == preId).firstOrNull;
          if (match != null) _selectedOrg = match;
        }
      });
    } catch (_) {
      setState(() => _loadingOrgs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Termin anfragen'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pet
                DropdownButtonFormField<Pet>(
                  value: _selectedPet,
                  decoration: const InputDecoration(
                    labelText: 'Tier',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.pets
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name),
                          ))
                      .toList(),
                  onChanged: (p) => setState(() => _selectedPet = p),
                  validator: (v) => v == null ? 'Tier auswählen' : null,
                ),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Titel eingeben' : null,
                ),
                const SizedBox(height: 12),

                // Date/Time
                InkWell(
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Datum & Uhrzeit',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      '${_scheduledAt.day}.${_scheduledAt.month}.${_scheduledAt.year}  '
                      '${_scheduledAt.hour.toString().padLeft(2, '0')}:'
                      '${_scheduledAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Duration
                DropdownButtonFormField<int>(
                  value: _duration,
                  decoration: const InputDecoration(
                    labelText: 'Dauer (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  items: [15, 30, 45, 60, 90, 120]
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d Minuten'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _duration = v ?? 30),
                ),
                const SizedBox(height: 12),

                // Provider/Organization selection
                if (_loadingOrgs)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  )
                else if (_organizations.isNotEmpty) ...[
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedOrg,
                    decoration: const InputDecoration(
                      labelText: 'Tierarzt / Dienstleister (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<Map<String, dynamic>>(
                        value: null,
                        child: Text('Keine Auswahl'),
                      ),
                      ..._organizations.map((org) => DropdownMenuItem(
                            value: org,
                            child: Text(org['name'] as String),
                          )),
                    ],
                    onChanged: (org) => setState(() => _selectedOrg = org),
                  ),
                  const SizedBox(height: 12),
                ],

                // Location
                TextFormField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ort (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Anmerkungen (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Anfragen'),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final result = await context.read<AppointmentProvider>().create(
          petId: _selectedPet!.id,
          title: _titleCtrl.text.trim(),
          scheduledAt: _scheduledAt,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          organizationId: _selectedOrg?['id'] as String?,
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          durationMinutes: _duration,
        );

    if (context.mounted) {
      Navigator.pop(context);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin angefragt!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Anfragen.')),
        );
      }
    }
  }
}
