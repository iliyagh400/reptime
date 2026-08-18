import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class EditRoutinePage extends StatefulWidget {
  final Map<String, dynamic> routine;
  final List<Map<String, dynamic>> pets;
  const EditRoutinePage({super.key, required this.routine, required this.pets});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  late final TextEditingController _intervalController;

  late String _type;
  late String _repeatType;
  late Set<String> _selectedWeekdays;
  late Set<String> _selectedPetIds;
  bool _isLoading = false;

  final _weekdayOptions = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const _green = Color(0xFF3F5D45);

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

  Future<void> _updateRoutine() async {
    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک حیوون انتخاب کن')),
      );
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

      await NotificationService.scheduleRoutineNotifications(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('روتین بروزرسانی شد ✅')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRoutine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف روتین'),
        content: const Text('مطمئنی می‌خوای این روتین رو حذف کنی؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themedChoiceChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _green,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _green : const Color(0xFFC9D0BA)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _themedFilterChip(
      String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      selectedColor: _green,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _green : const Color(0xFFC9D0BA)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش روتین'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteRoutine,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان'),
            ),
            _sectionLabel('نوع'),
            Wrap(
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
            _sectionLabel('حیوان‌ها'),
            Wrap(
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
            _sectionLabel('زمان‌بندی'),
            TextField(
              controller: _timeController,
              decoration:
                  const InputDecoration(labelText: 'ساعت (مثلاً 08:00)'),
            ),
            const SizedBox(height: 14),
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
                _themedChoiceChip(
                    'بازه‌ای (هر N روز)',
                    _repeatType == 'interval',
                    () => setState(() => _repeatType = 'interval')),
                _themedChoiceChip('یک‌بار', _repeatType == 'once',
                    () => setState(() => _repeatType = 'once')),
              ],
            ),
            if (_repeatType == 'weekly') ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _weekdayOptions.map((day) {
                  return _themedFilterChip(
                    day,
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
              const SizedBox(height: 14),
              TextField(
                controller: _intervalController,
                decoration:
                    const InputDecoration(labelText: 'هر چند روز؟ (مثلاً 5)'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 28),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updateRoutine,
                    child: const Text('ذخیره تغییرات'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}