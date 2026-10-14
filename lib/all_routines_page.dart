import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routine_logic.dart';
import 'notification_service.dart';
import 'app_feedback.dart';
import 'edit_routine_page.dart';

class AllRoutinesPage extends StatefulWidget {
  const AllRoutinesPage({super.key});

  @override
  State<AllRoutinesPage> createState() => _AllRoutinesPageState();
}

class _AllRoutinesPageState extends State<AllRoutinesPage> {
  // ─── Dark Terrarium Palette ────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0E1512);
  static const Color _card = Color(0xFF131B17);
  static const Color _cardHover = Color(0xFF18221D);
  static const Color _line = Color(0xFF24342C);
  static const Color _text = Color(0xFFE6F1EA);
  static const Color _muted = Color(0xFF9FB3A9);
  static const Color _forestDark = Color(0xFF1C2B24);
  static const Color _moss = Color(0xFF2D4A3E);
  static const Color _accent = Color(0xFF3BD671);
  static const Color _accentSoft = Color(0xFF285C3F);
  static const Color _warning = Color(0xFFE5A93C);
  static const Color _danger = Color(0xFFFF6D6D);
  static const Color _dangerSoft = Color(0xFF4A2323);

  final SupabaseClient _sb = Supabase.instance.client;

  bool _isLoading = true;
  bool _hasError = false;

  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _routines = [];
  List<Map<String, dynamic>> _completions = [];

  // Filter state
  int? _selectedPetId; // null = all
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // In-flight action keys to prevent duplicate taps: "${routineId}_${petId}"
  final Set<String> _processingKeys = {};

  // For delete routine progress: routineId
  final Set<int> _deletingRoutineIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

    Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      // ۱. دریافت حیوانات (مشابه home_page و today_task_page)
      final petsData = await _sb
          .from('pets')
          .select()
          .eq('user_id', user.id);

      // ۲. دریافت تمام روتین‌ها
      final routinesData = await _sb
          .from('routines')
          .select()
          .eq('user_id', user.id);

      // ۳. دریافت وضعیت انجام روتین‌ها (از جدول completions)
      final completionsData = await _sb
          .from('completions')
          .select()
          .eq('user_id', user.id);

      if (!mounted) return;

