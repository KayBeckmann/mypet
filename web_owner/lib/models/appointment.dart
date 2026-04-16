enum AppointmentStatus { upcoming, confirmed, completed, cancelled }

class Appointment {
  final String id;
  final String title;
  final String? petName;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? providerName;

  const Appointment({
    required this.id,
    required this.title,
    this.petName,
    required this.dateTime,
    this.status = AppointmentStatus.upcoming,
    this.providerName,
  });

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  String get dateLabel {
    if (isToday) return 'HEUTE';
    if (isTomorrow) return 'MORGEN';
    final months = [
      '', 'JAN.', 'FEB.', 'MÄR.', 'APR.', 'MAI', 'JUN.',
      'JUL.', 'AUG.', 'SEP.', 'OKT.', 'NOV.', 'DEZ.',
    ];
    return '${dateTime.day}. ${months[dateTime.month]}';
  }

  String get timeLabel {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String get statusLabel {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Geplant';
      case AppointmentStatus.confirmed:
        return 'Bestätigt';
      case AppointmentStatus.completed:
        return 'Abgeschlossen';
      case AppointmentStatus.cancelled:
        return 'Abgesagt';
    }
  }
}
