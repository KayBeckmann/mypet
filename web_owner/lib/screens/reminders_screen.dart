import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/reminder_provider.dart';
import '../providers/pet_provider.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReminderProvider>();

    return Padding(
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
                      'Erinnerungen',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LivingLedgerTheme.onSurface,
                          ),
                    ),
                    Text(
                      '${provider.upcoming.length} ausstehend',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add_alarm_rounded, size: 18),
                label: const Text('Neue Erinnerung'),
                style: FilledButton.styleFrom(
                  backgroundColor: LivingLedgerTheme.primary,
                  foregroundColor: LivingLedgerTheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          if (provider.isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (provider.reminders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm_outlined,
                        size: 64, color: LivingLedgerTheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Erinnerungen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle eine Erinnerung für Impfungen, Medikamente oder Termine',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: provider.reminders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _ReminderCard(reminder: provider.reminders[i]),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String type = 'custom';
    DateTime? remindAt;
    String? petId;

    final animals = context.read<PetProvider>().pets;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neue Erinnerung'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: const [
                      DropdownMenuItem(
                          value: 'custom', child: Text('Allgemein')),
                      DropdownMenuItem(
                          value: 'vaccination', child: Text('Impfung')),
                      DropdownMenuItem(
                          value: 'medication', child: Text('Medikament')),
                      DropdownMenuItem(
                          value: 'appointment', child: Text('Termin')),
                      DropdownMenuItem(
                          value: 'feeding', child: Text('Fütterung')),
                      DropdownMenuItem(
                          value: 'weight', child: Text('Gewichtskontrolle')),
                    ],
                    onChanged: (v) => setDs(() => type = v!),
                  ),
                  const SizedBox(height: 12),
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
                    controller: messageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nachricht (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  if (animals.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      value: petId,
                      decoration:
                          const InputDecoration(labelText: 'Tier (optional)'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Kein Tier')),
                        ...animals.map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            )),
                      ],
                      onChanged: (v) => setDs(() => petId = v),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(remindAt != null
                        ? DateFormat('dd.MM.yyyy HH:mm').format(remindAt!)
                        : 'Datum & Zeit wählen *'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (date == null) return;
                      if (!ctx.mounted) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time == null) return;
                      setDs(() {
                        remindAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            FilledButton(
              onPressed: (titleCtrl.text.trim().isNotEmpty && remindAt != null)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ReminderProvider>().create(
            title: titleCtrl.text.trim(),
            message: messageCtrl.text.trim(),
            type: type,
            remindAt: remindAt!,
            petId: petId,
          );
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ReminderProvider>();
    final isPast = reminder.isPast;
    final isDismissed = reminder.status == 'dismissed';
    final isSent = reminder.status == 'sent';

    final Color accentColor;
    final IconData typeIcon;
    switch (reminder.reminderType) {
      case 'vaccination':
        accentColor = LivingLedgerTheme.secondary;
        typeIcon = Icons.vaccines_rounded;
        break;
      case 'medication':
        accentColor = LivingLedgerTheme.primary;
        typeIcon = Icons.medication_rounded;
        break;
      case 'appointment':
        accentColor = LivingLedgerTheme.tertiary;
        typeIcon = Icons.calendar_month_rounded;
        break;
      case 'feeding':
        accentColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.restaurant_rounded;
        break;
      case 'weight':
        accentColor = const Color(0xFF06B6D4);
        typeIcon = Icons.monitor_weight_rounded;
        break;
      default:
        accentColor = LivingLedgerTheme.onSurfaceVariant;
        typeIcon = Icons.alarm_rounded;
    }

    return Opacity(
      opacity: isDismissed ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: LivingLedgerTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPast && !isDismissed
                ? LivingLedgerTheme.tertiary.withValues(alpha: 0.4)
                : LivingLedgerTheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: isDismissed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        if (isSent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: LivingLedgerTheme.secondary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'E-Mail gesendet',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: LivingLedgerTheme.secondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    if (reminder.message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(reminder.message,
                          style: const TextStyle(
                              fontSize: 13,
                              color: LivingLedgerTheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isPast && !isDismissed
                              ? Icons.warning_amber_rounded
                              : Icons.schedule_rounded,
                          size: 13,
                          color: isPast && !isDismissed
                              ? LivingLedgerTheme.tertiary
                              : LivingLedgerTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yyyy HH:mm').format(reminder.remindAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isPast && !isDismissed
                                ? LivingLedgerTheme.tertiary
                                : LivingLedgerTheme.onSurfaceVariant,
                            fontWeight: isPast && !isDismissed
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (reminder.petName != null) ...[
                          const SizedBox(width: 8),
                          const Text('·',
                              style: TextStyle(
                                  color: LivingLedgerTheme.onSurfaceVariant)),
                          const SizedBox(width: 4),
                          Icon(Icons.pets_rounded,
                              size: 12,
                              color: LivingLedgerTheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(reminder.petName!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: LivingLedgerTheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isDismissed) ...[
                IconButton(
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  color: LivingLedgerTheme.secondary,
                  tooltip: 'Erledigt',
                  onPressed: () => provider.dismiss(reminder.id),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: LivingLedgerTheme.onSurfaceVariant,
                tooltip: 'Löschen',
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Erinnerung löschen?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Abbrechen')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Löschen')),
                          ],
                        ),
                      ) ??
                      false;
                  if (ok) provider.delete(reminder.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
