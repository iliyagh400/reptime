import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _onTimeReminders = true;
  bool _overdueReminders = true;
  int _overdueIntervalHours = 1;
  bool _dailySummary = false;
  bool _isLoading = true;

  static const _green = Color(0xFF3F5D45);
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

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFC9D0BA)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('یادآورها')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _sectionLabel('یادآور به‌موقع'),
                _card(
                  child: SwitchListTile(
                    activeColor: _green,
                    title: const Text('نوتیفیکیشن سر وقت'),
                    subtitle: const Text('دقیقاً سر ساعت روتین'),
                    value: _onTimeReminders,
                    onChanged: (value) {
                      setState(() => _onTimeReminders = value);
                      _saveBool('on_time_reminders', value);
                    },
                  ),
                ),
                _sectionLabel('کارهای دیرشده'),
                _card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeColor: _green,
                        title: const Text('یادآور کارهای دیرشده'),
                        subtitle: const Text('تا وقتی انجام نشده، تکرار می‌شود'),
                        value: _overdueReminders,
                        onChanged: (value) {
                          setState(() => _overdueReminders = value);
                          _saveBool('overdue_reminders', value);
                        },
                      ),
                      if (_overdueReminders) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'هر چند ساعت یک‌بار یادآوری کند؟',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _hourOptions.map((h) {
                                  final selected =
                                      _overdueIntervalHours == h;
                                  return ChoiceChip(
                                    label: Text(
                                        h == 1 ? 'هر ۱ ساعت' : 'هر $h ساعت'),
                                    selected: selected,
                                    onSelected: (_) {
                                      setState(
                                          () => _overdueIntervalHours = h);
                                      _saveInt('overdue_interval_hours', h);
                                    },
                                    selectedColor: _green,
                                    backgroundColor: const Color(0xFFE4E8D9),
                                    labelStyle: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: BorderSide(
                                      color: selected
                                          ? _green
                                          : const Color(0xFFC9D0BA),
                                    ),
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
                _sectionLabel('خلاصه‌ی روزانه'),
                _card(
                  child: SwitchListTile(
                    activeColor: _green,
                    title: const Text('خلاصه‌ی روزانه'),
                    subtitle: const Text('هر شب ساعت ۲۱:۰۰، جمع‌بندی کارهای امروز'),
                    value: _dailySummary,
                    onChanged: (value) {
                      setState(() => _dailySummary = value);
                      _saveBool('daily_summary', value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'این تنظیمات ذخیره می‌شوند و بعداً به سیستم یادآور وصل خواهند شد.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
    );
  }
}