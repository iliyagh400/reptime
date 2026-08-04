import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _nameController = TextEditingController();
  final _speciesGroupController = TextEditingController();
  final _breedController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;

  Future<void> _savePet() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('pets').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'species_group': _speciesGroupController.text.trim(),
        'breed': _breedController.text.trim(),
        'gender': _genderController.text.trim(),
        'age': _ageController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پت با موفقیت ذخیره شد ✅')),
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
      appBar: AppBar(title: const Text('افزودن حیوان')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _speciesGroupController,
              decoration: const InputDecoration(labelText: 'نوع/گروه'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: 'گونه/نژاد'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: 'جنسیت'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'سن'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'وزن (گرم)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _savePet,
                    child: const Text('ذخیره'),
                  ),
          ],
        ),
      ),
    );
  }
}