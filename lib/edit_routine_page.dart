import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

/// Premium redesigned EditRoutinePage.
///
/// The existing Supabase queries, routine logic and navigation are preserved.
/// This file focuses on presentation, hierarchy, spacing and interaction design,
/// matching the dark terrarium style of HomePage.
class EditRoutinePage extends StatefulWidget {
  final Map<String, dynamic> routine;
  final List<Map<String, dynamic>> pets;

  const EditRoutinePage({super.key, required this.routine, required this.pets});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  // Dark Terrarium palette — visual styling only.
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _forest = Color(0xFF6E8B52);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _terracotta = Color(0xFFB86F4D);
  static const _leaf = Color(0xFF486344);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _danger = Color(0xFFB64B45);
  static const _inputBg = Color(0xFF1C2621);

  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  late final TextEditingController _intervalController;

  late String _type;
  late String _repeatType;
  late Set<String> _selectedWeekdays;
  late Set<String> _selectedPetIds;
  bool _isLoading = false;

  final _weekdayOptions = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const _weekdayLabels = {
    'Sat': 'شنبه',
    'Sun': 'یکشنبه',
    'Mon': 'دوشنبه',
    'Tue': 'سه‌شنبه',
    'Wed': 'چهارشنبه',
    'Thu': 'پنج‌شنبه',
    'Fri': 'جمعه',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.routine;
    _titleController = TextEditingController(text: r['title']);
    _timeController = TextEditingController(text: r['time']);
    _intervalController =
        TextEditingController(text: r['interval_days']?.toString() ?? '');
    _type = r['type'] ?? 'food';
    _repeatType = r['repeat_type'] ?? 'daily';
    _selectedWeekdays = Set<String>.from(r['weekdays'] ?? []);
    _selectedPetIds =
        Set<String>.from((r['pet_ids'] ?? []).map((e) => e.toString()));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _updateRoutine() async {
    if (_selectedPetIds.isEmpty) {
      _showSnack('حداقل یک حیوون انتخاب کن');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updated = await Supabase.instance.client
          .from('routines')
          .update({
            'title': _titleController.text.trim(),
            'type': _type,
            'pet_ids': _selectedPetIds.map((e) => int.parse(e)).toList(),
            'time': _timeController.text.trim(),
            'repeat_type': _repeatType,
            'weekdays':
                _repeatType == 'weekly' ? _selectedWeekdays.toList() : null,
            'interval_days': _repeatType == 'interval'
                ? int.tryParse(_intervalController.text.trim())
                : null,
          })
          .eq('id', widget.routine['id'])
          .select()
          .single();

      final petNames = widget.pets
          .where((p) => _selectedPetIds.contains(p['id'].toString()))
          .map((p) => p['name'] as String)
          .toList();
      await NotificationService.scheduleRoutineNotifications(
        updated,
        petNames: petNames,
      );

      if (mounted) {
        _showSnack('روتین بروزرسانی شد ✅');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('خطا: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'حذف روتین',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        content: const Text(
          'مطمئنی می‌خوای این روتین رو حذف کنی؟',
          textAlign: TextAlign.right,
          style: TextStyle(color: _muted, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'انصراف',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'حذف',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('routines')
          .delete()
          .eq('id', widget.routine['id']);

      await NotificationService.cancelRoutineNotifications(
          widget.routine['id']);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnack('خطا: $e', isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF5A2B28) : _surfaceRaised,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              color: _terracotta,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line.withOpacity(.78)),
      ),
      child: child,
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        color: _ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: _terracotta,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: _muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: _forest,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: _muted, size: 20),
        filled: true,
        fillColor: _inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _line.withOpacity(.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _forest, width: 1.6),
        ),
      ),
    );
  }

  Widget _themedChoiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _leaf,
      backgroundColor: _surface,
      side: BorderSide(color: selected ? _leaf : _line.withOpacity(.7)),
      labelStyle: TextStyle(
        color: selected ? _ink : _muted,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _themedFilterChip(
      String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: _leaf,
      backgroundColor: _surface,
      side: BorderSide(color: selected ? _leaf : _line.withOpacity(.7)),
      labelStyle: TextStyle(
        color: selected ? _ink : _muted,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
      checkmarkColor: _ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _ink),
          title: const Text(
            'ویرایش روتین',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 4),
              child: IconButton(
                tooltip: 'حذف روتین',
                onPressed: _deleteRoutine,
                icon: const Icon(Icons.delete_outline_rounded, color: _danger),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              _card(
                child: _buildField(
                  controller: _titleController,
                  label: 'عنوان',
                  icon: Icons.edit_rounded,
                ),
              ),
              _sectionLabel('نوع'),
              _card(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _themedChoiceChip('غذا', _type == 'food',
                        () => setState(() => _type = 'food')),
                    _themedChoiceChip('نظافت', _type == 'cleaning',
                        () => setState(() => _type = 'cleaning')),
                    _themedChoiceChip('دارو', _type == 'medicine',
                        () => setState(() => _type = 'medicine')),
                    _themedChoiceChip('دیگر', _type == 'other',
                        () => setState(() => _type = 'other')),
                  ],
                ),
              ),
              _sectionLabel('حیوان‌ها'),
              _card(
                child: widget.pets.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'حیوانی برای انتخاب وجود نداره',
                          style: TextStyle(color: _muted, fontSize: 13),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.pets.map((pet) {
                          final id = pet['id'].toString();
                          return _themedFilterChip(
                            pet['name'] ?? '',
                            _selectedPetIds.contains(id),
                            (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPetIds.add(id);
                                } else {
                                  _selectedPetIds.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              _sectionLabel('زمان‌بندی'),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _timeController,
                      label: 'ساعت (مثلاً 08:00)',
                      icon: Icons.schedule_rounded,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _themedChoiceChip('روزانه', _repeatType == 'daily',
                            () => setState(() => _repeatType = 'daily')),
                        _themedChoiceChip('هفتگی', _repeatType == 'weekly',
                            () => setState(() => _repeatType = 'weekly')),
                        _themedChoiceChip('ماهانه', _repeatType == 'monthly',
                            () => setState(() => _repeatType = 'monthly')),
                        _themedChoiceChip('بازه‌ای', _repeatType == 'interval',
                            () => setState(() => _repeatType = 'interval')),
                        _themedChoiceChip('یک‌بار', _repeatType == 'once',
                            () => setState(() => _repeatType = 'once')),
                      ],
                    ),
                    if (_repeatType == 'weekly') ...[
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _weekdayOptions.map((day) {
                          return _themedFilterChip(
                            _weekdayLabels[day] ?? day,
                            _selectedWeekdays.contains(day),
                            (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWeekdays.add(day);
                                } else {
                                  _selectedWeekdays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (_repeatType == 'interval') ...[
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _intervalController,
                        label: 'هر چند روز؟ (مثلاً 5)',
                        icon: Icons.repeat_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _forest,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _updateRoutine,
                        style: FilledButton.styleFrom(
                          backgroundColor: _terracotta,
                          foregroundColor: const Color(0xFF171B17),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text(
                          'ذخیره تغییرات',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
