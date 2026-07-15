enum AlertSeverity { critical, warning, info }

extension AlertSeverityX on AlertSeverity {
  String get label => name;
}

enum AlertStatus { open, inProgress, closed }

extension AlertStatusX on AlertStatus {
  String get label {
    switch (this) {
      case AlertStatus.open:
        return 'Open';
      case AlertStatus.inProgress:
        return 'In Progress';
      case AlertStatus.closed:
        return 'Resolved';
    }
  }
}

class AlertItem {
  final int id;
  final String type;
  final String message;
  final String time;
  final AlertSeverity severity;
  final String location;
  final String? assigned;
  final AlertStatus status;

  const AlertItem({
    required this.id,
    required this.type,
    required this.message,
    required this.time,
    required this.severity,
    required this.location,
    this.assigned,
    required this.status,
  });
}