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
  });

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
