import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'species_data.dart';
import 'species_picker_page.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final _nameController = TextEditingController();
  final _customSpeciesGroupController = TextEditingController();
  final _breedController = TextEditingController();
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;

  String? _selectedCategory; // category name, or null if not picked yet
  String? _selectedCategoryEmoji;
  bool _isCustomSpecies = false;

  static const _green = Color(0xFF3F5D45);

  String get _finalSpeciesGroup {
    if (_isCustomSpecies) return _customSpeciesGroupController.text.trim();
    return _selectedCategory ?? '';
  }

  Future<void> _openPicker() async {
    final result = await Navigator.push<SpeciesPickResult>(
      context,
      MaterialPageRoute(builder: (context) => const SpeciesPickerPage()),
    );
    if (result == null) return;

    setState(() {
      if (result.isCustom && result.categoryName.isEmpty) {
        // Fully custom: no matching category at all.
        _isCustomSpecies = true;
        _selectedCategory = null;
        _selectedCategoryEmoji = null;
      } else if (result.isCustom) {
        // Known category, but the specific species isn't in the list —
        // keep the category, let the user type the species in the
        // existing breed field.
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

  Future<void> _savePet() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('pets').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'species_group': _finalSpeciesGroup,
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
      appBar: AppBar(title: const Text('افزودن حیوان')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ListView(
          children: [
            const SizedBox(height: 12),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (_selectedCategory == null &&
                                  !_isCustomSpecies)
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
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
                    onPressed: _savePet,
                    child: const Text('ذخیره'),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}