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

  // Each entry: { date: DateTime, type: 'done'|'skipped'|'event', title, subtitle }
  List<Map<String, dynamic>> _entries = [];

  static const _green = Color(0xFF3F5D45);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'food':
        return 'غذا';
      case 'cleaning':
        return 'نظافت';
      case 'medicine':
        return 'دارو';
      default:
        return 'دیگر';
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final petId = widget.pet['id'];

    // Routine titles/types, so completion rows can show meaningful text.
    final routinesResponse = await Supabase.instance.client
        .from('routines')
        .select()
        .eq('user_id', userId);
    final routinesById = {
      for (final r in List<Map<String, dynamic>>.from(routinesResponse))
        r['id']: r
    };

    final completionsResponse = await Supabase.instance.client
        .from('completions')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', petId);
    final completions =
        List<Map<String, dynamic>>.from(completionsResponse);

    final eventsResponse = await Supabase.instance.client
        .from('pet_events')
        .select()
        .eq('user_id', userId)
        .eq('pet_id', petId);
    final events = List<Map<String, dynamic>>.from(eventsResponse);

    final List<Map<String, dynamic>> merged = [];

    for (final c in completions) {
      final routine = routinesById[c['routine_id']];
      final title = routine?['title'] ?? 'روتین حذف‌شده';
      final typeLabel = _typeLabel(routine?['type']);
      final isDone = c['status'] == 'done';
      merged.add({
        'date': DateTime.parse(c['completed_at']),
        'kind': isDone ? 'done' : 'skipped',
        'title': title,
        'subtitle': isDone
            ? typeLabel
            : (c['note'] != null && (c['note'] as String).isNotEmpty
                ? 'رد شد · ${c['note']}'
                : 'رد شد'),
      });
    }

    for (final e in events) {
      merged.add({
        'date': DateTime.parse(e['event_date']),
        'kind': 'event',
        'title': e['description'] ?? '',
        'subtitle': 'ثبت دستی',
      });
    }

    merged.sort((a, b) => (b['date'] as DateTime).compareTo(a['date']));

    setState(() {
      _entries = merged;
      _isLoading = false;
    });
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

  String _timeLabel(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'done':
        return Icons.check_circle;
      case 'skipped':
        return Icons.cancel;
      default:
        return Icons.event_note;
    }
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'done':
        return _green;
      case 'skipped':
        return Colors.grey;
      default:
        return const Color(0xFFB5563C);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group entries by date label, preserving sort order.
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final entry in _entries) {
      final label = _dateLabel(entry['date'] as DateTime);
      grouped.putIfAbsent(label, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('تاریخچه‌ی ${widget.pet['name'] ?? ''}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text(
                    'هنوز هیچ اتفاقی ثبت نشده',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((groupEntry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                          child: Text(
                            groupEntry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...groupEntry.value.map((entry) {
                          final kind = entry['kind'] as String;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFC9D0BA)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _kindColor(kind)
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(_kindIcon(kind),
                                      color: _kindColor(kind), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry['subtitle'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _timeLabel(entry['date'] as DateTime),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}