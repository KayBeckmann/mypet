import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PetNote {
  final String id;
  final String petId;
  final String title;
  final String? content;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PetNote({
    required this.id,
    required this.petId,
    required this.title,
    this.content,
    required this.isPrivate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetNote.fromJson(Map<String, dynamic> j) => PetNote(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        title: j['title'] as String,
        content: j['content'] as String?,
        isPrivate: j['is_private'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}

class OwnerNotesProvider extends ChangeNotifier {
  final ApiService _api;

  OwnerNotesProvider({required ApiService api}) : _api = api;

  final Map<String, List<PetNote>> _byPet = {};
  final Map<String, bool> _loading = {};
  String? _error;

  String? get error => _error;

  List<PetNote> forPet(String petId) => _byPet[petId] ?? const [];
  bool isLoading(String petId) => _loading[petId] ?? false;

  Future<void> loadForPet(String petId) async {
    _loading[petId] = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/pets/$petId/notes');
      _byPet[petId] = (data['notes'] as List<dynamic>? ?? [])
          .map((j) => PetNote.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _error = 'Notizen konnten nicht geladen werden';
    }

    _loading[petId] = false;
    notifyListeners();
  }

  Future<bool> create(
    String petId, {
    required String title,
    String? content,
    bool isPrivate = false,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/notes', body: {
        'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        'is_private': isPrivate,
      });
      final note = PetNote.fromJson(data['note'] as Map<String, dynamic>);
      _byPet[petId] = [note, ...(_byPet[petId] ?? [])];
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Notiz konnte nicht erstellt werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    String petId,
    String noteId, {
    required String title,
    String? content,
    bool? isPrivate,
  }) async {
    try {
      final data = await _api.put('/pets/$petId/notes/$noteId', body: {
        'title': title,
        'content': content ?? '',
        if (isPrivate != null) 'is_private': isPrivate,
      });
      final updated = PetNote.fromJson(data['note'] as Map<String, dynamic>);
      final notes = List<PetNote>.from(_byPet[petId] ?? []);
      final idx = notes.indexWhere((n) => n.id == noteId);
      if (idx >= 0) notes[idx] = updated;
      _byPet[petId] = notes;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Notiz konnte nicht aktualisiert werden';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String petId, String noteId) async {
    try {
      await _api.delete('/pets/$petId/notes/$noteId');
      _byPet[petId] = (_byPet[petId] ?? [])
          .where((n) => n.id != noteId)
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Notiz konnte nicht gelöscht werden';
      notifyListeners();
      return false;
    }
  }
}
