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