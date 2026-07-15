class Gateway {
  final int id;
  final String name;
  final String location;
  final int signal;
  final String power; // "PoE" or "Battery"
  final bool ups;
  final int temperature;
  final bool online;
  final String lastComm;
  final int batteryHealth;

  const Gateway({
    required this.id,
    required this.name,
    required this.location,
    required this.signal,
    required this.power,
    required this.ups,
    required this.temperature,
    required this.online,
    required this.lastComm,
    required this.batteryHealth,
  });
}