// lib/models/routine_model.dart

class Routine {
  final int id;
  final DateTime createdAt;
  final String? userId;
  final String title;
  final String? type;
  final List<int> petIds;
  final String? time;
  final String? repeatType; // e.g. 'daily', 'weekly', 'monthly', 'interval'
  final List<int>? weekdays; // e.g. [1, 2, 3]
  final int? monthDay;
  final int? intervalDays;
  final DateTime? startDate;
  final bool isActive;

  Routine({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.title,
    this.type,
    required this.petIds,
    this.time,
    this.repeatType,
    this.weekdays,
    this.monthDay,
    this.intervalDays,
    this.startDate,
    this.isActive = true,
  });

  // تبدیل داده خام دیتابیس به مدل Routine به صورت کاملاً امن
  factory Routine.fromJson(Map<String, dynamic> json) {
    // خواندن pet_ids یا pets_ids به صورت امن
    final rawPetIds = json['pet_ids'] ?? json['pets_ids'];
    List<int> parsedPetIds = [];
    if (rawPetIds is List) {
      parsedPetIds = rawPetIds.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0).toList();
    }

    // خواندن weekdays به صورت امن
    List<int>? parsedWeekdays;
    if (json['weekdays'] is List) {
      parsedWeekdays = (json['weekdays'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((w) => w > 0)
          .toList();
    }

    return Routine(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String?,
      title: (json['title'] as String?) ?? 'بدون عنوان',
      type: json['type'] as String?,
      petIds: parsedPetIds,
      time: json['time'] as String?,
      repeatType: json['repeat_type'] as String?,
      weekdays: parsedWeekdays,
      monthDay: json['month_day'] as int?,
      intervalDays: json['interval_days'] as int?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  // تبدیل مدل به JSON جهت ذخیره در Supabase
  Map<String, dynamic> toJson({String? currentUserId}) {
    final map = <String, dynamic>{
      'title': title,
      'type': type,
      'pet_ids': petIds,
      'pets_ids': petIds, // برای سازگاری کامل با هر دو ستون در دیتابیس
      'time': time,
      'repeat_type': repeatType,
      'weekdays': weekdays,
      'month_day': monthDay,
      'interval_days': intervalDays,
      'start_date': startDate?.toIso8601String().split('T').first, // فرمت YYYY-MM-DD
      'is_active': isActive,
    };

    if (currentUserId != null) {
      map['user_id'] = currentUserId;
    }

    return map;
  }
}
