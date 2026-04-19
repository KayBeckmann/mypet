import 'package:flutter/material.dart';
import 'package:mypet_shared/shared.dart';

/// Kunden = Tiere, auf die der Dienstleister Zugriff hat
class CustomersProvider extends ChangeNotifier {
  final ApiService _api;

  CustomersProvider({required ApiService api}) : _api = api;

  List<Map<String, dynamic>> _pets = [];
  bool _loading = false;
  String? _error;
  String _search = '';

  List<Map<String, dynamic>> get pets => _pets
      .where((p) =>
          _search.isEmpty ||
          (p['name'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase()) ||
          (p['owner_name'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase()))
      .toList();

  bool get loading => _loading;
  String? get error => _error;
  String get search => _search;

  void setSearch(String q) {
    _search = q;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets');
      _pets =
          (data['pets'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
