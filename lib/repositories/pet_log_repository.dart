// lib/repositories/pet_log_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_event_model.dart';
import '../models/pet_checkin_model.dart';

class PetLogRepository {
  final SupabaseClient _supabase;

  PetLogRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // ==========================================
  // بخش ۱: رویدادهای پت (Pet Events)
  // ==========================================

  // دریافت تمام رویدادهای یک پت مشخص بر اساس تاریخ نزولی
  Future<List<PetEvent>> getEventsForPet(int petId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final response = await _supabase
        .from('pet_events')
        .select()
        .eq('pet_id', petId)
        .eq('user_id', userId)
        .order('event_date', ascending: false);

    return (response as List).map((json) => PetEvent.fromJson(json)).toList();
  }

  // ثبت یک رویداد جدید (غذا دادن، پوست‌اندازی، دارو و...)
  Future<PetEvent> addEvent(PetEvent event) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final eventData = event.toJson();
    eventData['user_id'] = userId;

    final response = await _supabase
        .from('pet_events')
        .insert(eventData)
        .select()
        .single();

    return PetEvent.fromJson(response);
  }

  // حذف رویداد
  Future<void> deleteEvent(int eventId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    await _supabase
        .from('pet_events')
        .delete()
        .eq('id', eventId)
        .eq('user_id', userId);
  }

  // ==========================================
  // بخش ۲: چک‌این‌ها و نمودار رشد (Pet Check-ins)
  // ==========================================

  // دریافت سوابق وزن و رشد یک پت
  Future<List<PetCheckin>> getCheckinsForPet(int petId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final response = await _supabase
        .from('pet_checkins')
        .select()
        .eq('pet_id', petId)
        .eq('user_id', userId)
        .order('checkin_date', ascending: false);

    return (response as List).map((json) => PetCheckin.fromJson(json)).toList();
  }

  // ثبت چک‌این جدید (وزن، طول و یادداشت)
  Future<PetCheckin> addCheckin(PetCheckin checkin) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    final checkinData = checkin.toJson();
    checkinData['user_id'] = userId;

    final response = await _supabase
        .from('pet_checkins')
        .insert(checkinData)
        .select()
        .single();

    return PetCheckin.fromJson(response);
  }

  // حذف چک‌این
  Future<void> deleteCheckin(int checkinId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('کاربر وارد حساب کاربری نشده است.');

    await _supabase
        .from('pet_checkins')
        .delete()
        .eq('id', checkinId)
        .eq('user_id', userId);
  }
}
