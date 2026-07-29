import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _dateTime = DateFormat('EEE, MMM d · h:mm a');
  static final _date = DateFormat('MMM d, yyyy');
  static final _time = DateFormat('h:mm a');

  static String dateTime(DateTime dt) => _dateTime.format(dt.toLocal());
  static String date(DateTime dt) => _date.format(dt.toLocal());
  static String time(DateTime dt) => _time.format(dt.toLocal());

  static String compactCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(fraction * 100 >= 10 ? 0 : 1)}%';

  /// "Closes in 2d 4h", "Closes in 35m", "Closed".
  static String countdown(DateTime? end, {DateTime? now}) {
    if (end == null) return 'No deadline set';
    final current = now ?? DateTime.now();
    final diff = end.difference(current);
    if (diff.isNegative) return 'Closed';
    if (diff.inDays >= 1) {
      return 'Closes in ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours >= 1) {
      return 'Closes in ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    return 'Closes in ${diff.inMinutes}m';
  }

  static String relative(DateTime dt, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
