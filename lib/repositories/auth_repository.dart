// lib/repositories/auth_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // استریم تغییرات احراز هویت
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // سشن و کاربر فعلی
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  String? get currentUserEmail => _client.auth.currentUser?.email;

  // ورود با ایمیل و رمز
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ثبت‌نام کاربر جدید
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  // خروج از حساب
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // بازیابی رمز عبور
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'reptime://reset-password',
    );
  }

  // بررسی مجاز بودن کاربر لاگین شده بر اساس جدول allowed_users
  Future<bool> isUserAllowed() async {
    final email = currentUserEmail;
    if (email == null) return false;
    return await checkEmailAllowed(email);
  }

  // بررسی مجاز بودن ایمیل از طریق RPC یا کوئری
  Future<bool> checkEmailAllowed(String email) async {
    try {
      final res = await _client.rpc(
        'can_register_email',
        params: {'check_email': email.trim().toLowerCase()},
      );
      return res == true;
    } catch (_) {
      // در صورت بروز خطا به دلیل مسائل امنیتی مسدود می‌شود
      return false;
    }
  }

  // بررسی وجود داشتن ایمیل ثبت‌شده در دیتابیس
  Future<bool> checkUserExists(String email) async {
    try {
      final res = await _client.rpc(
        'user_exists_by_email',
        params: {'check_email': email.trim().toLowerCase()},
      );
      return res == true;
    } catch (_) {
      return true; // در صورت خطا پیش‌فرض true برمی‌گرداند تا ایمیل لو نرود
    }
  }
}
