import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MobileReminderProvider>();
    final reminders = provider.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Erinnerungen')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_off_rounded,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Keine offenen Erinnerungen',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: provider.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _ReminderCard(reminder: reminders[i]),
                  ),
                ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final pets = context.read<MobilePetProvider>().pets;
    String? selectedPetId;
    DateTime remindAt =
        DateTime.now().add(const Duration(hours: 1));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Erinnerung hinzufügen'),
          content: SingleChildScrollView(
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
                if (pets.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedPetId,
                    decoration: const InputDecoration(
                      labelText: 'Tier (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Kein Tier')),
                      ...pets.map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) => setDs(() => selectedPetId = v),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    '${remindAt.day.toString().padLeft(2, '0')}.${remindAt.month.toString().padLeft(2, '0')}.${remindAt.year} '
                    '${remindAt.hour.toString().padLeft(2, '0')}:${remindAt.minute.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: remindAt,
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (date != null && ctx.mounted) {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(remindAt),
                      );
                      if (time != null) {
                        setDs(() => remindAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ));
                      }
                    }
                  },
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
              onPressed: titleCtrl.text.trim().isNotEmpty
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<MobileReminderProvider>().create(
            title: titleCtrl.text.trim(),
            remindAt: remindAt,
            petId: selectedPetId,
          );
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final MobileReminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverdue = reminder.isOverdue;
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      color: isOverdue ? cs.errorContainer : null,
      child: ListTile(
        leading: Icon(
          _typeIcon(reminder.type),
          color: isOverdue ? cs.error : cs.primary,
        ),
        title: Text(reminder.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          fmt.format(reminder.remindAt),
          if (reminder.petName != null) reminder.petName!,
          if (isOverdue) 'Überfällig',
        ].join(' · ')),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline_rounded),
          color: cs.primary,
          tooltip: 'Erledigt',
          onPressed: () =>
              context.read<MobileReminderProvider>().dismiss(reminder.id),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vaccination': return Icons.vaccines_rounded;
      case 'medication': return Icons.medication_rounded;
      case 'appointment': return Icons.calendar_month_rounded;
      case 'feeding': return Icons.restaurant_rounded;
      case 'weight': return Icons.monitor_weight_rounded;
      default: return Icons.alarm_rounded;
    }
  }
}
