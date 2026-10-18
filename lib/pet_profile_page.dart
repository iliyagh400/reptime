import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_pet_page.dart';

import 'add_routine_page.dart';

import 'edit_routine_page.dart';

import 'routine_logic.dart';

import 'notification_service.dart';

import 'pet_history_page.dart';

import 'add_event_page.dart';

import 'species_data.dart';

import 'add_checkin_page.dart';
import 'app_feedback.dart';

class PetProfilePage extends StatefulWidget {

  final Map<String, dynamic> pet;

  const PetProfilePage({super.key, required this.pet});

  @override

  State<PetProfilePage> createState() => _PetProfilePageState();

}

class _PetProfilePageState extends State<PetProfilePage> {

  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _upcomingRoutines = [];
  List<Map<String, dynamic>> _allPets = [];

  Map<String, dynamic>? _latestCheckin;

  bool _isLoading = true;

  final Set<String> _processingKeys = {};

  // Reptime — Dark Terrarium palette
  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _moss = Color(0xFF6E8B52);
  static const _lightMoss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);

  @override

  void initState() {

    super.initState();

    _loadRoutines();

    _loadLatestCheckin();

  }
      DateTime? _calculateNextOccurrence(
      Map<String, dynamic> routine, List<Map<String, dynamic>> completions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final repeatType = (routine['repeat_type'] ?? '').toString().toLowerCase();

    if (repeatType == 'daily') {
      return today.add(const Duration(days: 1));
    }

    if (repeatType == 'weekly') {
      final rawDays = routine['weekdays'];
      if (rawDays is! List || rawDays.isEmpty) return null;
      final validDays = <int>{};
      for (final day in rawDays) {
        final numDay = weekdayNumberFromShortName(day.toString());
        if (numDay != null) validDays.add(numDay);
      }
      if (validDays.isEmpty) return null;
      for (int offset = 1; offset <= 7; offset++) {
        final candidate = today.add(Duration(days: offset));
        if (validDays.contains(candidate.weekday)) {
          return candidate;
        }
      }
      return null;
    }

    if (repeatType == 'monthly') {
      final monthDay = int.tryParse(routine['month_day']?.toString() ?? '');
      if (monthDay == null) return null;

      int clampDay(int y, int m, int d) {
        final lastDay = DateTime(y, m + 1, 0).day;
        if (d < 1) return 1;
        return d > lastDay ? lastDay : d;
      }

      if (monthDay > today.day) {
        final d = clampDay(today.year, today.month, monthDay);
        final candidate = DateTime(today.year, today.month, d);
        if (candidate.isAfter(today)) return candidate;
      }
      final nextMonth = DateTime(today.year, today.month + 1, 1);
      final d = clampDay(nextMonth.year, nextMonth.month, monthDay);
      return DateTime(nextMonth.year, nextMonth.month, d);
    }

    if (repeatType == 'interval') {
      final days = int.tryParse(routine['interval_days']?.toString() ?? '') ?? 1;
      final intervalDays = days <= 0 ? 1 : days;
      final lastComp = lastCompletionDate(completions, routine['id']);


      if (lastComp != null) {
        final compDate = DateTime(lastComp.year, lastComp.month, lastComp.day);
        final next = compDate.add(Duration(days: intervalDays));
        if (next.isAfter(today)) return next;
        return today.add(Duration(days: intervalDays));
      } else {
        final start = routine['start_date'] != null
            ? DateTime.tryParse(routine['start_date'].toString())?.toLocal()
            : null;
        if (start != null) {
          final startDate = DateTime(start.year, start.month, start.day);
          if (startDate.isAfter(today)) return startDate;
        }
        return today.add(Duration(days: intervalDays));
      }
    }

    return null;
  }

      Future<void> _loadRoutines() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userId = user.id;
      final petId = widget.pet['id'];
      final allPetsResponse = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('user_id', userId);
      _allPets = List<Map<String, dynamic>>.from(allPetsResponse);

      final routinesResponse = await Supabase.instance.client
          .from('routines')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);
      final allRoutines = List<Map<String, dynamic>>.from(routinesResponse);
      final petRoutines = allRoutines.where((r) {
        final ids = List.from(r['pet_ids'] ?? []);
        return ids.map((id) => id.toString()).contains(petId.toString());
      }).toList();

      final completionsResponse = await Supabase.instance.client
          .from('completions')
          .select()
          .eq('user_id', userId)
          .eq('pet_id', petId);
      final completions = List<Map<String, dynamic>>.from(completionsResponse);

      final List<Map<String, dynamic>> relevantToday = [];
      final List<Map<String, dynamic>> upcomingList = [];

      for (final routine in petRoutines) {
        if (isRelevantToday(routine, completions)) {
          relevantToday.add({
            ...routine,
            'isDoneToday': isDoneToday(routine, completions),
            'isSkippedToday': isSkippedToday(routine, completions),
          });
        }

        final nextDate = _calculateNextOccurrence(routine, completions);
        final lastDoneDate = lastSuccessfulCompletionDate(
            routine,
            completions: completions,
          );
        if (nextDate != null) {
          upcomingList.add({
            ...routine,
            'nextDueDate': nextDate,
            'lastDoneText': formatLastCompletionText(lastDoneDate),
          });
        }
      }

      upcomingList.sort((a, b) =>
          (a['nextDueDate'] as DateTime).compareTo(b['nextDueDate'] as DateTime));

      if (!mounted) return;
      setState(() {
        _routines = relevantToday;
        _upcomingRoutines = upcomingList;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load routines: $e\n$stackTrace');
      if (!mounted) return;
      AppFeedback.showError(context, 'خطا در بارگذاری کارها');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }




    Future<void> _loadLatestCheckin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('pet_checkins')
          .select()
          .eq('user_id', user.id)
          .eq('pet_id', widget.pet['id'])
          .order('checkin_date', ascending: false)
          .limit(1);
      final results = List<Map<String, dynamic>>.from(response);

      if (!mounted) return;
      setState(() {
        _latestCheckin = results.isEmpty ? null : results.first;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load latest check-in: $e\n$stackTrace');
      if (!mounted) return;
            AppFeedback.showError(context, 'خطا در بارگذاری آخرین چک‌این');

    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  bool get _checkinIsOverdue {
    final rawDate = _latestCheckin?['checkin_date'];
    final lastDate = DateTime.tryParse(rawDate?.toString() ?? '');
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate).inDays >= 30;
  }


  Future<void> _openCheckinForm() async {

    final saved = await Navigator.push<bool>(

      context,

      MaterialPageRoute(

        builder: (context) => AddCheckinPage(pet: widget.pet),

      ),

    );

    if (saved == true) {

      _loadLatestCheckin();

    }

  }

    Future<void> _respond(
    Map<String, dynamic> routine,
    String status, {
    String? note,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
            AppFeedback.showError(
        context,
        'کاربر وارد نشده است. لطفاً ابتدا وارد شوید.',
      );

      return;
    }

    final routineId = routine['id'];
    final petId = widget.pet['id'];
    final key = '${routineId}_$petId';
    if (_processingKeys.contains(key)) return;

    _processingKeys.add(key);
    if (mounted) setState(() {});

    final matchingRoutine = _routines.firstWhere(
      (candidate) => candidate['id'] == routineId,
      orElse: () => routine,
    );
    final previousDone = matchingRoutine['isDoneToday'] == true;
    final previousSkipped = matchingRoutine['isSkippedToday'] == true;
    matchingRoutine['isDoneToday'] = (status == 'done');
    matchingRoutine['isSkippedToday'] = (status != 'done');
    if (mounted) setState(() {});

    final userId = user.id;
    final repeatType = routine['repeat_type'];
    List<Map<String, dynamic>> completions = [];

    try {
      // 1. ثبت وضعیت تکمیل روتین برای همین پت
      await Supabase.instance.client.from('completions').insert({
        'user_id': userId,
        'routine_id': routineId,
        'pet_id': petId,
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'status': status,
        'note': note,
      });

      // 2. کوئری completions ایزوله‌شده بر اساس pet_id جهت محاسبه موعد بعدی
      if (repeatType == 'interval' || repeatType == 'once') {
        final completionsResponse = await Supabase.instance.client
            .from('completions')
            .select()
            .eq('user_id', userId)
            .eq('routine_id', routineId)
            .eq('pet_id', petId)
            .order('completed_at', ascending: false);
        completions = List<Map<String, dynamic>>.from(completionsResponse);
      }

      if (mounted) {
             AppFeedback.showSuccess(
        context,
        status == 'done' ? 'ثبت شد ✅' : 'رد شد ⏭️',
      );

      }

      // 3. مدیریت ایمن نوتیفیکیشن‌ها بدون تداخل
      try {
        await NotificationService.cancelOverdueReminders(routineId);

        if (repeatType == 'once') {
          await NotificationService.cancelRoutineNotifications(routineId);
        } else if (repeatType == 'interval') {
          final next = nextDueDate(routine, completions);
          final petIds = List.from(routine['pet_ids'] ?? []);
          final petNames = _allPets
              .where((p) => petIds.contains(p['id']))
              .map((p) => (p['name'] ?? '').toString())
              .toList();

          await NotificationService.scheduleRoutineNotifications(
            routine,
            overrideDate: next,
            petNames: petNames,
          );
        }
      } catch (e) {
        debugPrint('Error updating routine notifications: $e');
      }

    } catch (e) {
      matchingRoutine['isDoneToday'] = previousDone;
      matchingRoutine['isSkippedToday'] = previousSkipped;
      if (mounted) setState(() {});
      debugPrint('Error saving routine response: $e');
      if (mounted) {
              AppFeedback.showError(
        context,
        'خطا در ثبت وضعیت. لطفاً دوباره تلاش کنید.',
      );

      }
    } finally {
      _processingKeys.remove(key);
      if (mounted) setState(() {});
    }
  }



    Future<void> _showSkipDialog(Map<String, dynamic> routine) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: _line, width: 1),
          ),
          title: const Text(
            'رد کردن این بار',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'چرا این بار انجامش نمی‌دی؟ (اختیاری)',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: const TextStyle(
                  color: _text,
                  fontSize: 14,
                ),
                cursorColor: _terracotta,
                decoration: InputDecoration(
                  hintText: 'مثلاً: این هفته در حال پوست‌اندازیه',
                  hintStyle: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: _background,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _terracotta, width: 1.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _muted,
              ),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _terracotta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('رد کن'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final note = noteController.text.trim();
      await _respond(routine, 'skipped', note: note.isEmpty ? null : note);
    }
  }

 String _typeLabel(String type) {
  switch (type.toLowerCase().trim()) {
    case 'food':
      return 'غذا';
    case 'water':
      return 'آب';
    case 'cleaning':
      return 'نظافت';
    case 'humidity':
      return 'رطوبت و مه‌پاشی';
    case 'temperature':
      return 'بررسی دما';
    case 'lighting':
      return 'نور و UVB';
    case 'shedding':
      return 'پوست‌اندازی';
    case 'weight':
      return 'وزن‌کشی';
    case 'medicine':
      return 'دارو و درمان';
    case 'health':
      return 'بررسی سلامتی';
    case 'other':
    default:
      return 'سایر موارد';
  }
}

  IconData _typeIcon(String type) {
  switch (type.toLowerCase().trim()) {
    case 'food':
      return Icons.restaurant_rounded;
    case 'water':
      return Icons.water_drop_rounded;
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'humidity':
      return Icons.water_rounded;
    case 'temperature':
      return Icons.thermostat_rounded;
    case 'lighting':
      return Icons.wb_sunny_rounded;
    case 'shedding':
      return Icons.auto_awesome_rounded;
    case 'weight':
      return Icons.scale_rounded;
    case 'medicine':
      return Icons.medication_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'other':
    default:
      return Icons.more_horiz_rounded;
  }
}

  Color _typeColor(String type) {
  switch (type.toLowerCase().trim()) {
    case 'food':
      return const Color(0xFF66BB6A); // Green
    case 'water':
      return const Color(0xFF4FA8D6); // Light Blue
    case 'cleaning':
      return const Color(0xFF2EC4B6); // Teal
    case 'humidity':
      return const Color(0xFF48CAE4); // Aqua Blue
    case 'temperature':
      return const Color(0xFFE76F51); // Amber / Orange
    case 'lighting':
      return const Color(0xFFF4A261); // Warm Sun
    case 'shedding':
      return const Color(0xFF9D4EDD); // Purple
    case 'weight':
      return const Color(0xFF8E9AAF); // Slate
    case 'medicine':
      return const Color(0xFFE63946); // Red
    case 'health':
      return const Color(0xFFFF6B6B); // Coral / Pink
    case 'other':
    default:
      return const Color(0xFF9E9E9E); // Grey
  }
}

  Widget _buildPetIcon(Map<String, dynamic> pet, {required double size}) {

    final imagePath = imagePathForBreed(pet['breed']);

    final fallback = Center(

      child: Text(

        emojiForSpeciesGroup(pet['species_group']),

        style: TextStyle(fontSize: size * 0.46),

      ),

    );

    if (imagePath == null) return fallback;

    return Image.asset(

      imagePath,

      width: size,

      height: size,

      fit: BoxFit.cover,

      errorBuilder: (context, error, stackTrace) => fallback,

    );

  }
        Widget _buildUpcomingSection() {
    if (_upcomingRoutines.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'کارهای آینده',
            style: TextStyle(
              color: _sand.withValues(alpha: 0.8),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._upcomingRoutines.map((r) {
          final nextDate = r['nextDueDate'] as DateTime?;
          final dateStr = nextDate != null
              ? '${nextDate.year}/${nextDate.month.toString().padLeft(2, '0')}/${nextDate.day.toString().padLeft(2, '0')}'
              : '';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                hoverColor: _moss.withValues(alpha: 0.08),
                splashColor: _moss.withValues(alpha: 0.16),
                highlightColor: _moss.withValues(alpha: 0.10),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditRoutinePage(
                        routine: r,
                        pets: _allPets,
                      ),
                    ),
                  );
                  _loadRoutines();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _surfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _line),
                        ),
                        child: Icon(
                          Icons.event_note,
                          color: _muted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                                                                 Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title'] ?? '',
                              style: TextStyle(
                                color: _text.withValues(alpha: 0.75),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextDate != null
                                  ? 'موعد بعدی: ${nextDate.toLocal().toString().split(' ')[0]}'
                                  : 'بدون موعد مشخص',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                            if (r['lastDoneText'] != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                r['lastDoneText'] as String,
                                style: TextStyle(
                                  color: _muted.withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),


                      Icon(
                        Icons.chevron_left,
                        color: _muted.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }



  @override

  Widget build(BuildContext context) {

    final doneCount =

        _routines.where((r) => r['isDoneToday'] == true).length;

    final totalCount = _routines

        .where((r) => r['isSkippedToday'] != true)

        .length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          foregroundColor: _text,
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 18,
          title: Text(
            widget.pet['name'] ?? '',
            style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w800),
          ),

        actions: [

          IconButton(

            icon: const Icon(Icons.history),

            tooltip: 'تاریخچه',

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => PetHistoryPage(pet: widget.pet),

                ),

              );

            },

          ),

          IconButton(

            icon: const Icon(Icons.note_add_outlined),

            tooltip: 'ثبت اتفاق جدید',

            onPressed: () async {

              await Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => AddEventPage(pet: widget.pet),

                ),

              );

            },

          ),

          IconButton(

            icon: const Icon(Icons.edit),

            onPressed: () async {

              await Navigator.push(

                context,

                MaterialPageRoute(

                  builder: (context) => EditPetPage(pet: widget.pet),

                ),

              );

              if (mounted) Navigator.pop(context);

            },

          ),

        ],

      ),

      body: _isLoading

          ? const Center(child: CircularProgressIndicator(color: _moss, strokeWidth: 2.5))

          : Column(

              children: [

                Container(

                  width: double.infinity,

                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    color: _surface,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: _line),

                  ),

                  child: Row(

                    children: [

                      Container(

                        width: 64,

                        height: 64,

                        decoration: BoxDecoration(

                          color: _sand.withOpacity(.22),

                          borderRadius: BorderRadius.circular(16),

                        ),

                        child: ClipRRect(

                          borderRadius: BorderRadius.circular(16),

                          child: _buildPetIcon(widget.pet, size: 64),

                        ),

                      ),

                      const SizedBox(width: 14),

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Text(
                              widget.pet['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(

                              widget.pet['breed'] ?? '',

                              style: TextStyle(

                                fontSize: 13,

                                color: _muted,

                              ),

                            ),
                          if ((widget.pet['morph'] ?? '').toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.pet['morph'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              )),
                          ],

                        ),

                      ),

                      if (totalCount > 0)

                        Container(

                          padding: const EdgeInsets.symmetric(

                              horizontal: 10, vertical: 6),

                          decoration: BoxDecoration(

                            color: doneCount >= totalCount

                                ? _moss.withOpacity(0.15)

                                : _sand.withOpacity(0.15),

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: doneCount >= totalCount

                              ? const Icon(Icons.check_circle,

                                  color: _moss, size: 20)

                              : Text(

                                  '$doneCount/$totalCount',

                                  style: const TextStyle(

                                    color: _sand,

                                    fontWeight: FontWeight.w600,

                                  ),

                                ),

                        ),

                    ],

                  ),

                ),

                Container(

                  width: double.infinity,

                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),

                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    color: _checkinIsOverdue

                        ? _surfaceRaised

                        : _surface,

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(

                      color: _checkinIsOverdue

                          ? _sand

                          : _line,

                    ),

                  ),

                  child: Row(

                    children: [

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Text(

                              _checkinIsOverdue

                                  ? 'وقتشه اطلاعات رو به‌روز کنی'

                                  : 'آخرین بروزرسانی',

                              style: TextStyle(

                                fontSize: 13,

                                fontWeight: FontWeight.w600,

                                color: _checkinIsOverdue

                                    ? _sand

                                    : _text,

                              ),

                            ),

                            const SizedBox(height: 4),

                            if (_latestCheckin != null)

                              Text(

                                'وزن: ${_latestCheckin!['weight'] ?? '—'} گرم · سلامت: ${_latestCheckin!['health_score'] ?? '—'}/10',

                                style: TextStyle(

                                  fontSize: 12,

                                  color: _muted,

                                ),

                              )

                            else

                              Text(

                                'هنوز هیچ اطلاعاتی ثبت نشده',

                                style: TextStyle(

                                  fontSize: 12,

                                  color: _muted,

                                ),

                              ),

                          ],

                        ),

                      ),

                      TextButton(
                        onPressed: _openCheckinForm,
                        // استفاده از style برای کنترل رنگ دکمه
                        style: TextButton.styleFrom(
                          // اگر معوقه است رنگ متفاوتی بده، اگر نیست رنگ اصلی (مثلا رنگ _text یا یک رنگ مشخص)
                          foregroundColor: _checkinIsOverdue ? Colors.orangeAccent : _text, 
                          // اگر می‌خواهید کاملا برجسته باشد می‌توانید از رنگ primary استفاده کنید:
                          // foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          'ثبت جدید',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],

                  ),

                ),

                Padding(

                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),

                  child: Row(

                    children: [

                      Text(

                        'کارهای امروز',

                        style: TextStyle(

                          fontSize: 12,

                          fontWeight: FontWeight.w600,

                          color: _muted,

                          letterSpacing: 0.5,

                        ),

                      ),

                    ],

                  ),

                ),

                                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      if (_routines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'امروز کاری برای این حیوون نیست 🎉',
                              style: TextStyle(color: _muted),
                            ),
                          ),
                        )
                      else
                        ..._routines.map((r) {
                          final doneToday = r['isDoneToday'] == true;
                          final skippedToday = r['isSkippedToday'] == true;
                          final type = r['type'] ?? 'other';
                          final isBusy = _processingKeys
                              .contains('${r['id']}_${widget.pet['id']}');

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _line),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditRoutinePage(
                                          routine: r, pets: _allPets),
                                    ),
                                  );
                                  _loadRoutines();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: _typeColor(type)
                                                  .withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(_typeIcon(type),
                                                color: _typeColor(type)),
                                          ),
                                          if (doneToday)
                                            const Positioned(
                                              right: -2,
                                              bottom: -2,
                                              child: Icon(Icons.check_circle,
                                                  color: _moss, size: 16),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r['title'] ?? '',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    (doneToday || skippedToday)
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                color:
                                                    (doneToday || skippedToday)
                                                        ? _muted
                                                        : _text,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              skippedToday
                                                  ? '${_typeLabel(type)} · رد شد'
                                                  : '${_typeLabel(type)} · ${r['time'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (doneToday)
                                        const Icon(Icons.check_circle,
                                            color: _moss)
                                      else if (skippedToday)
                                        const Icon(Icons.cancel,
                                            color: _muted)
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              color: _muted,
                                              tooltip: 'رد کردن این بار',
                                              onPressed: isBusy
                                                  ? null
                                                  : () => _showSkipDialog(r),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.check_circle_outline),
                                              color: const Color(0xFF6E8B52),
                                              onPressed: isBusy
                                                  ? null
                                                  : () => _respond(r, 'done'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      _buildUpcomingSection(),
                    ],
                  ),
                ),


              ],

            ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _moss,
        foregroundColor: _background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () async {

          await Navigator.push(

            context,

            MaterialPageRoute(

              builder: (context) => AddRoutinePage(

                pets: _allPets,

                initialSelectedPetId: widget.pet['id'],

              ),

            ),

          );

          _loadRoutines();

        },

        child: const Icon(Icons.add_alarm),

      ),
)
    );
  }

}