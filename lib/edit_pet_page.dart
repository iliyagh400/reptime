import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'species_data.dart';
import 'species_picker_page.dart';

class EditPetPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _customSpeciesGroupController;
  late final TextEditingController _breedController;
  late final TextEditingController _genderController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  bool _isLoading = false;

  String? _selectedCategory;
  String? _selectedCategoryEmoji;
  bool _isCustomSpecies = false;

  String get _finalSpeciesGroup {
    if (_isCustomSpecies) return _customSpeciesGroupController.text.trim();
    return _selectedCategory ?? '';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet['name']);
    _breedController = TextEditingController(text: widget.pet['breed']);
    _genderController = TextEditingController(text: widget.pet['gender']);
    _ageController = TextEditingController(text: widget.pet['age']);
    _weightController =
        TextEditingController(text: widget.pet['weight']?.toString() ?? '');

    final currentGroup = widget.pet['species_group'] as String?;
    final matchesKnown =
        speciesCategories.any((c) => c.name == currentGroup);
    if (currentGroup != null && currentGroup.isNotEmpty && matchesKnown) {
      _selectedCategory = currentGroup;
      _selectedCategoryEmoji = emojiForSpeciesGroup(currentGroup);
      _isCustomSpecies = false;
      _customSpeciesGroupController = TextEditingController();
    } else if (currentGroup != null && currentGroup.isNotEmpty) {
      _isCustomSpecies = true;
      _customSpeciesGroupController =
          TextEditingController(text: currentGroup);
    } else {
      _customSpeciesGroupController = TextEditingController();
    }
  }

  Future<void> _openPicker() async {
    final result = await Navigator.push<SpeciesPickResult>(
      context,
      MaterialPageRoute(builder: (context) => const SpeciesPickerPage()),
    );
    if (result == null) return;

    setState(() {
      if (result.isCustom && result.categoryName.isEmpty) {
        _isCustomSpecies = true;
        _selectedCategory = null;
        _selectedCategoryEmoji = null;
      } else if (result.isCustom) {
        _isCustomSpecies = false;
        _selectedCategory = result.categoryName;
        _selectedCategoryEmoji = emojiForSpeciesGroup(result.categoryName);
        _breedController.clear();
      } else {
        _isCustomSpecies = false;
        _selectedCategory = result.categoryName;
        _selectedCategoryEmoji = emojiForSpeciesGroup(result.categoryName);
        _breedController.text = result.speciesName;
      }
    });
  }

  Future<void> _updatePet() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('pets').update({
        'name': _nameController.text.trim(),
        'species_group': _finalSpeciesGroup,
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

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ویرایش حیوان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deletePet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3B679),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _isCustomSpecies
                        ? '✏️'
                        : (_selectedCategoryEmoji ?? defaultSpeciesEmoji),
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ),
            _sectionLabel('مشخصات پایه'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم'),
            ),
            _sectionLabel('نوع/گونه'),
            InkWell(
              onTap: _openPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E8D9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _isCustomSpecies
                          ? '✏️'
                          : (_selectedCategoryEmoji ?? '🔍'),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isCustomSpecies
                            ? otherSpeciesLabel
                            : (_selectedCategory ?? 'انتخاب نوع/گونه'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_left, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (_isCustomSpecies) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customSpeciesGroupController,
                decoration:
                    const InputDecoration(labelText: 'نوع/گروه را بنویس'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: 'گونه/نژاد'),
            ),
            _sectionLabel('جزئیات بیشتر'),
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
            const SizedBox(height: 28),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _updatePet,
                    child: const Text('ذخیره تغییرات'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}