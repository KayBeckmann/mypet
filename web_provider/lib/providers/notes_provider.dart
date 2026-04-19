import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

class ProviderNote {
  final String id;
  final String petId;
  final String authorId;
  final String? authorName;
  final String? organizationId;
  final String? organizationName;
  final String? title;
  final String content;
  final String visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderNote({
    required this.id,
    required this.petId,
    required this.authorId,
    this.authorName,
    this.organizationId,
    this.organizationName,
    this.title,
    required this.content,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderNote.fromJson(Map<String, dynamic> j) => ProviderNote(
        id: j['id'] as String,
        petId: j['pet_id'] as String,
        authorId: j['author_id'] as String,
        authorName: j['author_name'] as String?,
        organizationId: j['organization_id'] as String?,
        organizationName: j['organization_name'] as String?,
        title: j['title'] as String?,
        content: j['content'] as String,
        visibility: j['visibility'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  String get visibilityLabel => switch (visibility) {
        'private' => 'Privat',
        'colleagues' => 'Kollegen',
        'all_professionals' => 'Alle Fachkräfte',
        _ => visibility,
      };
}

class ProviderNotesProvider extends ChangeNotifier {
  final ApiService _api;

  ProviderNotesProvider({required ApiService api}) : _api = api;

  String? _selectedPetId;
  List<ProviderNote> _notes = [];
  bool _loading = false;
  String? _error;

  String? get selectedPetId => _selectedPetId;
  List<ProviderNote> get notes => _notes;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadForPet(String petId) async {
    _selectedPetId = petId;
    _notes = [];
    notifyListeners();
    await _load();
  }

  Future<void> _load() async {
    if (_selectedPetId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$_selectedPetId/notes');
      _notes = (data['notes'] as List<dynamic>? ?? [])
          .map((e) => ProviderNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    String? title,
    required String content,
    String visibility = 'private',
  }) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.post('/pets/$_selectedPetId/notes', body: {
        if (title != null && title.isNotEmpty) 'title': title,
        'content': content,
        'visibility': visibility,
      });
      await _load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String noteId) async {
    if (_selectedPetId == null) return false;
    try {
      await _api.delete('/pets/$_selectedPetId/notes/$noteId');
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
