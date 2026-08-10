import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await Supabase.instance.client.from('routines').update({
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
      }).eq('id', widget.routine['id']);

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

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش روتین'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRoutine,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'عنوان'),
            ),
            const SizedBox(height: 16),
            const Text('نوع'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('غذا'),
                  selected: _type == 'food',
                  onSelected: (_) => setState(() => _type = 'food'),
                ),
                ChoiceChip(
                  label: const Text('نظافت'),
                  selected: _type == 'cleaning',
                  onSelected: (_) => setState(() => _type = 'cleaning'),
                ),
                ChoiceChip(
                  label: const Text('دارو'),
                  selected: _type == 'medicine',
                  onSelected: (_) => setState(() => _type = 'medicine'),
                ),
                ChoiceChip(
                  label: const Text('دیگر'),
                  selected: _type == 'other',
                  onSelected: (_) => setState(() => _type = 'other'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('حیوان‌ها'),
            Wrap(
              spacing: 8,
              children: widget.pets.map((pet) {
                final id = pet['id'].toString();
                return FilterChip(
                  label: Text(pet['name'] ?? ''),
                  selected: _selectedPetIds.contains(id),
                  onSelected: (selected) {
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
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration:
                  const InputDecoration(labelText: 'ساعت (مثلاً 08:00)'),
            ),
            const SizedBox(height: 16),
            const Text('نوع تکرار'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('روزانه'),
                  selected: _repeatType == 'daily',
                  onSelected: (_) => setState(() => _repeatType = 'daily'),
                ),
                ChoiceChip(
                  label: const Text('هفتگی'),
                  selected: _repeatType == 'weekly',
                  onSelected: (_) => setState(() => _repeatType = 'weekly'),
                ),
                ChoiceChip(
                  label: const Text('ماهانه'),
                  selected: _repeatType == 'monthly',
                  onSelected: (_) => setState(() => _repeatType = 'monthly'),
                ),
                ChoiceChip(
                  label: const Text('بازه‌ای (هر N روز)'),
                  selected: _repeatType == 'interval',
                  onSelected: (_) => setState(() => _repeatType = 'interval'),
                ),
                ChoiceChip(
                  label: const Text('یک‌بار'),
                  selected: _repeatType == 'once',
                  onSelected: (_) => setState(() => _repeatType = 'once'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_repeatType == 'weekly')
              Wrap(
                spacing: 8,
                children: _weekdayOptions.map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _selectedWeekdays.contains(day),
                    onSelected: (selected) {
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
            if (_repeatType == 'interval')
              TextField(
                controller: _intervalController,
                decoration:
                    const InputDecoration(labelText: 'هر چند روز؟ (مثلاً 5)'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updateRoutine,
                    child: const Text('ذخیره تغییرات'),
                  ),
          ],
        ),
      ),
    );
  }
}