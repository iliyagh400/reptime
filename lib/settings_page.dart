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
  bool _dailySummary = false;
  bool _isLoading = true;

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
      _dailySummary = prefs.getBool('daily_summary') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('یادآورها')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('نوتیفیکیشن سر وقت'),
                  subtitle: const Text('دقیقاً سر ساعت روتین'),
                  value: _onTimeReminders,
                  onChanged: (value) {
                    setState(() => _onTimeReminders = value);
                    _saveSetting('on_time_reminders', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('یادآور کارهای دیرشده'),
                  subtitle: const Text('هر ۳۰ دقیقه تکرار تا انجام'),
                  value: _overdueReminders,
                  onChanged: (value) {
                    setState(() => _overdueReminders = value);
                    _saveSetting('overdue_reminders', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('خلاصه‌ی روزانه'),
                  subtitle: const Text('هر شب ساعت ۲۱:۰۰'),
                  value: _dailySummary,
                  onChanged: (value) {
                    setState(() => _dailySummary = value);
                    _saveSetting('daily_summary', value);
                  },
                ),
              ],
            ),
    );
  }
}