import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/patients_provider.dart';
import '../providers/appointment_provider.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _sortBy = 'name'; // 'name' | 'species' | 'owner' | 'recent'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientsProvider>().loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PatientsProvider>();
    final apptProvider = context.watch<VetAppointmentProvider>();

    DateTime? _lastAppt(String petId) {
      final past = apptProvider.appointments
          .where((a) => a.petId == petId && a.scheduledAt.isBefore(DateTime.now()))
          .toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return past.isNotEmpty ? past.first.scheduledAt : null;
    }

    final filtered = ((_search.isEmpty
            ? provider.patients
            : provider.patients
                .where((p) =>
                    (p['name'] as String? ?? '')
                        .toLowerCase()
                        .contains(_search.toLowerCase()) ||
                    (p['species'] as String? ?? '')
                        .toLowerCase()
                        .contains(_search.toLowerCase()) ||
                    (p['owner_name'] as String? ?? '')
                        .toLowerCase()
                        .contains(_search.toLowerCase()))
                .toList())
          ..sort((a, b) {
            switch (_sortBy) {
              case 'species':
                return (a['species'] as String? ?? '')
                    .compareTo(b['species'] as String? ?? '');
              case 'owner':
                return (a['owner_name'] as String? ?? '')
                    .compareTo(b['owner_name'] as String? ?? '');
              case 'recent':
                final aDate = _lastAppt(a['id']?.toString() ?? '');
                final bDate = _lastAppt(b['id']?.toString() ?? '');
                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate);
              default:
                return (a['name'] as String? ?? '')
                    .compareTo(b['name'] as String? ?? '');
            }
          }));

    return Padding(
      padding: const EdgeInsets.all(VetTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Patienten',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.loadPatients(),
              ),
            ],
          ),
          const SizedBox(height: VetTheme.spacingMd),

          // Suche
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Patient suchen (Name, Tierart)...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: VetTheme.spacingSm),
          Row(
            children: [
              Text('Sortierung:',
                  style:
                      TextStyle(fontSize: 13, color: VetTheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              _SortChip(
                  label: 'Name',
                  selected: _sortBy == 'name',
                  onTap: () => setState(() => _sortBy = 'name')),
              const SizedBox(width: 6),
              _SortChip(
                  label: 'Tierart',
                  selected: _sortBy == 'species',
                  onTap: () => setState(() => _sortBy = 'species')),
              const SizedBox(width: 6),
              _SortChip(
                  label: 'Besitzer',
                  selected: _sortBy == 'owner',
                  onTap: () => setState(() => _sortBy = 'owner')),
              const SizedBox(width: 8),
              _SortChip(
                  label: 'Letzter Termin',
                  selected: _sortBy == 'recent',
                  onTap: () => setState(() => _sortBy = 'recent')),
              const Spacer(),
              Text('${filtered.length} Patienten',
                  style:
                      TextStyle(fontSize: 13, color: VetTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: VetTheme.spacingMd),

          if (provider.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VetTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(VetTheme.radiusMd),
              ),
              child: Text(provider.error!,
                  style: const TextStyle(color: VetTheme.secondary)),
            ),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pets_outlined,
                                size: 64, color: VetTheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              provider.patients.isEmpty
                                  ? 'Keine Patienten gefunden.\nBesitzer müssen dir erst Zugriff erteilen.'
                                  : 'Keine Übereinstimmungen',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: VetTheme.spacingSm),
                        itemBuilder: (context, i) =>
                            _PatientCard(patient: filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? '';
    final species = patient['species'] as String? ?? '';
    final breed = patient['breed'] as String? ?? '';
    final ownerName = patient['owner_name'] as String?;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: VetTheme.spacingMd, vertical: VetTheme.spacingSm),
        leading: CircleAvatar(
          backgroundColor: VetTheme.primaryContainer,
          child: Text(
            _speciesIcon(species),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          _speciesLabel(species),
          if (breed.isNotEmpty) breed,
          if (ownerName != null) 'Besitzer: $ownerName',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/patients/${patient['id']}'),
      ),
    );
  }

  String _speciesIcon(String s) {
    switch (s) {
      case 'dog':
        return '🐕';
      case 'cat':
        return '🐈';
      case 'horse':
        return '🐴';
      case 'bird':
        return '🐦';
      case 'rabbit':
        return '🐇';
      default:
        return '🐾';
    }
  }

  String _speciesLabel(String s) {
    switch (s) {
      case 'dog':
        return 'Hund';
      case 'cat':
        return 'Katze';
      case 'horse':
        return 'Pferd';
      case 'bird':
        return 'Vogel';
      case 'rabbit':
        return 'Kaninchen';
      case 'reptile':
        return 'Reptil';
      default:
        return 'Tier';
    }
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? VetTheme.primary
              : VetTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(VetTheme.radiusFull),
          border: Border.all(
              color: selected
                  ? VetTheme.primary
                  : VetTheme.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? VetTheme.onPrimary : VetTheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
