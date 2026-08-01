import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/pet.dart';

/// Pet-Karte im "Warm Care Narrative"-Stil (animals_desktop Mockup):
/// großes Foto oben mit Status-Badge, darunter Name, Rasse/Alter und Tags.
class PetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback? onTap;
  final String? imageBaseUrl;

  const PetCard({super.key, required this.pet, this.onTap, this.imageBaseUrl});

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final healthColor = _healthColor(widget.pet.healthStatus);
    final feedingColor = _feedingColor(widget.pet.feedingStatus);
    final hasImage = widget.pet.imageUrl != null &&
        widget.pet.imageUrl!.isNotEmpty &&
        widget.imageBaseUrl != null;

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
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
            border: Border.all(
                color: LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: _isHovered
                ? LivingLedgerTheme.ambientShadow
                : LivingLedgerTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Foto-Header mit Status-Badge
              Stack(
                children: [
                  SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: hasImage
                        ? Image.network(
                            '${widget.imageBaseUrl}${widget.pet.imageUrl}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackImage(),
                          )
                        : _fallbackImage(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.9),
                        borderRadius:
                            BorderRadius.circular(LivingLedgerTheme.radiusFull),
                        boxShadow: const [
                          BoxShadow(color: Color(0x22000000), blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.pet.healthStatusLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.pet.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.more_vert_rounded,
                            size: 18, color: LivingLedgerTheme.onSurfaceVariant),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pet.breed,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        widget.pet.speciesLabel,
                        if (widget.pet.ageYears != null)
                          '${widget.pet.ageYears} Jahre',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: LivingLedgerTheme.secondary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(
                          label: widget.pet.feedingNote ??
                              widget.pet.feedingStatusLabel,
                          color: feedingColor,
                        ),
                        if (widget.pet.microchipId != null)
                          _Tag(label: 'Gechipt', color: LivingLedgerTheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: LivingLedgerTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Text(widget.pet.speciesIcon, style: const TextStyle(fontSize: 40)),
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

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
