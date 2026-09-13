import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'species_data.dart';
import 'species_picker_page.dart';
import 'notification_service.dart';

class EditPetPage extends StatefulWidget {
  final Map<String, dynamic> pet;

  const EditPetPage({
    super.key,
    required this.pet,
  });

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
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

  late final TextEditingController _nameController;
  late final TextEditingController _customSpeciesGroupController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _morphController;

  int? _selectedGender;
  int _selectedAgeYears = 0;
  int _selectedAgeMonths = 0;

  DateTime? _birthDate;
  bool _isLoading = false;
  bool _isCustomSpecies = false;

  String? _selectedCategory;
  String? _selectedCategoryEmoji;
  String? _selectedSpeciesImage;

  String get _finalSpeciesGroup {
    if (_isCustomSpecies) {
      return _customSpeciesGroupController.text.trim();
    }

    return _selectedCategory ?? '';
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.pet['name']?.toString() ?? '',
    );

    _breedController = TextEditingController(
      text: widget.pet['breed']?.toString() ?? '',
    );

    _ageController = TextEditingController(
      text: widget.pet['age']?.toString() ?? '',
    );

    _weightController = TextEditingController(
      text: widget.pet['weight']?.toString() ?? '',
    );
    _morphController = TextEditingController(
      text: (widget.pet['morph'] as String?) ?? '',
    );

    _customSpeciesGroupController = TextEditingController();

    final gender = widget.pet['gender'];
    if (gender is int) {
      _selectedGender = gender;
    } else {
      _selectedGender = int.tryParse(gender?.toString() ?? '');
    }

    final currentGroup = widget.pet['species_group']?.toString() ?? '';

    final knownCategory = speciesCategories.any(
      (category) => category.name == currentGroup,
    );

    if (currentGroup.isNotEmpty && knownCategory) {
      _selectedCategory = currentGroup;
      _selectedCategoryEmoji = emojiForSpeciesGroup(currentGroup);
      _isCustomSpecies = false;

      final breed = _breedController.text.trim();
      if (breed.isNotEmpty) {
        _selectedSpeciesImage = imagePathForBreed(breed);
      }
    } else if (currentGroup.isNotEmpty) {
      _isCustomSpecies = true;
      _customSpeciesGroupController.text = currentGroup;
    }

    _birthDate = _parseBirthDate(widget.pet['birthDate']);

    if (_birthDate != null) {
      final age = _calculateAgeParts(_birthDate!);
      _selectedAgeYears = age.$1;
      _selectedAgeMonths = age.$2;
      _ageController.text = _calculateAge(_birthDate!);
    } else {
      final ageText = widget.pet['age']?.toString() ?? '';
      final age = _parseAgeText(ageText);

      _selectedAgeYears = age.$1;
      _selectedAgeMonths = age.$2;

      if (_selectedAgeYears > 0 || _selectedAgeMonths > 0) {
        _updateBirthDate();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customSpeciesGroupController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;

    return DateTime(year, month, day);
  }

  (int, int) _calculateAgeParts(DateTime birthDate) {
    final now = DateTime.now();

    var totalMonths =
        (now.year - birthDate.year) * 12 +
        now.month -
        birthDate.month;

    if (now.day < birthDate.day) {
      totalMonths--;
    }

    if (totalMonths < 0) {
      totalMonths = 0;
    }

    return (totalMonths ~/ 12, totalMonths % 12);
  }

  (int, int) _parseAgeText(String text) {
    final yearsMatch = RegExp(r'(\d+)\s*سال').firstMatch(text);
    final monthsMatch = RegExp(r'(\d+)\s*ماه').firstMatch(text);

    final years = int.tryParse(yearsMatch?.group(1) ?? '') ?? 0;
    final months = int.tryParse(monthsMatch?.group(1) ?? '') ?? 0;

    return (years, months);
  }

  String _calculateAge(DateTime birthDate) {
    final parts = _calculateAgeParts(birthDate);
    final years = parts.$1;
    final months = parts.$2;

    if (years == 0 && months == 0) {
      return 'کمتر از یک ماه';
    }

    if (years == 0) {
      return '$months ماه';
    }

    if (months == 0) {
      return '$years سال';
    }

    return '$years سال و $months ماه';
  }

  void _updateBirthDate() {
    final totalMonths =
        (_selectedAgeYears * 12) + _selectedAgeMonths;

    _birthDate = _subtractMonths(
      DateTime.now(),
      totalMonths,
    );

    _ageController.text = _calculateAge(_birthDate!);
  }

  Future<void> _openPicker() async {
    final result = await Navigator.push<SpeciesPickResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const SpeciesPickerPage(),
      ),
    );

