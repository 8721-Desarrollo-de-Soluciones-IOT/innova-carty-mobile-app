import 'i18n.dart';

/// Money and dates the way people in Peru read them.
String money(double value) => 'S/ ${value.toStringAsFixed(2)}';

String _two(int n) => n.toString().padLeft(2, '0');

String hourMinute(DateTime? date) => date == null ? '--:--' : '${_two(date.hour)}:${_two(date.minute)}';

String dayHour(DateTime? date) =>
    date == null ? '' : '${_two(date.day)}/${_two(date.month)}/${date.year} ${hourMinute(date)}';

/// "hace 2 min" / "2 min ago"...
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return I18n.t('ago.seconds', {'n': diff.inSeconds.clamp(0, 59)});
  if (diff.inMinutes < 60) return I18n.t('ago.minutes', {'n': diff.inMinutes});
  if (diff.inHours < 24) return I18n.t('ago.hours', {'n': diff.inHours});
  return dayHour(date);
}
