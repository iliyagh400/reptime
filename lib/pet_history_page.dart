import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetHistoryPage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetHistoryPage({super.key, required this.pet});

  @override
  State<PetHistoryPage> createState() => _PetHistoryPageState();
}

class _PetHistoryPageState extends State<PetHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];

  static const _background = Color(0xFF141C17);
  static const _surface = Color(0xFF263229);
  static const _surfaceRaised = Color(0xFF2D3930);
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
    _loadHistory();
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'food': return 'غذا';
      case 'cleaning': return 'نظافت';
      case 'medicine': return 'دارو';
      default: return 'دیگر';
    }
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() { _entries = []; _isLoading = false; });
        return;
      }

      final userId = user.id;
      final petId = widget.pet['id'];

      final routinesResponse = await Supabase.instance.client
          .from('routines').select().eq('user_id', userId);

      final routinesById = {
        for (final r in List<Map<String, dynamic>>.from(routinesResponse))
          r['id']: r
      };

      final completionsResponse = await Supabase.instance.client
          .from('completions').select()
          .eq('user_id', userId).eq('pet_id', petId);

      final eventsResponse = await Supabase.instance.client
          .from('pet_events').select()
          .eq('user_id', userId).eq('pet_id', petId);

      final checkinsResponse = await Supabase.instance.client
        .from('pet_checkins')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', petId);
    final checkins = List<Map<String, dynamic>>.from(checkinsResponse);

      final merged = <Map<String, dynamic>>[];

      for (final c in List<Map<String, dynamic>>.from(completionsResponse)) {
        final routine = routinesById[c['routine_id']];
        final isDone = c['status'] == 'done';
        final note = c['note'];

        merged.add({
          'date': DateTime.parse(c['completed_at']),
          'kind': isDone ? 'done' : 'skipped',
          'title': routine?['title'] ?? 'روتین حذف‌شده',
          'subtitle': isDone
              ? _typeLabel(routine?['type'])
              : (note != null && (note as String).isNotEmpty
                  ? 'رد شد · $note'
                  : 'رد شد'),
        });
      }

      for (final e in List<Map<String, dynamic>>.from(eventsResponse)) {
        merged.add({
          'date': DateTime.parse(e['event_date']),
          'kind': 'event',
          'title': e['description'] ?? '',
          'subtitle': 'ثبت دستی',
        });
      }
      for (final c in checkins) {
        final weight = c['weight'];
        final health = c['health_score'];
        final note = c['note'];
        merged.add({
          'date': DateTime.parse(c['checkin_date']),
          'kind': 'checkin',
          'title': 'وزن: ${weight ?? '—'} گرم · سلامت: ${health ?? '—'}/10',
          'subtitle': (note != null && (note as String).isNotEmpty)
              ? note
              : 'چک‌این ماهانه',
        });
        } 
      merged.sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _entries = merged;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در دریافت تاریخچه: $e',
                textDirection: TextDirection.rtl),
            backgroundColor: _surfaceRaised,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      }
    }
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(entryDay).inDays;
    if (diff == 0) return 'امروز';
    if (diff == 1) return 'دیروز';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  IconData _kindIcon(String kind) {
      switch (kind) {
        case 'done':
          return Icons.check_circle_rounded;
        case 'skipped':
          return Icons.cancel_rounded;
        case 'checkin':
          return Icons.monitor_weight_rounded;
        default:
          return Icons.event_note_rounded;
      }
    }

  Color _kindColor(String kind) {
      switch (kind) {
        case 'done':
          return Color(0xFF91B66D);;
        case 'skipped':
          return _muted;
        case 'checkin':
          return const Color(0xFFC8A66A); // sand
        default:
          return _terracotta;
      }
    }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'done': return 'انجام شد';
      case 'skipped': return 'رد شد';
      default: return 'رویداد';
    }
  }

  Widget _dateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: _moss, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(text, style: const TextStyle(
            color: _lightMoss, fontSize: 12, fontWeight: FontWeight.w800,
          )),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _line)),
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> entry) {
    final kind = entry['kind'] as String;
    final color = _kindColor(kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.13),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(.22)),
            ),
            child: Icon(_kindIcon(kind), color: color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['title']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text, fontSize: 15,
                    fontWeight: FontWeight.w800, height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry['subtitle']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted, fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      width: 3, height: 3,
                      decoration: const BoxDecoration(
                        color: _line, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(_kindLabel(kind), style: TextStyle(
                      color: color, fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: _surfaceRaised,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: _line),
            ),
            child: Text(_timeLabel(entry['date'] as DateTime),
                style: const TextStyle(
                  color: _sand, fontSize: 11, fontWeight: FontWeight.w800,
                )),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82, height: 82,
              decoration: BoxDecoration(
                color: _leaf.withOpacity(.28),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _line),
              ),
              child: const Icon(Icons.history_rounded,
                  color: _lightMoss, size: 38),
            ),
            const SizedBox(height: 20),
            const Text('هنوز هیچ اتفاقی ثبت نشده',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _text, fontSize: 17, fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 8),
            const Text(
              'وقتی روتینی انجام شود یا رویداد جدیدی برای حیوان ثبت کنی، اینجا نمایش داده می‌شود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 12, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petName = widget.pet['name']?.toString() ?? '';
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final entry in _entries) {
      final label = _dateLabel(entry['date'] as DateTime);
      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 20,
          iconTheme: const IconThemeData(color: _text),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تاریخچه', style: TextStyle(
                color: _muted, fontSize: 11, fontWeight: FontWeight.w600,
              )),
              Text(petName, style: const TextStyle(
                color: _text, fontSize: 20, fontWeight: FontWeight.w800,
              )),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(
                color: _moss, strokeWidth: 2.5))
            : _entries.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    color: _moss,
                    backgroundColor: _surface,
                    onRefresh: _loadHistory,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      children: grouped.entries.map((group) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _dateHeader(group.key),
                            ...group.value.map(_historyCard),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
      ),
    );
  }
}
