// lib/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  // وضعیت لاگین و کاربر فعلی
  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;
  String? get currentUserEmail => currentUser?.email;

  // استریم تغییرات وضعیت احراز هویت (Login / Logout)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ۱. بررسی مجاز بودن کاربر در جدول allowed_users (بر اساس ایمیل یا user_id)
  Future<bool> isUserAllowed() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final email = user.email?.toLowerCase().trim();
      if (email == null) return false;

      // بررسی بر اساس ستون email در جدول allowed_users
      final response = await _supabase
          .from('allowed_users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // در صورت وقوع هر خطایی، دسترسی بسته می‌ماند
      return false;
    }
  }

  // ۲. ورود با ایمیل و پسورد
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ۳. ثبت‌نام با ایمیل و پسورد
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: data,
    );
  }

  // ۴. خروج از حساب کاربری
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ۵. ارسال ایمیل بازیابی رمز عبور
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }
}
