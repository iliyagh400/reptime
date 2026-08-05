import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_pet_page.dart';
import 'add_routine_page.dart';

class PetProfilePage extends StatefulWidget {
  final Map<String, dynamic> pet;
  const PetProfilePage({super.key, required this.pet});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  List<Map<String, dynamic>> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('routines')
        .select()
        .eq('user_id', userId);

    // فقط روتین‌هایی که این حیوون توی pet_ids شونه رو نگه می‌داریم
    final petId = widget.pet['id'];
    final allRoutines = List<Map<String, dynamic>>.from(response);
    final filtered = allRoutines.where((r) {
      final ids = List.from(r['pet_ids'] ?? []);
      return ids.contains(petId);
    }).toList();

    setState(() {
      _routines = filtered;
      _isLoading = false;
    });
  }

  String _typeLabel(String type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet['name'] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPetPage(pet: widget.pet),
                ),
              );
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? const Center(child: Text('هنوز روتینی برای این حیوون نیست'))
              : ListView.builder(
                  itemCount: _routines.length,
                  itemBuilder: (context, index) {
                    final r = _routines[index];
                    return ListTile(
                      title: Text(r['title'] ?? ''),
                      subtitle: Text(
                          '${_typeLabel(r['type'])} · ${r['time'] ?? ''}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRoutinePage(pets: [widget.pet]),
            ),
          );
          _loadRoutines();
        },
        child: const Icon(Icons.add_alarm),
      ),
    );
  }
}