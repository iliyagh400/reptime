import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_pet_page.dart';
import 'pet_profile_page.dart';
import 'add_routine_page.dart';
import 'notification_service.dart';
import 'settings_page.dart';
import 'routine_logic.dart';

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

  Future<Map<String, int>> _todayTaskStatus(dynamic petId) async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final routinesResponse = await Supabase.instance.client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true);

    final allRoutines = List<Map<String, dynamic>>.from(routinesResponse);
    final petRoutines = allRoutines.where((r) {
      final ids = List.from(r['pet_ids'] ?? []);
      return ids.contains(petId);
    }).toList();

    final completionsResponse = await Supabase.instance.client
        .from('completions')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', petId)
        .eq('status', 'done');

    final completions = List<Map<String, dynamic>>.from(completionsResponse);

    int total = 0;
    int done = 0;

    for (final routine in petRoutines) {
      if (isRelevantToday(routine, completions)) {
        total++;
        if (isDoneToday(routine, completions)) {
          done++;
        }
      }
    }

    return {'total': total, 'done': done};
  }

  Future<Map<String, int>> _overallTodayStatus() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final routinesResponse = await Supabase.instance.client
        .from('routines')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true);

    final allRoutines = List<Map<String, dynamic>>.from(routinesResponse);

    final completionsResponse = await Supabase.instance.client
        .from('completions')
        .select()
        .eq('user_id', userId)
        .eq('status', 'done');

    final allCompletions = List<Map<String, dynamic>>.from(completionsResponse);

    int total = 0;
    int done = 0;

    for (final routine in allRoutines) {
      final petIds = List.from(routine['pet_ids'] ?? []);
      for (final petId in petIds) {
        final petCompletions =
            allCompletions.where((c) => c['pet_id'] == petId).toList();
        if (isRelevantToday(routine, petCompletions)) {
          total++;
          if (isDoneToday(routine, petCompletions)) {
            done++;
          }
        }
      }
    }

    return {'total': total, 'done': done};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPTIME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              final now = DateTime.now().add(const Duration(minutes: 1));
              try {
                await NotificationService.scheduleDailyNotification(
                  id: 999,
                  title: 'تست زمان‌بندی',
                  body: 'این باید یک دقیقه دیگه بیاد ✅',
                  hour: now.hour,
                  minute: now.minute,
                );
              } catch (e) {
                // ignore
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? const Center(child: Text('هنوز حیوونی اضافه نکردی'))
              : Column(
                  children: [
                    FutureBuilder<Map<String, int>>(
                      future: _overallTodayStatus(),
                      builder: (context, snapshot) {
                        final total = snapshot.data?['total'] ?? 0;
                        final done = snapshot.data?['done'] ?? 0;
                        final remaining = total - done;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F5D45),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            total == 0
                                ? 'امروز کاری ثبت نشده'
                                : remaining == 0
                                    ? 'همه‌ی کارهای امروز انجام شد 🎉'
                                    : 'امروز $remaining کار مونده از $total کار',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pets.length,
                        itemBuilder: (context, index) {
                          final pet = _pets[index];
                          return FutureBuilder<Map<String, int>>(
                            future: _todayTaskStatus(pet['id']),
                            builder: (context, snapshot) {
                              final total = snapshot.data?['total'] ?? 0;
                              final done = snapshot.data?['done'] ?? 0;
                              final allDone = total > 0 && done >= total;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFC9D0BA)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                PetProfilePage(pet: pet)),
                                      );
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3B679),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Image.asset(
                                                'assets/icons/ballpic.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pet['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  pet['breed'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (total > 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: allDone
                                                    ? Colors.green
                                                        .withOpacity(0.15)
                                                    : Colors.orange
                                                        .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: allDone
                                                  ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                      size: 18)
                                                  : Text(
                                                      '$done/$total',
                                                      style: const TextStyle(
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                            ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.chevron_left,
                                              color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetPage()),
          );
          _loadPets();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}