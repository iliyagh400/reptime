DateTime? lastCompletionDate(
    List<Map<String, dynamic>> completions, dynamic routineId) {
  final matches =
      completions.where((c) => c['routine_id'] == routineId).toList();
  if (matches.isEmpty) return null;

  matches.sort((a, b) => DateTime.parse(b['completed_at'])
      .compareTo(DateTime.parse(a['completed_at'])));

  return DateTime.parse(matches.first['completed_at']);
}

bool isDoneToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final lastDone = lastCompletionDate(completions, routine['id']);
  if (lastDone == null) return false;

  final lastDoneDay = DateTime(lastDone.year, lastDone.month, lastDone.day);
  return lastDoneDay.isAtSameMomentAs(today);
}

bool isDueToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  if (isDoneToday(routine, completions)) return false;

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
      final monthDay = routine['month_day'];
      return monthDay != null && now.day == monthDay;

    case 'interval':
      final intervalDays = routine['interval_days'] ?? 1;
      DateTime baseDate;
      if (lastDone != null) {
        final lastDoneDay =
            DateTime(lastDone.year, lastDone.month, lastDone.day);
        baseDate = lastDoneDay.add(Duration(days: intervalDays));
      } else {
        final startDateStr = routine['start_date'];
        baseDate =
            startDateStr != null ? DateTime.parse(startDateStr) : today;
      }
      return !today.isBefore(baseDate);

    case 'once':
      return lastDone == null;

    default:
      return false;
  }
}

bool isRelevantToday(
    Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
  return isDueToday(routine, completions) || isDoneToday(routine, completions);
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
/// notification after a routine is created, edited, or completed.
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
      final monthDay = routine['month_day'];
      if (monthDay == null) return null;
      var candidate = DateTime(now.year, now.month, monthDay);
      if (candidate.isBefore(today)) {
        candidate = DateTime(now.year, now.month + 1, monthDay);
      }
      return candidate;

    case 'interval':
      final intervalDays = routine['interval_days'] ?? 1;
      if (lastDone != null) {
        final lastDoneDay =
            DateTime(lastDone.year, lastDone.month, lastDone.day);
        final next = lastDoneDay.add(Duration(days: intervalDays));
        return next.isBefore(today) ? today : next;
      }
      final startDateStr = routine['start_date'];
      final startDate =
          startDateStr != null ? DateTime.parse(startDateStr) : today;
      return startDate.isBefore(today) ? today : startDate;

    case 'once':
      return lastDone == null ? today : null;

    default:
      return null;
  }
}