      setState(() {
        _pets = List<Map<String, dynamic>>.from(petsData);
        _routines = List<Map<String, dynamic>>.from(routinesData);
        _completions = List<Map<String, dynamic>>.from(completionsData);
        _isLoading = false;
        _hasError = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading all_routines data: $e');
      debugPrint('$stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      AppFeedback.showError(context, 'خطا در دریافت اطلاعات روتین‌ها');
    }
  }


  // ─── Pet Resolution Helpers ────────────────────────────────────────────────

  List<int> _routinePetIds(Map<String, dynamic> routine) {
    final raw = routine['pet_ids'] ?? routine['pets_ids'];
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map((e) => int.tryParse(e.toString()))
          .where((e) => e != null)
          .cast<int>()
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _petsOfRoutine(Map<String, dynamic> routine) {
    final ids = _routinePetIds(routine);
    return _pets.where((p) => ids.contains(p['id'] as int?)).toList();
  }

  List<Map<String, dynamic>> _getCompletionsFor(int routineId, int petId) {
    return _completions.where((c) {
      final rId = c['routine_id'] as int?;
      final pId = c['pet_id'] as int?;
      return rId == routineId && pId == petId;
    }).toList();
  }

  // ─── Presentation Helpers ──────────────────────────────────────────────────

  String _routineTitle(Map<String, dynamic> routine) {
    final t = routine['title'] as String?;
    if (t != null && t.trim().isNotEmpty) return t.trim();
    return _typeLabel(routine);
  }

  String _typeLabel(Map<String, dynamic> routine) {
    final type = routine['type'] as String?;
    switch (type) {
      case 'feeding':
        return 'غذا دهی';
      case 'cleaning':
        return 'نظافت';
      case 'misting':
        return 'مه‌پاشی / رطوبت';
      case 'supplement':
        return 'مکمل و ویتامین';
      case 'health_check':
        return 'بررسی سلامت';
      case 'handling':
        return 'ارتباط / هندلینگ';
      case 'measurement':
        return 'اندازه‌گیری وزن و طول';
      case 'lighting':
        return 'تنظیم نور و لامپ‌ها';
      case 'heating':
        return 'بررسی دما و هیتر';
      default:
        return type ?? 'روتین';
    }
  }

  IconData _typeIcon(Map<String, dynamic> routine) {
    final type = routine['type'] as String?;
    switch (type) {
      case 'feeding':
        return Icons.restaurant;
      case 'cleaning':
        return Icons.cleaning_services_outlined;
      case 'misting':
        return Icons.water_drop_outlined;
      case 'supplement':
        return Icons.medication_outlined;
      case 'health_check':
        return Icons.favorite_border;
      case 'handling':
        return Icons.pets_outlined;
      case 'measurement':
        return Icons.straighten;
      case 'lighting':
        return Icons.wb_incandescent_outlined;
      case 'heating':
        return Icons.thermostat;
      default:
        return Icons.event_repeat;
    }
  }

  String _repeatLabel(Map<String, dynamic> routine) {
    final repeatType = routine['repeat_type'];
    if (repeatType == null) return 'یک‌بار';
    switch (repeatType) {
      case 'daily':
        return 'روزانه';
      case 'weekly':
        return 'هفتگی';
      case 'monthly':
        return 'ماهانه';
      case 'interval':
        final days = routine['interval_days'] ?? 1;
        return 'هر $days روز';
      case 'once':
        return 'یک‌بار';
      default:
        return repeatType.toString();
    }
  }

  String _timeLabel(Map<String, dynamic> routine) {
    final timeStr = routine['time'] as String?;
    if (timeStr == null || timeStr.isEmpty) return '';
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }

  // ─── Filtering ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filteredRoutines() {
    return _routines.where((r) {
      if (_selectedPetId != null) {
        final ids = _routinePetIds(r);
        if (!ids.contains(_selectedPetId)) return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final title = _routineTitle(r).toLowerCase();
        final type = _typeLabel(r).toLowerCase();
        final petNames = _petsOfRoutine(r)
            .map((p) => (p['name'] as String? ?? '').toLowerCase())
            .join(' ');

        final matches = title.contains(query) ||
            type.contains(query) ||
            petNames.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  // ─── Actions: Done / Skip ──────────────────────────────────────────────────

  Future<void> _respondTask({
    required Map<String, dynamic> routine,
    required int petId,
    required String action, // 'done' | 'skipped'
    String? note,
  }) async {
    final routineId = routine['id'] as int;
    final key = '${routineId}_$petId';

    if (_processingKeys.contains(key)) return;

    final completions = _getCompletionsFor(routineId, petId);
    if (!isDueToday(routine, completions) || isHandledToday(routine, completions)) {
      AppFeedback.showError(context, 'این کار امروز در دسترس نیست');
      return;
    }

    final user = _sb.auth.currentUser;
    if (user == null) {
      AppFeedback.showError(context, 'کاربر لاگین نکرده است');
      return;
    }

    setState(() => _processingKeys.add(key));

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final tempCompletion = {
      'id': -DateTime.now().millisecondsSinceEpoch,
      'user_id': user.id,
      'routine_id': routineId,
      'pet_id': petId,
      'status': action,
      'note': note,
      'completed_at': nowIso,
    };

    // Optimistic UI update
    setState(() {
      _completions.add(tempCompletion);
    });

    try {
      final inserted = await _sb
          .from('completions')
          .insert({
            'user_id': user.id,
            'routine_id': routineId,
            'pet_id': petId,
            'status': action,
            'note': note,
            'completed_at': nowIso,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          final idx = _completions.indexWhere((c) => c['id'] == tempCompletion['id']);
          if (idx != -1) {
            _completions[idx] = Map<String, dynamic>.from(inserted);
          }
        });
      }

      // Notifications management
      try {
        await NotificationService.cancelOverdueReminders(routineId);
        final repeatType = routine['repeat_type'];
        if (repeatType == 'once') {
          await NotificationService.cancelRoutineNotifications(routineId);
        } else if (repeatType == 'interval') {
          final petNames = _petsOfRoutine(routine)
              .map((p) => p['name'] as String? ?? '')
              .where((n) => n.isNotEmpty)
              .toList();
          final next = nextDueDate(routine, _getCompletionsFor(routineId, petId));
          if (next != null) {
            await NotificationService.scheduleRoutineNotifications(
              routine,
              petNames: petNames,
              overrideDate: next,
            );
          }
        }
      } catch (notifErr) {
        debugPrint('Notification reschedule non-fatal error: $notifErr');
      }

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          action == 'done' ? 'کار با موفقیت ثبت شد ✅' : 'کار رد شد ⏭️',
        );
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _completions.removeWhere((c) => c['id'] == tempCompletion['id']);
        });
        AppFeedback.showError(context, 'ثبت وضعیت کار انجام نشد');
      }
    } finally {
      if (mounted) {
        setState(() => _processingKeys.remove(key));
      }
    }
  }

