class BLEDevice {
  final int id;
  final String tag;
  final int battery;
  final String firmware;
  final String status; // "Assigned" | "Available" | "Low Battery" | "Maintenance"
  final String employee;
  final String lastDetected;

  const BLEDevice({
    required this.id,
    required this.tag,
    required this.battery,
    required this.firmware,
    required this.status,
    required this.employee,
    required this.lastDetected,
  });
}