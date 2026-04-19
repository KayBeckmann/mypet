import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/pet_provider.dart';
import '../models/pet.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upcoming
                      if (provider.upcoming.isNotEmpty) ...[
                        _SectionHeader(title: 'Kommende Termine'),
                        const SizedBox(height: 12),
                        ...provider.upcoming.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AppointmentTile(
                              appointment: a,
                              onCancel: () => _confirmCancel(context, a),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (provider.upcoming.isEmpty)
                        _EmptyHint(
                          icon: Icons.event_available_rounded,
                          text: 'Keine kommenden Termine',
                        ),

                      // Past
                      if (provider.past.isNotEmpty) ...[
                        _SectionHeader(title: 'Vergangene Termine'),
                        const SizedBox(height: 12),
                        ...provider.past.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AppointmentTile(appointment: a),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
      builder: (ctx) => _BookAppointmentDialog(pets: pets),
    );
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
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: LivingLedgerTheme.onSurfaceVariant,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
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

  const _AppointmentTile({required this.appointment, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
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
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: 56,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (appointment.petName != null) ...[
                      Icon(Icons.pets_rounded,
                          size: 13,
                          color: LivingLedgerTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(appointment.petName!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      LivingLedgerTheme.onSurfaceVariant)),
                      const SizedBox(width: 12),
                    ],
                    if (appointment.providerName != null) ...[
                      Icon(Icons.person_outline_rounded,
                          size: 13,
                          color: LivingLedgerTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(appointment.providerName!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color:
                                      LivingLedgerTheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(LivingLedgerTheme.radiusFull),
            ),
            child: Text(
              appointment.statusLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          // Cancel button for upcoming
          if (onCancel != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              color: LivingLedgerTheme.error,
              tooltip: 'Termin absagen',
              iconSize: 20,
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

class _BookAppointmentDialog extends StatefulWidget {
  final List<Pet> pets;
  const _BookAppointmentDialog({required this.pets});

  @override
  State<_BookAppointmentDialog> createState() => _BookAppointmentDialogState();
}

class _BookAppointmentDialogState extends State<_BookAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Pet? _selectedPet;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  int _duration = 30;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.pets.isNotEmpty) _selectedPet = widget.pets.first;
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
