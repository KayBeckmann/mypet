import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomersProvider>();

    return Scaffold(
      backgroundColor: ProviderTheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kunden & Tiere',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Tiere, auf die Sie Zugriff haben',
              style: TextStyle(color: ProviderTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'Nach Tier oder Besitzer suchen...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: provider.setSearch,
            ),
            const SizedBox(height: 16),

            if (provider.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (provider.pets.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets_rounded,
                          size: 64,
                          color: ProviderTheme.onSurfaceVariant
                              .withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        provider.search.isEmpty
                            ? 'Keine Tiere gefunden.'
                            : 'Keine Treffer für "${provider.search}"',
                        style:
                            TextStyle(color: ProviderTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: provider.pets.length,
                  itemBuilder: (_, i) {
                    final pet = provider.pets[i];
                    return _PetCard(pet: pet);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final name = pet['name'] as String? ?? '—';
    final species = pet['species'] as String? ?? '';
    final breed = pet['breed'] as String? ?? '';
    final ownerName = pet['owner_name'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ProviderTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ProviderTheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ProviderTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _speciesEmoji(species),
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  breed.isNotEmpty ? breed : species,
                  style: TextStyle(
                      color: ProviderTheme.onSurfaceVariant,
                      fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (ownerName.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 12,
                          color: ProviderTheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          ownerName,
                          style: TextStyle(
                              color: ProviderTheme.onSurfaceVariant,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _speciesEmoji(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'horse':
        return '🐴';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐰';
      default:
        return '🐾';
    }
  }
}
