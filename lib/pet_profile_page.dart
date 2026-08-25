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

class PetProfilePage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _allPets = [];
  Map<String, dynamic>? _latestCheckin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
    _loadLatestCheckin();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
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
      return ids.contains(petId);
    }).toList();

    // Fetch both 'done' and 'skipped' responses — status filter removed
    // on purpose so isDoneToday / isSkippedToday can tell them apart.
    final completionsResponse = await Supabase.instance.client
        .from('completions')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', petId);

    final completions = List<Map<String, dynamic>>.from(completionsResponse);

    final List<Map<String, dynamic>> relevantToday = [];

    for (final routine in petRoutines) {
      if (isRelevantToday(routine, completions)) {
        relevantToday.add({
          ...routine,
          'isDoneToday': isDoneToday(routine, completions),
          'isSkippedToday': isSkippedToday(routine, completions),
        });
      }
    }

    setState(() {
      _routines = relevantToday;
      _isLoading = false;
    });
  }

  Future<void> _loadLatestCheckin() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('pet_checkins')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', widget.pet['id'])
        .order('checkin_date', ascending: false)
        .limit(1);

    final results = List<Map<String, dynamic>>.from(response);
    setState(() {
      _latestCheckin = results.isEmpty ? null : results.first;
    });
  }

  bool get _checkinIsOverdue {
    if (_latestCheckin == null) return true;
    final lastDate = DateTime.parse(_latestCheckin!['checkin_date']);
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

  Future<void> _respond(Map<String, dynamic> routine, String status,
      {String? note}) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    await Supabase.instance.client.from('completions').insert({
      'user_id': userId,
      'routine_id': routine['id'],
      'pet_id': widget.pet['id'],
      'completed_at': DateTime.now().toIso8601String(),
      'status': status,
      'note': note,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'done' ? 'ثبت شد ✅' : 'رد شد ⏭️'),
        ),
      );
    }

    await NotificationService.cancelOverdueReminders(routine['id']);

    // For interval/once routines, the real notification needs to be
    // recomputed now that a new response (done or skipped) exists.
    final repeatType = routine['repeat_type'];
    if (repeatType == 'interval' || repeatType == 'once') {
      final completionsResponse = await Supabase.instance.client
          .from('completions')
          .select()
          .eq('user_id', userId)
          .eq('routine_id', routine['id']);
      final completions =
          List<Map<String, dynamic>>.from(completionsResponse);

      if (repeatType == 'once') {
        await NotificationService.cancelRoutineNotifications(routine['id']);
      } else {
        final next = nextDueDate(routine, completions);
        final petIds = List.from(routine['pet_ids'] ?? []);
        final petNames = _allPets
            .where((p) => petIds.contains(p['id']))
            .map((p) => p['name'] as String)
            .toList();
        await NotificationService.scheduleRoutineNotifications(
          routine,
          overrideDate: next,
          petNames: petNames,
        );
      }
    }

    _loadRoutines();
  }

  Future<void> _showSkipDialog(Map<String, dynamic> routine) async {
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد کردن این بار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('چرا این بار انجامش نمی‌دی؟ (اختیاری)'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'مثلاً: این هفته در حال پوست‌اندازیه',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رد کن'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final note = noteController.text.trim();
      await _respond(routine, 'skipped', note: note.isEmpty ? null : note);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'food':
        return 'غذا';
      case 'cleaning':
        return 'نظافت';
      case 'medicine':
        return 'دارو';
      default:
        return 'دیگر';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'food':
        return Icons.restaurant;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'medicine':
        return Icons.medication;
      default:
        return Icons.event_note;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'food':
        return const Color(0xFF3F5D45);
      case 'cleaning':
        return Colors.blueGrey;
      case 'medicine':
        return const Color(0xFFB5563C);
      default:
        return Colors.grey;
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

  @override
  Widget build(BuildContext context) {
    final doneCount =
        _routines.where((r) => r['isDoneToday'] == true).length;
    final totalCount = _routines
        .where((r) => r['isSkippedToday'] != true)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet['name'] ?? ''),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC9D0BA)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3B679),
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
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.pet['breed'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (totalCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: doneCount >= totalCount
                                ? Colors.green.withOpacity(0.15)
                                : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: doneCount >= totalCount
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20)
                              : Text(
                                  '$doneCount/$totalCount',
                                  style: const TextStyle(
                                    color: Colors.orange,
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
                        ? const Color(0xFFF5E3C8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _checkinIsOverdue
                          ? const Color(0xFFC98A3E)
                          : const Color(0xFFC9D0BA),
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
                                    ? const Color(0xFF8A5A16)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_latestCheckin != null)
                              Text(
                                'وزن: ${_latestCheckin!['weight'] ?? '—'} گرم · سلامت: ${_latestCheckin!['health_score'] ?? '—'}/10',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              )
                            else
                              Text(
                                'هنوز هیچ اطلاعاتی ثبت نشده',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openCheckinForm,
                        child: const Text('ثبت جدید'),
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
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _routines.isEmpty
                      ? Center(
                          child: Text(
                            'امروز کاری برای این حیوون نیست 🎉',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: _routines.length,
                          itemBuilder: (context, index) {
                            final r = _routines[index];
                            final doneToday = r['isDoneToday'] == true;
                            final skippedToday = r['isSkippedToday'] == true;
                            final type = r['type'] ?? 'other';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFC9D0BA)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditRoutinePage(
                                                routine: r,
                                                pets: _allPets),
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
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Icon(_typeIcon(type),
                                                  color: _typeColor(type)),
                                            ),
                                            if (doneToday)
                                              const Positioned(
                                                right: -2,
                                                bottom: -2,
                                                child: Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 16),
                                              ),
                                            if (skippedToday)
                                              const Positioned(
                                                right: -2,
                                                bottom: -2,
                                                child: Icon(
                                                    Icons.cancel,
                                                    color: Colors.grey,
                                                    size: 16),
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
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  decoration: (doneToday ||
                                                          skippedToday)
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                  color: (doneToday ||
                                                          skippedToday)
                                                      ? Colors.grey
                                                      : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                skippedToday
                                                    ? '${_typeLabel(type)} · رد شد'
                                                    : '${_typeLabel(type)} · ${r['time'] ?? ''}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (doneToday)
                                          const Icon(Icons.check_circle,
                                              color: Colors.green)
                                        else if (skippedToday)
                                          const Icon(Icons.cancel,
                                              color: Colors.grey)
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.close),
                                                color: Colors.grey[500],
                                                tooltip: 'رد کردن این بار',
                                                onPressed: () =>
                                                    _showSkipDialog(r),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons
                                                    .check_circle_outline),
                                                color: const Color(
                                                    0xFF3F5D45),
                                                onPressed: () =>
                                                    _respond(r, 'done'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
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
    );
  }
}