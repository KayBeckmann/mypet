import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/media.dart';

class MediaProvider extends ChangeNotifier {
  final ApiService _api;

  MediaProvider({required ApiService api}) : _api = api;

  String? _selectedPetId;
  List<PetMedia> _media = [];
  bool _loading = false;
  String? _error;

  String? get selectedPetId => _selectedPetId;
  List<PetMedia> get media => _media;
  bool get loading => _loading;
  String? get error => _error;

  List<PetMedia> get images =>
      _media.where((m) => m.mediaType == 'image').toList();
  List<PetMedia> get documents =>
      _media.where((m) => m.mediaType == 'document').toList();
  List<PetMedia> get xrays =>
      _media.where((m) => m.mediaType == 'xray').toList();

  Future<void> selectPet(String petId) async {
    _selectedPetId = petId;
    _media = [];
    notifyListeners();
    await load();
  }

  Future<void> load() async {
    if (_selectedPetId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$_selectedPetId/media');
      _media = (data['media'] as List<dynamic>? ?? [])
          .map((e) => PetMedia.fromJson(e as Map<String, dynamic>))
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
    required String mimeType,
    String mediaType = 'document',
    String? title,
    String? description,
    bool isPrivate = false,
  }) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.uploadMedia(
        '/pets/$_selectedPetId/media',
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        fields: {
          'media_type': mediaType,
          if (title != null && title.isNotEmpty) 'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'is_private': isPrivate ? 'true' : 'false',
        },
      );
      await load();
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
