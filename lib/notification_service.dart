import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool get isInitialized => _initialized;
  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();

      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(
        tz.getLocation(timezoneInfo.identifier),
      );

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
      );

      final androidImpl =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();

      _initialized = true;
    } catch (e) {
      _initialized = false;
      // debugPrint('NotificationService init error: $e');
    }
  }

  static NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_channel',
        'یادآور روتین',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  static String _typeLabelFa(String? type) {
    switch (type) {
      case 'food':
        return 'غذا';
      case 'cleaning':
        return 'نظافت';
      case 'medicine':
        return 'دارو';
      default:
        return 'رسیدگی';
    }
  }

  static String _buildBody(Map<String, dynamic> routine, List<String>? petNames) {
    final typeLabel = _typeLabelFa(routine['type']);
    if (petNames == null || petNames.isEmpty) {
      return 'وقت انجام این روتینه 🐾';
    }
    final namesJoined = petNames.join(' و ');
    final verb = petNames.length > 1 ? 'دارن' : 'داره';
    return 'امروز $namesJoined نیاز به $typeLabel $verb 🐾';
  }

  // ---------- existing generic helpers (kept for the debug button) ----------

  static Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelNotification(int id) async {
    if (!_initialized) return;

    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      // debugPrint('Cancel notification error: $e');
    }
  }

  static Future<void> showInstantNotification() async {
    await _notifications.show(
      id: 998,
      title: 'تست فوری',
      body: 'این نوتیف باید همین الان بیاد ✅',
      notificationDetails: _defaultDetails(),
    );
  }

  // ---------- real per-routine scheduling ----------

  /// Notification ids for a given routine live in a reserved range so they
  /// never collide with each other or with the debug-button ids (998/999).
  /// Weekly routines use baseId + weekday number (1-7) since each weekday
  /// needs its own scheduled entry.
  static int _baseIdForRoutine(dynamic routineId) {
    final idInt =
        routineId is int ? routineId : int.tryParse(routineId.toString()) ?? 0;
    return 100000 + (idInt * 10);
  }

 static Future<void> cancelRoutineNotifications(dynamic routineId) async {
    if (!_initialized) return;

    try {
      final baseId = _baseIdForRoutine(routineId);

      await _notifications.cancel(id: baseId);

      for (int weekday = 1; weekday <= 7; weekday++) {
        await _notifications.cancel(
          id: baseId + weekday,
        );
      }

      for (int k = 1; k <= 8; k++) {
        await _notifications.cancel(
          id: baseId + 50 + k,
        );
      }
    } catch (e) {
      // debugPrint(
      //   'Cancel routine notifications error: $e',
      // );
    }
  }
  static tz.TZDateTime _nextInstanceOfWeekdayTime(
      int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfMonthDayTime(
      int monthDay, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, monthDay, hour, minute);
    if (scheduled.isBefore(now)) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      scheduled =
          tz.TZDateTime(tz.local, nextYear, nextMonth, monthDay, hour, minute);
    }
    return scheduled;
  }

  /// Schedules (or re-schedules) the real device notification(s) for a
  /// single routine, based on its repeat type. Call this any time a
  /// routine is created, edited, deleted, or completed.
  ///
  /// [overrideDate] is used for 'interval' and 'once' routines to force a
  /// specific next-occurrence date (e.g. computed from the last completion).
  /// If omitted, the next occurrence is computed as "today or tomorrow"
  /// based on the routine's time.
  static Future<void> scheduleRoutineNotifications(
    Map<String, dynamic> routine, {
    DateTime? overrideDate,
    List<String>? petNames,
  }) async {
    await cancelRoutineNotifications(routine['id']);

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('on_time_reminders') ?? true;
    if (!enabled) return;
    if (routine['is_active'] == false) return;

    final timeStr = routine['time'] as String?;
    if (timeStr == null || !timeStr.contains(':')) return;
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0].trim());
    final minute = int.tryParse(parts[1].trim());
    if (hour == null || minute == null) return;

    final title = routine['title'] ?? 'یادآوری روتین';
    final body = _buildBody(routine, petNames);
    final baseId = _baseIdForRoutine(routine['id']);
    final repeatType = routine['repeat_type'];

    switch (repeatType) {
      case 'daily':
        await _notifications.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: _nextInstanceOfTime(hour, minute),
          notificationDetails: _defaultDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        break;

      case 'weekly':
        final weekdayNames = List<String>.from(routine['weekdays'] ?? []);
        const nameToNumber = {
          'Mon': 1,
          'Tue': 2,
          'Wed': 3,
          'Thu': 4,
          'Fri': 5,
          'Sat': 6,
          'Sun': 7,
        };
        for (final name in weekdayNames) {
          final weekdayNum = nameToNumber[name];
          if (weekdayNum == null) continue;
          await _notifications.zonedSchedule(
            id: baseId + weekdayNum,
            title: title,
            body: body,
            scheduledDate:
                _nextInstanceOfWeekdayTime(weekdayNum, hour, minute),
            notificationDetails: _defaultDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
        break;

      case 'monthly':
        final monthDay = routine['month_day'];
        if (monthDay == null) return;
        await _notifications.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: _nextInstanceOfMonthDayTime(monthDay, hour, minute),
          notificationDetails: _defaultDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
        );
        break;

      case 'interval':
      case 'once':
        tz.TZDateTime scheduled;
        if (overrideDate != null) {
          scheduled = tz.TZDateTime(
            tz.local,
            overrideDate.year,
            overrideDate.month,
            overrideDate.day,
            hour,
            minute,
          );
          final now = tz.TZDateTime.now(tz.local);
          if (scheduled.isBefore(now)) {
            scheduled = _nextInstanceOfTime(hour, minute);
          }
        } else {
          scheduled = _nextInstanceOfTime(hour, minute);
        }
        await _notifications.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: scheduled,
          notificationDetails: _defaultDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        break;
    }
  }

  // ---------- daily summary (static reminder at a fixed hour) ----------

  static const int _dailySummaryId = 90000;

  static Future<void> updateDailySummaryNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_summary') ?? false;

    await _notifications.cancel(id: _dailySummaryId);
    if (!enabled) return;

    await _notifications.zonedSchedule(
      id: _dailySummaryId,
      title: 'خلاصه‌ی امروز',
      body: 'وقتشه خلاصه‌ی کارهای امروز حیوون‌هاتو تو اپ چک کنی 📋',
      scheduledDate: _nextInstanceOfTime(21, 0),
      notificationDetails: _defaultDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ---------- overdue reminders (one-shot, refreshed each app launch) ----------

  static const int _maxOverdueReminders = 8;

  static Future<void> cancelOverdueReminders(dynamic routineId) async {
    if (!_initialized) return;

    try {
      final baseId = _baseIdForRoutine(routineId);

      for (int k = 1; k <= _maxOverdueReminders; k++) {
        await _notifications.cancel(
          id: baseId + 50 + k,
        );
      }
    } catch (e) {
      debugPrint(
        'Cancel overdue notifications error: $e',
      );
    }
  }

  /// Schedules today's remaining overdue reminders for a list of routines
  /// that are due today but not yet completed. Call this whenever the app
  /// starts or the home screen data refreshes. Each reminder is a one-shot
  /// notification (not repeating) so it naturally stops once the day ends;
  /// call [cancelOverdueReminders] when the routine gets marked done.
  static Future<void> refreshOverdueReminders(
      List<Map<String, dynamic>> dueUncompletedRoutines) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('overdue_reminders') ?? true;
    final intervalHours = prefs.getInt('overdue_interval_hours') ?? 1;

    for (final routine in dueUncompletedRoutines) {
      await cancelOverdueReminders(routine['id']);
      if (!enabled) continue;

      final timeStr = routine['time'] as String?;
      if (timeStr == null || !timeStr.contains(':')) continue;
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0].trim());
      final minute = int.tryParse(parts[1].trim());
      if (hour == null || minute == null) continue;

      final baseId = _baseIdForRoutine(routine['id']);
      final title = routine['title'] ?? 'یادآور';
      final now = tz.TZDateTime.now(tz.local);
      var next =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      int k = 1;
      while (k <= _maxOverdueReminders) {
        next = next.add(Duration(hours: intervalHours));
        if (next.day != now.day) break;
        if (next.isAfter(now)) {
          await _notifications.zonedSchedule(
            id: baseId + 50 + k,
            title: title,
            body: 'هنوز این کار امروز انجام نشده ⏰',
            scheduledDate: next,
            notificationDetails: _defaultDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
        k++;
      }
    }
  }
}