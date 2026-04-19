enum AppointmentStatus { requested, confirmed, completed, cancelled, noShow }

class Appointment {
  final String id;
  final String petId;
  final String? petName;
  final String ownerId;
  final String? ownerName;
  final String? providerId;
  final String? providerName;
  final String? organizationId;
  final String? organizationName;
  final String title;
  final String? description;
  final AppointmentStatus status;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? location;
  final String? notes;
  final String? cancelledReason;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.petId,
    this.petName,
    required this.ownerId,
    this.ownerName,
    this.providerId,
    this.providerName,
    this.organizationId,
    this.organizationName,
    required this.title,
    this.description,
    required this.status,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.location,
    this.notes,
    this.cancelledReason,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> j) {
    return Appointment(
      id: j['id'] as String,
      petId: j['pet_id'] as String,
      petName: j['pet_name'] as String?,
      ownerId: j['owner_id'] as String,
      ownerName: j['owner_name'] as String?,
      providerId: j['provider_id'] as String?,
      providerName: j['provider_name'] as String?,
      organizationId: j['organization_id'] as String?,
      organizationName: j['organization_name'] as String?,
      title: j['title'] as String,
      description: j['description'] as String?,
      status: _parseStatus(j['status'] as String),
      scheduledAt: DateTime.parse(j['scheduled_at'] as String),
      durationMinutes: j['duration_minutes'] as int? ?? 30,
      location: j['location'] as String?,
      notes: j['notes'] as String?,
      cancelledReason: j['cancelled_reason'] as String?,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }

  static AppointmentStatus _parseStatus(String s) {
    switch (s) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no_show':
        return AppointmentStatus.noShow;
      default:
        return AppointmentStatus.requested;
    }
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return scheduledAt.year == tomorrow.year &&
        scheduledAt.month == tomorrow.month &&
        scheduledAt.day == tomorrow.day;
  }

  String get dateLabel {
    if (isToday) return 'HEUTE';
    if (isTomorrow) return 'MORGEN';
    final months = [
      '',
      'JAN.',
      'FEB.',
      'MÄR.',
      'APR.',
      'MAI',
      'JUN.',
      'JUL.',
      'AUG.',
      'SEP.',
      'OKT.',
      'NOV.',
      'DEZ.',
    ];
    return '${scheduledAt.day}. ${months[scheduledAt.month]}';
  }

  String get timeLabel {
    return '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.requested:
        return 'Angefragt';
      case AppointmentStatus.confirmed:
        return 'Bestätigt';
      case AppointmentStatus.completed:
        return 'Abgeschlossen';
      case AppointmentStatus.cancelled:
        return 'Abgesagt';
      case AppointmentStatus.noShow:
        return 'Nicht erschienen';
    }
  }
}
