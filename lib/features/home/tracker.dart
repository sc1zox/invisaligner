import 'package:sqflite/sqflite.dart';

import 'tracker_models.dart';

/// Owns persistence and the current snapshot. Writes are validated in transactions.
class Tracker {
  Tracker._(this._db);

  final Database _db;
  List<PauseInterval> _pauses = const [];
  List<Tray> _trays = const [];

  List<PauseInterval> get pauses => _pauses;
  Tray? get current => _trays.lastOrNull;
  DateTime? get firstDay => _trays.firstOrNull?.start;
  PauseInterval? get activePause {
    for (final pause in _pauses) {
      if (pause.end == null) return pause;
    }
    return null;
  }

  static Future<Tracker> open() async {
    final directory = await getDatabasesPath();
    final db = await openDatabase(
      '$directory/invisaligner.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pauses (
            id INTEGER PRIMARY KEY,
            start INTEGER NOT NULL,
            end INTEGER CHECK(end IS NULL OR end > start)
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX one_open_pause ON pauses ((1)) WHERE end IS NULL',
        );
        await db.execute('CREATE INDEX pauses_start ON pauses (start)');
        await db.execute('''
          CREATE TABLE trays (
            id INTEGER PRIMARY KEY,
            number INTEGER NOT NULL CHECK(number > 0),
            start INTEGER NOT NULL UNIQUE
          )
        ''');
      },
    );
    final tracker = Tracker._(db);
    try {
      await tracker._reload();
      return tracker;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> close() => _db.close();

  Future<void> _reload() async {
    final snapshot = await _db.transaction((txn) async {
      final pauses = await txn.query('pauses', orderBy: 'start, id');
      final trays = await txn.query('trays', orderBy: 'start, id');
      return (pauses, trays);
    });
    _pauses = List.unmodifiable(snapshot.$1.map(PauseInterval.fromRow));
    _trays = List.unmodifiable(snapshot.$2.map(Tray.fromRow));
  }

  bool tracksDay(DateTime day) =>
      firstDay != null && !dayOf(day).isBefore(firstDay!);

  Duration pausedOn(DateTime day, DateTime now) =>
      _pauses.fold(Duration.zero, (sum, pause) => sum + pause.onDay(day, now));

  /// Today only includes elapsed time; completed days use their actual length,
  /// including 23/25-hour days when the local timezone changes clocks.
  Duration wornOn(DateTime day, DateTime now) {
    final start = dayOf(day);
    if (!tracksDay(day) || !now.isAfter(start)) return Duration.zero;
    final end = nextDay(day).isBefore(now) ? nextDay(day) : now;
    final worn = end.difference(start) - pausedOn(day, now);
    return worn.isNegative ? Duration.zero : worn;
  }

  bool isSkipped(DateTime day, DateTime now) =>
      dayOf(day).isBefore(dayOf(now)) && wornOn(day, now) == Duration.zero;

  DateTime? plannedChange(DateTime now) {
    final tray = current;
    if (tray == null) return null;
    var date = tray.start;
    var countedDays = 0;
    while (countedDays < daysPerTray) {
      if (!isSkipped(date, now)) countedDays++;
      date = nextDay(date);
    }
    return date;
  }

  Future<void> stamp() async {
    if (current == null) {
      throw const FormatException('Bitte zuerst deine Schiene einrichten.');
    }
    final now = DateTime.now();
    await _db.transaction((txn) async {
      final open = await txn.query('pauses', where: 'end IS NULL', limit: 1);
      if (open.isEmpty) {
        await _checkOverlap(txn, null, now, null);
        await txn.insert('pauses', {'start': now.millisecondsSinceEpoch});
      } else {
        final pause = PauseInterval.fromRow(open.single);
        if (!now.isAfter(pause.start)) {
          throw const FormatException(
            'Die Einsetzzeit muss nach der Entnahme liegen.',
          );
        }
        await txn.update(
          'pauses',
          {'end': now.millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [pause.id],
        );
      }
    });
    await _reload();
  }

  Future<void> startTray(int number, DateTime start) async {
    final day = dayOf(start);
    if (number <= 0 || day.isAfter(dayOf(DateTime.now()))) {
      throw const FormatException(
        'Bitte eine gültige Schienennummer und einen bisherigen Tag wählen.',
      );
    }
    await _db.transaction((txn) async {
      final rows = await txn.query('trays', orderBy: 'start DESC', limit: 1);
      if (rows.isNotEmpty) {
        final previous = Tray.fromRow(rows.single);
        if (!day.isAfter(previous.start) || number <= previous.number) {
          throw const FormatException(
            'Die nächste Schiene muss nach der aktuellen beginnen und eine höhere Nummer haben.',
          );
        }
      }
      await txn.insert('trays', {
        'number': number,
        'start': day.millisecondsSinceEpoch,
      });
    });
    await _reload();
  }

  Future<void> savePause(int? id, DateTime start, DateTime? end) async {
    _validateDay(start);
    final now = DateTime.now();
    if (start.isAfter(now) ||
        (end != null && (!end.isAfter(start) || end.isAfter(now)))) {
      throw const FormatException(
        'Die Pause muss in der Vergangenheit beginnen und das Ende nach dem Anfang liegen.',
      );
    }
    await _db.transaction((txn) async {
      await _checkOverlap(txn, id, start, end);
      final values = {
        'start': start.millisecondsSinceEpoch,
        'end': end?.millisecondsSinceEpoch,
      };
      if (id == null) {
        await txn.insert('pauses', values);
      } else {
        final changed = await txn.update(
          'pauses',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        if (changed != 1) {
          throw const FormatException('Diese Pause existiert nicht mehr.');
        }
      }
    });
    await _reload();
  }

  Future<void> deletePause(int id) async {
    await _db.delete('pauses', where: 'id = ?', whereArgs: [id]);
    await _reload();
  }

  void _validateDay(DateTime day) {
    if (!tracksDay(day) || dayOf(day).isAfter(dayOf(DateTime.now()))) {
      throw const FormatException(
        'Bitte einen Tag seit Beginn deiner Erfassung wählen.',
      );
    }
  }

  static Future<void> _checkOverlap(
    Transaction txn,
    int? id,
    DateTime start,
    DateTime? end,
  ) async {
    // Half-open intervals allow one pause to start exactly when another ends.
    final overlaps = await txn.query(
      'pauses',
      columns: ['id'],
      where:
          '(? IS NULL OR id != ?) AND (? IS NULL OR start < ?) '
          'AND (end IS NULL OR end > ?)',
      whereArgs: [
        id,
        id,
        end?.millisecondsSinceEpoch,
        end?.millisecondsSinceEpoch,
        start.millisecondsSinceEpoch,
      ],
      limit: 1,
    );
    if (overlaps.isNotEmpty) {
      throw const FormatException(
        'Dieser Zeitraum überschneidet sich mit einer anderen Pause. Korrigiere zuerst die vorhandene Pause.',
      );
    }
  }
}
