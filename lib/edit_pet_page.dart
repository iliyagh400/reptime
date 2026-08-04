import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditPetPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _speciesGroupController;
  late final TextEditingController _breedController;
  late final TextEditingController _genderController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet['name']);
    _speciesGroupController =
        TextEditingController(text: widget.pet['species_group']);
    _breedController = TextEditingController(text: widget.pet['breed']);
    _genderController = TextEditingController(text: widget.pet['gender']);
    _ageController = TextEditingController(text: widget.pet['age']);
    _weightController =
        TextEditingController(text: widget.pet['weight']?.toString() ?? '');
  }

  Future<void> _updatePet() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('pets').update({
        'name': _nameController.text.trim(),
        'species_group': _speciesGroupController.text.trim(),
        'breed': _breedController.text.trim(),
        'gender': _genderController.text.trim(),
        'age': _ageController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
      }).eq('id', widget.pet['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تغییرات ذخیره شد ✅')),
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

  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف حیوان'),
        content: const Text('مطمئنی می‌خوای این حیوون رو حذف کنی؟'),
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
          .from('pets')
          .delete()
          .eq('id', widget.pet['id']);

      if (mounted) {
        Navigator.pop(context);
      }
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
        title: const Text('ویرایش حیوان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePet,
          ),
        ],
      ),
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
                    onPressed: _updatePet,
                    child: const Text('ذخیره تغییرات'),
                  ),
          ],
        ),
      ),
    );
  }
}