    if (result == null) return;

    setState(() {
      if (result.isCustom && result.categoryName.isEmpty) {
        _isCustomSpecies = true;
        _selectedCategory = null;
        _selectedCategoryEmoji = null;
        _selectedSpeciesImage = null;
        _breedController.clear();
      } else if (result.isCustom) {
        _isCustomSpecies = false;
        _selectedCategory = result.categoryName;
        _selectedCategoryEmoji =
            emojiForSpeciesGroup(result.categoryName);
        _selectedSpeciesImage = null;
        _breedController.clear();
      } else {
        _isCustomSpecies = false;
        _selectedCategory = result.categoryName;
        _selectedCategoryEmoji =
            emojiForSpeciesGroup(result.categoryName);
        _breedController.text = result.speciesName;
        _selectedSpeciesImage =
            imagePathForBreed(result.speciesName);
      }
    });
  }

  Future<void> _updatePet() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    _updateBirthDate();

    try {
      await Supabase.instance.client.from('pets').update({
        'name': _nameController.text.trim(),
        'species_group': _finalSpeciesGroup,
        'breed': _breedController.text.trim(),
        'gender': _selectedGender,
        'age': _ageController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
        'morph': _morphController.text.trim(),
        'birthDate': _birthDate?.toIso8601String(),
      }).eq('id', widget.pet['id']);

      if (!mounted) return;

      _showSnack('تغییرات ذخیره شد ✅');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnack('خطا: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'حذف حیوان',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          content: const Text(
            'مطمئنی می‌خوای این حیوون رو حذف کنی؟',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _muted,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'انصراف',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
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
        );
      },
    );

    if (confirm != true) return;

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;
      final petId = widget.pet['id'];

      final response = await client
          .from('routines')
          .select()
          .eq('user_id', userId);

      final routines = List<Map<String, dynamic>>.from(response);

      for (final routine in routines) {
        final petIds = List<dynamic>.from(routine['pet_ids'] ?? []);

        if (!petIds.contains(petId)) continue;

        petIds.remove(petId);

        if (petIds.isEmpty) {
          await client
              .from('routines')
              .delete()
              .eq('id', routine['id']);

          await NotificationService.cancelRoutineNotifications(
            routine['id'],
          );
        } else {
          await client
              .from('routines')
              .update({'pet_ids': petIds})
              .eq('id', routine['id']);
        }
      }

      await client
          .from('completions')
          .delete()
          .eq('pet_id', petId);

      await client
          .from('pet_events')
          .delete()
          .eq('pet_id', petId);

      await client
          .from('pets')
          .delete()
          .eq('id', petId);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('خطا: $e', isError: true);
      }
    }
  }

  void _showSnack(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFF5A2B28) : _surfaceRaised,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _genderIcon(int? gender) {
    switch (gender) {
      case 1:
        return const Icon(
          Icons.male,
          color: Colors.blueAccent,
          size: 22,
        );
      case 2:
        return const Icon(
          Icons.female,
          color: Colors.pinkAccent,
          size: 22,
        );
      case 0:
        return const Icon(
          Icons.help_outline_rounded,
          color: _muted,
          size: 22,
        );
      default:
        return const Icon(
          Icons.wc_rounded,
          color: _muted,
          size: 20,
        );
    }
  }

  Widget _genderOption({
    required int value,
    required String title,
  }) {
    return Row(
      children: [
        _genderIcon(value),
        const SizedBox(width: 10),
        Text(title),
      ],
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<int>(
      value: _selectedGender,
      isExpanded: true,
      dropdownColor: _inputBg,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _muted,
      ),
      style: const TextStyle(
        color: _ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration('جنسیت'),
      items: const [
        DropdownMenuItem(
          value: 1,
          child: Text('نر'),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text('ماده'),
        ),
        DropdownMenuItem(
          value: 0,
          child: Text('نامشخص'),
        ),
      ],
      selectedItemBuilder: (context) {
        return [
          _genderOption(value: 1, title: 'نر'),
          _genderOption(value: 2, title: 'ماده'),
          _genderOption(value: 0, title: 'نامشخص'),
        ];
      },
      onChanged: (value) {
        setState(() => _selectedGender = value);
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
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
      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _line.withOpacity(.78),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _forest,
          width: 1.5,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildAgeDropdown({
    required String label,
    required IconData icon,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      dropdownColor: _inputBg,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _muted,
      ),
      style: const TextStyle(
        color: _ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: _inputDecoration(label).copyWith(
        prefixIcon: Icon(
          icon,
          color: _muted,
          size: 21,
        ),
      ),
      items: items,
      onChanged: onChanged,
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
      decoration: _inputDecoration(label).copyWith(
        prefixIcon: Icon(
          icon,
          color: _muted,
          size: 20,
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
              letterSpacing: .3,
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
        border: Border.all(
          color: _line.withOpacity(.78),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSpeciesTile() {
    final emoji = _isCustomSpecies
        ? '✏️'
        : (_selectedCategoryEmoji ?? '🔍');

    final label = _isCustomSpecies
        ? otherSpeciesLabel
        : (_selectedCategory ?? 'انتخاب نوع/گونه');

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _openPicker,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _line.withOpacity(.78),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _leaf.withOpacity(.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: _muted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
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
            'ویرایش حیوان',
            style: TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'حذف حیوان',
              onPressed: _deletePet,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: _danger,
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _leaf,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _line.withOpacity(.78),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF080D09)
                            .withOpacity(.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _selectedSpeciesImage != null
                      ? Image.asset(
                          _selectedSpeciesImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _selectedCategoryEmoji ??
                                    defaultSpeciesEmoji,
                                style: const TextStyle(fontSize: 42),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _isCustomSpecies
                                ? '✏️'
                                : (_selectedCategoryEmoji ??
                                    defaultSpeciesEmoji),
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  _nameController.text.trim().isEmpty
                      ? 'حیوان خانگی'
                      : _nameController.text.trim(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              _sectionLabel('مشخصات پایه'),

              _card(
                child: _buildField(
                  controller: _nameController,
                  label: 'اسم',
                  icon: Icons.pets_rounded,
                ),
              ),

              _sectionLabel('نوع/گونه'),

              _buildSpeciesTile(),

              if (_isCustomSpecies) ...[
                const SizedBox(height: 12),
                _buildField(
                  controller: _customSpeciesGroupController,
                  label: 'نوع/گروه را بنویس',
                  icon: Icons.edit_rounded,
                ),
              ],

              const SizedBox(height: 12),

              _buildField(
                controller: _breedController,
                label: 'گونه/نژاد',
                icon: Icons.science_outlined,
              ),

              _sectionLabel('جزئیات بیشتر'),

              _card(
                child: Column(
                  children: [
                    _buildGenderField(),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildAgeDropdown(
                            label: 'سال',
                            icon: Icons.cake_rounded,
                            value: _selectedAgeYears,
                            items: List.generate(
                              31,
                              (index) => DropdownMenuItem<int>(
                                value: index,
                                child: Text('$index سال'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedAgeYears = value;
                                _updateBirthDate();
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _buildAgeDropdown(
                            label: 'ماه',
                            icon: Icons.calendar_month_rounded,
                            value: _selectedAgeMonths,
                            items: List.generate(
                              12,
                              (index) => DropdownMenuItem<int>(
                                value: index,
                                child: Text('$index ماه'),
                              ),
                            ),
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _selectedAgeMonths = value;
                                _updateBirthDate();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: _weightController,
                      label: 'وزن (گرم)',
                      icon: Icons.monitor_weight_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    _buildField(
                      controller: _morphController,
                      label: 'مورف',
                      icon: Icons.auto_awesome_rounded,
                    ),
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
                        onPressed: _updatePet,
                        style: FilledButton.styleFrom(
                          backgroundColor: _terracotta,
                          foregroundColor: const Color(0xFF171B17),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        icon: const Icon(
                          Icons.save_rounded,
                          size: 20,
                        ),
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
