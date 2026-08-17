import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRoutinePage extends StatefulWidget {
  final List<Map<String, dynamic>> pets;
  final dynamic initialSelectedPetId;
  const AddRoutinePage(
      {super.key, required this.pets, this.initialSelectedPetId});

  @override
  State<AddRoutinePage> createState() => _AddRoutinePageState();
}

class _AddRoutinePageState extends State<AddRoutinePage> {
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  final _intervalController = TextEditingController();

  String _type = 'food';
  String _repeatType = 'daily';
  final Set<String> _selectedWeekdays = {};
  late final Set<String> _selectedPetIds;
  bool _isLoading = false;

  final _weekdayOptions = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const _green = Color(0xFF3F5D45);

  @override
  void initState() {
    super.initState();
    _selectedPetIds = widget.initialSelectedPetId != null
        ? {widget.initialSelectedPetId.toString()}
        : {};
  }

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
        'pet_ids': _selectedPetIds.map((e) => int.parse(e)).toList(),
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
      appBar: AppBar(title: const Text('روتین جدید')),
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
              children: [
                if (widget.pets.length > 1)
                  ActionChip(
                    label: const Text('انتخاب همه'),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: _green),
                    labelStyle: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedPetIds.addAll(
                            widget.pets.map((p) => p['id'].toString()));
                      });
                    },
                  ),
                ...widget.pets.map((pet) {
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
                }),
              ],
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
                    onPressed: _saveRoutine,
                    child: const Text('ذخیره روتین'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}