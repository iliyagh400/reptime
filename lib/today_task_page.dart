import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';
import 'routine_logic.dart';

class TodayTasksPage extends StatefulWidget {
  const TodayTasksPage({super.key});

  @override
  State<TodayTasksPage> createState() => _TodayTasksPageState();
}

class _TodayTasksPageState extends State<TodayTasksPage> {
  List<Map<String, dynamic>> _pets = [];
  List<_TodayTask> _tasks = [];
  final Set<String> _processingKeys = {};
  bool _isLoading = true;

  // Reptime Dark Terrarium design system
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _forest = Color(0xFF6E8B52);
  static const _forestDark = Color(0xFF17251D);
  static const _sage = Color(0xFF2D3B2F);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _orange = Color(0xFFD08A52);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _moss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
  }

    Future<void> _loadTodayTasks() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // ۱. بررسی کاملاً ایمن کاربر بدون عملگر !
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _pets = [];
            _tasks = [];
            _isLoading = false;
          });
        }
        return;
      }

      final userId = user.id;

      final petsRes = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final routinesRes = await Supabase.instance.client
          .from('routines')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      final completionsRes = await Supabase.instance.client
          .from('completions')
          .select()
          .eq('user_id', userId);

      final pets = List<Map<String, dynamic>>.from(petsRes);
      final routines = List<Map<String, dynamic>>.from(routinesRes);
      final allCompletions =
          List<Map<String, dynamic>>.from(completionsRes);

      final List<_TodayTask> tasks = [];

      for (final routine in routines) {
        final rawPetIds = routine['pet_ids'];
        final petIds = rawPetIds is List ? List<dynamic>.from(rawPetIds) : [];

        for (final petId in petIds) {
          final pet = pets.firstWhere(
            (p) => p['id']?.toString() == petId?.toString(),
            orElse: () => {},
          );

          if (pet.isEmpty) continue;

          final petCompletions = allCompletions.where((c) {
            return c['routine_id']?.toString() == routine['id']?.toString() &&
                c['pet_id']?.toString() == petId?.toString();
          }).toList();

          if (!isRelevantToday(routine, petCompletions)) {
            continue;
          }

                    final done = isDoneToday(
            routine,
            petCompletions,
          );

          final skipped = isSkippedToday(
            routine,
            petCompletions,
          );

          tasks.add(
            _TodayTask(
              routine: routine,
              pet: pet,
              isDone: done,
              isSkipped: skipped,
            ),
          );
        }
      }

      // مرتب‌سازی: اول کارهای باقی‌مانده، بعد انجام‌شده و در نهایت ردشده
      tasks.sort((a, b) {
        final aPending = !a.isDone && !a.isSkipped;
        final bPending = !b.isDone && !b.isSkipped;

        if (aPending && !bPending) return -1;
        if (!aPending && bPending) return 1;

        final aTime = (a.routine['time'] ?? '00:00').toString();
        final bTime = (b.routine['time'] ?? '00:00').toString();

        return aTime.compareTo(bTime);
      });


      if (!mounted) return;

      setState(() {
        _pets = pets;
        _tasks = tasks;
      });
    } catch (e) {
     debugPrint('Error loading today tasks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('خطا در دریافت کارهای امروز'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    
    } finally {
      // ۲. تضمین قطعی خاموش شدن لودینگ در هر شرایطی
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  int get _remainingCount {
    return _tasks
        .where((task) => !task.isDone && !task.isSkipped)
        .length;
  }

  String _petName(Map<String, dynamic> pet) {
    return pet['name']?.toString() ?? 'حیوان';
  }

  String _routineTitle(Map<String, dynamic> routine) {
    return routine['title']?.toString() ?? 'رسیدگی';
  }

  String _routineType(Map<String, dynamic> routine) {
    switch (routine['type']?.toString()) {
      case 'food':
        return 'غذا';
      case 'cleaning':
        return 'نظافت';
      case 'medicine':
        return 'دارو';
      case 'water':
        return 'آب';
      default:
        return _routineTitle(routine);
    }
  }

  IconData _routineIcon(Map<String, dynamic> routine) {
    switch (routine['type']?.toString()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'medicine':
        return Icons.medication_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

        Future<void> _respond(_TodayTask task, String status, {String? note}) async {
    final String processingKey = "${task.routine['id']}_${task.pet['id']}";
    if (_processingKeys.contains(processingKey)) return;
    _processingKeys.add(processingKey);
    if (mounted) setState(() {});

    final matchingTask = _tasks.firstWhere(
      (candidate) =>
          candidate.routine['id'] == task.routine['id'] &&
          candidate.pet['id'] == task.pet['id'],
      orElse: () => task,
    );
    final previousDone = matchingTask.isDone;
    final previousSkipped = matchingTask.isSkipped;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _processingKeys.remove(processingKey);
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('کاربر وارد نشده است. لطفاً ابتدا وارد شوید.'),
            backgroundColor: _terracotta,
          ),
        );
      }
      return;
    }

    matchingTask.isDone = (status == 'done');
    matchingTask.isSkipped = (status != 'done');
    if (mounted) setState(() {});

    try {
      await Supabase.instance.client.from('completions').insert({
        'user_id': user.id,
        'routine_id': task.routine['id'],
        'pet_id': task.pet['id'],
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'done' ? 'کار با موفقیت ثبت شد ✅' : 'کار رد شد ⏭️',
            ),
            backgroundColor: _forest,
          ),
        );
      }

      // بخش مدیریت نوتیفیکیشن‌ها محصور در try/catch مجزا
      try {
        await NotificationService.cancelOverdueReminders(task.routine['id']);

        final repeatType = task.routine['repeat_type'];
        if (repeatType == 'interval' || repeatType == 'once') {
          final res = await Supabase.instance.client
              .from('completions')
              .select()
              .eq('user_id', user.id)
              .eq('routine_id', task.routine['id']);
          final completions = List<Map<String, dynamic>>.from(res);

          if (repeatType == 'once') {
            await NotificationService.cancelRoutineNotifications(task.routine['id']);
          } else {
            final next = nextDueDate(task.routine, completions);
            final petIds = task.routine['pet_ids'] is List
                ? List<String>.from(task.routine['pet_ids'])
                : <String>[];
            final petNames = petIds.map((id) {
              final p = _pets.firstWhere(
                (element) => element['id'] == id,
                orElse: () => <String, dynamic>{},
              );
              return _petName(p);
            }).toList();

            await NotificationService.scheduleRoutineNotifications(
               task.routine,
              petNames: petNames,
              overrideDate: next,
            );
          }
        }
      } catch (e) {
        debugPrint('Error managing notifications: $e');
      }

    } catch (e) {
      matchingTask.isDone = previousDone;
      matchingTask.isSkipped = previousSkipped;
      if (mounted) setState(() {});
      debugPrint('Error responding to task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ثبت وضعیت کار انجام نشد'),
            backgroundColor: _terracotta,
          ),
        );
      }
    } finally {
      _processingKeys.remove(processingKey);
      if (mounted) setState(() {});
    }
  }



  Future<void> _markDone(_TodayTask task) async {
    await _respond(task, 'done');
  }

  Future<void> _showSkipDialog(_TodayTask task) async {
    final noteController =
        TextEditingController();

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'رد کردن این بار',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'چرا این بار انجامش نمی‌دی؟ (اختیاری)',
                  style: TextStyle(
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(
                    hintText:
                        'مثلاً: این هفته در حال پوست‌اندازیه',
                    filled: true,
                    fillColor: _cream,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                  false,
                ),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _terracotta,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    Navigator.pop(
                  dialogContext,
                  true,
                ),
                child: const Text('رد کن'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      final note =
          noteController.text.trim();

      await _respond(
        task,
        'skipped',
        note: note.isEmpty ? null : note,
      );
    }

    noteController.dispose();
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            _forestDark,
            _leaf,
          ],
        ),
        borderRadius:
            BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:_forest.withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.today_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'کارهای امروز',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _remainingCount == 0
                      ? 'همه کارهای امروز انجام شده 🎉'
                      : '$_remainingCount کار باقی مانده',
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(0.78),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildTaskCard(_TodayTask task) {
  final done = task.isDone;
  final skipped = task.isSkipped;
  final handled = done || skipped;
  final taskKey = "${task.routine['id']}_${task.pet['id']}";
  final isProcessing = _processingKeys.contains(taskKey);

  return AnimatedOpacity(
    duration: const Duration(milliseconds: 250),
    opacity: handled ? 0.68 : 1,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: handled ? _surface : _surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? _forest.withOpacity(0.6)
              : skipped
                  ? _terracotta.withOpacity(0.55)
                  : _line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_routineIcon(task.routine), color: _moss, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _petName(task.pet),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),

      const SizedBox(height: 2),

      Text(
        _routineTitle(task.routine),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _ink.withOpacity(0.85),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          decoration: handled
              ? TextDecoration.lineThrough
              : null,
        ),
      ),

      const SizedBox(height: 2),

      Text(
        skipped
            ? '${_routineType(task.routine)} · رد شد'
            : '${_routineType(task.routine)}'
              '${task.routine['time'] != null ? ' · ${task.routine['time']}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _muted,
          fontSize: 11.5,
        ),
      ),
    ],
  ),
),
          if (handled)
            Icon(
              done ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: done ? _moss : _terracotta,
              size: 22,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: _muted,
                  tooltip: 'رد شد',
                  onPressed: isProcessing ? null : () => _showSkipDialog(task),),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: _terracotta,
                  tooltip: 'انجام شد',
                  onPressed: isProcessing ? null : () => _markDone(task),),
              ],
            ),
        ],
      ),
    ),
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 70,
        ),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _sage,
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons
                    .check_circle_outline_rounded,
                color: _forest,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'برای امروز کاری باقی نمانده 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'همه‌چیز تحت کنترله. پت‌هات ازت ممنونن 🐾',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            'امروز',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: const IconThemeData(
            color: _ink,
          ),
        ),
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: _forest,
                ),
              )
            : RefreshIndicator(
                color: _forest,
                onRefresh: _loadTodayTasks,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.only(
                    bottom: 30,
                  ),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 10),

                    if (_tasks.isEmpty)
                      _buildEmptyState()
                    else
                      Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          5,
                          16,
                          0,
                        ),
                        child: Column(
                          children: _tasks
                              .map(
                                _buildTaskCard,
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TodayTask {
  final Map<String, dynamic> routine;
  final Map<String, dynamic> pet;
  bool isDone;
  bool isSkipped;

  _TodayTask({
    required this.routine,
    required this.pet,
    required this.isDone,
    required this.isSkipped,
  });
}