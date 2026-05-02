// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../config/theme.dart';
import '../providers/pet_provider.dart';
import '../providers/media_provider.dart';
import '../providers/health_provider.dart';
import '../models/media.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pets = context.read<PetProvider>().pets;
      final mediaProvider = context.read<MediaProvider>();
      if (pets.isNotEmpty && mediaProvider.selectedPetId == null) {
        final petId = pets.first.id;
        mediaProvider.selectPet(petId);
        context.read<OwnerHealthProvider>().loadForPet(petId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final mediaProvider = context.watch<MediaProvider>();
    final healthProvider = context.watch<OwnerHealthProvider>();
    final pets = petProvider.pets;
    final selectedPetId = mediaProvider.selectedPetId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akten & Medien',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Medizinische Akte, Fotos und Dokumente deiner Tiere.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LivingLedgerTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Pet selector
          if (pets.isEmpty)
            const Text('Noch keine Tiere vorhanden.')
          else
            Row(
              children: [
                const Text('Tier: ',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 8,
                  children: pets
                      .map((p) => ChoiceChip(
                            label: Text(p.name),
                            selected: selectedPetId == p.id,
                            onSelected: (_) {
                              mediaProvider.selectPet(p.id);
                              healthProvider.loadForPet(p.id);
                            },
                          ))
                      .toList(),
                ),
                const Spacer(),
                if (_tabController.index < 3)
                  FilledButton.icon(
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Datei hochladen'),
                    onPressed: selectedPetId == null
                        ? null
                        : () => _showUploadDialog(context, mediaProvider),
                  ),
              ],
            ),
          const SizedBox(height: 16),

          if (mediaProvider.loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            TabBar(
              controller: _tabController,
              labelColor: LivingLedgerTheme.primary,
              unselectedLabelColor: LivingLedgerTheme.onSurfaceVariant,
              indicatorColor: LivingLedgerTheme.primary,
              onTap: (_) => setState(() {}),
              tabs: [
                Tab(text: 'Alle (${mediaProvider.media.length})'),
                Tab(text: 'Bilder (${mediaProvider.images.length})'),
                Tab(text: 'Dokumente (${mediaProvider.documents.length})'),
                Tab(
                  text: selectedPetId != null
                      ? 'Krankenakte (${healthProvider.recordsForPet(selectedPetId).length})'
                      : 'Krankenakte',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 600,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MediaGrid(items: mediaProvider.media),
                  _MediaGrid(items: mediaProvider.images),
                  _MediaGrid(items: mediaProvider.documents),
                  selectedPetId != null
                      ? _MedicalRecordsTab(
                          petId: selectedPetId,
                          provider: healthProvider,
                        )
                      : const Center(
                          child: Text('Tier auswählen')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, MediaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _UploadDialog(provider: provider),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<PetMedia> items;

  const _MediaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 64,
                color: LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Keine Dateien vorhanden',
                style:
                    TextStyle(color: LivingLedgerTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _MediaCard(item: items[i]),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final PetMedia item;

  const _MediaCard({required this.item});

  IconData get _icon {
    if (item.mediaType == 'image') return Icons.image_rounded;
    if (item.mediaType == 'xray') return Icons.medical_information_rounded;
    if (item.mediaType == 'video') return Icons.videocam_rounded;
    return Icons.description_rounded;
  }

  Color get _color {
    if (item.mediaType == 'image') return Colors.blue;
    if (item.mediaType == 'xray') return Colors.purple;
    if (item.mediaType == 'video') return Colors.red;
    return LivingLedgerTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final apiBase = const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://localhost:8080');
    final provider = context.read<MediaProvider>();

    return Container(
      decoration: BoxDecoration(
        color: LivingLedgerTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivingLedgerTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview area
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: item.isImage
                  ? Image.network(
                      '$apiBase${item.url}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.sizeLabel,
                      style: TextStyle(
                          color: LivingLedgerTheme.onSurfaceVariant,
                          fontSize: 11),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        html.window.open('$apiBase${item.url}', '_blank');
                      },
                      child: Icon(
                        item.isImage
                            ? Icons.open_in_new_rounded
                            : Icons.download_rounded,
                        size: 16,
                        color: LivingLedgerTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Datei löschen?'),
                                content: Text(
                                    '${item.displayName} wirklich löschen?'),
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
                        if (ok) provider.delete(item.id);
                      },
                      child: Icon(Icons.delete_outline_rounded,
                          size: 16,
                          color: LivingLedgerTheme.onSurfaceVariant),
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

  Widget _placeholder() {
    return Container(
      color: _color.withValues(alpha: 0.08),
      child: Center(
        child: Icon(_icon, size: 48, color: _color.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _UploadDialog extends StatefulWidget {
  final MediaProvider provider;

  const _UploadDialog({required this.provider});

  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _mediaType = 'document';
  bool _isPrivate = false;
  bool _uploading = false;
  String? _selectedFileName;
  List<int>? _selectedBytes;
  String? _selectedMime;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _selectedFileName = file.name;
      _selectedBytes = file.bytes?.toList();
      _selectedMime = file.extension != null
          ? _mimeFromExt(file.extension!)
          : 'application/octet-stream';
    });
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datei hochladen'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type selector
            DropdownButtonFormField<String>(
              value: _mediaType,
              decoration: const InputDecoration(labelText: 'Typ'),
              items: const [
                DropdownMenuItem(value: 'image', child: Text('Bild')),
                DropdownMenuItem(value: 'document', child: Text('Dokument')),
                DropdownMenuItem(value: 'xray', child: Text('Röntgenbild')),
                DropdownMenuItem(value: 'video', child: Text('Video')),
                DropdownMenuItem(value: 'other', child: Text('Sonstiges')),
              ],
              onChanged: (v) => setState(() => _mediaType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titel (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Privat'),
              subtitle: const Text('Nur für dich sichtbar'),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_selectedFileName ?? 'Datei auswählen'),
              onPressed: _pickFile,
            ),
            if (_selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Ausgewählt: $_selectedFileName',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _uploading || _selectedBytes == null
              ? null
              : () async {
                  setState(() => _uploading = true);
                  final ok = await widget.provider.upload(
                    bytes: _selectedBytes!,
                    filename: _selectedFileName!,
                    mimeType: _selectedMime!,
                    mediaType: _mediaType,
                    title: _titleCtrl.text,
                    description: _descCtrl.text,
                    isPrivate: _isPrivate,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload fehlgeschlagen')),
                      );
                    }
                  }
                },
          child: _uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Hochladen'),
        ),
      ],
    );
  }
}

class _MedicalRecordsTab extends StatelessWidget {
  final String petId;
  final OwnerHealthProvider provider;

  const _MedicalRecordsTab({required this.petId, required this.provider});

  @override
  Widget build(BuildContext context) {
    final records = provider.recordsForPet(petId);
    final loading = provider.isLoading(petId);
    final fmt = DateFormat('dd.MM.yyyy');

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined,
                size: 56,
                color:
                    LivingLedgerTheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'Noch keine Einträge in der Krankenakte.',
              style: TextStyle(color: LivingLedgerTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = records[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LivingLedgerTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LivingLedgerTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: LivingLedgerTheme.secondaryContainer,
                      borderRadius:
                          BorderRadius.circular(LivingLedgerTheme.radiusFull),
                    ),
                    child: Text(r.typeLabel,
                        style: TextStyle(
                            fontSize: 10,
                            color: LivingLedgerTheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (r.recordedAt != null)
                    Text(
                      fmt.format(r.recordedAt!),
                      style: const TextStyle(
                          fontSize: 12,
                          color: LivingLedgerTheme.onSurfaceVariant),
                    ),
                ],
              ),
              if (r.vetName != null) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    r.vetName!,
                    if (r.organizationName != null) r.organizationName!,
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 12,
                      color: LivingLedgerTheme.onSurfaceVariant),
                ),
              ],
              if (r.diagnosis != null && r.diagnosis!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  r.diagnosis!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: LivingLedgerTheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
