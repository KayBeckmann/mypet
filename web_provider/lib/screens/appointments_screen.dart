import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/appointment_provider.dart';

class ProviderAppointmentsScreen extends StatefulWidget {
  const ProviderAppointmentsScreen({super.key});

  @override
  State<ProviderAppointmentsScreen> createState() =>
      _ProviderAppointmentsScreenState();
}

class _ProviderAppointmentsScreenState
    extends State<ProviderAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderAppointmentProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderAppointmentProvider>();

    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Termine',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
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
                  ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _CountChip('Anfragen', provider.pending.length, Colors.orange),
                const SizedBox(width: 8),
                _CountChip('Bestätigt', provider.confirmed.length,
                    ProviderTheme.secondary),
                const SizedBox(width: 8),
                _CountChip('Vergangen', provider.past.length,
                    ProviderTheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 16),

            TabBar(
              controller: _tabController,
              labelColor: ProviderTheme.primary,
              unselectedLabelColor: ProviderTheme.onSurfaceVariant,
              indicatorColor: ProviderTheme.primary,
              tabs: const [
                Tab(text: 'Anfragen'),
                Tab(text: 'Bestätigt'),
                Tab(text: 'Vergangen'),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: provider.error != null
                  ? Center(
                      child: Text('Fehler: ${provider.error}',
                          style:
                              TextStyle(color: ProviderTheme.error)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _AppointmentList(
                          appointments: provider.pending,
                          emptyText: 'Keine offenen Anfragen',
                          actions: (a) => [
                            _ActionBtn('Bestätigen', ProviderTheme.secondary,
                                Icons.check_circle_outline,
                                () => _confirm(context, a)),
                            _ActionBtn('Ablehnen', ProviderTheme.error,
                                Icons.cancel_outlined,
                                () => _cancel(context, a)),
                          ],
                        ),
                        _AppointmentList(
                          appointments: provider.confirmed,
                          emptyText: 'Keine bestätigten Termine',
                          actions: (a) => [
                            _ActionBtn('Abschließen', ProviderTheme.primary,
                                Icons.task_alt_rounded,
                                () => context
                                    .read<ProviderAppointmentProvider>()
                                    .complete(a.id)),
                            _ActionBtn('Absagen', ProviderTheme.error,
                                Icons.cancel_outlined,
                                () => _cancel(context, a)),
                          ],
                        ),
                        _AppointmentList(
                          appointments: provider.past,
                          emptyText: 'Keine vergangenen Termine',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, ProviderAppointment a) async {
    final ok = await context.read<ProviderAppointmentProvider>().confirm(a.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Termin bestätigt' : 'Fehler'),
      ));
    }
  }

  Future<void> _cancel(BuildContext context, ProviderAppointment a) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin absagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${a.title} absagen?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Grund (optional)',
                  border: OutlineInputBorder()),
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
                foregroundColor: ProviderTheme.error),
            child: const Text('Absagen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProviderAppointmentProvider>().cancel(a.id,
          reason: reasonCtrl.text.trim().isEmpty
              ? null
              : reasonCtrl.text.trim());
    }
  }
}

Widget _CountChip(String label, int count, Color color) {
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
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
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

class _AppointmentList extends StatelessWidget {
  final List<ProviderAppointment> appointments;
  final String emptyText;
  final List<Widget> Function(ProviderAppointment)? actions;

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
                size: 48,
                color: ProviderTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(emptyText,
                style:
                    TextStyle(color: ProviderTheme.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _AppointmentCard(
          appointment: appointments[i], actions: actions?.call(appointments[i])),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final ProviderAppointment appointment;
  final List<Widget>? actions;

  const _AppointmentCard({required this.appointment, this.actions});

  @override
  Widget build(BuildContext context) {
    final color = _color(appointment.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.dateLabel,
                        style: TextStyle(
                            color: ProviderTheme.onSurfaceVariant,
                            fontSize: 11)),
                    Text(appointment.timeLabel,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('${appointment.durationMinutes} min',
                        style: TextStyle(
                            color: ProviderTheme.onSurfaceVariant,
                            fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 3),
                    if (appointment.petName != null)
                      _Row(Icons.pets_rounded, appointment.petName!),
                    if (appointment.ownerName != null)
                      _Row(Icons.person_outline_rounded,
                          appointment.ownerName!),
                    if (appointment.location != null)
                      _Row(Icons.location_on_outlined, appointment.location!),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(appointment.statusLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(left: 8), child: w))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _Row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Icon(icon, size: 13, color: ProviderTheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    color: ProviderTheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );

  Color _color(ProviderAppointmentStatus s) {
    switch (s) {
      case ProviderAppointmentStatus.requested:
        return Colors.orange;
      case ProviderAppointmentStatus.confirmed:
        return ProviderTheme.secondary;
      case ProviderAppointmentStatus.completed:
        return ProviderTheme.primary;
      case ProviderAppointmentStatus.cancelled:
        return ProviderTheme.error;
      case ProviderAppointmentStatus.noShow:
        return Colors.grey;
    }
  }
}

Widget _ActionBtn(
    String label, Color color, IconData icon, VoidCallback onPressed) {
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
