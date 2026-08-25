import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCheckinPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const AddCheckinPage({super.key, required this.pet});

  @override
  State<AddCheckinPage> createState() => _AddCheckinPageState();
}

class _AddCheckinPageState extends State<AddCheckinPage> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  int _healthScore = 8;
  bool _isLoading = false;

  static const _green = Color(0xFF3F5D45);

  @override
  void initState() {
    super.initState();
    final currentWeight = widget.pet['weight'];
    if (currentWeight != null) {
      _weightController.text = currentWeight.toString();
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final weight = double.tryParse(_weightController.text.trim());

      await Supabase.instance.client.from('pet_checkins').insert({
        'user_id': userId,
        'pet_id': widget.pet['id'],
        'weight': weight,
        'health_score': _healthScore,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'checkin_date': DateTime.now().toIso8601String(),
      });

      // Keep the pet's main weight field in sync with the latest check-in
      // so the rest of the app (forms, etc.) shows the current value.
      if (weight != null) {
        await Supabase.instance.client
            .from('pets')
            .update({'weight': weight}).eq('id', widget.pet['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اطلاعات ثبت شد ✅')),
        );
        Navigator.pop(context, true);
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
      appBar:
          AppBar(title: Text('بروزرسانی ${widget.pet['name'] ?? ''}')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'وزن (گرم)'),
            ),
            const SizedBox(height: 24),
            Text(
              'نمره‌ی سلامت: $_healthScore از 10',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Slider(
              value: _healthScore.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: _green,
              label: '$_healthScore',
              onChanged: (value) {
                setState(() => _healthScore = value.round());
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'یادداشت (اختیاری)',
                hintText: 'مثلاً: اشتهاش خوبه، فعاله',
              ),
            ),
            const SizedBox(height: 28),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _save,
                    child: const Text('ثبت'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}