import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_pet_page.dart';
import 'pet_profile_page.dart';
import 'add_routine_page.dart';
import 'notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('pets')
        .select()
        .eq('user_id', userId);

    setState(() {
      _pets = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('حیوانات من'),
          actions: [
IconButton(
  icon: const Icon(Icons.bug_report),
  onPressed: () async {
    print('دکمه زده شد!');
    final now = DateTime.now().add(const Duration(minutes: 1));
    print('زمان الان: ${DateTime.now()} - زمان‌بندی برای: $now');
    try {
      await NotificationService.scheduleDailyNotification(
        id: 999,
        title: 'تست زمان‌بندی',
        body: 'این باید یک دقیقه دیگه بیاد ✅',
        hour: now.hour,
        minute: now.minute,
      );
      print('زمان‌بندی با موفقیت انجام شد ✅');
    } catch (e) {
      print('خطا در زمان‌بندی: $e');
    }
  },
),
  IconButton(
    icon: const Icon(Icons.alarm_add),
    onPressed: _pets.isEmpty
        ? null
        : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddRoutinePage(pets: _pets),
              ),
            );
          },
  ),
],
          ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(child: Text('هنوز حیوونی اضافه نکردی'))
              : ListView.builder(
                  itemCount: _pets.length,
                  itemBuilder: (context, index) {
                    final pet = _pets[index];
                   return ListTile(
                      title: Text(pet['name'] ?? ''),
                      subtitle: Text(pet['breed'] ?? ''),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PetProfilePage(pet: pet)),
                        );
                        _loadPets();
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetPage()),
          );
          _loadPets(); // بعد از برگشت، لیست رو دوباره بخون
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}