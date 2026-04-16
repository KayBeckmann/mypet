import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/pet.dart';

class PetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback? onTap;

  const PetCard({super.key, required this.pet, this.onTap});

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
            boxShadow: _isHovered
                ? LivingLedgerTheme.ambientShadow
                : LivingLedgerTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pet Image & Name Row
              Row(
                children: [
                  // Uncontained pet image - overlapping style
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LivingLedgerTheme.surfaceContainerLow,
                    ),
                    child: Center(
                      child: Text(
                        widget.pet.speciesIcon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.pet.breed.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    letterSpacing: 1,
                                    color: LivingLedgerTheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Health Status
              _StatusRow(
                icon: Icons.favorite_rounded,
                iconColor: _healthColor(widget.pet.healthStatus),
                label: 'Gesundheit',
                value: widget.pet.healthStatusLabel,
                valueBg: _healthColor(widget.pet.healthStatus).withValues(alpha: 0.1),
                valueColor: _healthColor(widget.pet.healthStatus),
              ),
              const SizedBox(height: 8),

              // Feeding Status
              _StatusRow(
                icon: Icons.restaurant_rounded,
                iconColor: _feedingColor(widget.pet.feedingStatus),
                label: 'Fütterung',
                value: widget.pet.feedingNote ?? widget.pet.feedingStatusLabel,
                valueBg: _feedingColor(widget.pet.feedingStatus).withValues(alpha: 0.1),
                valueColor: _feedingColor(widget.pet.feedingStatus),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _healthColor(HealthStatus status) {
    switch (status) {
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

  Color _feedingColor(FeedingStatus status) {
    switch (status) {
      case FeedingStatus.done:
        return LivingLedgerTheme.success;
      case FeedingStatus.upcoming:
        return LivingLedgerTheme.secondary;
      case FeedingStatus.overdue:
        return LivingLedgerTheme.error;
    }
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueBg;
  final Color valueColor;

  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueBg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueBg,
            borderRadius:
                BorderRadius.circular(LivingLedgerTheme.radiusFull),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ),
      ],
    );
  }
}
