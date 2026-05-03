import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';
import '../providers/family_invitation_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';

/// Consolidated notification types for the notification center.
enum _NotifType { familyInvitation, overdueReminder, upcomingReminder, appointmentRequest, birthday }

class _Notification {
  final _NotifType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? id;
  final String? route;

  const _Notification({
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.id,
    this.route,
  });
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  List<_Notification> _buildNotifications(BuildContext context) {
    final invitations = context.watch<FamilyInvitationProvider>().invitations;
    final reminders = context.watch<ReminderProvider>().reminders;
    final appointments = context.watch<AppointmentProvider>().appointments;
    final pets = context.watch<PetProvider>().pets;

    final result = <_Notification>[];

    // Birthday notifications (pets with birthdays in the next 14 days)
    final now = DateTime.now();
    for (final pet in pets) {
      if (pet.birthDate == null) continue;
      final bd = pet.birthDate!;
      // Calculate next birthday this year or next year
      var nextBirthday = DateTime(now.year, bd.month, bd.day);
      if (nextBirthday.isBefore(now)) {
        nextBirthday = DateTime(now.year + 1, bd.month, bd.day);
      }
      final daysUntil = nextBirthday.difference(now).inDays;
      if (daysUntil <= 14) {
        final years = nextBirthday.year - bd.year;
        result.add(_Notification(
          type: _NotifType.birthday,
          title: '${pet.name}s Geburtstag',
          body: daysUntil == 0
              ? 'Heute! ${pet.name} wird $years Jahre alt 🎂'
              : daysUntil == 1
                  ? 'Morgen! ${pet.name} wird $years Jahre alt'
                  : 'In $daysUntil Tagen — ${pet.name} wird $years Jahre alt',
          createdAt: nextBirthday,
          route: '/animals/${pet.id}',
        ));
      }
    }

    for (final inv in invitations) {
      result.add(_Notification(
        type: _NotifType.familyInvitation,
        title: 'Familieneinladung',
        body: '${inv.invitedByName} lädt dich in die Familie „${inv.familyName}" ein'
            '${inv.message?.isNotEmpty == true ? ' · "${inv.message}"' : ''}',
        createdAt: inv.createdAt,
        id: inv.id,
        route: '/families',
      ));
    }

    final tomorrow = now.add(const Duration(hours: 24));

    for (final r in reminders.where((r) => r.isPending)) {
      if (r.isPast) {
        result.add(_Notification(
          type: _NotifType.overdueReminder,
          title: r.title,
          body: r.petName != null ? '${r.petName} · ${_fmtDate(r.remindAt)}' : _fmtDate(r.remindAt),
          createdAt: r.remindAt,
          id: r.id,
          route: '/reminders',
        ));
      } else if (r.remindAt.isBefore(tomorrow)) {
        result.add(_Notification(
          type: _NotifType.upcomingReminder,
          title: r.title,
          body: r.petName != null ? '${r.petName} · heute' : 'Heute fällig',
          createdAt: r.remindAt,
          id: r.id,
          route: '/reminders',
        ));
      }
    }

    for (final a in appointments.where((a) => a.status == AppointmentStatus.requested)) {
      result.add(_Notification(
        type: _NotifType.appointmentRequest,
        title: 'Terminanfrage ausstehend',
        body: '${a.petName ?? 'Tier'} · ${a.dateLabel} ${a.timeLabel}'
            '${a.organizationName != null ? ' · ${a.organizationName}' : ''}',
        createdAt: a.scheduledAt.subtract(const Duration(days: 1)),
        id: a.id,
        route: '/appointments',
      ));
    }

    result.sort((a, b) {
      // Overdue and invitations come first
      final priorityA = a.type == _NotifType.overdueReminder ||
          a.type == _NotifType.familyInvitation ? 0 : 1;
      final priorityB = b.type == _NotifType.overdueReminder ||
          b.type == _NotifType.familyInvitation ? 0 : 1;
      if (priorityA != priorityB) return priorityA - priorityB;
      return b.createdAt.compareTo(a.createdAt);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _buildNotifications(context);
    final invProvider = context.watch<FamilyInvitationProvider>();
    final invitations = invProvider.invitations;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Benachrichtigungen',
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    notifications.isEmpty
                        ? 'Keine neuen Benachrichtigungen.'
                        : '${notifications.length} Benachrichtigung${notifications.length == 1 ? '' : 'en'}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LivingLedgerTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (notifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 72,
                      color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text('Alles erledigt!',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Du hast keine offenen Benachrichtigungen.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: notifications.map((notif) {
                final inv = notif.type == _NotifType.familyInvitation && notif.id != null
                    ? invitations.where((i) => i.id == notif.id).firstOrNull
                    : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NotificationTile(
                    notification: notif,
                    invitation: inv,
                    invProvider: invProvider,
                    onTap: notif.route != null ? () => context.go(notif.route!) : null,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Heute';
    final diff = today.difference(d).inDays;
    if (diff == 1) return 'Gestern';
    if (diff > 1 && diff < 7) return 'Vor $diff Tagen';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _NotificationTile extends StatelessWidget {
  final _Notification notification;
  final FamilyInvitation? invitation;
  final FamilyInvitationProvider invProvider;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.invProvider,
    this.invitation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, bgColor) = _style();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LivingLedgerTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (invitation != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () async {
                          final ok = await invProvider.accept(invitation!.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Willkommen in „${invitation!.familyName}"!'),
                              ),
                            );
                          }
                        },
                        child: const Text('Annehmen'),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(88, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: LivingLedgerTheme.error,
                          side: BorderSide(
                              color: LivingLedgerTheme.error.withValues(alpha: 0.5)),
                        ),
                        onPressed: () => invProvider.reject(invitation!.id),
                        child: const Text('Ablehnen'),
                      ),
                    ],
                  ),
                ] else if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color, Color) _style() {
    switch (notification.type) {
      case _NotifType.familyInvitation:
        return (
          Icons.family_restroom_rounded,
          LivingLedgerTheme.primary,
          LivingLedgerTheme.primary.withValues(alpha: 0.04),
        );
      case _NotifType.overdueReminder:
        return (
          Icons.alarm_rounded,
          LivingLedgerTheme.error,
          LivingLedgerTheme.error.withValues(alpha: 0.04),
        );
      case _NotifType.upcomingReminder:
        return (
          Icons.alarm_rounded,
          Colors.amber.shade700,
          Colors.amber.withValues(alpha: 0.04),
        );
      case _NotifType.appointmentRequest:
        return (
          Icons.calendar_today_rounded,
          LivingLedgerTheme.secondary,
          LivingLedgerTheme.secondary.withValues(alpha: 0.04),
        );
      case _NotifType.birthday:
        return (
          Icons.cake_rounded,
          Colors.pink.shade400,
          Colors.pink.withValues(alpha: 0.04),
        );
    }
  }
}
