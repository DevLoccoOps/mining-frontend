class RecentEvent {
  final int id;
  final int color; // ARGB int
  final String msg;
  final String time;

  const RecentEvent({
    required this.id,
    required this.color,
    required this.msg,
    required this.time,
  });
}