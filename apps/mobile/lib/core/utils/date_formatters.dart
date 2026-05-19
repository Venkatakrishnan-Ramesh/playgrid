class DateFormatters {
  const DateFormatters._();

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String shortDate(DateTime value) =>
      '${_weekdays[value.weekday - 1]}, ${value.day} ${_months[value.month - 1]}';
  static String dateTime(DateTime value) =>
      '${shortDate(value)} • ${time(value)}';
  static String time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String monthDay(DateTime value) =>
      '${_months[value.month - 1]} ${value.day}';
}

String formatDayMonth(DateTime value) => DateFormatters.monthDay(value);

String formatTimeRange(DateTime startAt, DateTime endAt) {
  return '${DateFormatters.time(startAt)} - ${DateFormatters.time(endAt)}';
}
