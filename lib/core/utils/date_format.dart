import 'package:intl/intl.dart';

/// Friendly date/time formatting used across the app.
class Dates {
  const Dates._();

  static final _full = DateFormat('EEEE, MMM d'); // Tuesday, Oct 14
  static final _short = DateFormat('EEE, MMM d'); // Tue, Oct 14
  static final _weekday = DateFormat('EEE'); // Tue
  static final _time = DateFormat('h:mm a'); // 8:42 AM
  static final _monthDay = DateFormat('MMM d');
  static final _dayNum = DateFormat('d');

  static String fullDate(DateTime d) => _full.format(d);
  static String shortDate(DateTime d) => _short.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String time(DateTime d) => _time.format(d);
  static String monthDay(DateTime d) => _monthDay.format(d);
  static String dayNumber(DateTime d) => _dayNum.format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// "Today" / "Tomorrow" / "Yesterday" / weekday / date.
  static String relativeDay(DateTime d, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return weekday(d);
    return monthDay(d);
  }

  /// Grouping bucket for Due Soon.
  static String dueGroup(DateTime due, {DateTime? from}) {
    final now = from ?? DateTime.now();
    if (due.isBefore(now)) return 'Overdue';
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final diff = target.difference(today).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'This week';
    return 'Later';
  }

  /// Compact relative time: "now", "5m", "2h", "3d", else date.
  static String timeAgo(DateTime d, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return monthDay(d);
  }

  /// "in 12 min" / "in 2 hr 5 min" from a minute count.
  static String inMinutes(int minutes) {
    if (minutes <= 0) return 'now';
    if (minutes < 60) return 'in $minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? 'in $h hr' : 'in $h hr $m min';
  }
}
