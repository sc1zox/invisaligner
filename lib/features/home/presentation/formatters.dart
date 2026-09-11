String longDateText(DateTime date) {
  const weekdays = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];
  const months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day}. ${months[date.month - 1]}';
}

String dateText(DateTime date) => '${date.day}.${date.month}.${date.year}';

String timeText(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String dateTimeText(DateTime date) => '${dateText(date)} · ${timeText(date)}';

String hoursText(Duration duration) =>
    '${duration.inHours} h ${duration.inMinutes.remainder(60).toString().padLeft(2, '0')} min';

String saveError(Object error) => error is FormatException
    ? error.message
    : 'Speichern fehlgeschlagen. Bitte erneut versuchen.';
