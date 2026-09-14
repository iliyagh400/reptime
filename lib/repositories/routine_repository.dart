// lib/repositories/routine_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routine_model.dart';
import '../models/completion_model.dart';

class RoutineRepository {
  final SupabaseClient _supabase;

  RoutineRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ۱. دریافت تمام روتین‌های کاربر جاری
  Future<List<Routine>> getRoutines() async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final response = await _supabase
        .from('routines')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Routine.fromJson(json)).toList();
  }

  // ۲. دریافت روتین‌های مرتبط با یک پت خاص
  Future<List<Routine>> getRoutinesForPet(int petId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    // جستجو در آرایه pet_ids
    final response = await _supabase
        .from('routines')
        .select()
        .eq('user_id', userId)
        .contains('pet_ids', [petId])
        .order('created_at', ascending: false);

    return (response as List).map((json) => Routine.fromJson(json)).toList();
  }

  // ۳. ایجاد یک روتین جدید
  Future<Routine> addRoutine(Routine routine) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final routineData = routine.toJson();
    routineData['user_id'] = userId;

    // سازگاری عقب‌رو (Backward compatibility) با کدهای قدیمی
    if (routineData.containsKey('pet_ids')) {
      routineData['pets_ids'] = routineData['pet_ids'];
    }

    final response = await _supabase
        .from('routines')
        .insert(routineData)
        .select()
        .single();

    return Routine.fromJson(response);
  }

  // ۴. ویرایش روتین
  Future<Routine> updateRoutine(int id, Routine routine) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final routineData = routine.toJson();
    if (routineData.containsKey('pet_ids')) {
      routineData['pets_ids'] = routineData['pet_ids'];
    }

    final response = await _supabase
        .from('routines')
        .update(routineData)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return Routine.fromJson(response);
  }

  // ۵. حذف روتین
  Future<void> deleteRoutine(int id) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    await _supabase
        .from('routines')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  // ۶. دریافت Completionهای ثبت‌شده برای امروز
  Future<List<Completion>> getTodayCompletions(DateTime date) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final dateStr = date.toIso8601String().split('T').first; // فرمت YYYY-MM-DD

    final response = await _supabase
        .from('completions')
        .select()
        .eq('user_id', userId)
        .eq('completion_date', dateStr);

    return (response as List).map((json) => Completion.fromJson(json)).toList();
  }

  // ۷. ثبت وضعیت انجام شدن/نشدن روتین (Complete / Uncomplete)
  Future<void> toggleRoutineCompletion({
    required int routineId,
    required int petId,
    required DateTime date,
    required bool isCompleted,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final dateStr = date.toIso8601String().split('T').first;

    if (isCompleted) {
      // ثبت در جدول completions
      await _supabase.from('completions').upsert({
        'routine_id': routineId,
        'pet_id': petId,
        'user_id': userId,
        'completion_date': dateStr,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } else {
      // حذف از جدول completions در صورت لغو تیک
      await _supabase
          .from('completions')
          .delete()
          .eq('routine_id', routineId)
          .eq('pet_id', petId)
          .eq('user_id', userId)
          .eq('completion_date', dateStr);
    }
  }
}
