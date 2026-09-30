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

  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _moss = Color(0xFF6E8B52);
  static const _lightMoss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _text = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _line = Color(0xFF3A463C);

  @override
  void initState() {
    super.initState();
    final currentWeight = widget.pet['weight'];
    if (currentWeight != null) {
      _weightController.text = currentWeight.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _normalizeDigitsAndDecimals(String input) {
    var result = input.trim();
    const Map<String, String> digits = {
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    };
    digits.forEach((nonLatin, latin) {
      result = result.replaceAll(nonLatin, latin);
    });
    result = result
        .replaceAll('،', '.')
        .replaceAll(',', '.')
        .replaceAll('/', '.');
    return result;
  }

  Future<void> _save() async {
    if (_isLoading) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ابتدا باید وارد حساب کاربری خود شوید.')),
        );
      }
      return;
    }

    final rawWeight = _weightController.text.trim();
    double? parsedWeight;

    if (rawWeight.isNotEmpty) {
      final normalized = _normalizeDigitsAndDecimals(rawWeight);
      parsedWeight = double.tryParse(normalized);
      if (parsedWeight == null || parsedWeight <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لطفاً وزن معتبر و بزرگتر از صفر وارد کنید.'),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final checkinPayload = {
        'user_id': user.id,
        'pet_id': widget.pet['id'],
        'weight': parsedWeight,
        'health_score': _healthScore,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'checkin_date': DateTime.now().toUtc().toIso8601String(),
      };

      await Supabase.instance.client
          .from('pet_checkins')
          .insert(checkinPayload);

      if (parsedWeight != null) {
        await Supabase.instance.client
            .from('pets')
            .update({'weight': parsedWeight})
            .eq('id', widget.pet['id'])
            .eq('user_id', user.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اطلاعات ثبت شد ✅')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving checkin: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطایی در ثبت اطلاعات رخ داد. لطفاً دوباره تلاش کنید.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _lightMoss, width: 1.5),
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _leaf.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _lightMoss, size: 16),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: _lightMoss,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _petCard() {
    final petName = widget.pet['name'] ?? 'حیوان خانگی';
    final petSpecies = widget.pet['species'] ?? '';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _lightMoss.withValues(alpha: 0.24),
                  _leaf.withValues(alpha: 0.34),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.pets_rounded, color: _moss, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petName,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (petSpecies.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    petSpecies,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: _terracotta, size: 20),
              const SizedBox(width: 8),
              const Text(
                'نمره سلامت',
                style: TextStyle(
                  color: _text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _terracotta.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_healthScore / 10',
                  style: const TextStyle(
                    color: _terracotta,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _lightMoss,
              inactiveTrackColor: _line,
              thumbColor: _sand,
              overlayColor: _lightMoss.withValues(alpha: 0.12),
              trackHeight: 5,
            ),
            child: Slider(
              value: _healthScore.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _healthScore = v.round()),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نیاز به توجه', style: TextStyle(color: _muted, fontSize: 11)),
              Text('وضعیت عالی', style: TextStyle(color: _lightMoss, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _text),
          title: const Text(
            'بروزرسانی حیوان',
            style: TextStyle(
              color: _text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 32),
          children: [
            _petCard(),
            _section('وزن فعلی', Icons.monitor_weight_outlined),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              decoration: _inputDecoration(
                label: 'وزن (گرم)',
                icon: Icons.scale_rounded,
                hint: 'مثلاً 450',
              ),
            ),
            _section('وضعیت سلامت', Icons.favorite_outline_rounded),
            _healthCard(),
            _section('یادداشت', Icons.notes_rounded),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: _inputDecoration(
                label: 'یادداشت وضعیت امروز',
                icon: Icons.edit_note_rounded,
                hint: 'مثلاً پوست‌اندازی، میزان اشتها، رفتار...',
              ),
            ),
            const SizedBox(height: 30),
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_moss, _sand]),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: _moss.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(_background),
                        ),
                      ),
                    )
                  : InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: _save,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: _background, size: 23),
                          SizedBox(width: 9),
                          Text(
                            'ثبت اطلاعات',
                            style: TextStyle(
                              color: _background,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
