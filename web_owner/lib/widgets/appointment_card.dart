import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status dot
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time
                Text(
                  '${appointment.dateLabel}, ${appointment.timeLabel}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 4),

                // Title
                Text(
                  appointment.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),

                // Pet name
                if (appointment.petName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        size: 12,
                        color: LivingLedgerTheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.petName!,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: LivingLedgerTheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    if (appointment.isTomorrow || appointment.isToday) {
      return LivingLedgerTheme.secondary;
    }
    return LivingLedgerTheme.success;
  }
}
