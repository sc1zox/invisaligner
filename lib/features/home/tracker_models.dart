DateTime dayOf(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

const dailyWearGoal = Duration(hours: 20);
const daysPerTray = 14;

class PauseInterval {
  const PauseInterval({required this.id, required this.start, this.end});

  factory PauseInterval.fromRow(Map<String, Object?> row) => PauseInterval(
    id: row['id'] as int,
    start: DateTime.fromMillisecondsSinceEpoch(row['start'] as int),
    end: switch (row['end']) {
      final int value => DateTime.fromMillisecondsSinceEpoch(value),
      _ => null,
    },
  );

  final int id;
  final DateTime start;
  final DateTime? end;

  bool overlapsDay(DateTime day) =>
      start.isBefore(nextDay(day)) && (end == null || end!.isAfter(dayOf(day)));

  Duration onDay(DateTime day, DateTime now) {
    final lower = dayOf(day);
    final upper = nextDay(day);
    final from = start.isAfter(lower) ? start : lower;
    var to = end ?? now;
    if (to.isAfter(now)) to = now;
    if (to.isAfter(upper)) to = upper;
    return to.isAfter(from) ? to.difference(from) : Duration.zero;
  }
}

class Tray {
  const Tray({required this.id, required this.number, required this.start});

  factory Tray.fromRow(Map<String, Object?> row) => Tray(
    id: row['id'] as int,
    number: row['number'] as int,
    start: DateTime.fromMillisecondsSinceEpoch(row['start'] as int),
  );

  final int id;
  final int number;
  final DateTime start;
}
