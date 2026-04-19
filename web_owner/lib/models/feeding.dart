class FeedingComponent {
  final String id;
  final String mealId;
  final String foodName;
  final double? amountGrams;
  final String unit;
  final String? notes;
  final int sortOrder;

  const FeedingComponent({
    required this.id,
    required this.mealId,
    required this.foodName,
    this.amountGrams,
    this.unit = 'g',
    this.notes,
    this.sortOrder = 0,
  });

  factory FeedingComponent.fromJson(Map<String, dynamic> j) {
    return FeedingComponent(
      id: j['id'] as String,
      mealId: j['meal_id'] as String,
      foodName: j['food_name'] as String,
      amountGrams: (j['amount_grams'] as num?)?.toDouble(),
      unit: j['unit'] as String? ?? 'g',
      notes: j['notes'] as String?,
      sortOrder: j['sort_order'] as int? ?? 0,
    );
  }
}

class FeedingMeal {
  final String id;
  final String planId;
  final String name;
  final String? timeOfDay;
  final String? notes;
  final int sortOrder;
  final List<FeedingComponent> components;

  const FeedingMeal({
    required this.id,
    required this.planId,
    required this.name,
    this.timeOfDay,
    this.notes,
    this.sortOrder = 0,
    this.components = const [],
  });

  factory FeedingMeal.fromJson(Map<String, dynamic> j) {
    final rawComponents = j['components'];
    List<FeedingComponent> components = [];
    if (rawComponents is List) {
      components = rawComponents
          .whereType<Map<String, dynamic>>()
          .map(FeedingComponent.fromJson)
          .toList();
    }
    return FeedingMeal(
      id: j['id'] as String,
      planId: j['plan_id'] as String,
      name: j['name'] as String,
      timeOfDay: j['time_of_day'] as String?,
      notes: j['notes'] as String?,
      sortOrder: j['sort_order'] as int? ?? 0,
      components: components,
    );
  }
}

class FeedingPlan {
  final String id;
  final String petId;
  final String createdBy;
  final String name;
  final String? description;
  final bool isActive;
  final String? validFrom;
  final String? validUntil;
  final int? mealCount;
  final List<FeedingMeal> meals;
  final DateTime createdAt;

  const FeedingPlan({
    required this.id,
    required this.petId,
    required this.createdBy,
    required this.name,
    this.description,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
    this.mealCount,
    this.meals = const [],
    required this.createdAt,
  });

  factory FeedingPlan.fromJson(Map<String, dynamic> j) {
    final rawMeals = j['meals'];
    List<FeedingMeal> meals = [];
    if (rawMeals is List) {
      meals = rawMeals
          .whereType<Map<String, dynamic>>()
          .map(FeedingMeal.fromJson)
          .toList();
    }
    return FeedingPlan(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      createdBy: j['created_by'] as String,
      name: j['name'] as String,
      description: j['description'] as String?,
      isActive: j['is_active'] as bool? ?? true,
      validFrom: j['valid_from'] as String?,
      validUntil: j['valid_until'] as String?,
      mealCount: j['meal_count'] as int?,
      meals: meals,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

class FeedingLogEntry {
  final String id;
  final String petId;
  final String? mealId;
  final String? mealName;
  final String fedBy;
  final String? fedByName;
  final DateTime fedAt;
  final String? notes;
  final double? amountFedGrams;
  final bool skipped;
  final String? skipReason;

  const FeedingLogEntry({
    required this.id,
    required this.petId,
    this.mealId,
    this.mealName,
    required this.fedBy,
    this.fedByName,
    required this.fedAt,
    this.notes,
    this.amountFedGrams,
    this.skipped = false,
    this.skipReason,
  });

  factory FeedingLogEntry.fromJson(Map<String, dynamic> j) {
    return FeedingLogEntry(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      mealId: j['meal_id'] as String?,
      mealName: j['meal_name'] as String?,
      fedBy: j['fed_by'] as String,
      fedByName: j['fed_by_name'] as String?,
      fedAt: DateTime.parse(j['fed_at'] as String),
      notes: j['notes'] as String?,
      amountFedGrams: (j['amount_fed_grams'] as num?)?.toDouble(),
      skipped: j['skipped'] as bool? ?? false,
      skipReason: j['skip_reason'] as String?,
    );
  }
}
