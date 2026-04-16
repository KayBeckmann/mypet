enum PetSpecies { dog, cat, horse, bird, rabbit, reptile, other }

enum HealthStatus { optimal, good, attention, critical }

enum FeedingStatus { done, upcoming, overdue }

class Pet {
  final String id;
  final String name;
  final String breed;
  final PetSpecies species;
  final DateTime? birthDate;
  final double? weightKg;
  final String? imageUrl;
  final HealthStatus healthStatus;
  final FeedingStatus feedingStatus;
  final String? feedingNote;
  final String? microchipId;
  final String? ownerName;

  final String? notes;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.species,
    this.birthDate,
    this.weightKg,
    this.imageUrl,
    this.healthStatus = HealthStatus.optimal,
    this.feedingStatus = FeedingStatus.done,
    this.feedingNote,
    this.microchipId,
    this.ownerName,
    this.notes,
  });

  /// Erstellt ein Pet aus der Backend-API-Response
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String? ?? '',
      species: _parseSpecies(json['species'] as String? ?? 'other'),
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      weightKg: json['weight_kg'] != null
          ? (json['weight_kg'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      microchipId: json['microchip_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Konvertiert zu JSON für die Backend-API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species.name,
      'breed': breed,
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T').first,
      if (weightKg != null) 'weight_kg': weightKg,
      if (microchipId != null) 'microchip_id': microchipId,
      if (notes != null) 'notes': notes,
    };
  }

  static PetSpecies _parseSpecies(String value) {
    return PetSpecies.values.firstWhere(
      (s) => s.name == value,
      orElse: () => PetSpecies.other,
    );
  }

  String get speciesLabel {
    switch (species) {
      case PetSpecies.dog:
        return 'Hund';
      case PetSpecies.cat:
        return 'Katze';
      case PetSpecies.horse:
        return 'Pferd';
      case PetSpecies.bird:
        return 'Vogel';
      case PetSpecies.rabbit:
        return 'Kaninchen';
      case PetSpecies.reptile:
        return 'Reptil';
      case PetSpecies.other:
        return 'Sonstiges';
    }
  }

  String get healthStatusLabel {
    switch (healthStatus) {
      case HealthStatus.optimal:
        return 'OPTIMAL';
      case HealthStatus.good:
        return 'GUT';
      case HealthStatus.attention:
        return 'ACHTUNG';
      case HealthStatus.critical:
        return 'KRITISCH';
    }
  }

  String get feedingStatusLabel {
    switch (feedingStatus) {
      case FeedingStatus.done:
        return 'ERLEDIGT';
      case FeedingStatus.upcoming:
        return 'IN 2 STD.';
      case FeedingStatus.overdue:
        return 'ÜBERFÄLLIG';
    }
  }

  int? get ageYears {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  String get speciesIcon {
    switch (species) {
      case PetSpecies.dog:
        return '🐕';
      case PetSpecies.cat:
        return '🐈';
      case PetSpecies.horse:
        return '🐎';
      case PetSpecies.bird:
        return '🐦';
      case PetSpecies.rabbit:
        return '🐇';
      case PetSpecies.reptile:
        return '🦎';
      case PetSpecies.other:
        return '🐾';
    }
  }
}
