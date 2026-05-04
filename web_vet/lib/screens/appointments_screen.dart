import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mypet_shared/shared.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/appointment_provider.dart';
import '../providers/patients_provider.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VetAppointmentProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VetAppointmentProvider>();

    return Scaffold(
      backgroundColor: VetTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Termine',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: VetTheme.onSurface,
                        ),
                  ),
                ),
                if (provider.loading)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: provider.load,
                    tooltip: 'Aktualisieren',
                  ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Neuer Termin'),
                  onPressed: () => _createAppointment(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Summary chips
            Row(
              children: [
                _CountChip(
                  label: 'Anfragen',
                  count: provider.pending.length,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _CountChip(
                  label: 'Bestätigt',
                  count: provider.confirmed.length,
                  color: VetTheme.secondary,
                ),
                const SizedBox(width: 8),
                _CountChip(
                  label: 'Abgeschlossen',
                  count: provider.past.length,
                  color: VetTheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),

            TabBar(
              controller: _tabController,
              labelColor: VetTheme.primary,
              unselectedLabelColor: VetTheme.onSurfaceVariant,
              indicatorColor: VetTheme.primary,
              tabs: const [
                Tab(text: 'Anfragen'),
                Tab(text: 'Bestätigt'),
                Tab(text: 'Vergangen'),
                Tab(text: 'Kalender'),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: provider.error != null
                  ? Center(
                      child: Text('Fehler: ${provider.error}',
                          style: TextStyle(color: VetTheme.error)),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _AppointmentList(
                          appointments: provider.pending,
                          emptyText: 'Keine offenen Anfragen',
                          actions: (a) => [
                            _ActionButton(
                              label: 'Bestätigen',
                              color: VetTheme.secondary,
                              icon: Icons.check_circle_outline,
                              onPressed: () => _confirm(context, a),
                            ),
                            _ActionButton(
                              label: 'Ablehnen',
                              color: VetTheme.error,
                              icon: Icons.cancel_outlined,
                              onPressed: () => _cancel(context, a),
                            ),
                          ],
                        ),
                        _AppointmentList(
                          appointments: provider.confirmed,
                          emptyText: 'Keine bestätigten Termine',
                          actions: (a) => [
                            _ActionButton(
                              label: 'Abschließen',
                              color: VetTheme.primary,
                              icon: Icons.task_alt_rounded,
                              onPressed: () =>
                                  context.read<VetAppointmentProvider>().complete(a.id),
                            ),
                            _ActionButton(
                              label: 'Nicht erschienen',
                              color: Colors.grey,
                              icon: Icons.person_off_outlined,
                              onPressed: () =>
                                  context.read<VetAppointmentProvider>().markNoShow(a.id),
                            ),
                            _ActionButton(
                              label: 'Absagen',
                              color: VetTheme.error,
                              icon: Icons.cancel_outlined,
                              onPressed: () => _cancel(context, a),
                            ),
                          ],
                        ),
                        _AppointmentList(
                          appointments: provider.past,
                          emptyText: 'Keine vergangenen Termine',
                        ),
                        _CalendarView(appointments: provider.appointments),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
      BuildContext context, VetAppointment a) async {
    final ok = await context.read<VetAppointmentProvider>().confirm(a.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Termin bestätigt' : 'Fehler beim Bestätigen'),
      ));
    }
  }

  Future<void> _cancel(
      BuildContext context, VetAppointment a) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin absagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Termin "${a.title}" absagen?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
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
            style: TextButton.styleFrom(foregroundColor: VetTheme.error),
            child: const Text('Absagen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await context.read<VetAppointmentProvider>().cancel(
            a.id,
            reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Termin abgesagt' : 'Fehler')),
        );
      }
    }
  }

  Future<void> _createAppointment(BuildContext context) async {
    final patients = context.read<PatientsProvider>().patients;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Patienten verfügbar')),
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    String? selectedPetId = patients.first['id'] as String?;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final formKey = GlobalKey<FormState>();
    final dateFmt = DateFormat('dd.MM.yyyy');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neuer Termin'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPetId,
                      decoration: const InputDecoration(labelText: 'Patient *'),
                      items: patients
                          .map((p) => DropdownMenuItem<String>(
                                value: p['id'] as String,
                                child: Text(
                                    '${p['name']} (${p['owner_name'] ?? '—'})'),
                              ))
                          .toList(),
                      onChanged: (v) => setDs(() => selectedPetId = v),
                      validator: (v) =>
                          v == null ? 'Patient erforderlich' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Titel *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Titel erforderlich'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(dateFmt.format(selectedDate)),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (d != null) setDs(() => selectedDate = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(selectedTime.format(ctx)),
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                              );
                              if (t != null) setDs(() => selectedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: durationCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Dauer (Minuten)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Ort'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Beschreibung'),
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
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final scheduledAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      final api = context.read<ApiService>();
      try {
        await api.post('/appointments', body: {
          'pet_id': selectedPetId,
          'title': titleCtrl.text.trim(),
          'scheduled_at': scheduledAt.toIso8601String(),
          'duration_minutes': int.tryParse(durationCtrl.text) ?? 30,
          if (locationCtrl.text.trim().isNotEmpty)
            'location': locationCtrl.text.trim(),
          if (descCtrl.text.trim().isNotEmpty)
            'description': descCtrl.text.trim(),
        });
        if (context.mounted) {
          context.read<VetAppointmentProvider>().load();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Termin angelegt')),
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
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<VetAppointment> appointments;
  final String emptyText;
  final List<Widget> Function(VetAppointment)? actions;

  const _AppointmentList({
    required this.appointments,
    required this.emptyText,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded,
                size: 48, color: VetTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(emptyText,
                style: TextStyle(color: VetTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = appointments[i];
        return _AppointmentCard(appointment: a, actions: actions?.call(a));
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final VetAppointment appointment;
  final List<Widget>? actions;

  const _AppointmentCard({required this.appointment, this.actions});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);

    return Material(
      color: VetTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.go('/patients/${appointment.petId}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date/time column
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.dateLabel,
                      style: TextStyle(
                          color: VetTheme.onSurfaceVariant,
                          fontSize: 12),
                    ),
                    Text(
                      appointment.timeLabel,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${appointment.durationMinutes} min',
                      style: TextStyle(
                          color: VetTheme.onSurfaceVariant, fontSize: 12),
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
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                        icon: Icons.pets_rounded,
                        text: appointment.petName ?? '—'),
                    _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: appointment.ownerName ?? '—'),
                    if (appointment.location != null)
                      _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: appointment.location!),
                    if (appointment.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          appointment.description!,
                          style: TextStyle(
                              color: VetTheme.onSurfaceVariant,
                              fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          // Action buttons
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: a,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.requested:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return VetTheme.secondary;
      case AppointmentStatus.completed:
        return VetTheme.primary;
      case AppointmentStatus.cancelled:
        return VetTheme.error;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: VetTheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style:
                  TextStyle(color: VetTheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Calendar View ─────────────────────────────────────────────────────────────

class _CalendarView extends StatefulWidget {
  final List<VetAppointment> appointments;
  const _CalendarView({required this.appointments});

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));
    final fmt = DateFormat('E', 'de_DE');
    final dayFmt = DateFormat('d.M');
    final timeFmt = DateFormat('HH:mm');
    final now = DateTime.now();

    return Column(
      children: [
        // Navigation row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(
                    () => _weekStart = _weekStart.subtract(const Duration(days: 7))),
              ),
              Text(
                '${dayFmt.format(_weekStart)} – ${dayFmt.format(_weekStart.add(const Duration(days: 6)))}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _weekStart = _mondayOf(DateTime.now())),
                    child: const Text('Heute'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: () => setState(
                        () => _weekStart = _weekStart.add(const Duration(days: 7))),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Day headers
        Row(
          children: weekDays.map((d) {
            final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: isToday ? VetTheme.primary.withValues(alpha: 0.08) : null,
                child: Column(
                  children: [
                    Text(
                      fmt.format(d),
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? VetTheme.primary : VetTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      d.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isToday ? VetTheme.primary : VetTheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(height: 1),
        // Appointments per day
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weekDays.map((day) {
                final dayAppts = widget.appointments.where((a) {
                  final sd = a.scheduledAt;
                  return sd.year == day.year && sd.month == day.month && sd.day == day.day;
                }).toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

                return Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 200),
                    decoration: BoxDecoration(
                      color: isToday ? VetTheme.primary.withValues(alpha: 0.04) : null,
                      border: const Border(
                        right: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                      ),
                    ),
                    child: Column(
                      children: dayAppts.map((a) {
                        final color = switch (a.status) {
                          AppointmentStatus.confirmed => VetTheme.secondary,
                          AppointmentStatus.requested => Colors.orange,
                          AppointmentStatus.completed => Colors.grey,
                          _ => Colors.red,
                        };
                        return GestureDetector(
                          onTap: () => context.go('/patients/${a.petId}'),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeFmt.format(a.scheduledAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  a.petName ?? a.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  a.title,
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
