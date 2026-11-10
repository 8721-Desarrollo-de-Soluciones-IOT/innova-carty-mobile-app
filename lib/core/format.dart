/// Money and dates the way people in Peru read them.
String money(double value) => 'S/ ${value.toStringAsFixed(2)}';

String _two(int n) => n.toString().padLeft(2, '0');

String hourMinute(DateTime? date) => date == null ? '--:--' : '${_two(date.hour)}:${_two(date.minute)}';

String dayHour(DateTime? date) =>
    date == null ? '' : '${_two(date.day)}/${_two(date.month)}/${date.year} ${hourMinute(date)}';

/// "hace 2 min", "hace 3 h"...
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'hace ${diff.inSeconds.clamp(0, 59)} s';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return dayHour(date);
}
