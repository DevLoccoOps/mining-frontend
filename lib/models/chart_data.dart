/// Chart data DTOs shared by the chart widgets and the pages feeding them.

class BatterySlice {
  final String name;
  final int value;
  final int color;
  const BatterySlice(this.name, this.value, this.color);
}

class ZoneCount {
  final String zone;
  final int n;
  const ZoneCount(this.zone, this.n);
}