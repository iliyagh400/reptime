import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRoutinePage extends StatefulWidget {
  final List<Map<String, dynamic>> pets;
  const AddRoutinePage({super.key, required this.pets});

  @override
  State<AddRoutinePage> createState() => _AddRoutinePageState();
}

class _AddRoutinePageState extends State<AddRoutinePage> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _intervalController = TextEditingController();

  String _type = 'food'; // food, cleaning, medicine, other
  String _repeatType = 'daily'; // daily, weekly, monthly, interval, once
  final Set<String> _selectedWeekdays = {};
  final Set<String> _selectedPetIds = {};
  bool _isLoading = false;

  final _weekdayOptions = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  Future<void> _saveRoutine() async {
    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک حیوون انتخاب کن')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('routines').insert({
        'user_id': userId,
        'title': _titleController.text.trim(),
        'type': _type,
        'pet_ids': _selectedPetIds.toList(),
        'time': _timeController.text.trim(),
        'repeat_type': _repeatType,
        'weekdays':
            _repeatType == 'weekly' ? _selectedWeekdays.toList() : null,
        'interval_days': _repeatType == 'interval'
            ? int.tryParse(_intervalController.text.trim())
            : null,
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('روتین ذخیره شد ✅')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('روتین جدید')),
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

            // فیلد اضافه بر اساس نوع تکرار
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
                    onPressed: _saveRoutine,
                    child: const Text('ذخیره روتین'),
                  ),
          ],
        ),
      ),
    );
  }
}