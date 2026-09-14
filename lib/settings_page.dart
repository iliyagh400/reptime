import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // پالت رنگی تراریوم شب
  static const Color _cream = Color(0xFF141C17);
  static const Color _surface = Color(0xFF263229);
  static const Color _ink = Color(0xFFECE8DD);
  static const Color _muted = Color(0xFFA8A99A);
  static const Color _terracotta = Color(0xFFB86F4D);
  static const Color _line = Color(0xFF3A463C);

  bool _onTimeReminders = true;
  bool _overdueReminders = true;
  int _overdueIntervalHours = 1;
  bool _dailySummary = false;
  bool _isLoading = true;

  final List<int> _hourOptions = [1, 2, 3, 6, 12];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onTimeReminders = prefs.getBool('on_time_reminders') ?? true;
      _overdueReminders = prefs.getBool('overdue_reminders') ?? true;
      _overdueIntervalHours = prefs.getInt('overdue_interval_hours') ?? 1;
      _dailySummary = prefs.getBool('daily_summary') ?? false;
      _isLoading = false;
    });
  }

  // ویجت‌های استاندارد طراحی
  Widget _buildSectionLabel(String text) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      sliver: SliverToBoxAdapter(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _muted,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line.withOpacity(.78)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream, // پس‌زمینه اصلی تراریوم
        appBar: AppBar(
          backgroundColor: _cream,
          elevation: 0,
          title: const Text('تنظیمات یادآور', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
          iconTheme: const IconThemeData(color: _ink),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _terracotta))
            : CustomScrollView(
                slivers: [
                  _buildSectionLabel('یادآور به‌موقع'),
                  _buildCard(
                    child: SwitchListTile(
                      activeColor: _terracotta,
                      title: const Text('نوتیفیکیشن سر وقت', style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                      subtitle: const Text('دقیقاً سر ساعت روتین', style: TextStyle(color: _muted)),
                      value: _onTimeReminders,
                      onChanged: (value) async {
                        setState(() => _onTimeReminders = value);
                        await _saveBool('on_time_reminders', value);
                        await _applyOnTimeReminderSetting(value);
                      },
                    ),
                  ),

                  _buildSectionLabel('کارهای دیرشده'),
                  _buildCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeColor: _terracotta,
                          title: const Text('یادآور کارهای دیرشده', style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                          subtitle: const Text('تکرار تا انجام کار', style: TextStyle(color: _muted)),
                          value: _overdueReminders,
                          onChanged: (value) async {
                            setState(() => _overdueReminders = value);
                            await _saveBool('overdue_reminders', value);
                            await _applyOverdueReminderSetting(value);
                          },
                        ),
                        if (_overdueReminders) ...[
                          Divider(color: _line.withOpacity(.5), height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('بازه تکرار (ساعت)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: _hourOptions.map((h) {
                                    final selected = _overdueIntervalHours == h;
                                    return ChoiceChip(
                                      label: Text(h == 1 ? 'هر ۱ ساعت' : 'هر $h ساعت'),
                                      selected: selected,
                                      onSelected: (_) async {
                                        setState(() => _overdueIntervalHours = h);
                                        await _saveInt('overdue_interval_hours', h);
                                        if (_overdueReminders) {
                                          await _refreshAllOverdueReminders();
                                        }
                                      },
                                      selectedColor: _terracotta,
                                      backgroundColor: _cream,
                                      labelStyle: TextStyle(color: selected ? _ink : _muted, fontWeight: FontWeight.w700),
                                      side: BorderSide(color: selected ? _terracotta : _line),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  _buildSectionLabel('خلاصه‌ی روزانه'),
                  _buildCard(
                    child: SwitchListTile(
                      activeColor: _terracotta,
                      title: const Text('خلاصه‌ی روزانه', style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                      subtitle: const Text('ساعت ۲۱:۰۰، جمع‌بندی امروز', style: TextStyle(color: _muted)),
                      value: _dailySummary,
                      onChanged: (value) async {
                        setState(() => _dailySummary = value);
                        await _saveBool('daily_summary', value);
                        await NotificationService.updateDailySummaryNotification();
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadActiveRoutines() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('routines')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _loadUserPets() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('pets')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _applyOnTimeReminderSetting(bool enabled) async {
    try {
      final routines = await _loadActiveRoutines();

      if (!enabled) {
        for (final routine in routines) {
          await NotificationService.cancelRoutineNotifications(routine['id']);
        }
        return;
      }

      final pets = await _loadUserPets();

      for (final routine in routines) {
        final petIds = List.from(routine['pet_ids'] ?? []);
        final petNames = pets
            .where((pet) => petIds.contains(pet['id']))
            .map((pet) => (pet['name'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList();

        await NotificationService.scheduleRoutineNotifications(
          routine,
          petNames: petNames,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('اعلان‌ها بروزرسانی نشدند', isError: true);
      }
    }
  }

  Future<void> _applyOverdueReminderSetting(bool enabled) async {
    try {
      if (!enabled) {
        final routines = await _loadActiveRoutines();
        for (final routine in routines) {
          await NotificationService.cancelOverdueReminders(routine['id']);
        }
        return;
      }

      await _refreshAllOverdueReminders();
    } catch (e) {
      if (mounted) {
        _showSnack('یادآورهای دیرشده بروزرسانی نشدند', isError: true);
      }
    }
  }

  // این نسخه اصلاح شده بر اساس ساختار تابع شما در سرویس است
Future<void> _refreshAllOverdueReminders() async {
  try {
    // فرض می‌کنیم لیست روتین‌ها را از جایی می‌خوانید
    // اگر لیست را از قبل دارید، آن را مستقیماً اینجا قرار دهید
    List<Map<String, dynamic>> routinesToProcess = []; 
    
    // گرفتن داده‌ها از سوپابیس (مثال)
    // routinesToProcess = await supabase.from('routines').select()... 

    if (routinesToProcess.isNotEmpty) {
      // فقط و فقط یک پارامتر می‌فرستیم: لیست روتین‌ها
      await NotificationService.refreshOverdueReminders(routinesToProcess);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}


  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFF5A2B28) : _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _saveBool(String key, bool value) async => (await SharedPreferences.getInstance()).setBool(key, value);
  Future<void> _saveInt(String key, int value) async => (await SharedPreferences.getInstance()).setInt(key, value);
}
