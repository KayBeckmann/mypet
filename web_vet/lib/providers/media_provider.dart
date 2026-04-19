import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class VetMedia {
  final String id;
  final String petId;
  final String uploadedBy;
  final String? uploadedByName;
  final String? medicalRecordId;
  final String? recordTitle;
  final String mediaType;
  final String filename;
  final String? originalName;
  final String mimeType;
  final int fileSize;
  final String url;
  final String? title;
  final String? description;
  final bool isPrivate;
  final DateTime createdAt;

  const VetMedia({
    required this.id,
    required this.petId,
    required this.uploadedBy,
    this.uploadedByName,
    this.medicalRecordId,
    this.recordTitle,
    required this.mediaType,
    required this.filename,
    this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.url,
    this.title,
    this.description,
    required this.isPrivate,
    required this.createdAt,
  });

  factory VetMedia.fromJson(Map<String, dynamic> j) => VetMedia(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        uploadedBy: j['uploaded_by'] as String,
        uploadedByName: j['uploaded_by_name'] as String?,
        medicalRecordId: j['medical_record_id'] as String?,
        recordTitle: j['record_title'] as String?,
        mediaType: j['media_type'] as String,
        filename: j['filename'] as String,
        originalName: j['original_name'] as String?,
        mimeType: j['mime_type'] as String,
        fileSize: (j['file_size'] as num).toInt(),
        url: j['url'] as String,
        title: j['title'] as String?,
        description: j['description'] as String?,
        isPrivate: j['is_private'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get displayName => title ?? originalName ?? filename;

  String get sizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      mimeType.startsWith('image/') || mediaType == 'image' || mediaType == 'xray';
}

class VetMediaProvider extends ChangeNotifier {
  final ApiService _api;

  VetMediaProvider({required ApiService api}) : _api = api;

  String? _selectedPetId;
  List<VetMedia> _media = [];
  bool _loading = false;
  String? _error;

  String? get selectedPetId => _selectedPetId;
  List<VetMedia> get media => _media;
  bool get loading => _loading;
  String? get error => _error;

  List<VetMedia> get xrays =>
      _media.where((m) => m.mediaType == 'xray').toList();
  List<VetMedia> get images =>
      _media.where((m) => m.mediaType == 'image').toList();

  Future<void> loadForPet(String petId) async {
    _selectedPetId = petId;
    _media = [];
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    if (_selectedPetId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$_selectedPetId/media');
      _media = (data['media'] as List<dynamic>? ?? [])
          .map((e) => VetMedia.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> upload({
    required List<int> bytes,
    required String filename,
    String mediaType = 'xray',
    String? title,
    String? description,
    String? medicalRecordId,
    bool isPrivate = false,
  }) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.uploadMedia(
        '/pets/$_selectedPetId/media',
        bytes: bytes,
        filename: filename,
        fields: {
          'media_type': mediaType,
          if (title != null && title.isNotEmpty) 'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (medicalRecordId != null && medicalRecordId.isNotEmpty)
            'medical_record_id': medicalRecordId,
          'is_private': isPrivate ? 'true' : 'false',
        },
      );
      await _load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String mediaId) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.delete('/pets/$_selectedPetId/media/$mediaId');
      _media.removeWhere((m) => m.id == mediaId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
