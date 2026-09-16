DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  return DateTime.tryParse(value.toString())?.toLocal();
}

int _parseIntervalDays(dynamic value) {
  if (value == null) return 1;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 1;
}

int? _parseMonthDay(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

int _lastDayOfMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}

int _clampedMonthDay(int year, int month, int monthDay) {
  final lastDay = _lastDayOfMonth(year, month);
  if (monthDay < 1) return 1;
  return monthDay > lastDay ? lastDay : monthDay;
}

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Map<String, dynamic>? _lastResponseRecord(
    List<Map<String, dynamic>> completions, dynamic routineId) {
  final matches = completions.where((c) {
    final status = c['status']?.toString();
    final isHandled = status == 'completed' || status == 'done' || status == 'skipped';
    return c['routine_id']?.toString() == routineId?.toString() &&
        isHandled &&
        _tryParseDate(c['completed_at']) != null;
  }).toList();
  if (matches.isEmpty) return null;

  matches.sort((a, b) => _tryParseDate(b['completed_at'])!
      .compareTo(_tryParseDate(a['completed_at'])!));

  return matches.first;
}

/// Date of the most recent response (done OR skipped) for this routine.
/// Used to compute the next occurrence for interval-based routines, since
/// skipping an interval routine should push its next reminder forward
/// just like completing it does.
DateTime? lastCompletionDate(
    List<Map<String, dynamic>> completions, dynamic routineId) {
  final record = _lastResponseRecord(completions, routineId);
  if (record == null) return null;
  return _tryParseDate(record['completed_at']);
}

bool _isRecordToday(Map<String, dynamic>? record, String status) {
  if (record == null) return false;
  if (record['status'] != status) return false;
  final date = _tryParseDate(record['completed_at']);
  if (date == null) return false;
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

bool isDoneToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  final record = _lastResponseRecord(completions, routine['id']);
  return _isRecordToday(record, 'completed') || _isRecordToday(record, 'done');
}

bool isSkippedToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  final record = _lastResponseRecord(completions, routine['id']);
  return _isRecordToday(record, 'skipped');
}

/// True if the routine already got a response today, either done or
/// skipped. Once handled, it should stop showing as "due" and stop
/// triggering overdue reminders for the rest of the day.
bool isHandledToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  return isDoneToday(routine, completions) ||
      isSkippedToday(routine, completions);
}

bool isDueToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  if (isHandledToday(routine, completions)) return false;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final repeatType = routine['repeat_type'];
  final lastDone = lastCompletionDate(completions, routine['id']);

  switch (repeatType) {
    case 'daily':
      return true;

    case 'weekly':
      const weekdayMap = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun',
      };
      final todayName = weekdayMap[now.weekday];
      final weekdays = List<String>.from(routine['weekdays'] ?? []);
      return weekdays.contains(todayName);

    case 'monthly':
      final monthDay = _parseMonthDay(routine['month_day']);
      if (monthDay == null) return false;
      final clamped = _clampedMonthDay(now.year, now.month, monthDay);
      return now.day == clamped;

    case 'interval':
      final intervalDays = _parseIntervalDays(routine['interval_days']);
      DateTime baseDate;
      if (lastDone != null) {
        final lastDoneDay = _dateOnly(lastDone);
        baseDate = lastDoneDay.add(Duration(days: intervalDays));
      } else {
        final startDate = _tryParseDate(routine['start_date']);
        baseDate = startDate != null ? _dateOnly(startDate) : today;
      }
      return !today.isBefore(baseDate);

    case 'once':
      return lastDone == null;

    default:
      return false;
  }
}

/// Whether a routine should show up in "today's tasks" at all: either it's
/// currently due, or it already got a response (done/skipped) today so the
/// user can see the outcome.
bool isRelevantToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  return isDueToday(routine, completions) ||
      isHandledToday(routine, completions);
}

/// Converts a short weekday name ('Mon', 'Tue', ...) back into Dart's
/// weekday number (Monday = 1 ... Sunday = 7). Used when scheduling
/// real device notifications for weekly routines.
int? weekdayNumberFromShortName(String name) {
  const map = {
    'Mon': 1,
    'Tue': 2,
    'Wed': 3,
    'Thu': 4,
    'Fri': 5,
    'Sat': 6,
    'Sun': 7,
  };
  return map[name];
}

/// Computes the next date (date only, no time) this routine is due,
/// based on its repeat type. Used to schedule the *next* real
/// notification after a routine is created, edited, completed, or skipped.
DateTime? nextDueDate(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final repeatType = routine['repeat_type'];
  final lastDone = lastCompletionDate(completions, routine['id']);

  switch (repeatType) {
    case 'daily':
      return today;

    case 'weekly':
      final weekdays = List<String>.from(routine['weekdays'] ?? []);
      final weekdayNums = weekdays
          .map(weekdayNumberFromShortName)
          .whereType<int>()
          .toList();
      if (weekdayNums.isEmpty) return null;
      for (int i = 0; i < 8; i++) {
        final candidate = today.add(Duration(days: i));
        if (weekdayNums.contains(candidate.weekday)) {
          return candidate;
        }
      }
      return null;

    case 'monthly':
      final monthDay = _parseMonthDay(routine['month_day']);
      if (monthDay == null) return null;
      final thisMonthDay = _clampedMonthDay(now.year, now.month, monthDay);
      var candidate = DateTime(now.year, now.month, thisMonthDay);
      if (candidate.isBefore(today)) {
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final nextMonthDay =
            _clampedMonthDay(nextMonth.year, nextMonth.month, monthDay);
        candidate =
            DateTime(nextMonth.year, nextMonth.month, nextMonthDay);
      }
      return candidate;

    case 'interval':
      final intervalDays = _parseIntervalDays(routine['interval_days']);
      if (lastDone != null) {
        final lastDoneDay = _dateOnly(lastDone);
        final next = lastDoneDay.add(Duration(days: intervalDays));
        return next.isBefore(today) ? today : next;
      }
      final startDate = _tryParseDate(routine['start_date']);
      if (startDate == null) return today;
      final startDay = _dateOnly(startDate);
      return startDay.isBefore(today) ? today : startDay;

    case 'once':
      return lastDone == null ? today : null;

    default:
      return null;
  }
}
