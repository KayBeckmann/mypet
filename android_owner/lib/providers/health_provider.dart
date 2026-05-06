import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

/// Aggregierter Gesundheits-Provider für Allergien, Lab-Befunde, Impfstatus
class MobileHealthProvider extends ChangeNotifier {
  final ApiService _api;

  MobileHealthProvider({required ApiService api}) : _api = api;

  final Map<String, List<Map<String, dynamic>>> _allergies = {};
  final Map<String, List<Map<String, dynamic>>> _labResults = {};
  final Map<String, Map<String, dynamic>?> _stats = {};
  final Map<String, List<Map<String, dynamic>>> _notes = {};
  final Set<String> _loading = {};

  List<Map<String, dynamic>> allergiesForPet(String petId) => _allergies[petId] ?? [];
  List<Map<String, dynamic>> labResultsForPet(String petId) => _labResults[petId] ?? [];
  Map<String, dynamic>? statsForPet(String petId) => _stats[petId];
  List<Map<String, dynamic>> notesForPet(String petId) => _notes[petId] ?? [];
  bool isLoading(String petId) => _loading.contains(petId);

  Future<void> loadForPet(String petId) async {
    if (_loading.contains(petId)) return;
    _loading.add(petId);
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.get('/pets/$petId/allergies').catchError((_) => {'allergies': []}),
        _api.get('/pets/$petId/lab-results').catchError((_) => {'lab_results': []}),
        _api.get('/pets/$petId/stats').catchError((_) => {'stats': null}),
        _api.get('/pets/$petId/notes').catchError((_) => {'notes': []}),
      ]);
      _allergies[petId] = (results[0]['allergies'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _labResults[petId] = (results[1]['lab_results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      _stats[petId] = results[2]['stats'] as Map<String, dynamic>?;
      _notes[petId] = (results[3]['notes'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (_) {} finally {
      _loading.remove(petId);
      notifyListeners();
    }
  }

  Future<bool> addNote({
    required String petId,
    required String title,
    required String content,
  }) async {
    try {
      final data = await _api.post('/pets/$petId/notes', body: {
        'title': title,
        'content': content,
        'visibility': 'private',
      });
      final note = data['note'] as Map<String, dynamic>?;
      if (note != null) {
        _notes[petId] = [note, ...(_notes[petId] ?? [])];
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
