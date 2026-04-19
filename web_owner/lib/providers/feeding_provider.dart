import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/feeding.dart';

class FeedingProvider extends ChangeNotifier {
  final ApiService _api;

  FeedingProvider({required ApiService api}) : _api = api;

  String? _selectedPetId;
  List<FeedingPlan> _plans = [];
  FeedingPlan? _selectedPlan;
  List<FeedingLogEntry> _log = [];
  bool _loading = false;
  String? _error;

  String? get selectedPetId => _selectedPetId;
  List<FeedingPlan> get plans => _plans;
  FeedingPlan? get selectedPlan => _selectedPlan;
  List<FeedingLogEntry> get log => _log;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> selectPet(String petId) async {
    _selectedPetId = petId;
    _plans = [];
    _log = [];
    _selectedPlan = null;
    notifyListeners();
    await _loadPlans();
    await _loadLog();
  }

  Future<void> _loadPlans() async {
    if (_selectedPetId == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/pets/$_selectedPetId/feeding-plans');
      _plans = (data['plans'] as List<dynamic>? ?? [])
          .map((e) => FeedingPlan.fromJson(e as Map<String, dynamic>))
          .toList();
      if (_plans.isNotEmpty) {
        await loadPlanDetail(_plans.first.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlanDetail(String planId) async {
    if (_selectedPetId == null) return;
    try {
      final data =
          await _api.get('/pets/$_selectedPetId/feeding-plans/$planId');
      _selectedPlan =
          FeedingPlan.fromJson(data['plan'] as Map<String, dynamic>);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<FeedingPlan?> createPlan({
    required String name,
    String? description,
    String? validFrom,
    String? validUntil,
  }) async {
    if (_selectedPetId == null) return null;
    try {
      final data = await _api.post('/pets/$_selectedPetId/feeding-plans', body: {
        'name': name,
        if (description != null) 'description': description,
        if (validFrom != null) 'valid_from': validFrom,
        if (validUntil != null) 'valid_until': validUntil,
      });
      final plan = FeedingPlan.fromJson(data['plan'] as Map<String, dynamic>);
      _plans.insert(0, plan);
      _selectedPlan = plan;
      notifyListeners();
      return plan;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<FeedingMeal?> addMeal({
    required String planId,
    required String name,
    String? timeOfDay,
    String? notes,
  }) async {
    if (_selectedPetId == null) return null;
    try {
      final data = await _api.post(
          '/pets/$_selectedPetId/feeding-plans/$planId/meals',
          body: {
            'name': name,
            if (timeOfDay != null) 'time_of_day': timeOfDay,
            if (notes != null) 'notes': notes,
          });
      final meal =
          FeedingMeal.fromJson(data['meal'] as Map<String, dynamic>);
      await loadPlanDetail(planId);
      return meal;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<FeedingComponent?> addComponent({
    required String planId,
    required String mealId,
    required String foodName,
    double? amountGrams,
    String unit = 'g',
    String? notes,
  }) async {
    if (_selectedPetId == null) return null;
    try {
      final data = await _api.post(
          '/pets/$_selectedPetId/feeding-plans/$planId/meals/$mealId/components',
          body: {
            'food_name': foodName,
            if (amountGrams != null) 'amount_grams': amountGrams,
            'unit': unit,
            if (notes != null) 'notes': notes,
          });
      final component = FeedingComponent.fromJson(
          data['component'] as Map<String, dynamic>);
      await loadPlanDetail(planId);
      return component;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> _loadLog() async {
    if (_selectedPetId == null) return;
    try {
      final data = await _api.get('/pets/$_selectedPetId/feeding-log');
      _log = (data['log'] as List<dynamic>? ?? [])
          .map((e) => FeedingLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      // non-fatal
    }
  }

  Future<FeedingLogEntry?> logFeeding({
    String? mealId,
    String? notes,
    double? amountFedGrams,
    bool skipped = false,
    String? skipReason,
  }) async {
    if (_selectedPetId == null) return null;
    try {
      final data = await _api.post('/pets/$_selectedPetId/feeding-log', body: {
        if (mealId != null) 'meal_id': mealId,
        if (notes != null) 'notes': notes,
        if (amountFedGrams != null) 'amount_fed_grams': amountFedGrams,
        'skipped': skipped,
        if (skipReason != null) 'skip_reason': skipReason,
      });
      final entry =
          FeedingLogEntry.fromJson(data['entry'] as Map<String, dynamic>);
      _log.insert(0, entry);
      notifyListeners();
      return entry;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
