enum WorkerStatus { moving, stationary, emergency, surface }

extension WorkerStatusX on WorkerStatus {
  String get label {
    switch (this) {
      case WorkerStatus.moving:
        return 'Moving';
      case WorkerStatus.stationary:
        return 'Stationary';
      case WorkerStatus.emergency:
        return 'Emergency';
      case WorkerStatus.surface:
        return 'Surface';
    }
  }
}

class Worker {
  final int id;
  final String name;
  final String empNo;
  final String dept;
  final String zone;
  final String bleTag;
  final int battery;
  final int signal;
  final String lastSeen;
  final String gateway;
  final WorkerStatus status;
  final String shift;
  final double x;
  final double y;

  const Worker({
    required this.id,
    required this.name,
    required this.empNo,
    required this.dept,
    required this.zone,
    required this.bleTag,
    required this.battery,
    required this.signal,
    required this.lastSeen,
    required this.gateway,
    required this.status,
    required this.shift,
    required this.x,
    required this.y,
  });

  String get initials =>
      name.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join();
}