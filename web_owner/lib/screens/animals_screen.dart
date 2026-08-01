import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/pet_provider.dart';
import '../widgets/pet_card.dart';
import '../widgets/skeleton_loader.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pets = _search.isEmpty
        ? petProvider.pets
        : petProvider.pets
            .where((p) =>
                p.name.toLowerCase().contains(_search.toLowerCase()) ||
                p.breed.toLowerCase().contains(_search.toLowerCase()) ||
                p.species.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    return RefreshIndicator(
      onRefresh: () => petProvider.loadPets(),
      color: LivingLedgerTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deine Tiere',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _search.isEmpty
                          ? '${petProvider.pets.length} Tiere registriert'
                          : '${pets.length} von ${petProvider.pets.length} Tieren',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: LivingLedgerTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Aktualisieren',
                      onPressed: petProvider.isLoading
                          ? null
                          : () => petProvider.loadPets(),
                      icon: petProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/animals/add'),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Tier hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar (only when ≥3 pets)
            if (petProvider.pets.length >= 3) ...[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tiere suchen …',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _search = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: LivingLedgerTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          LivingLedgerTheme.radiusFull),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 16),

            // Animals Grid or Empty State
            if (petProvider.isLoading && pets.isEmpty)
              const PetListSkeleton(count: 3)
            else if (pets.isEmpty)
              _EmptyState()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 1;
                  if (constraints.maxWidth > 1300) {
                    crossAxisCount = 4;
                  } else if (constraints.maxWidth > 1000) {
                    crossAxisCount = 3;
                  } else if (constraints.maxWidth > 600) {
                    crossAxisCount = 2;
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: pets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == pets.length) {
                        return _AddPetPlaceholderCard(
                          onTap: () => context.go('/animals/add'),
                        );
                      }
                      final pet = pets[index];
                      return PetCard(
                        pet: pet,
                        imageBaseUrl: petProvider.apiBaseUrl,
                        onTap: () => context.go('/animals/${pet.id}'),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPetPlaceholderCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetPlaceholderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
      child: DottedBorderContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: LivingLedgerTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded,
                  color: LivingLedgerTheme.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Neues Tier',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Lege ein Profil für dein nächstes Familienmitglied an.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LivingLedgerTheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Container mit gestricheltem Rand (dashed border) für die "Add Pet"-Karte.
class DottedBorderContainer extends StatelessWidget {
  final Widget child;
  const DottedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: LivingLedgerTheme.outlineVariant,
        radius: LivingLedgerTheme.radiusXl,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: LivingLedgerTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(LivingLedgerTheme.radiusXl),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 6.0;
      const dashGap = 5.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashGap;
      }
    }
    canvas.drawPath(
      dashPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LivingLedgerTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets_rounded,
                size: 40,
                color: LivingLedgerTheme.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Tiere registriert',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Füge dein erstes Tier hinzu, um die Übersicht zu nutzen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LivingLedgerTheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/animals/add'),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Erstes Tier hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
