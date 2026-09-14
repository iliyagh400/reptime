// lib/repositories/pet_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';

class PetRepository {
  final SupabaseClient _supabase;

  PetRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // دریافت لیست پت‌های کاربر جاری
  Future<List<Pet>> getPets() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر لاگین نکرده است.');

    final response = await _supabase
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Pet.fromJson(json)).toList();
  }

  // دریافت یک پت بر اساس شناسه
  Future<Pet?> getPetById(int id) async {
    final response = await _supabase
        .from('pets')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Pet.fromJson(response);
  }

  // افزودن پت جدید
  Future<Pet> addPet(Pet pet) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر لاگین نکرده است.');

    final petData = pet.toJson();
    petData['user_id'] = userId;

    final response = await _supabase
        .from('pets')
        .insert(petData)
        .select()
        .single();

    return Pet.fromJson(response);
  }

  // ویرایش اطلاعات پت
  Future<Pet> updatePet(int id, Pet pet) async {
    final petData = pet.toJson();
    final response = await _supabase
        .from('pets')
        .update(petData)
        .eq('id', id)
        .select()
        .single();

    return Pet.fromJson(response);
  }

  // حذف پت
  Future<void> deletePet(int id) async {
    await _supabase.from('pets').delete().eq('id', id);
  }
}
