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
    // flutter_local_notifications scheduling APIs used by this service
    // are not supported on Flutter Web. Keep the rest of the app usable.
    if (kIsWeb) {
      _initialized = false;
      return;
    }

    try {
      tz_data.initializeTimeZones();

      // خواندن امن تایم‌زون سازگار با flutter_timezone 5.x و نسخه های قبل
            // خواندن امن و ضدگلوله تایم‌زون
      try {
        final dynamic tzRes = await FlutterTimezone.getLocalTimezone();
        final String? timeZoneName =
            (tzRes is String) ? tzRes : tzRes?.identifier?.toString();
        if (timeZoneName != null && timeZoneName.isNotEmpty) {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          if (kDebugMode) {
            debugPrint('NotificationService: Timezone set to $timeZoneName');
          }
        } else {
          throw Exception('Empty timezone name');
        }
      } catch (_) {
        // در صورت بروز خطا، بر اساس آفست واقعی دستگاه ست می‌کنیم تا به UTC نیافتد
        try {
          final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
          String fallbackZone = 'UTC';
          if (offsetMinutes == 210) {
            fallbackZone = 'Asia/Tehran'; // ایران (UTC+3:30)
          } else if (offsetMinutes == 270) {
            fallbackZone = 'Asia/Kabul';
          } else if (offsetMinutes == 330) {
            fallbackZone = 'Asia/Kolkata';
          } else if (offsetMinutes == 240) {
            fallbackZone = 'Asia/Dubai';
          } else if (offsetMinutes == 180) {
            fallbackZone = 'Asia/Riyadh';
          }
          tz.setLocalLocation(tz.getLocation(fallbackZone));
          if (kDebugMode) {
            debugPrint('NotificationService: Fallback timezone set to $fallbackZone');
          }
        } catch (_) {
          try {
            tz.setLocalLocation(tz.getLocation('UTC'));
          } catch (_) {}
        }
      }


      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        settings: initSettings,
      );

      final androidImpl =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // ثبت صریح کانال نوتیفیکیشن در سیستم عامل اندروید
      // این خط باعث می‌شود Reptime بلافاصله در تنظیمات سیستم اندروید ثبت شود
      const AndroidNotificationChannel routineChannel = AndroidNotificationChannel(
        'routine_channel',
        'یادآور روتین',
        description: 'کانال یادآوری روتین‌ها و کارهای روزانه پت‌ها',
        importance: Importance.max,
      );
      await androidImpl?.createNotificationChannel(routineChannel);

      // درخواست مجوز نوتیفیکیشن در اندروید ۱۳ به بعد
      await androidImpl?.requestNotificationsPermission();
      // بررسی وضعیت مجوز آلارم دقیق؛ اگر خاموش بود صفحه تنظیمات را باز می‌کند
      final bool canScheduleExact =
          await androidImpl?.canScheduleExactNotifications() ?? true;

      if (!canScheduleExact) {
        await androidImpl?.requestExactAlarmsPermission();
      }


      // درخواست مجوز در iOS با پشتیبانی دوطرفه (Darwin یا IOS سنتی)
      try {
        final iosImpl =
            _notifications.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (_) {}

      _initialized = true;
    } catch (e) {
      _initialized = false;
      // debugPrint('NotificationService init error: $e');
    }
  }
    static Future<AndroidScheduleMode> _getScheduleMode() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidImpl?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }


  static NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_channel',
        'یادآور روتین',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
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
    if (kIsWeb || !_initialized) return;

    try {
      final scheduleMode = await _getScheduleMode();
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: _defaultDetails(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // debugPrint('Schedule daily notification error: $e');
    }
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
    if (kIsWeb || !_initialized) return;

    try {
      await _notifications.cancel(id: id);
    } catch (e) {
      // debugPrint('Cancel notification error: $e');
    }
  }

  static Future<void> showInstantNotification() async {
    if (kIsWeb || !_initialized) return;

    try {
      await _notifications.show(
        id: 998,
        title: 'تست فوری',
        body: 'این نوتیف باید همین الان بیاد ✅',
        notificationDetails: _defaultDetails(),
      );
    } catch (e) {
      // debugPrint('Show instant notification error: $e');
    }
  }

  // ---------- real per-routine scheduling ----------

  /// Notification ids for a given routine live in a reserved range so they
  /// never collide with each other or with the debug-button ids (998/999).
  /// Weekly routines use baseId + weekday number (1-7) since each weekday
  /// needs its own scheduled entry.
  /// Returns null if routineId cannot be parsed to prevent collisions on ID 100000.
   static int? _baseIdForRoutine(dynamic routineId) {
    if (routineId == null) return null;
    final idInt =
        routineId is int ? routineId : int.tryParse(routineId.toString());
    if (idInt == null) return null;
    return 100000 + (idInt * 100);
  }

  static Future<void> cancelRoutineNotifications(dynamic routineId) async {
    if (kIsWeb || !_initialized) return;

    final baseId = _baseIdForRoutine(routineId);
    if (baseId == null) return;

    try {
      await _notifications.cancel(id: baseId);

      for (int weekday = 1; weekday <= 7; weekday++) {
        await _notifications.cancel(id: baseId + weekday);
      }

      for (int k = 1; k <= _maxOverdueReminders; k++) {
        await _notifications.cancel(id: baseId + 50 + k);
      }
    } catch (e) {
      debugPrint('[NotificationService] Cancel routine notifications error: $e');
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
    int monthDay,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final clampedTargetDay = monthDay.clamp(1, 31);

    int maxDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    int targetYear = now.year;
    int targetMonth = now.month;

    int effectiveDay = clampedTargetDay.clamp(1, maxDaysInMonth(targetYear, targetMonth));
    var scheduled = tz.TZDateTime(
      tz.local,
      targetYear,
      targetMonth,
      effectiveDay,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      targetMonth++;
      if (targetMonth > 12) {
        targetMonth = 1;
        targetYear++;
      }
      effectiveDay = clampedTargetDay.clamp(1, maxDaysInMonth(targetYear, targetMonth));
      scheduled = tz.TZDateTime(
        tz.local,
        targetYear,
        targetMonth,
        effectiveDay,
        hour,
        minute,
      );
    }

    return scheduled;
  }


  /// Schedules (or re-schedules) the real device notification(s) for a
  /// single routine, based on its repeat type. Call this any time a
  /// routine is created, edited, deleted, or completed.
  static Future<void> scheduleRoutineNotifications(
    Map<String, dynamic> routine, {
    DateTime? overrideDate,
    List<String>? petNames,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      final baseId = _baseIdForRoutine(routine['id']);
      if (baseId == null) return;

      await cancelRoutineNotifications(routine['id']);

      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('on_time_reminders') ?? true;
      if (!enabled) return;

      if (routine['is_active'] == false) return;

      final timeStr = routine['time'] as String?;
      if (timeStr == null || !timeStr.contains(':')) return;
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;

      final title = routine['title'] as String? ?? 'یادآور روتین';
      final body = _buildBody(routine, petNames);
      final repeatType =
          (routine['repeat_type'] as String? ?? 'daily').toLowerCase();

      switch (repeatType) {
        case 'daily':
          final scheduleMode = await _getScheduleMode();
          await _notifications.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate: _nextInstanceOfTime(hour, minute),
            notificationDetails: _defaultDetails(),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          break;

        case 'weekly':
          final weekdays = routine['weekdays'] as List<dynamic>? ?? [];
          final dayMap = {
            'mon': DateTime.monday,
            'tue': DateTime.tuesday,
            'wed': DateTime.wednesday,
            'thu': DateTime.thursday,
            'fri': DateTime.friday,
            'sat': DateTime.saturday,
            'sun': DateTime.sunday,
          };

          for (final dayStr in weekdays) {
            final weekdayNum = dayMap[dayStr.toString().toLowerCase()];
            if (weekdayNum == null) continue;
            final scheduleMode = await _getScheduleMode();
            await _notifications.zonedSchedule(
              id: baseId + weekdayNum,
              title: title,
              body: body,
              scheduledDate:
                  _nextInstanceOfWeekdayTime(weekdayNum, hour, minute),
              notificationDetails: _defaultDetails(),
              androidScheduleMode: scheduleMode,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
          break;

        case 'monthly':
          final monthDay =
              int.tryParse(routine['month_day']?.toString() ?? '');
          if (monthDay == null) return;
          final scheduleMode = await _getScheduleMode();
          await _notifications.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate:
                _nextInstanceOfMonthDayTime(monthDay, hour, minute),
            notificationDetails: _defaultDetails(),
            androidScheduleMode: scheduleMode,
            matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
          );
          break;

        case 'interval':
        case 'once':
           tz.TZDateTime scheduledDate;
          if (overrideDate != null) {
            final localDate = overrideDate.toLocal();
            scheduledDate = tz.TZDateTime(
              tz.local,
              localDate.year,
              localDate.month,
              localDate.day,
              hour,
              minute,
            );
            final now = tz.TZDateTime.now(tz.local);
            if (scheduledDate.isBefore(now)) {
              scheduledDate = _nextInstanceOfTime(hour, minute);
            }
          } else {
            scheduledDate = _nextInstanceOfTime(hour, minute);
          }
          final scheduleMode = await _getScheduleMode();
          await _notifications.zonedSchedule(
            id: baseId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            notificationDetails: _defaultDetails(),
            androidScheduleMode: scheduleMode,
          );
          break;
      }
    } catch (e) {
      // debugPrint('Schedule routine notifications error: $e');
    }
  }

  // ---------- daily summary (fixed 21:00 reminder) ----------

  static const int _dailySummaryId = 90000;

  static Future<void> updateDailySummaryNotification() async {
    if (kIsWeb || !_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('daily_summary') ?? false;

      await _notifications.cancel(id: _dailySummaryId);

      if (!enabled) return;
      final scheduleMode = await _getScheduleMode();
      await _notifications.zonedSchedule(
        id: _dailySummaryId,
        title: 'خلاصه کارهای امروز',
        body: 'یادت نره کارهای باقیمانده امروز رو چک کنی و تیک بزنی 🐾',
        scheduledDate: _nextInstanceOfTime(21, 0),
        notificationDetails: _defaultDetails(),
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // debugPrint('Update daily summary notification error: $e');
    }
  }

  // ---------- overdue nudges ----------

  static const int _maxOverdueReminders = 8;

  static Future<void> cancelOverdueReminders(dynamic routineId) async {
    if (kIsWeb || !_initialized) return;

    final baseId = _baseIdForRoutine(routineId);
    if (baseId == null) return;

    try {
      for (int k = 1; k <= _maxOverdueReminders; k++) {
        await _notifications.cancel(id: baseId + 50 + k);
      }
    } catch (e) {
      // debugPrint('Cancel overdue reminders error: $e');
    }
  }

  static Future<void> refreshOverdueReminders(
      List<Map<String, dynamic>> dueUncompletedRoutines) async {
    if (kIsWeb || !_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('overdue_reminders') ?? true;
      final intervalHours = prefs.getInt('overdue_interval_hours') ?? 1;

      for (final routine in dueUncompletedRoutines) {
        final baseId = _baseIdForRoutine(routine['id']);
        if (baseId == null) continue;

        await cancelOverdueReminders(routine['id']);

        if (!enabled) continue;

        final timeStr = routine['time'] as String?;
        if (timeStr == null || !timeStr.contains(':')) continue;
        final parts = timeStr.split(':');
        final baseHour = int.tryParse(parts[0]) ?? 9;
        final baseMinute = int.tryParse(parts[1]) ?? 0;

        final now = tz.TZDateTime.now(tz.local);
        final title = 'یادآوری: ${routine['title'] ?? 'روتین'}';
        final body = 'این کار هنوز انجام نشده، وقتشه بهش برسی!';

        for (int k = 1; k <= _maxOverdueReminders; k++) {
          final nudgeTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            baseHour + (k * intervalHours),
            baseMinute,
          );

          if (nudgeTime.day != now.day) break;
          if (nudgeTime.isBefore(now)) continue;
          final scheduleMode = await _getScheduleMode();
          await _notifications.zonedSchedule(
            id: baseId + 50 + k,
            title: title,
            body: body,
            scheduledDate: nudgeTime,
            notificationDetails: _defaultDetails(),
            androidScheduleMode: scheduleMode,
          );
        }
      }
    } catch (e) {
      // debugPrint('Refresh overdue reminders error: $e');
    }
  }
}
