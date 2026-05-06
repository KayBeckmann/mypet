import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Pulsierender Skeleton-Loader Platzhalter
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: LivingLedgerTheme.onSurface.withValues(alpha: _anim.value * 0.1),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton für eine PetCard
class PetCardSkeleton extends StatelessWidget {
  const PetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusLg),
        border: Border.all(color: LivingLedgerTheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 60, height: 60, borderRadius: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: 80, height: 12),
                const SizedBox(height: 4),
                SkeletonBox(width: 60, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mehrere Skeleton-Cards
class PetListSkeleton extends StatelessWidget {
  final int count;
  const PetListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const PetCardSkeleton(),
        ),
      ),
    );
  }
}
