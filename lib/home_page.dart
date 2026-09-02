import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_pet_page.dart';
import 'pet_profile_page.dart';
import 'add_routine_page.dart';
import 'notification_service.dart';
import 'settings_page.dart';
import 'routine_logic.dart';
import 'login_page.dart';
import 'species_data.dart';
import 'animated_entry.dart';

/// Premium redesigned HomePage.
///
/// The existing Supabase queries, routine logic and navigation are preserved.
/// This file focuses on presentation, hierarchy, spacing and interaction design.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _pets = [];
  bool _isLoading = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Dark Terrarium palette — visual styling only.
  static const _ink = Color(0xFFECE8DD);
  static const _muted = Color(0xFFA8A99A);
  static const _forest = Color(0xFF6E8B52);
  static const _forestDark = Color(0xFF17251D);
  static const _sage = Color(0xFF2D3B2F);
  static const _cream = Color(0xFF141C17);
  static const _line = Color(0xFF3A463C);
  static const _orange = Color(0xFFD08A52);
  static const _terracotta = Color(0xFFB86F4D);
  static const _sand = Color(0xFFC8A66A);
  static const _moss = Color(0xFF879B5D);
  static const _leaf = Color(0xFF486344);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPets() async {
    if (mounted) setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;

    final response = await Supabase.instance.client
        .from('pets')
        .select()
        .eq('user_id', userId);

    if (!mounted) return;

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
        .eq('pet_id', petId);

    final completions =
        List<Map<String, dynamic>>.from(completionsResponse);

    int total = 0;
    int done = 0;

    for (final routine in petRoutines) {
      if (isRelevantToday(routine, completions)) {
        if (isSkippedToday(routine, completions)) continue;

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
        .eq('user_id', userId);

    final allCompletions =
        List<Map<String, dynamic>>.from(completionsResponse);

    int total = 0;
    int done = 0;
    final List<Map<String, dynamic>> dueUncompleted = [];

    for (final routine in allRoutines) {
      final petIds = List.from(routine['pet_ids'] ?? []);
      bool anyPetDueUncompleted = false;

      for (final petId in petIds) {
        final petCompletions =
            allCompletions.where((c) => c['pet_id'] == petId).toList();

        if (isSkippedToday(routine, petCompletions)) continue;

        if (isRelevantToday(routine, petCompletions)) {
          total++;

          if (isDoneToday(routine, petCompletions)) {
            done++;
          } else {
            anyPetDueUncompleted = true;
          }
        }
      }

      if (anyPetDueUncompleted) {
        dueUncompleted.add(routine);
      }
    }

    await NotificationService.refreshOverdueReminders(dueUncompleted);

    return {'total': total, 'done': done};
  }

  Widget _buildPetIcon(
    Map<String, dynamic> pet, {
    required double size,
  }) {
    final imagePath = imagePathForBreed(pet['breed']);

    final fallback = Center(
      child: Text(
        emojiForSpeciesGroup(pet['species_group']),
        style: TextStyle(fontSize: size * 0.46),
      ),
    );

    if (imagePath == null) return fallback;

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Future<void> _openAddRoutine() async {
    if (_pets.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRoutinePage(pets: _pets),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _openAddPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPetPage()),
    );

    _loadPets();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'خروج از حساب',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        content: const Text(
          'مطمئنی می‌خوای از حسابت خارج بشی؟',
          textAlign: TextAlign.right,
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB64B45),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: _isLoading
              ? const _PremiumLoading()
              : RefreshIndicator(
                  color: _forest,
                  onRefresh: _loadPets,
                  child: _buildContent(),
                ),
        ),
        floatingActionButton: _pets.isEmpty
            ? FloatingActionButton.extended(
                backgroundColor: _terracotta,
                foregroundColor: const Color(0xFF171B17),
                elevation: 5,
                onPressed: _openAddPet,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'افزودن حیوان',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : FloatingActionButton(
                backgroundColor: _terracotta,
                foregroundColor: const Color(0xFF171B17),
                elevation: 6,
                onPressed: _openAddPet,
                child: const Icon(Icons.add_rounded, size: 28),
              ),
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _buildHeader(),
          ),
        ),
        if (_pets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildTodayHero(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildQuickActions(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _buildSearch(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            sliver: SliverToBoxAdapter(
              child: _buildSectionTitle(),
            ),
          ),
          _buildPetSliver(),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _leaf,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPTIME',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: _forestDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'مراقبت بهتر، حیوان سالم‌تر',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.alarm_add_rounded,
          tooltip: 'روتین جدید',
          onPressed: _pets.isEmpty ? null : _openAddRoutine,
        ),
        const SizedBox(width: 7),
        PopupMenuButton<String>(
          tooltip: 'منو',
          offset: const Offset(0, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            } else if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('تنظیمات'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20),
                  SizedBox(width: 10),
                  Text('خروج از حساب'),
                ],
              ),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _line.withOpacity(.78)),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayHero() {
    return FutureBuilder<Map<String, int>>(
      future: _overallTodayStatus(),
      builder: (context, snapshot) {
        final total = snapshot.data?['total'] ?? 0;
        final done = snapshot.data?['done'] ?? 0;
        final remaining = total - done;
        final progress = total == 0 ? 1.0 : (done / total).clamp(0.0, 1.0);

        final complete = total == 0 || remaining == 0;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: const [Color(0xFF17251D), Color(0xFF3D573B), Color(0xFF5D4635)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF080D09).withOpacity(.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -28,
                top: -30,
                child: Icon(
                  Icons.spa_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(.045),
                ),
              ),
              Positioned(
                right: -18,
                bottom: -42,
                child: Icon(
                  Icons.pets_rounded,
                  size: 130,
                  color: Colors.white.withOpacity(.035),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.10),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            complete ? 'همه‌چیز مرتبه ✓' : 'مراقبت امروز',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          complete
                              ? 'حیوون‌هات امروز\nکامل مراقبت شدن'
                              : '$remaining کار برای امروز باقی مونده',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          total == 0
                              ? 'روتین فعالی برای امروز نداری.'
                              : '$done از $total فعالیت انجام شده',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.70),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(.12),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD9E9D7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 78,
                          height: 78,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 7,
                            backgroundColor:
                                Colors.white.withOpacity(.10),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD9E9D7),
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'دسترسی سریع',
          style: TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.add_circle_outline_rounded,
                title: 'حیوان جدید',
                subtitle: 'ثبت حیوان',
                color: _forest,
                onTap: _openAddPet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.event_note_rounded,
                title: 'روتین جدید',
                subtitle: 'برنامه مراقبت',
                color: _terracotta,
                onTap: _pets.isEmpty ? null : _openAddRoutine,
              ),
            ),
          ],
        ),
      ],
    );
  }

 Widget _buildSearch() {
  return Container(
    height: 52,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1E2825), // رنگ کارت تیره هماهنگ با تم
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.08),
        width: 1,
      ),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      textDirection: TextDirection.rtl,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      cursorColor: const Color(0xFF4EBA88),
      decoration: InputDecoration(
        isDense: true,
        filled: false, // این خط جلوی سفید شدن اتوماتیک پس‌زمینه را می‌گیرد
        hintText: 'جستجوی حیوان...',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.white.withOpacity(0.6),
          size: 22,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                splashRadius: 18,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.6),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    ),
  );
}



  Widget _buildSectionTitle() {
    final count = _filteredPets().length;

    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حیوانات من',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'مدیریت و بررسی وضعیت حیوانات',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: _sage,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count حیوان',
            style: const TextStyle(
              color: _forestDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filteredPets() {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _pets;

    return _pets.where((pet) {
      final name = (pet['name'] ?? '').toString().toLowerCase();
      final breed = (pet['breed'] ?? '').toString().toLowerCase();
      return name.contains(query) || breed.contains(query);
    }).toList();
  }

  Widget _buildPetSliver() {
    final filteredPets = _filteredPets();

    if (filteredPets.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildNoSearchResults(),
      );
    }

    return SliverList.builder(
      itemCount: filteredPets.length,
      itemBuilder: (context, index) {
        final pet = filteredPets[index];

        return FutureBuilder<Map<String, int>>(
          future: _todayTaskStatus(pet['id']),
          builder: (context, snapshot) {
            final total = snapshot.data?['total'] ?? 0;
            final done = snapshot.data?['done'] ?? 0;
            final progress =
                total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
            final allDone = total > 0 && done >= total;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 5,
              ),
              child: FadeSlideIn(
                index: index,
                child: _PetCard(
                  pet: pet,
                  progress: progress,
                  total: total,
                  done: done,
                  allDone: allDone,
                  imageBuilder: () => _buildPetIcon(
                    pet,
                    size: 72,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetProfilePage(pet: pet),
                      ),
                    );

                    _loadPets();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: const Color(0xFF2C3C30),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: _forest,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'حیوانی پیدا نشد',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'اسم یا نژاد حیوان را جستجو کن.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3C30),
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.pets_rounded,
                size: 55,
                color: _forest,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'هنوز حیوانی اضافه نکردی',
              style: TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'اولین حیوانت را اضافه کن تا بتوانی\nروتین‌ها و مراقبت‌های روزانه‌اش را مدیریت کنی.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openAddPet,
              style: FilledButton.styleFrom(
                backgroundColor: _terracotta,
                foregroundColor: const Color(0xFF171B17),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'افزودن اولین حیوان',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _HomePageState._line.withOpacity(.78)),
            ),
            child: Icon(
              icon,
              color: onPressed == null
                  ? _HomePageState._muted.withOpacity(.35)
                  : _HomePageState._forestDark,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return Material(
      color: Color(0xFF263229),
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: disabled ? .45 : 1,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: _HomePageState._line.withOpacity(.78)),
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _HomePageState._ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _HomePageState._muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final double progress;
  final int total;
  final int done;
  final bool allDone;
  final Widget Function() imageBuilder;
  final VoidCallback onTap;

  const _PetCard({
    required this.pet,
    required this.progress,
    required this.total,
    required this.done,
    required this.allDone,
    required this.imageBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (pet['name'] ?? '').toString();
    final breed = (pet['breed'] ?? 'گونه نامشخص').toString();

    return Material(
      color: Color(0xFF263229),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _HomePageState._line.withOpacity(.78)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF354638),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: imageBuilder(),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _HomePageState._ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: _HomePageState._cream,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: _HomePageState._muted,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          breed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _HomePageState._muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              allDone
                                  ? Icons.check_circle_rounded
                                  : Icons.schedule_rounded,
                              size: 15,
                              color: allDone
                                  ? const Color(0xFF91B66D)
                                  : _HomePageState._orange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              total == 0
                                  ? 'امروز روتینی نداره'
                                  : allDone
                                      ? 'مراقبت امروز کامل شد'
                                      : '$done از $total فعالیت انجام شده',
                              style: TextStyle(
                                color: allDone
                                    ? const Color(0xFF91B66D)
                                    : _HomePageState._muted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 13),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    backgroundColor: const Color(0xFF3C473E),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allDone
                          ? const Color(0xFF91B66D)
                          : _HomePageState._orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumLoading extends StatelessWidget {
  const _PremiumLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: _HomePageState._sage,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: _HomePageState._forest,
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _HomePageState._forest,
            ),
          ),
        ],
      ),
    );
  }
}
