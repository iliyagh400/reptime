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
      final userId =
          Supabase.instance.client.auth.currentUser!.id;

      final petsResponse = await Supabase.instance.client
          .from('pets')
          .select()
          .eq('user_id', userId);

      final routinesResponse = await Supabase.instance.client
          .from('routines')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);

      final completionsResponse =
          await Supabase.instance.client
              .from('completions')
              .select()
              .eq('user_id', userId);

      final pets =
          List<Map<String, dynamic>>.from(petsResponse);

      final routines =
          List<Map<String, dynamic>>.from(routinesResponse);

      final allCompletions =
          List<Map<String, dynamic>>.from(
        completionsResponse,
      );

      final List<_TodayTask> tasks = [];

      for (final routine in routines) {
        final petIds =
            List<dynamic>.from(routine['pet_ids'] ?? []);

        for (final petId in petIds) {
          final petIndex = pets.indexWhere(
            (pet) => pet['id'].toString() == petId.toString(),
          );

          if (petIndex == -1) continue;

          final pet = pets[petIndex];

          final petCompletions = allCompletions
              .where(
                (completion) =>
                    completion['pet_id'].toString() ==
                    petId.toString(),
              )
              .toList();

          if (!isRelevantToday(
            routine,
            petCompletions,
          )) {
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

      // مرتب‌سازی: اول کارهای باقی‌مانده،
      // بعد انجام‌شده و در نهایت ردشده
      tasks.sort((a, b) {
        final aHandled = a.isDone || a.isSkipped;
        final bHandled = b.isDone || b.isSkipped;

        if (aHandled != bHandled) {
          return aHandled ? 1 : -1;
        }

        final aTime =
            a.routine['time']?.toString() ?? '';
        final bTime =
            b.routine['time']?.toString() ?? '';

        return aTime.compareTo(bTime);
      });

      if (!mounted) return;

      setState(() {
        _pets = pets;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در دریافت کارهای امروز: $e'),
        ),
      );
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

  Future<void> _respond(
    _TodayTask task,
    String status, {
    String? note,
  }) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('completions')
          .insert({
        'user_id': user.id,
        'routine_id': task.routine['id'],
        'pet_id': task.pet['id'],
        'completed_at':
            DateTime.now().toIso8601String(),
        'status': status,
        'note': note,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'done'
                ? 'کار با موفقیت ثبت شد ✅'
                : 'کار رد شد ⏭️',
          ),
        ),
      );

      await NotificationService.cancelOverdueReminders(
        task.routine['id'],
      );

      final repeatType =
          task.routine['repeat_type'];

      if (repeatType == 'interval' ||
          repeatType == 'once') {
        final completionsResponse =
            await Supabase.instance.client
                .from('completions')
                .select()
                .eq('user_id', user.id)
                .eq(
                  'routine_id',
                  task.routine['id'],
                );

        final completions =
            List<Map<String, dynamic>>.from(
          completionsResponse,
        );

        if (repeatType == 'once') {
          await NotificationService
              .cancelRoutineNotifications(
            task.routine['id'],
          );
        } else {
          final next = nextDueDate(
            task.routine,
            completions,
          );

          final petIds = List.from(
            task.routine['pet_ids'] ?? [],
          );

          final petNames = _pets
              .where(
                (pet) => petIds.contains(pet['id']),
              )
              .map(
                (pet) =>
                    pet['name'] as String,
              )
              .toList();

          await NotificationService
              .scheduleRoutineNotifications(
            task.routine,
            overrideDate: next,
            petNames: petNames,
          );
        }
      }

      await _loadTodayTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ثبت کار انجام نشد: $e'),
        ),
      );
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
              color: Colors.white
                  .withOpacity(0.15),
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
                  onPressed: () => _showSkipDialog(task),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  color: _terracotta,
                  tooltip: 'انجام شد',
                  onPressed: () => _markDone(task),
                ),
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
  final bool isDone;
  final bool isSkipped;

  const _TodayTask({
    required this.routine,
    required this.pet,
    required this.isDone,
    required this.isSkipped,
  });
}