  Future<void> _handleSkipTap({
    required Map<String, dynamic> routine,
    required int petId,
  }) async {
    final note = await _showSkipNoteDialog();
    if (note == null) return;
    await _respondTask(
      routine: routine,
      petId: petId,
      action: 'skipped',
      note: note.isEmpty ? null : note,
    );
  }

  Future<String?> _showSkipNoteDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.skip_next, color: _danger, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'رد کردن این کار',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'در صورت تمایل می‌توانید دلیل رد کردن (اختیاری) را بنویسید:',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    style: const TextStyle(color: _text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'مثال: زمان تغذیه مناسب نبود یا حیوان سیر بود...',
                      hintStyle: TextStyle(
                        color: _muted.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('انصراف', style: TextStyle(color: _muted)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _warning,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                        child: const Text(
                          'ثبت و رد',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Edit & Delete Routine ─────────────────────────────────────────────────

  Future<void> _openEditRoutine(Map<String, dynamic> routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRoutinePage(
          routine: routine,
          pets: _pets,
        ),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _confirmDeleteRoutine(Map<String, dynamic> routine) async {
    final routineId = routine['id'] as int;
    final title = _routineTitle(routine);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _line),
            ),
            title: const Row(
              children: [
                Icon(Icons.delete_outline, color: _danger, size: 22),
                SizedBox(width: 8),
                Text(
                  'حذف روتین',
                  style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'آیا از حذف روتین «$title» اطمینان دارید؟ تمام تاریخچه و یادآورهای این روتین پاک خواهند شد.',
              style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('انصراف', style: TextStyle(color: _muted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final user = _sb.auth.currentUser;
    if (user == null) {
      if (mounted) AppFeedback.showError(context, 'کاربر لاگین نکرده است');
      return;
    }

    setState(() => _deletingRoutineIds.add(routineId));

    try {
      await _sb
          .from('routines')
          .delete()
          .eq('id', routineId)
          .eq('user_id', user.id);

      try {
        await NotificationService.cancelRoutineNotifications(routineId);
      } catch (notifErr) {
        debugPrint('Notification cancel non-fatal error: $notifErr');
      }

      if (mounted) {
        setState(() {
          _routines.removeWhere((r) => r['id'] == routineId);
          _completions.removeWhere((c) => c['routine_id'] == routineId);
        });
        AppFeedback.showSuccess(context, 'روتین با موفقیت حذف شد');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'خطا در حذف روتین');
      }
    } finally {
      if (mounted) {
        setState(() => _deletingRoutineIds.remove(routineId));
      }
    }
  }

  // ─── Build Tree ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'همه روتین‌ها',
            style: TextStyle(
              color: _text,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _muted),
              tooltip: 'تازه‌سازی',
              onPressed: _isLoading ? null : _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: _accent),
              )
            : _hasError
                ? _buildErrorState()
                : RefreshIndicator(
                    color: _accent,
                    backgroundColor: _card,
                    onRefresh: _loadData,
                    child: Column(
                      children: [
                        _buildSearchBar(),
                        _buildPetFilterBar(),
                        Expanded(
                          child: _filteredRoutines().isEmpty
                              ? _buildEmptyState()
                              : _buildRoutinesList(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ─── Search Bar ────────────────────────────────────────────────────────────

    Widget _buildSearchBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2825),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        textDirection: TextDirection.rtl,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        cursorColor: const Color(0xFF4EBA88),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          hintText: 'جستجو بر اساس عنوان، نوع یا نام حیوان...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.6),
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }


  // ─── Pet Filter Bar ────────────────────────────────────────────────────────

  Widget _buildPetFilterBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: 'همه حیوانات',
            isSelected: _selectedPetId == null,
            onTap: () {
              setState(() => _selectedPetId = null);
            },
          ),
          const SizedBox(width: 8),
          ..._pets.map((pet) {
            final pid = pet['id'] as int;
            final name = pet['name'] as String? ?? 'بدون نام';
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildFilterChip(
                label: name,
                isSelected: _selectedPetId == pid,
                onTap: () {
                  setState(() {
                    _selectedPetId = _selectedPetId == pid ? null : pid;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _moss : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accent : _line,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _text : _muted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Routines List & Cards ─────────────────────────────────────────────────

  Widget _buildRoutinesList() {
    final list = _filteredRoutines();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        return _buildRoutineCard(list[i]);
      },
    );
  }

  Widget _buildRoutineCard(Map<String, dynamic> routine) {
    final routineId = routine['id'] as int;
    final routinePetIds = _routinePetIds(routine);
    final title = _routineTitle(routine);
    final typeLabel = _typeLabel(routine);
    final typeIcon = _typeIcon(routine);
    final repeatLabel = _repeatLabel(routine);
    final timeLabel = _timeLabel(routine);
    final isActive = routine['is_active'] as bool? ?? true;
    final isDeleting = _deletingRoutineIds.contains(routineId);

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _line : _line.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header: Type icon + title + menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _forestDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _line),
                      ),
                      child: Icon(typeIcon, color: _accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isActive ? _text : _muted,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildMetaTag(typeLabel, Icons.category_outlined),
                              _buildMetaTag(repeatLabel, Icons.repeat),
                              if (timeLabel.isNotEmpty)
                                _buildMetaTag(timeLabel, Icons.access_time),
                              if (!isActive)
                                _buildMetaTag('غیرفعال', Icons.pause_circle_outline,
                                    color: _warning),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: _muted, size: 20),
                      color: _cardHover,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: _line),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _openEditRoutine(routine);
                        } else if (val == 'delete') {
                          _confirmDeleteRoutine(routine);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: _text, size: 18),
                                SizedBox(width: 8),
                                Text('ویرایش', style: TextStyle(color: _text, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: _danger, size: 18),
                                SizedBox(width: 8),
                                Text('حذف', style: TextStyle(color: _danger, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: _line, height: 1),
                const SizedBox(height: 10),

                // Pet Task Rows
                if (routinePetIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'هیچ حیوانی به این روتین متصل نیست',
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  ...routinePetIds.map((petId) {
                    final pet = _pets.firstWhere(
                      (p) => p['id'] == petId,
                      orElse: () => {'id': petId, 'name': 'حیوان نامشخص'},
                    );
                    return _buildPetTaskRow(routine, pet);
                  }),
              ],
            ),
          ),
          if (isDeleting)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _bg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: _danger),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(String text, IconData icon, {Color? color}) {
    final c = color ?? _muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(color: c, fontSize: 11),
        ),
      ],
    );
  }

  // ─── Per-Pet Task Row ──────────────────────────────────────────────────────

  Widget _buildPetTaskRow(Map<String, dynamic> routine, Map<String, dynamic> pet) {
    final routineId = routine['id'] as int;
    final petId = pet['id'] as int;
    final petName = pet['name'] as String? ?? 'حیوان';
    final key = '${routineId}_$petId';
    final isProcessing = _processingKeys.contains(key);

    final completions = _getCompletionsFor(routineId, petId);
    final dueToday = isDueToday(routine, completions);
    final doneToday = isDoneToday(routine, completions);
    final skippedToday = isSkippedToday(routine, completions);
    final handledToday = isHandledToday(routine, completions);
    final canAct = dueToday && !handledToday;

    Color badgeBg;
    Color badgeBorder;
    Color badgeText;
    String statusLabel;
    IconData statusIcon;

    if (doneToday) {
      badgeBg = _accentSoft.withValues(alpha: 0.4);
      badgeBorder = _accent;
      badgeText = _accent;
      statusLabel = 'انجام شد';
      statusIcon = Icons.check_circle;
    } else if (skippedToday) {
      badgeBg = _dangerSoft;
      badgeBorder = _danger;
      badgeText = _danger;
      statusLabel = 'رد شد';
      statusIcon = Icons.cancel;
    } else if (dueToday) {
      badgeBg = _warning.withValues(alpha: 0.15);
      badgeBorder = _warning;
      badgeText = _warning;
      statusLabel = 'امروز موعد است';
      statusIcon = Icons.schedule;
    } else {
      badgeBg = Colors.transparent;
      badgeBorder = _line;
      badgeText = _muted;
      statusLabel = 'موعد نیست';
      statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: _forestDark,
            backgroundImage: (pet['photo_url'] != null &&
                    pet['photo_url'].toString().isNotEmpty)
                ? NetworkImage(pet['photo_url'].toString())
                : null,
            child: (pet['photo_url'] == null ||
                    pet['photo_url'].toString().isEmpty)
                ? Text(
                    petName.isNotEmpty ? petName.characters.first : '؟',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              petName,
              style: const TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: badgeBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: badgeText),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          if (canAct) ...[
            const SizedBox(width: 6),
            if (isProcessing)
              const SizedBox(
                width: 28,
                height: 28,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _accent,
                  ),
                ),
              )
            else ...[
              // Skip button
              InkWell(
                onTap: () => _handleSkipTap(routine: routine, petId: petId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _dangerSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: _danger, size: 16),
                ),
              ),
              const SizedBox(width: 6),
              // Done button
              InkWell(
                onTap: () => _respondTask(
                  routine: routine,
                  petId: petId,
                  action: 'done',
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: _accent, size: 16),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Empty & Error States ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final hasSearch = _searchQuery.trim().isNotEmpty;
    final hasPetFilter = _selectedPetId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _forestDark,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
              ),
              child: Icon(
                hasSearch || hasPetFilter
                    ? Icons.search_off
                    : Icons.event_repeat_outlined,
                color: _muted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch || hasPetFilter
                  ? 'هیچ روتینی با این فیلترها پیدا نشد'
                  : 'هنوز هیچ روتینی ثبت نشده است',
              style: const TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch || hasPetFilter
                  ? 'عبارت جستجو یا فیلتر حیوان را تغییر دهید'
                  : 'برای ساخت روتین از دکمه افزودن روتین در صفحه اصلی استفاده کنید',
              style: const TextStyle(color: _muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _dangerSoft,
                shape: BoxShape.circle,
                border: Border.all(color: _danger.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.error_outline, color: _danger, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'خطا در بارگذاری اطلاعات',
              style: TextStyle(
                color: _text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'امکان برقراری ارتباط با سرور وجود ندارد. لطفا اینترنت خود را بررسی کنید.',
              style: TextStyle(color: _muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _forestDark,
                foregroundColor: _text,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
