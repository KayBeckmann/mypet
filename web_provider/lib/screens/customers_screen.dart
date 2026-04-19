import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/customers_provider.dart';
import '../providers/notes_provider.dart';

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

  void _openNotes(BuildContext context) {
    final petId = pet['id'] as String;
    context.read<ProviderNotesProvider>().loadForPet(petId);
    showDialog(
      context: context,
      builder: (_) => _PetNotesDialog(
        petName: pet['name'] as String? ?? '—',
        petId: petId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = pet['name'] as String? ?? '—';
    final species = pet['species'] as String? ?? '';
    final breed = pet['breed'] as String? ?? '';
    final ownerName = pet['owner_name'] as String? ?? '';

    return InkWell(
      onTap: () => _openNotes(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
      ),  // Container
    );  // InkWell
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

class _PetNotesDialog extends StatelessWidget {
  final String petName;
  final String petId;

  const _PetNotesDialog({required this.petName, required this.petId});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<ProviderNotesProvider>();

    return Dialog(
      child: SizedBox(
        width: 560,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notizen — $petName',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Notes list
            if (notesProvider.loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (notesProvider.notes.isEmpty)
              const Expanded(
                child: Center(child: Text('Noch keine Notizen vorhanden.')),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  itemCount: notesProvider.notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = notesProvider.notes[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ProviderTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: ProviderTheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (n.title != null)
                                Expanded(
                                  child: Text(n.title!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                )
                              else
                                const Spacer(),
                              _VisChip(n.visibility),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () async {
                                  final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title:
                                              const Text('Notiz löschen?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Abbrechen'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Löschen'),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                  if (ok) notesProvider.delete(n.id);
                                },
                                child: const Icon(Icons.delete_outline,
                                    size: 16,
                                    color: ProviderTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(n.content, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            '${n.authorName ?? '?'} · '
                            '${n.createdAt.day}.${n.createdAt.month}.${n.createdAt.year}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: ProviderTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Add note button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.note_add_rounded, size: 18),
                  label: const Text('Neue Notiz'),
                  onPressed: () => _showAddNoteDialog(context, notesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(
      BuildContext context, ProviderNotesProvider notesProvider) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String visibility = 'private';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Neue Notiz'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titel (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: visibility,
                  decoration:
                      const InputDecoration(labelText: 'Sichtbarkeit'),
                  items: const [
                    DropdownMenuItem(
                        value: 'private', child: Text('Nur ich')),
                    DropdownMenuItem(
                        value: 'colleagues', child: Text('Meine Kollegen')),
                    DropdownMenuItem(
                        value: 'all_professionals',
                        child: Text('Alle Fachkräfte')),
                  ],
                  onChanged: (v) => setDs(() => visibility = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                if (contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await notesProvider.create(
                  title: titleCtrl.text,
                  content: contentCtrl.text,
                  visibility: visibility,
                );
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisChip extends StatelessWidget {
  final String visibility;
  const _VisChip(this.visibility);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (visibility) {
      'private' => ('Privat', Colors.grey),
      'colleagues' => ('Kollegen', ProviderTheme.secondary),
      'all_professionals' => ('Alle', ProviderTheme.primary),
      _ => (visibility, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
