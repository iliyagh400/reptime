import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'species_data.dart';
import 'species_picker_page.dart';

/// Premium redesigned AddPetPage.
///
/// The existing Supabase insert, species-picker flow and navigation are
/// preserved. This file focuses on presentation, hierarchy, spacing and
/// interaction design, matching the dark terrarium style of HomePage.
class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  // Dark Terrarium palette — visual styling only.
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _forest = Color(0xFF6E8B52);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _terracotta = Color(0xFFB86F4D);
  static const _leaf = Color(0xFF486344);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
  static const _inputBg = Color(0xFF1C2621);

  final _nameController = TextEditingController();
  final _customSpeciesGroupController = TextEditingController();
  final _breedController = TextEditingController();
  final _morphController = TextEditingController();
  int? _selectedGender;
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;
  int _selectedAgeYears = 0;
  int _selectedAgeMonths = 0; 
  DateTime? _birthDate;


  String? _selectedCategory; // category name, or null if not picked yet
  String? _selectedCategoryEmoji;
  String? _selectedSpeciesImage;
  bool _isCustomSpecies = false;

  String get _finalSpeciesGroup {
    if (_isCustomSpecies) return _customSpeciesGroupController.text.trim();
    return _selectedCategory ?? '';
  }
  DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + date.month - 1 - months;

    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;

    final lastDayOfMonth = DateTime(year, month + 1, 0).day;

    final day = date.day > lastDayOfMonth
        ? lastDayOfMonth
        : date.day;

    return DateTime(year, month, day);
  }
  @override
  void dispose() {
    _nameController.dispose();
    _customSpeciesGroupController.dispose();
    _breedController.dispose();
    _morphController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int totalMonths =
        (now.year - birthDate.year) * 12 +
        now.month -
        birthDate.month;
    if (now.day < birthDate.day) {
      totalMonths--;}
    if (totalMonths < 0) {
      totalMonths = 0;}
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (years == 0 && months == 0) {
      return 'کمتر از یک ماه';}
    if (years == 0) {
      return '$months ماه';}
    if (months == 0) {
      return '$years سال';}
    return '$years سال و $months ماه';}

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
    // نوع و گونه کاملاً سفارشی
    _isCustomSpecies = true;
    _selectedCategory = null;
    _selectedCategoryEmoji = null;
    _selectedSpeciesImage = null;
    _breedController.clear();
  } else if (result.isCustom) {
    // دسته مشخص است، اما گونه سفارشی است
    _isCustomSpecies = false;
    _selectedCategory = result.categoryName;
    _selectedCategoryEmoji = emojiForSpeciesGroup(result.categoryName);

    // ✅ اصلاح شد: حالا به جای null، آیکون پیش‌فرض دسته را نمایش می‌دهیم
    _selectedSpeciesImage = defaultImagePathForGroup(result.categoryName);
    
    _breedController.clear();
  } else {
    // گونه شناخته‌شده انتخاب شده است
    _isCustomSpecies = false;
    _selectedCategory = result.categoryName;
    _selectedCategoryEmoji = emojiForSpeciesGroup(result.categoryName);

    _breedController.text = result.speciesName;

    // پیدا کردن تصویر بر اساس نام گونه
    _selectedSpeciesImage = imagePathForBreed(result.speciesName);
  }
});
;
}


  Future<void> _savePet() async {
    setState(() => _isLoading = true);
    _updateBirthDate();
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await Supabase.instance.client.from('pets').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'species_group': _finalSpeciesGroup,
        'breed': _breedController.text.trim(),
        'morph': _morphController.text.trim(),
        'gender': _selectedGender,
        'age': _ageController.text.trim(),
        'weight': double.tryParse(_weightController.text.trim()),
        'birthDate': _birthDate?.toIso8601String(),
        // 'ageYears': _selectedAgeYears,
        // 'ageMonths': _selectedAgeMonths,
      });

      if (mounted) {
        _showSnack('پت با موفقیت ذخیره شد ✅');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('خطا: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFF5A2B28) : _surfaceRaised,
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
    decoration: InputDecoration(
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
      prefixIcon: Icon(
        icon,
        color: _muted,
        size: 21,
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
          color: _line.withValues(alpha: .78),
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
    ),
    items: items,
    onChanged: onChanged,
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
    decoration: InputDecoration(
      labelText: 'جنسیت',
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: _forest,
        fontWeight: FontWeight.w600,
      ),

      // آیکون این قسمت بعد از انتخاب، بر اساس جنسیت تغییر می‌کند
      // prefixIcon: _genderIcon(_selectedGender),

      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _line.withOpacity(.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _forest,
          width: 1.6,
        ),
      ),
    ),
    items: [
      DropdownMenuItem<int>(
        value: 1,
        child: _genderOption(
          value: 1,
          title: 'نر',
        ),
      ),
      DropdownMenuItem<int>(
        value: 2,
        child: _genderOption(
          value: 2,
          title: 'ماده',
        ),
      ),
      DropdownMenuItem<int>(
        value: 0,
        child: _genderOption(
          value: 0,
          title: 'نامشخص',
        ),
      ),
    ],
    onChanged: (value) {
      setState(() {
        _selectedGender = value;
      });
    },
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
              letterSpacing: 0.3,
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
        border: Border.all(color: _line.withOpacity(.78)),
      ),
      child: child,
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
      decoration: InputDecoration(
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
        prefixIcon: Icon(icon, color: _muted, size: 20),
        filled: true,
        fillColor: _inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _line.withOpacity(.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _forest, width: 1.6),
        ),
      ),
    );
  }
  Widget _buildSpeciesTile() {
    // تشخیص اینکه چه چیزی باید نمایش داده شود:
    // 1. اگر تصویر انتخابی وجود دارد -> تصویر PNG
    // 2. اگر در حالت سفارشی است و تصویری نیست -> ایموجی مداد ✏️
    // 3. در غیر این صورت -> ایموجی گروه
    final String emoji = _isCustomSpecies ? '✏️' : (_selectedCategoryEmoji ?? '🔍');
    final bool isPlaceholder = _selectedCategory == null && !_isCustomSpecies;
    final String label = _isCustomSpecies
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPlaceholder
                  ? _terracotta.withOpacity(.7)
                  : _line.withOpacity(.78),
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
                clipBehavior: Clip.antiAlias, // برای اینکه تصویر از لبه‌ها بیرون نزند
                child: Center(
                  // --- بخش اصلی تغییر: نمایش تصویر به جای متن ---
                  child: _selectedSpeciesImage != null
                      ? Image.asset(
                          _selectedSpeciesImage!,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // اگر تصویر پیدا نشد، به ایموجی سوئیچ کن
                            return Text(emoji, style: const TextStyle(fontSize: 18));
                          },
                        )
                      : Text(emoji, style: const TextStyle(fontSize: 18)),
                  // ------------------------------------------
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPlaceholder ? _muted : _ink,
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
          'افزودن حیوان',
          style: TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
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
                      color: _line.withValues(alpha: .78),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF080D09).withValues(alpha: .45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _selectedSpeciesImage != null
                      ? Image.asset(
                          _selectedSpeciesImage!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _selectedCategoryEmoji ?? defaultSpeciesEmoji,
                                style: const TextStyle(fontSize: 42),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            _isCustomSpecies
                                ? '✏️'
                                : (_selectedCategoryEmoji ?? defaultSpeciesEmoji),
                            style: const TextStyle(fontSize: 42),
                          ),
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

            const SizedBox(height: 12),

            _buildField(
              controller: _morphController,
              label: 'مورف',
              icon: Icons.auto_awesome_rounded,
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
                      onPressed: _savePet,
                      style: FilledButton.styleFrom(
                        backgroundColor: _terracotta,
                        foregroundColor: const Color(0xFF171B17),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(17),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'ذخیره',
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